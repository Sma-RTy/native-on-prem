import os
import sys
import libvirt
import time
import json
import re
import subprocess
from paramiko import SSHClient, AutoAddPolicy, ssh_exception
from scp import SCPClient
from shutil import copyfile
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from xml.etree import ElementTree as ET

_DPDK_DEVBIND_URL = 'https://raw.githubusercontent.com/DPDK/dpdk/master/usertools/dpdk-devbind.py'

_SNAPSHOT_XML_TEMPLATE = """
    <domainsnapshot>
      <name>{name}</name>
    </domainsnapshot>"""

_PCI_PASSTHROUGH_DEVICE_TEMPLATE = """
    <interface type='hostdev' managed='yes'>
      <driver name='vfio'/>
      <source>
        <address type='pci' domain='0x{domain}' bus='0x{bus}' slot='0x{slot}' function='0x{function}'/>
      </source>
    </interface>"""

_BRIDGE_DEVICE_TEMPLATE = """
    <interface type='bridge'>
      <source bridge='{bridge_interface}'/>
    </interface>"""

_MAC_ADDRESS_TEMPLATE = "<mac address='{address}'/>"


def _subst_filename(orig_path, filename):
    path, _ = os.path.split(orig_path)
    return os.path.join(path, filename)


_utils_lib = BuiltIn().get_library_instance("Utils")


def _prepare_xmls(vm_name, domain_xml_path, volume_xml_path, nic_vfs, bridge_if, mac_addr):
    # Prepare Domain XML
    cur_domain_xml_path = BuiltIn().get_variable_value("${deployment_dir}", default='./') + '/cur_domain.xml'
    copyfile(domain_xml_path, cur_domain_xml_path)

    # Set domain name
    root = ET.parse(cur_domain_xml_path)
    name = root.find('./name')
    name.text = vm_name

    # Set domain volume
    vol_path = root.find('./devices/disk/source')
    orig_path = vol_path.get('file')
    new_path = _subst_filename(orig_path, vm_name + '.qcow2')
    vol_path.set('file', new_path)

    devices = root.find('./devices')
    # Add all NIV VFs
    for nic_vf in nic_vfs:
        address = re.split(r'[:.]', nic_vf)
        nic_element = ET.fromstring(_PCI_PASSTHROUGH_DEVICE_TEMPLATE.format(domain=address[0], bus=address[1],
                                                                            slot=address[2], function=address[3]))
        devices.append(nic_element)

    # If a bridged network is defined add it as a device and remove default network device
    if bridge_if:
        bridge_element = ET.fromstring(_BRIDGE_DEVICE_TEMPLATE.format(bridge_interface=bridge_if))

        # Use specific MAC if it's provied
        if mac_addr:
            mac_element = ET.fromstring(_MAC_ADDRESS_TEMPLATE.format(address=mac_addr))
            bridge_element.append(mac_element)

        devices.append(bridge_element)

        default_net = devices.find("./interface[@type='network']/source[@network='default']/..")
        devices.remove(default_net)

    root.write(cur_domain_xml_path)

    # ---

    # Prepare Volume XML
    cur_volume_xml_path = BuiltIn().get_variable_value("${deployment_dir}", default='./') + '/cur_volume.xml'
    copyfile(volume_xml_path, cur_volume_xml_path)

    # Set volume name
    root = ET.parse(cur_volume_xml_path)
    name = root.find('./name')
    name.text = vm_name + '.qcow2'

    # Set path to qcow2 file
    key = root.find('./key')
    key.text = _subst_filename(key.text, vm_name + '.qcow2')

    path = root.find('./target/path')
    path.text = _subst_filename(path.text, vm_name + '.qcow2')

    root.write(cur_volume_xml_path)

    paths = (cur_domain_xml_path, cur_volume_xml_path)

    for path in paths:
        with open(path, 'r') as file:
            logger.debug("{}:\n{}".format(path, file.read().replace('\n', '')))

    return paths


def _get_dpdk_devbind_path():
    # We can't hardcode the path because the ${deployment_dir} can be set after Virtualization lib is initialized
    return os.path.join(BuiltIn().get_variable_value("${deployment_dir}"), 'dpdk-devbind.py')


def _get_dpdk_devbind(dest):
    if not os.path.exists(dest):
        subprocess.run(['wget', '-O', dest, _DPDK_DEVBIND_URL], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       check=True)
        os.chmod(dest, 0o755)
        logger.debug('Downloaded {} to {}'.format(_DPDK_DEVBIND_URL, dest))
    else:
        logger.debug('{} already exists'.format(dest))


def _reserve_nic_vfs(nic_vfs, nic_vfs_pool, dpdk_devbind_path):
    nic_vfs_info = dict()

    def reserve_one_nic_vf(nic_vf, nic_vfs_pool, dpdk_devbind_path):
        VFIO_PCI_DRIVER = 'vfio-pci'

        if nic_vf not in nic_vfs_pool:
            raise LookupError('NIC VF: {} is not listed in the pool: {}'.format(nic_vf, nic_vfs_pool))
        handle = subprocess.run([dpdk_devbind_path, '-s'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        logger.debug('{} -s\n{}'.format(dpdk_devbind_path, handle.stdout))

        # Get lines with a specific address
        nic_status = list(filter(lambda line: line.startswith(nic_vf), handle.stdout.decode().split('\n')))

        # Only one line should match
        if len(nic_status) == 0:
            raise LookupError('NIC VF: {} not found in dpdk-devbind status!'.format(nic_vf))
        elif len(nic_status) > 1:
            raise RuntimeError('Multiple ({}) NIC VF: {} entries found in dpdk-devbind status!\n{}'.format(
                len(nic_status), specific_vfs, '\n'.join(nic_status)))

        # Get current driver
        old_driver_match = re.search(r'drv=(\S+)', nic_status[0])
        old_driver = old_driver_match.groups()[0]

        if old_driver != VFIO_PCI_DRIVER:
            subprocess.run([dpdk_devbind_path, '-b', VFIO_PCI_DRIVER, nic_vf], check=True)

            nic_vfs_info[nic_vf] = dict()
            nic_vfs_info[nic_vf]['old_driver'] = old_driver
            nic_vfs_info[nic_vf]['cur_driver'] = VFIO_PCI_DRIVER
            nic_vfs_info[nic_vf]['if'] = ''
            nic_vfs_info[nic_vf]['is_internet_if'] = False

            logger.debug('NIC {} reserved, {}'.format(nic_vf, nic_vfs_info[nic_vf]))
        else:
            raise ValueError('NIC VF {} already in use'.format(nic_vf))

    def revert_changes():
        for nic_vf in nic_vfs_info:
            subprocess.run([dpdk_devbind_path, '-b', nic_vfs_info[nic_vf]['old_driver'], nic_vf], check=True)
            logger.debug('NIC {} reverted to old driver {}'.format(nic_vf, nic_vfs_info[nic_vf]['old_driver']))

    # Handle specific addresses first (remove duplicate addresses)
    specific_vfs = set(list(filter(lambda addr: addr != 'any', nic_vfs)))
    logger.debug('Trying to reserve following NICs: {}'.format(', '.join(specific_vfs)))
    for specific_vf in specific_vfs:
        try:
            reserve_one_nic_vf(specific_vf, nic_vfs_pool, dpdk_devbind_path)
            nic_vfs_pool.remove(specific_vf)
        except Exception as err:
            revert_changes()
            raise err

    # Handle 'any' NICs
    num_any = nic_vfs.count('any')
    num_reserved = 0
    while num_reserved < num_any:
        # Try to bind any NIC from the pool
        if len(nic_vfs_pool) == 0:
            revert_changes()
            raise EnvironmentError('Not enough free NIC VFs')
        any_nic = nic_vfs_pool[0]
        try:
            reserve_one_nic_vf(any_nic, nic_vfs_pool, dpdk_devbind_path)
            num_reserved += 1
        except ValueError:
            # This VF is already in use, try the next one
            pass
        finally:
            nic_vfs_pool.remove(any_nic)

    return nic_vfs_info

class Virtualization(object):
    """
    A high-level Virtualization abstraction based on libvirt.
    A typical use case is:

        Virtualization.Set Environment Config    ${env_config}
        ${vm_info}=    Virtualization.Clone VM    clone_name
        Virtualization.Cleanup
    """

    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'

    BASE_DIR = BuiltIn().get_variable_value("${ROBOT_BASE_DIR}", default='./')
    DOMAIN_XML_DEFAULT_PATH = BASE_DIR + '/resources/xml/default_domain.xml'
    VOLUME_XML_DEFAULT_PATH = BASE_DIR + '/resources/xml/default_volume.xml'

    POOL_DEFAULT_NAME = 'default'
    SNAPSHOT_RESERVED_NAMES = ('clean', 'deploy')

    def __init__(self):
        self._conn = libvirt.open('qemu:///system')
        self._env = None

        self._reserved_vfs_info = dict()

        run_uid = BuiltIn().get_variable_value("${RUN_UID}")
        assert run_uid is not None, 'RUN_UID variable is not set!'
        suite_name = BuiltIn().get_variable_value("${SUITE NAME}")
        assert suite_name is not None, 'SUITE NAME variable is not set!'

        utils_lib = BuiltIn().get_library_instance("Utils")
        suite_name = utils_lib.sanitize_testsuite_name(suite_name)
        self._run_uid = "{}_{}".format(run_uid, suite_name)

        logger.info("Virtualization library initialized, run_uid = '{}'".format(self._run_uid))

    @_utils_lib.retry_decorator()
    def _get_vm_ip(self, vm_name):
        dom = self._conn.lookupByName(vm_name)
        ifaces = dom.interfaceAddresses(libvirt.VIR_DOMAIN_INTERFACE_ADDRESSES_SRC_AGENT)
        logger.debug("'{}' VM interfaces: {}".format(vm_name, ifaces))

        for interface, val in ifaces.items():
            if interface != 'lo':
                for addr in val['addrs']:
                    if addr['type'] == libvirt.VIR_IP_ADDR_TYPE_IPV4:
                        return addr['addr']
        raise UserWarning("Couldn't obtain '{}' VM IP".format(vm_name))

    def _get_vm_mac(self, vm_name):
        dom = self._conn.lookupByName(vm_name)
        ifaces = dom.interfaceAddresses(libvirt.VIR_DOMAIN_INTERFACE_ADDRESSES_SRC_AGENT)
        logger.debug("'{}' VM interfaces: {}".format(vm_name, ifaces))
        for interface, val in ifaces.items():
            if interface != 'lo' and val['hwaddr']:
                return val['hwaddr']
        raise RuntimeError("Couldn't obtain '{}' VM NIC MAC address".format(vm_name))

    def _get_domain_volume(self, domain_name):
        # Get the base VM volume name from its XML
        domain = self._conn.lookupByName(domain_name)
        domain_xml = domain.XMLDesc(0)

        root = ET.fromstring(domain_xml)
        volume_path = root.find('./devices/disk/source').get('file')

        pool = self._conn.storagePoolLookupByName(self.POOL_DEFAULT_NAME)

        volumes = pool.listVolumes()
        for vol_name in volumes:
            volume = pool.storageVolLookupByName(vol_name)
            if volume.path() == volume_path:
                base_vol_name = volume.name()
                break
        else:
            raise RuntimeError('Volume with path: \'{}\' not found'.format(volume_path))

        return pool.storageVolLookupByName(base_vol_name)

    @_utils_lib.retry_decorator()
    def _copy_ssh_key(self, ip_addr):
        ssh = SSHClient()
        ssh.set_missing_host_key_policy(AutoAddPolicy())
        ssh.connect(ip_addr, username=self._env['vm']['username'], password=self._env['vm']['password'])

        scp = SCPClient(ssh.get_transport())
        ssh.exec_command('mkdir -p /root/.ssh')
        scp.put('/root/.ssh/id_rsa.pub', '/root/.ssh/client.pub')
        ssh.exec_command('cat /root/.ssh/client.pub >> /root/.ssh/authorized_keys')

        scp.close()
        logger.info('SSH public key copied to a machine with IP: {}'.format(ip_addr), also_console=True)

    @_utils_lib.retry_decorator()
    def copy_ssh_key_master_to_worker(self, cn_ip_addr, wn_ip_addr):

        ssh_wn = SSHClient()
        ssh_wn.set_missing_host_key_policy(AutoAddPolicy())
        ssh_wn.connect(wn_ip_addr, username=self._env['vm']['username'], password=self._env['vm']['password'])

        subprocess.call('mkdir -p /root/controller-key', shell=True)
        ssh_cn = SSHClient()
        ssh_cn.set_missing_host_key_policy(AutoAddPolicy())
        ssh_cn.connect(cn_ip_addr, username=self._env['vm']['username'], password=self._env['vm']['password'])
       
        ssh_cn.exec_command('ssh-keyscan -H '+wn_ip_addr+' >> ~/.ssh/known_hosts') 
        ssh_cn.exec_command('ssh-keygen -f /root/.ssh/id_rsa -N ""')
        scp = SCPClient(ssh_cn.get_transport())
        scp.get('/root/.ssh/id_rsa.pub', '/root/controller-key')

        scp1 = SCPClient(ssh_wn.get_transport())
        scp1.put('/root/controller-key/id_rsa.pub', '/root/.ssh/client.pub')
        ssh_wn.exec_command('cat /root/.ssh/client.pub >> /root/.ssh/authorized_keys')
 
        scp.close()
        scp1.close()
        ssh_wn.close()
        ssh_cn.close()
        subprocess.call('rm -rf /root/controller-key', shell=True)

        logger.info('SSH public key copied to a machine with IP: {}'.format(wn_ip_addr), also_console=True)
        
    def _make_unique(self, name):
        return "{}_{}".format(name, self._run_uid)

    def _get_vm_nics(self, vm_name, nic_vfs_info):
        nics = dict()

        domain = self._conn.lookupByName(vm_name)
        domain_xml = domain.XMLDesc(0)
        root = ET.fromstring(domain_xml)

        for nic_vf in nic_vfs_info:
            address = re.split(r'[:.]', nic_vf)
            vm_address_elem = root.find(("./devices/interface/source/address"
                "[@domain='0x{}'][@bus='0x{}'][@slot='0x{}'][@function='0x{}']../../address").format(
                address[0], address[1], address[2], address[3]))
            prefix = '0x'
            vm_address = "{}:{}:{}.{}".format(vm_address_elem.get('domain')[len(prefix):],
                                                vm_address_elem.get('bus')[len(prefix):],
                                                vm_address_elem.get('slot')[len(prefix):],
                                                vm_address_elem.get('function')[len(prefix):])
            nics[vm_address] = nic_vfs_info[nic_vf]
            nics[vm_address]['host_address'] = nic_vf

        return nics

    def get_passthrough_devs(self, vm_name):
        vm_unique_name = self._make_unique(vm_name)
        dom = self._conn.lookupByName(vm_unique_name)

        dom_xml = dom.XMLDesc()
        root = ET.fromstring(dom_xml)

        passthrough_devs = root.findall("./devices/*[@type='hostdev']")
        passthrough_dev_xmls = [ET.tostring(dev).decode() for dev in passthrough_devs]
        logger.info('VM {} passthrough devs: {}'.format(vm_name, passthrough_dev_xmls))

        return passthrough_dev_xmls

    def detach_dev(self, vm_name, dev_xml):
        vm_unique_name = self._make_unique(vm_name)
        dom = self._conn.lookupByName(vm_unique_name)
        logger.info('VM {} detach dev: {}'.format(vm_name, dev_xml))
        dom.detachDevice(dev_xml)

    def attach_dev(self, vm_name, dev_xml):
        vm_unique_name = self._make_unique(vm_name)
        dom = self._conn.lookupByName(vm_unique_name)
        logger.info('VM {} attach dev: {}'.format(vm_name, dev_xml))
        dom.attachDevice(dev_xml)

    def return_vfs_to_host(self):
        for vf, info in self._reserved_vfs_info.items():
            subprocess.run([_get_dpdk_devbind_path(), '-b', info['old_driver'], vf], check=True)
        self._reserved_vfs_info.clear()

    def set_environment_config(self, env_config):
        """
        Sets enviroment variables.

        :param dict env_config:
            a dict of environment variables containing information such as the
            default base VM.
        """

        self._env = env_config

        logger.info('Virtualization::Environment config set.', also_console=True)
        logger.debug('env: {}'.format(env_config))

    def clone_vm(self, vm_clone_name, vm_base_name=None, domain_xml_path=DOMAIN_XML_DEFAULT_PATH,
                 volume_xml_path=VOLUME_XML_DEFAULT_PATH, nic_vfs=[]):
        """
        Clones a VM from a base image and configuration XML.

        :param str vm_clone_name: new VM name
        :param str vm_base_name: name of the base VM
        :param str domain_xml_path: path to the VM configuration XML
        :param str volume_xml_path: path to the Volume (disk) configuration XML
        :param [str] nic_vfs: list of NIC VF pci addresses which should be passed through to the VM.
                              User can pass 'any' to passthrough any free NIC.

        :return: dictionary containing VM information
            { 'vm_name': {'ip': str, 'snapshots': [str], 'nic_vfs_info': {'addr1': {'old_driver': str, 'cur_driver': str}, ...}} }
        """

        if vm_base_name is None:
            vm_base_name = self._env['vm']['default_name']

        logger.info("Cloning VM: '{}' --> '{}'...".format(vm_base_name, vm_clone_name), also_console=True)

        # Reserve NICs
        nic_vfs_info = dict()
        if nic_vfs:
            _get_dpdk_devbind(_get_dpdk_devbind_path())
            nic_vfs_info = _reserve_nic_vfs(nic_vfs, self._env["nic_vfs_pool"], _get_dpdk_devbind_path())
            self._reserved_vfs_info.update(nic_vfs_info)

        # Get bridge interface from env config
        bridge_if = self._env['network_bridge']

        # Get unused MAC address from the pool if network bridge was provided
        mac_addr_reused = ''
        if bridge_if:
            resource_mgr_lib = BuiltIn().get_library_instance('ResourceMgr')
            try:
                mac_addr_reused = resource_mgr_lib.get_free_vm_mac(bridge_if)
            except LookupError as e:
                # There are no free MAC addresses
                logger.info(e)

        vm_unique_name = self._make_unique(vm_clone_name)

        # Substitute names in XMLs and add NIC VFs passthrough devices
        vm_domain_xml_path, vm_volume_xml_path = _prepare_xmls(vm_unique_name, domain_xml_path, volume_xml_path,
                                                               nic_vfs_info.keys(), bridge_if, mac_addr_reused)

        # Get the base volume in order to clone it
        base_vol = self._get_domain_volume(vm_base_name)

        # Clone the volume
        pool = self._conn.storagePoolLookupByName(self.POOL_DEFAULT_NAME)

        logger.info("Cloning disk image...", also_console=True)
        with open(vm_volume_xml_path, 'r') as file:
            volume_xml = file.read().replace('\n', '')
        pool.createXMLFrom(volume_xml, base_vol, 0)
        logger.info("Disk image cloned.", also_console=True)

        # Clone VM domain
        with open(vm_domain_xml_path, 'r') as file:
            domain_xml = file.read().replace('\n', '')
        dom = self._conn.defineXML(domain_xml)
        dom.create()
        logger.info("VM domain cloned.", also_console=True)

        # Get the machine's IP and copy the public key
        ip_addr = self._get_vm_ip(vm_unique_name)
        self._copy_ssh_key(ip_addr)

        # Get the machine's NIC MAC address
        mac_addr = self._get_vm_mac(vm_unique_name)

        # If new MAC address was assigned then add it to the pool
        if bridge_if and not mac_addr_reused:
            resource_mgr_lib.add_vm_mac(mac_addr, bridge_if, in_use=True)

        # We need to wait a few seconds in order to successfuly unplug the PCI
        # devices which is needed to create a snapshot.
        time.sleep(5)

        clean_snapshot_name = 'clean'
        self.create_snapshot(vm_clone_name, clean_snapshot_name, False)

        vm_info = dict()
        vm_info['username'] = self._env['vm']['username']
        vm_info['ip'] = ip_addr
        vm_info['mac'] = mac_addr
        vm_info['snapshots'] = [clean_snapshot_name, ]
        vm_info['nics'] = self._get_vm_nics(vm_unique_name, nic_vfs_info)
        vm_info['is_physical'] = False
        logger.info("Created VM '{}': {}".format(vm_clone_name, vm_info), also_console=True)

        return vm_clone_name, vm_info

    def delete_vm(self, vm_name):
        """
        Removes a VM (configuration and storage).

        :param str vm_name: VM name
        """

        vm_unique_name = self._make_unique(vm_name)
        domain = self._conn.lookupByName(vm_unique_name)

        # Return VM MAC to the pool
        bridge_if = self._env['network_bridge']
        resource_mgr_lib = BuiltIn().get_library_instance('ResourceMgr')
        if bridge_if:
            mac_addr = self._get_vm_mac(vm_unique_name)
            resource_mgr_lib.return_vm_mac_to_pool(mac_addr, bridge_if)

        try:
            domain.destroy()
        except Exception:
            pass
        for snap_name in domain.snapshotListNames():
            domain.snapshotLookupByName(snap_name).delete()
        domain.undefine()

        vol = self._get_domain_volume(vm_unique_name)
        vol.wipe()
        vol.delete()

        logger.info("Deleted VM: '{}'".format(vm_name), also_console=True)

    def cleanup(self):
        """
        Removes all disk images and VMs created during this test execution.
        """
        bridge_if = self._env['network_bridge']
        resource_mgr_lib = BuiltIn().get_library_instance('ResourceMgr')

        if self._run_uid:
            for domain in self._conn.listAllDomains():
                if self._run_uid in domain.name():
                    # Return VM MAC to the pool
                    if bridge_if:
                        mac_addr = self._get_vm_mac(domain.name())
                        resource_mgr_lib.return_vm_mac_to_pool(mac_addr, bridge_if)

                    try:
                        domain.destroy()
                    except Exception:
                        pass
                    for snap_name in domain.snapshotListNames():
                        domain.snapshotLookupByName(snap_name).delete()
                    domain.undefine()
                    logger.info("'{}' VM destroyed and undefined.".format(domain.name()), also_console=True)

            pool = self._conn.storagePoolLookupByName(self.POOL_DEFAULT_NAME)
            for volume in pool.listAllVolumes():
                if self._run_uid in volume.name():
                    volume.wipe()
                    volume.delete()
                    logger.info("'{}' disk deleted.".format(volume.name()), also_console=True)

    def create_snapshot(self, vm_name, snapshot_name, is_custom=True):
        """
        Creates a snapshot for VM.

        :param str vm_name: VM name.
        :param str snapshot_name: Snapshot name.
        :param bool is_custom:
            Signals if a snapshot is created by the user. This flag is needed to prevent the user from creating a
            snapshot with a conflicting name ('clean' and 'deploy' names are reserved by this library).
        """

        vm_unique_name = self._make_unique(vm_name)

        logger.info("Creating snapshot: '{}' on VM: '{}'...".format(snapshot_name, vm_name), also_console=True)

        if is_custom and snapshot_name in self.SNAPSHOT_RESERVED_NAMES:
            raise TypeError("Given snapshot_name ('{}') can't be used by user."
                            "Reserved snapshot names: '{}'".format(snapshot_name, self.SNAPSHOT_RESERVED_NAMES))
        else:
            dom = self._conn.lookupByName(vm_unique_name)

            # All VFs need to be detached before creating a snapshot
            passthrough_devs = self.get_passthrough_devs(vm_name)
            for passthrough_dev in passthrough_devs:
                self.detach_dev(vm_name, passthrough_dev)

            # 'virsh' command is used to create snapshots as there are some issues when reverting to the snapshots
            # created by snapshotCreateXML
            # TODO: investigate why reverting to snapshots created using snapshotCreateXML breaks kubernetes pods
            subprocess.run(['virsh', 'snapshot-create-as', '--domain', vm_unique_name, '--name', snapshot_name],
                           check=True)

            # dom.snapshotCreateXML(_SNAPSHOT_XML_TEMPLATE.format(name=snapshot_name))
            # logger.info("Snapshot created.", also_console=True)

            # Re-attach VFs
            for passthrough_dev in passthrough_devs:
                self.attach_dev(vm_name, passthrough_dev)

    @_utils_lib.retry_decorator()
    def update_sys_clock(self, vm_name, vm_ip):
        """Updates VM system clock from HW clock.

        :param str vm_name: VM name.
        :param str vm_ip: VM IP.
        """

        ssh = SSHClient()
        ssh.set_missing_host_key_policy(AutoAddPolicy())
        ssh.connect(vm_ip, username=self._env['vm']['username'], timeout=120)

        _utils_lib.run_ssh_command(vm_name, ssh, "hwclock --hctosys")
        logger.info("Updated VM {} clock to hwclock".format(vm_name))

    def revert_to_snapshot(self, vm_name, vm_ip, snapshot_name):
        """
        Reverts a VM to a given snapshot.

        :param str vm_name: VM name
        :param str snapshot_name: Snapshot name
        """

        logger.info("Reverting to snapshot: '{}' on VM: '{}'...".format(snapshot_name, vm_name), also_console=True)

        vm_unique_name = self._make_unique(vm_name)

        # All VFs need to be detached
        passthrough_devs = self.get_passthrough_devs(vm_name)
        for passthrough_dev in passthrough_devs:
            self.detach_dev(vm_name, passthrough_dev)

        dom = self._conn.lookupByName(vm_unique_name)
        snap = dom.snapshotLookupByName(snapshot_name)
        dom.revertToSnapshot(snap)

        self.update_sys_clock(vm_name, vm_ip)

        # Re-attach VFs
        for passthrough_dev in passthrough_devs:
            self.attach_dev(vm_name, passthrough_dev)

        logger.info("Revert done.", also_console=True)

    def get_run_uid(self):
        """Returns a unique ID of a current run.
        """
        return self._run_uid

    def suspend_vms(self):
        """
        Suspend VMs created by this instance.
        """

        if self._run_uid:
            for domain in self._conn.listAllDomains():
                if self._run_uid in domain.name():
                    domain.suspend()
                    logger.info("'{}' VM suspended.".format(domain.name()), also_console=True)

    def use_existing_setup(self, run_uid):
        """
        Use setup from previous run (devel mode).

        :param str run_uid: Run UID
        """

        self._run_uid = run_uid
