import copy
import fcntl
import os
import subprocess

from paramiko import AutoAddPolicy, SSHClient
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from xml.etree import ElementTree as ET


_utils_lib = BuiltIn().get_library_instance("Utils")
_ip_regexp = r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"


def _get_lv_names(hostname, ssh_client):
    # Get all LV names
    stdout = _utils_lib.run_ssh_command(hostname, ssh_client, "lvs --noheadings --options lv_name")

    # Strip names from  leading and trailing spaces and remove empty strings
    lv_names = stdout.split('\n')
    lv_names = [lv_name.strip() for lv_name in lv_names]
    lv_names = [lv_name for lv_name in lv_names if lv_name]

    logger.info('{} LVs: {}'.format(hostname, lv_names))
    return lv_names


@_utils_lib.retry_decorator(exc_type=UserWarning)
def _wait_until_machine_is_offline(hostname):
    handle = subprocess.run(['ping', '-c', '1', hostname], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if handle.returncode == 0:
        raise UserWarning('Machine is not offline')


@_utils_lib.retry_decorator(count=30, sleep_interval=120, exc_type=UserWarning)
def _wait_until_revert_completes(hostname, ssh_client, root_lv):
    # While revert is in progress the root LV has 'O' attribute
    stdout = _utils_lib.run_ssh_command(hostname, ssh_client, "lvs --select 'lv_name={} && lv_attr=~.*O.*'".format(root_lv))
    if stdout:
        raise UserWarning('Revert not complete')


@_utils_lib.retry_decorator(count=20, sleep_interval=30)
def _ssh_connect_with_retry(ssh, hostname, username):
    ssh.connect(hostname, username=username)


def _get_nics(hostname, ssh_client):
    # Find internet connection interface
    stdout = _utils_lib.run_ssh_command(hostname, ssh_client, r"ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)'")
    internet_if = stdout.strip()

    # Get proxy settings
    env = BuiltIn().get_variable_value("${env_config}")

    # Install lshw
    _utils_lib.run_ssh_command(hostname, ssh_client, "http_proxy={} yum install -y lshw".format(env['proxy']['http']))

    # Get all network interfaces
    stdout = _utils_lib.run_ssh_command(hostname, ssh_client, r"lshw -class network -quiet -xml")
    logger.debug("Network devices: {}".format(stdout))
    hw_list = ET.fromstring(stdout)

    # Filter physical interfaces with PCI addresses
    nics = dict()
    HANDLE_PREFIX = "PCI:"
    physical_nics = hw_list.findall("./node[@handle]")
    for physical_nic in physical_nics:
        pci_addr = physical_nic.get("handle")[len(HANDLE_PREFIX):]
        if_name = physical_nic.find('logicalname').text

        nics[pci_addr] = dict()
        nics[pci_addr]['if'] = if_name
        nics[pci_addr]['is_internet_if'] = (if_name == internet_if)

    return nics


class PhysicalMachines(object):
    """Physical machines control class.

    PhysicalMachines can be used for reserving the machines, managing their LVM snapshots etc.
    A typical use case:

        ${pm_name}    ${pm_info}=    PhysicalMachines.Reserve Physical Machine
        <work with the machine, change its state>
        PhysicalMachines.Revert To Snapshot    clean
        ...
        PhysicalMachines.Cleanup
    """

    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'
    CLEAN_SNAPSHOT = 'clean'
    LOCK_FILES_PATH = '/var/lock/robot/'

    def __init__(self):
        self._reserved_machines = dict()
        self._env = None
        self._lockfiles = dict()
        self._snapshots = dict()
        if not os.path.exists(self.LOCK_FILES_PATH):
            os.mkdir(self.LOCK_FILES_PATH)

    def _get_machine_ip(self, machine_name):
        """Returns machine IP address.

        :param str machine_name: Machine name.
        """

        machines_pool = self._env['physical_machines']
        machine_data = machines_pool[machine_name]

        hostname = machine_data['hostname']
        username = machine_data['username']

        ssh = SSHClient()
        ssh.set_missing_host_key_policy(AutoAddPolicy())
        ssh.connect(hostname, username=username, timeout=120)

        # Find internet connection interface
        stdout = _utils_lib.run_ssh_command(hostname, ssh, r"ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)'")
        internet_if = stdout.strip()

        stdout = _utils_lib.run_ssh_command(hostname, ssh, r"ip a show dev {} | grep -Po '(?<=inet )({})'".format(internet_if, _ip_regexp))
        ip_addr = stdout.strip()
        return ip_addr

    def _get_machine_hostname(self, machine_name):
        """Returns machine hostname.

        :param str machine_name: Machine name.
        """

        machines_pool = self._env['physical_machines']
        machine_data = machines_pool[machine_name]

        hostname = machine_data['hostname']
        username = machine_data['username']

        ssh = SSHClient()
        ssh.set_missing_host_key_policy(AutoAddPolicy())
        ssh.connect(hostname, username=username, timeout=120)

        # Get hostname
        stdout = _utils_lib.run_ssh_command(hostname, ssh, r"hostnamectl --static")
        hostname = stdout.strip()
        return hostname

    def set_environment_config(self, env_config):
        """Sets enviroment variables.

        :param dict env_config: a dict of environment variables containing information such as the default base VM.
        """

        self._env = env_config

        logger.info('PhysicalMachines::Environment config set.', also_console=True)
        logger.debug('env: {}'.format(env_config))

    def lock_machine(self, machine_name, reuse=False):
        """Locks a file /var/lock/robot/<machine_name> to indicate that the machine is in use

        :param str machine_name: Specifies which machine should be locked.
        :param bool reuse: True if machines are reused in developer mode, False otherwise
        """

        already_used_msg = 'Machine {} is already in use'.format(machine_name)

        lock_file_path = os.path.join(self.LOCK_FILES_PATH, machine_name)
        if not os.path.exists(lock_file_path):
            if reuse:
                logger.warn('Missing lock file for reused machine {}'.format(machine_name))
            os.system("touch {}".format(lock_file_path))
        elif not reuse:
            logger.warn(already_used_msg)
            raise UserWarning(already_used_msg)

        f = open(lock_file_path, 'w')
        try:
            fcntl.flock(f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            logger.debug('Successfuly locked machine {} (lock file {})'.format(machine_name, lock_file_path))
            self._lockfiles[machine_name] = f
        except Exception as e:
            f.close()
            logger.warn(already_used_msg)
            raise e

    def reserve_physical_machine(self, machine_type=""):
        """Reserve one physical machine from ${env_config['physical_machines']} pool.

        :param str machine_type: Machine type (as selected in 'physical_nodes' in env.json).

        :return: Dictionary with machine info.
        """

        def check_machine_prereqs():
            # Check if there's a clean snapshot on a machine
            lv_names = _get_lv_names(hostname, ssh)

            if self.CLEAN_SNAPSHOT not in lv_names:
                logger.warn("Machine {} does not meet the requirements (no '{}' snapshot)".format(
                    machine_name, self.CLEAN_SNAPSHOT))
                raise LookupError("No '{}' LV snapshot on {}".format(self.CLEAN_SNAPSHOT, machine_name))

            # Kernel boot file should be present
            kernel_presnap_path = '/boot/kernel.presnap.{}'.format(self.CLEAN_SNAPSHOT)
            try:
                _utils_lib.run_ssh_command(hostname, ssh, "ls {}".format(kernel_presnap_path))
            except Exception as e:
                logger.warn("Machine {} does not meet the requirements (no '{}' kernel boot file)".format(
                    machine_name, kernel_presnap_path))
                raise e

        machines_pool = copy.deepcopy(self._env['physical_machines'])

        if not machine_type:
            logger.info('Reserving first valid machine')
            while True:
                if len(machines_pool) == 0:
                    raise EnvironmentError('Not enough free physical machines')

                machine_name, machine_data = machines_pool.popitem()
                hostname = machine_data['hostname']
                username = machine_data['username']

                ssh = SSHClient()
                ssh.set_missing_host_key_policy(AutoAddPolicy())
                ssh.connect(hostname, username=username, timeout=120)

                logger.info("Reserving machine: '{}': {}".format(machine_name, machine_data))
                try:
                    check_machine_prereqs()
                    self.lock_machine(machine_name)
                    break
                except Exception:
                    # This Machine is already in use or is invalid, try the next one
                    ssh.close()
                    pass
        else:
            # Concrete machine type is specified
            typed_machines = [key for (key, data) in machines_pool.items() if data['type'] == machine_type]

            logger.debug('Machines of type {}: {}'.format(machine_type, typed_machines))

            while True:
                if len(typed_machines) == 0:
                    raise LookupError('No free machines with type {} listed in the pool: {}'.format(machine_type, machines_pool))

                machine_name = typed_machines.pop()
                machine_data = machines_pool[machine_name]
                hostname = machine_data['hostname']
                username = machine_data['username']

                ssh = SSHClient()
                ssh.set_missing_host_key_policy(AutoAddPolicy())
                ssh.connect(hostname, username=username, timeout=120)

                logger.info('Reserving machine: {}'.format(machine_data))
                try:
                    check_machine_prereqs()
                    self.lock_machine(machine_name)
                    break
                except Exception:
                    ssh.close()
                    pass

        # Get all available NICs without loopback and internet connection interface
        nics = _get_nics(hostname, ssh)

        machine_info = dict()
        machine_info['hostname'] = self._get_machine_hostname(machine_name).lower()
        machine_info['username'] = machine_data['username']
        machine_info['ip'] = self._get_machine_ip(machine_name)
        machine_info['snapshots'] = [self.CLEAN_SNAPSHOT, ]
        machine_info['nics'] = nics
        machine_info['is_physical'] = True

        self._reserved_machines[machine_name] = machine_info
        self._snapshots[machine_name] = [self.CLEAN_SNAPSHOT]

        logger.info("Reserved Physical Machine '{}': {}".format(machine_name, machine_info), also_console=True)

        return machine_name, machine_info

    def cleanup(self):
        """Release all currently used lock files by file objects and deleting the files.
        """

        for machine_name, fd in self._lockfiles.items():
            # Remove all snapshots except for CLEAN_SNAPSHOT
            for snap in self._snapshots[machine_name]:
                if snap != self.CLEAN_SNAPSHOT:
                    self.remove_snapshot(machine_name, snap)

            # Revert to CLEAN_SNAPSHOT
            self.revert_to_snapshot_and_recreate(machine_name, self.CLEAN_SNAPSHOT)

            # Remove lock
            fd.close()
            os.unlink(fd.name)
            logger.info('Released lock file {}'.format(fd.name), also_console=True)
        self._lockfiles.clear()

    def use_machines(self, machines):
        """Use given machines and lock them.

        :param [str] machines: List of machines.
        """
        for machine in machines:
            self.lock_machine(machine, reuse=True)

    def update_snapshot_list(self, machine_name, snapshots):
        """Update snapshot list for a given machine.

        :param str machine_name: Machine name returned by reserve_physical_machine().
        :param [str] snapshots: List of snapshots.
        """
        self._snapshots[machine_name] = snapshots

    def create_snapshot(self, machine_name, snapshot_name, size='100G'):
        """Create a LV snapshot.

        :param str machine_name: Machine name returned by reserve_physical_machine().
        :param str snapshot_name: Snapshot name.
        :param str size: Size string passed to lvcreate command.
        """

        machine_data = self._env['physical_machines'][machine_name]
        hostname = machine_data['hostname']
        username = machine_data['username']

        logger.info("Creating snapshot: '{}' on Machine: '{}'...".format(snapshot_name, machine_name), also_console=True)

        # Connect to the machine
        with SSHClient() as ssh:
            ssh.set_missing_host_key_policy(AutoAddPolicy())
            ssh.connect(hostname, username=username, timeout=120)

            # Verify that the snapshot doesn't already exist
            lv_names = _get_lv_names(hostname, ssh)
            if snapshot_name in lv_names:
                raise ValueError("Snapshot '{}' already exists on machine {}".format(snapshot_name, machine_name))

            # Create pre-snap kernel version file
            _utils_lib.run_ssh_command(hostname, ssh, ("echo \"/boot/vmlinuz-`uname -r`\" "
                                            "> /boot/kernel.presnap.{}").format(snapshot_name))

            # Create snapshot
            _utils_lib.run_ssh_command(hostname, ssh, 'lvcreate --chunksize 64k --snapshot /dev/{}/{} --name {} --size {}'.format(
                machine_data['vg'], machine_data['root_lv'], snapshot_name, size))

        self._snapshots[machine_name].append(snapshot_name)

        logger.info("Snapshot created.", also_console=True)

    def revert_to_snapshot(self, machine_name, snapshot_name):
        """Revert to a LV snapshot (snapshot is destroyed upon revert).

        :param str machine_name: Machine name returned by reserve_physical_machine().
        :param str snapshot_name: Snapshot name.
        """

        machine_data = self._env['physical_machines'][machine_name]
        hostname = machine_data['hostname']
        username = machine_data['username']

        logger.info("Reverting to snapshot: '{}' on Machine: '{}'...".format(snapshot_name, machine_name), also_console=True)

        # Connect to the machine
        with SSHClient() as ssh:
            ssh.set_missing_host_key_policy(AutoAddPolicy())
            ssh.connect(hostname, username=username, timeout=120)

            # Verify that the snapshot already exist
            lv_names = _get_lv_names(hostname, ssh)
            if snapshot_name not in lv_names:
                raise ValueError("Snapshot '{}' doesn't exist on machine {}".format(snapshot_name, machine_name))

            # Set the correct kernel image to boot
            stdout = _utils_lib.run_ssh_command(hostname, ssh, "cat /boot/kernel.presnap.{}".format(snapshot_name))
            kernel_image = stdout.strip()
            logger.info("Setting boot '{}' kernel image".format(kernel_image), also_console=True)
            _utils_lib.run_ssh_command(hostname, ssh, "grubby --set-default {}".format(kernel_image))

            # Revert to snapshot and reboot
            _utils_lib.run_ssh_command(hostname, ssh, "lvconvert --merge /dev/{}/{} -y".format(machine_data['vg'], snapshot_name))

            # Sleep before reboot to avoid getting error return code
            _utils_lib.run_ssh_command(hostname, ssh, "sh -c 'sync; sleep 1; reboot' &")
            logger.info("Rebooting {}...".format(machine_name), also_console=True)

        _wait_until_machine_is_offline(hostname)

        # Connect to the machine after a reboot
        with SSHClient() as ssh:
            ssh.set_missing_host_key_policy(AutoAddPolicy())
            _ssh_connect_with_retry(ssh, hostname, username)

            logger.info("Connected, waiting for revert to complete...", also_console=True)
            _wait_until_revert_completes(hostname, ssh, machine_data['root_lv'])

        self._snapshots[machine_name].remove(snapshot_name)

        logger.info("Revert done.", also_console=True)


    def reboot_and_wait_until_up(self, machine_name):
        """Reboot a machine and wait until is up again

        :param str machine_name: Machine name returned by reserve_physical_machine().
        """

        machine_data = self._env['physical_machines'][machine_name]
        hostname = machine_data['hostname']
        username = machine_data['username']

        logger.info("Rebooting machine: '{}'".format(machine_name), also_console=True)
        with SSHClient() as ssh:
            ssh.set_missing_host_key_policy(AutoAddPolicy())
            ssh.connect(hostname, username=username, timeout=120)
            _utils_lib.run_ssh_command(hostname, ssh, "sh -c 'sync; sleep 1; reboot' &")

        _wait_until_machine_is_offline(hostname)

        with SSHClient() as ssh:
            ssh.set_missing_host_key_policy(AutoAddPolicy())
            _ssh_connect_with_retry(ssh, hostname, username)

        logger.info("Rebooted", also_console=True)


    def revert_to_snapshot_and_recreate(self, machine_name, snapshot_name, size=''):
        """Revert to a LV snapshot and recreate it.

        :param str machine_name: Machine name returned by reserve_physical_machine().
        :param str snapshot_name: Snapshot name.
        :param str size: Size string passed to lvcreate command. If omitted the current snapshot size is kept.
        """

        logger.info("Reverting and recreating {} snapshot on {}.".format(snapshot_name, machine_name), also_console=True)

        machine_data = self._env['physical_machines'][machine_name]
        hostname = machine_data['hostname']
        username = machine_data['username']

        # Get current snapshot size
        if not size:
            with SSHClient() as ssh:
                ssh.set_missing_host_key_policy(AutoAddPolicy())
                ssh.connect(hostname, username=username, timeout=120)

                stdout = _utils_lib.run_ssh_command(hostname, ssh,
                    "lvs --noheadings --select 'lv_name={}' --options lv_size".format(snapshot_name))
                # Size can be returned in following format: '<90g', we need to remove the less sign
                size = stdout.strip().replace('<','')
                logger.debug("Snapshot {} size is {}".format(snapshot_name, size))


        self.revert_to_snapshot(machine_name, snapshot_name)
        self.create_snapshot(machine_name, snapshot_name, size)

    def remove_snapshot(self, machine_name, snapshot_name):
        """Remove given snapshot.

        :param str machine_name: Machine name returned by reserve_physical_machine().
        :param str snapshot_name: Snapshot name.
        """

        logger.info("Removing {} snapshot on {}.".format(snapshot_name, machine_name), also_console=True)

        machine_data = self._env['physical_machines'][machine_name]
        hostname = machine_data['hostname']
        username = machine_data['username']

        with SSHClient() as ssh:
            ssh.set_missing_host_key_policy(AutoAddPolicy())
            ssh.connect(hostname, username=username, timeout=120)
            _utils_lib.run_ssh_command(hostname, ssh, "lvremove /dev/{}/{} -y".format(machine_data['vg'], snapshot_name))

        logger.info("Snapshot removed.", also_console=True)
