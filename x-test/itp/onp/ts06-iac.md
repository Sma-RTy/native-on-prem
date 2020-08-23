```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/06: Inter-App Communication](#itponp06-inter-app-communication)
  - [ITP/ONP/06/01: Virtual interface for VM](#itponp0601-virtual-interface-for-vm)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test steps](#test-steps)
  - [ITP/ONP/06/02: Virtual interface for docker container](#itponp0602-virtual-interface-for-docker-container)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test steps](#test-steps-1)
  - [ITP/ONP/06/03: Virtual interface for two VMs](#itponp0603-virtual-interface-for-two-vms)
    - [Test Summary](#test-summary-2)
    - [Prerequisites](#prerequisites-2)
    - [Test steps](#test-steps-2)
  - [ITP/ONP/06/04: Virtual interface for containers](#itponp0604-virtual-interface-for-containers)
    - [Test Summary](#test-summary-3)
    - [Prerequisites](#prerequisites-3)
    - [Test steps](#test-steps-3)
  - [ITP/ONP/06/05: Check communication between VM’s](#itponp0605-check-communication-between-vms)
    - [Test Summary](#test-summary-4)
    - [Prerequisites](#prerequisites-4)
    - [Test steps](#test-steps-4)
  - [ITP/ONP/06/06: Check communication between VM and external port](#itponp0606-check-communication-between-vm-and-external-port)
    - [Test Summary](#test-summary-5)
    - [Prerequisites](#prerequisites-5)
    - [Test steps](#test-steps-5)
  - [ITP/ONP/06/07: Check communication between VM and container](#itponp0607-check-communication-between-vm-and-container)
    - [Test Summary](#test-summary-6)
    - [Prerequisites](#prerequisites-6)
    - [Test steps](#test-steps-6)

# ITP/ONP/06: Inter-App Communication

Test suite original definition: https://openness.atlassian.net/wiki/spaces/INTEL/pages/51937626/ITP+2019+12+ONP+6+IAC+Test+Suite

## ITP/ONP/06/01: Virtual interface for VM

### Test Summary

Check if VM gets virtual interface on deployment

### Prerequisites

- Edge Controller in OnPrem Mode set-up (default roles) and running as described in: [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
- Edge Node in OnPrem Mode set-up (default role + **OVS Inter-App Communication enabled**), running and enrolled as described in: [ITP/ONP/01/02: Deploy Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-edge-node-in-onprem-mode)
- NTS configured (see [ITP/ONP/02/07: Configure interface with traffic policy & start NTS](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts02-microservice.md#itponp0207-configure-interface-with-traffic-policy--start-nts))
- Edge Application VM image prepared to be deployed

### Test steps

1. Deploy the prepared VM Edge Application
2. Expected outcome
    - VM has additional virtual interface
        - Verify in VM with `ip a` command that new interface (`br0-*app_id*`) is present
    - OVS has additional virtual interface
        - Verify on host with `ovs-vsctl list-ports br0` that one new interface is present

## ITP/ONP/06/02: Virtual interface for docker container

### Test Summary

Check if container gets virtual interface on deployment

### Prerequisites

- Edge Controller in OnPrem Mode set-up (default roles) and running as described in: [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
- Edge Node in OnPrem Mode set-up (default role + **OVS Inter-App Communication enabled**), running and enrolled as described in: [ITP/ONP/01/02: Deploy Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-edge-node-in-onprem-mode)
- NTS configured (see [ITP/ONP/02/07: Configure interface with traffic policy & start NTS](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts02-microservice.md#itponp0207-configure-interface-with-traffic-policy--start-nts))
- Edge Application Docker image prepared to be deployed

### Test steps

1. Deploy the prepared container Edge Application
2. Expected outcome
    - Docker container has additional virtual interface
      - Verify in container with `ip a` command that new interface (`ve2-*docker_name*`) is present
    - OVS has additional virtual interface
      - Verify on host with `ovs-vsctl list-ports br0` that one new interface (`ve1-*docker_name*`) is present

## ITP/ONP/06/03: Virtual interface for two VMs

### Test Summary

Check if VM gets virtual interface on deployment

### Prerequisites

- Edge Controller in OnPrem Mode set-up (default roles) and running as described in: [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
- Edge Node in OnPrem Mode set-up (default role + **OVS Inter-App Communication enabled**), running and enrolled as described in: [ITP/ONP/01/02: Deploy Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-edge-node-in-onprem-mode)
- NTS configured (see [ITP/ONP/02/07: Configure interface with traffic policy & start NTS](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts02-microservice.md#itponp0207-configure-interface-with-traffic-policy--start-nts))
- Edge Application VM image prepared to be deployed

### Test steps

1. Deploy two VMs using prepared image
2. Expected outcome
    - Each VM has additional virtual interface
      - Verify in both VMs with `ip a` command that new interface (`br0-*app_id*`) is present
    - OVS has two additional virtual interfaces
      - Verify on host with `ovs-vsctl list-ports br0` that there are two ports
      - Verify on host with `ovs-vsctl list-ports br0` that new interface is present

## ITP/ONP/06/04: Virtual interface for containers

### Test Summary

Check if containers gets virtual interfaces on deployment

### Prerequisites

- Edge Controller in OnPrem Mode set-up (default roles) and running as described in: [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
- Edge Node in OnPrem Mode set-up (default role + **OVS Inter-App Communication enabled**), running and enrolled as described in: [ITP/ONP/01/02: Deploy Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-edge-node-in-onprem-mode)
- NTS configured (see [ITP/ONP/02/07: Configure interface with traffic policy & start NTS](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts02-microservice.md#itponp0207-configure-interface-with-traffic-policy--start-nts))
- Edge Application Docker image prepared to be deployed

### Test steps

1. Deploy two docker containers using prepared image
2. Expected outcome
    - Each container has additional virtual interface
      - Verify in both containers with `ip a` command that new interface (`ve2-*docker_name*`) is present
    - OVS has two additional virtual interfaces
      - Verify on host with `ovs-vsctl list-ports br0` that there are two ports
      - Verify on host with `ovs-vsctl list-ports br0` that new interface (`ve1-*docker_name*`) is present

## ITP/ONP/06/05: Check communication between VM’s

### Test Summary

Check if two deployed VM’s can communicate with each other

### Prerequisites

- Edge Controller in OnPrem Mode set-up (default roles) and running as described in: [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
- Edge Node in OnPrem Mode set-up (default role + **OVS Inter-App Communication enabled**), running and enrolled as described in: [ITP/ONP/01/02: Deploy Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-edge-node-in-onprem-mode)
- NTS configured (see [ITP/ONP/02/07: Configure interface with traffic policy & start NTS](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts02-microservice.md#itponp0207-configure-interface-with-traffic-policy--start-nts))
- Edge Application VM image prepared to be deployed

### Test steps

1. Depoly the VM application twice as separate instances
2. Assign IP addresses to virtual interfaces
    - For VM-1:

        ```shell
        # ip addr add 192.168.120.17/24 dev >ifname<
        # ip link set >ifname< up
        ```

    - For VM-2:

        ```shell
        # ip addr add 192.168.120.18/24 dev >ifname<
        # ip link set >ifname< up
        ```

3. In VM-1 following command should succeed: `ping 192.168.120.18`
4. In VM-2 following command should succeed: `ping 192.168.120.17`
5. Expected outcome:
    - Verify that VMs pings get responses

## ITP/ONP/06/06: Check communication between VM and external port

### Test Summary

Check if VM can communicate with device connected with physical connection

### Prerequisites

- Edge Controller in OnPrem Mode set-up (default roles) and running as described in: [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
- Physical Edge Node with clean CentOS installation (not deployed)
- Additional machine connected with physical connection
- Edge Application VM image prepared to be deployed

### Test steps

1. Enable OVS Inter-App Communication feature (`onprem_iac_enable` variable in `group_vars/all/10-default.yml`)
2. Add physical port’s PCI address to the node specific ansible configuration file:
    - To identify the physical port, invoke: `ethtool -p >if<`
    - To get the PCI address of the interface, invoke: `lshw -c network -businfo`
    - Add the PCI address to the `ovs_ports` list property in the node config file.
3. Deploy the Edge Node using Ansible
4. Deploy a VM and assign IP address to interface

    ```shell
    # ip addr add 192.168.120.17/24 dev >ifname<
    # ip link set >ifname< up
    ```

5. Assign IP address to the connected port on the external machine:

    ```shell
    # ip addr add 192.168.120.18/24 dev >ifname<
    # ip link set >ifname< up
    ```

6. Test communication in both ways
    - In the VM, following command should succeed: `ping 192.168.120.18`
    - On the external machine, following command should succeed: `ping 192.168.120.17`
7. Expected outcome
    - Verify that VM pings get responses
    - Verify that additional machines pings get responses

## ITP/ONP/06/07: Check communication between VM and container

### Test Summary

Check if VM and docker container can communicate with each other

### Prerequisites

- Edge Controller in OnPrem Mode set-up (default roles) and running as described in: [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
- Edge Node in OnPrem Mode set-up (default role + **OVS Inter-App Communication enabled**), running and enrolled as described in: [ITP/ONP/01/02: Deploy Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-edge-node-in-onprem-mode)
- NTS configured (see [ITP/ONP/02/07: Configure interface with traffic policy & start NTS](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts02-microservice.md#itponp0207-configure-interface-with-traffic-policy--start-nts))
- Edge Application VM image prepared to be deployed
- Edge Application Docker image prepared to be deployed
  
### Test steps

1. Deploy the VM application
2. Deploy the Docker application
3. Assign IP addresses to virtual interfaces in VM and container:
    - For the VM:

        ```shell
        # ip addr add 192.168.120.17/24 dev >ifname<
        # ip link set >ifname< up
        ```

    - For the container:

        ```shell
        # ip addr add 192.168.120.18/24 dev >ifname<
        # ip link set >ifname< up
        ```

4. Test communication in both ways
    - In the VM, following command should succeed: `ping 192.168.120.18`
    - In the container, following command should succeed: `ping 192.168.120.17`
5. Expected outcome:
    - Verify that VM pings get responses
    - Verify that dockers container pings get responses
