```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/12: NIC SRIOV](#itponp12-nic-sriov)
  - [ITP/ONP/12/01: Container Deployment with SRIOV](#itponp1201-container-deployment-with-sriov)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test Steps](#test-steps)
  - [ITP/ONP/12/02: Container Deployment with incorrect SRIOV setting](#itponp1202-container-deployment-with-incorrect-sriov-setting)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test Steps](#test-steps-1)
  - [ITP/ONP/12/03: VM Deployment with SRIOV](#itponp1203-vm-deployment-with-sriov)
    - [Test Summary](#test-summary-2)
    - [Prerequisites](#prerequisites-2)
    - [Test Steps](#test-steps-2)
  - [ITP/ONP/12/04: VM Deployment with incorrect SRIOV setting](#itponp1204-vm-deployment-with-incorrect-sriov-setting)
    - [Test Summary](#test-summary-3)
    - [Prerequisites](#prerequisites-3)
    - [Test Steps](#test-steps-3)

# ITP/ONP/12: NIC SRIOV

## ITP/ONP/12/01: Container Deployment with SRIOV

### Test Summary

This test will ensure that the deployed container uses a SRIOV port provided from the Edge Node host system.

### Prerequisites

- NIC with SRIOV support installed on the Edge Node.
- Controller API, UI and database installed using the ansible scripts and running.
- Ansible scripts updated with the required SRIOV settings for On-Premises mode as outlined in [SRIOV EPA Document](https://github.com/otcshare/specs/blob/master/doc/enhanced-platform-awareness/openness-sriov-multiple-interfaces.md).
- Edge Node installed using updated ansible scripts and running.
- Apache server has been set up with the ansible scripts and has a container image with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*.
   - Add the following input:
     - **Name:** EAC_App_SRIOV_Container
     - **Type:** container
     - **Version:** 77
     - **Vendor:** Intel
     - **Description:** A container app using an SRIOV port
     - **Cores:**: 7
     - **Memory:** 1234
     - **Source:** container image stored in the Apache server
     - Skip the port settings
     - EPA Feature:
       - **EPA Feature Key:** sriov_nic
       - **EPA Feature Value:** *docker network name*
   - Click *Upload Application*.
   - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on.
   - Select *Apps*, click *DEPLOY APP*, select EAC_App_SRIOV_Container from the dropdown menu and click *DEPLOY*.
   - Click *START* to start the container on the node.
2. Log onto the node:
   - Run `docker ps -a` to get the name of the deployed container
   - To check the docker network that the container is connected to, run `docker inspect <container_name>` and look for the entry *NetworkMode*, this should be set to the network name that was provided as the EPA Feature Key in the UI.
   - Check the output of the command `docker network inspect <network_name>` to see if the SRIOV port has been assigned to the network, output should be similar to the following with the entry `parent` set to a SRIOV port on the Edge Node:
```bash
# docker network inspect test_network1
[
    {
        "Name": "test_network1",
        "Id": "a44d578b4523499eab1357387c1daeabfb306e362286976257a7ad33d559a56a",
        "Created": "2020-03-11T12:24:40.779474718Z",
        "Scope": "local",
        "Driver": "macvlan",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "192.168.1.0/24",
                    "Gateway": "192.168.1.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {
            "parent": "enp24s10"
        },
        "Labels": {}
    }
]
```
3. Once the container is started, run the following command, `docker exec -it <container_name> ip a s`, to confirm that the port connected to the network is the SRIOV port. Compare this result to the output from `ip a s <sriov_interface_name>` on the Edge Node, the result should be similar to the following.
```bash
# docker exec -it 7d50be85-58da-4452-a2f9-6718fcf0fd89 ip a s
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
111: eth0@if50: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state LOWERLAYERDOWN group default
    link/ether 02:42:c0:a8:01:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.1.2/24 brd 192.168.1.255 scope global eth0
       valid_lft forever preferred_lft forever
112: vEth1: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 9a:09:f3:84:f9:7b brd ff:ff:ff:ff:ff:ff
```
```bash
# ip a s enp24s10
50: enp24s10: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 8e:97:bc:62:7f:76 brd ff:ff:ff:ff:ff:ff
```
> **Note**: To confirm that the correct VF has been passed to the deployed container, check the port name shown in the output from `ip a s` on the container. This will be in the format of `portNum: ifName@if<hostPortNum>`, where `hostPortNum` is the port number provided by the `ip a s <sriov_interface_name>` command on the host. In the above example, `ip a s enp24s10` is port number 50, while the `ip a s` command on the container shows the interface used for SRIOV as `eth0@if50`, meaning it is linked to port 50 on the host.

## ITP/ONP/12/02: Container Deployment with incorrect SRIOV setting

### Test Summary

This test will ensure that the deployed container does not run if the incorrect SRIOV port is provided from the Edge Node host system.

### Prerequisites

- Controller API, UI and database installed using the ansible scripts and running.
- Ansible scripts **DO NOT** include any SRIOV settings.
- Edge Node installed using ansible scripts and running.
- Apache server has been set up with the ansible scripts and has a container image with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*.
   - Add the following input:
     - **Name:** EAC_App_Incorrect_SRIOV_Container
     - **Type:** container
     - **Version:** 77
     - **Vendor:** Intel
     - **Description:** A container app using an incorrect SRIOV port
     - **Cores:**: 7
     - **Memory:** 1234
     - **Source:** container image stored in the Apache server
     - Skip the port settings
     - EPA Feature:
       - **EPA Feature Key:** sriov_nic
       - **EPA Feature Value:** test_network
   - Click *Upload Application*.
   - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on.
   - Select *Apps*, click *DEPLOY APP*, select EAC_App_Incorrect_SRIOV_Container from the dropdown menu and click *DEPLOY*.
   - Click *START* to start the container on the node.
2. Log onto the node:
   - Run `docker ps -a` to get the name of the deployed container.
   - To check the docker network that the container is connected to, run `docker inspect <container_name>` and look for the entry *NetworkMode*, this should be set to the network name that was provided as the EPA Feature Key in the UI.
   - Attempt to start the container from the UI, the result should be an error due to the missing network.

## ITP/ONP/12/03: VM Deployment with SRIOV

### Test Summary

This test will ensure that the deployed VM uses a SRIOV port provided from the Edge Node host system.

### Prerequisites

- NIC with SRIOV support installed on the Edge Node.
- Controller API, UI and database installed using the ansible scripts and running.
- Ansible scripts updated with the required SRIOV supplied settings as outlined in [SRIOV EPA Document](https://github.com/otcshare/specs/blob/master/doc/enhanced-platform-awareness/openness-sriov-multiple-interfaces.md).
- Edge Node installed using ansible scripts and running.
- Apache server has been set up with the ansible scripts and is storing a VM image with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*.
   - Add the following input:
     - **Name:** EAC_App_SRIOV_VM
     - **Type:** vm
     - **Version:** 77
     - **Vendor:** Intel
     - **Description:** A vm app using an SRIOV port
     - **Cores:**: 7
     - **Memory:** 1234
     - **Source:** vm image stored in the Apache server
     - Skip the port settings
     - EPA Feature:
       - **EPA Feature Key:** sriov_nic
       - **EPA Feature Value:** *PCI Address of SRIOV port on Edge Node*
   - Click *Upload Application*.
   - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on.
   - Select *Apps*, click *DEPLOY APP*, select EAC_App_SRIOV_VM from the dropdown menu and click *DEPLOY*.
   - Click *START* to start the VM on the node.
2. Log onto the node:
   - Run `virsh list --all` to get the name of the VM image.
   - To check the interfaces assigned to the VM, run `virsh domiflist <vm_name>`. The output should include a port labelled as type hostdev which is the SRIOV port, an example output is below:
```bash
# virsh domiflist 321e1f2d-d686-42a6-af87-390ebb67293d
Interface  Type       Source     Model       MAC
-------------------------------------------------------
-          network    default    virtio      52:54:00:39:3d:80
-          vhostuser  -          virtio      52:54:00:90:44:ee
-          hostdev    -          -           52:54:00:eb:f0:10
```

## ITP/ONP/12/04: VM Deployment with incorrect SRIOV setting

### Test Summary

This test will ensure that the deployed VM does not run if an incorrect SRIOV port is provided.

### Prerequisites

- Controller API, UI and database installed using the ansible scripts and running.
- Ansible scripts **DO NOT** include any SRIOV settings.
- Edge Node installed using ansible scripts and running.
- Apache server has been set up with the ansible scripts and is storing a VM image with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*.
   - Add the following input:
     - **Name:** EAC_App_Incorrect_SRIOV_VM
     - **Type:** vm
     - **Version:** 77
     - **Vendor:** Intel
     - **Description:** A VM app using an incorrect SRIOV port
     - **Cores:**: 7
     - **Memory:** 1234
     - **Source:** VM image stored in the Apache server
     - Skip the port settings
     - EPA Feature:
       - **EPA Feature Key:** sriov_nic
       - **EPA Feature Value:** *PCI Address which does not exist on the Edge Node*
   - Click *Upload Application*.
   - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on.
   - Select *Apps*, click *DEPLOY APP*, select EAC_App_Incorrect_SRIOV_VM from the dropdown menu and click *DEPLOY*.
   - Click *START* to start the VM on the node.
2. Log onto the node:
   - Run `virsh list --all` to get the name of the VM image.
   - To check the interfaces assigned to the VM, run `virsh domiflist <vm_name>` which will show three ports, including a hostdev port for the PCI address provided in the UI. Example output is below:
```bash
# virsh domiflist acd03f1a-b8f1-46ee-82b4-d6ac16a80793
Interface  Type       Source     Model       MAC
-------------------------------------------------------
-          network    default    virtio      52:54:00:f3:7b:12
-          vhostuser  -          virtio      52:54:00:79:7b:0e
-          hostdev    -          -           52:54:00:2a:ad:6e
```
3. Attempt to start the VM from the Controller UI, it should fial with an error due to the incorrectly configured SRIOV port.
