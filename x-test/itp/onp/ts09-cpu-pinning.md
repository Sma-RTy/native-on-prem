```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/09: CPU Pinning](#itponp09-cpu-pinning)
  - [ITP/ONP/09/01: CPU Pinning Container to single core](#itponp0901-cpu-pinning-container-to-single-core)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test Steps](#test-steps)
  - [ITP/ONP/09/02: CPU Pinning Container to multiple cores (comma separated list)](#itponp0902-cpu-pinning-container-to-multiple-cores-comma-separated-list)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test Steps](#test-steps-1)
  - [ITP/ONP/09/03: CPU Pinning Container to multiple cores (sequential cores)](#itponp0903-cpu-pinning-container-to-multiple-cores-sequential-cores)
    - [Test Summary](#test-summary-2)
    - [Prerequisites](#prerequisites-2)
    - [Test Steps](#test-steps-2)
  - [ITP/ONP/09/04: CPU Pinning Container with unsupported core setting](#itponp0904-cpu-pinning-container-with-unsupported-core-setting)
    - [Test Summary](#test-summary-3)
    - [Prerequisites](#prerequisites-3)
    - [Test Steps](#test-steps-3)
  - [ITP/ONP/09/05: CPU Pinning VM to single core](#itponp0905-cpu-pinning-vm-to-single-core)
    - [Test Summary](#test-summary-4)
    - [Prerequisites](#prerequisites-4)
    - [Test Steps](#test-steps-4)
  - [ITP/ONP/09/06: CPU Pinning VM to multiple cores (comma separated list)](#itponp0906-cpu-pinning-vm-to-multiple-cores-comma-separated-list)
    - [Test Summary](#test-summary-5)
    - [Prerequisites](#prerequisites-5)
    - [Test Steps](#test-steps-5)
  - [ITP/ONP/09/07: CPU Pinning VM to multiple cores (sequential cores)](#itponp0907-cpu-pinning-vm-to-multiple-cores-sequential-cores)
    - [Test Summary](#test-summary-6)
    - [Prerequisites](#prerequisites-6)
    - [Test Steps](#test-steps-6)
  - [ITP/ONP/09/08: CPU Pinning VM with unsupported core setting](#itponp0908-cpu-pinning-vm-with-unsupported-core-setting)
    - [Test Summary](#test-summary-7)
    - [Prerequisites](#prerequisites-7)
    - [Test Steps](#test-steps-7)

# ITP/ONP/09: CPU Pinning

Test suite original definition: https://openness.atlassian.net/wiki/spaces/INTEL/pages/119537669/ITP+2020+03+ONP+4+EAC+tests

## ITP/ONP/09/01: CPU Pinning Container to single core

### Test Summary

This test will ensure that the deployed container will be pinned to a single core based on the value provided in the controller UI.

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains images of a container with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_CPU_Pin_Container_Single_Core
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app pinned to a single core on the host
      - **Cores:** 7
      - **Memory:** 1234
      - ***Source:*** *a suitable container (not in scope of this test)*
      - Skip the port settings
      - EPA Feature:
        - **EPA Feature Key:** cpu_pin
        - **EPA Feature Value:** 3
    - Click *Upload Application*
    - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_CPU_Pin_Container_Single_Core from the dropdown menu and click *DEPLOY*
    - Click *START* to start the container on the node
2. Log onto the node
    - Run `docker ps` to get the name of the deployed container
    - Once the container has been started, run `docker inspect <container_name>` and look for the entry labelled *Pid*
    - Run `taskset -pc <Pid>` to check the CPU pinning of the container, result should look like the following:
```
taskset -pc 131438
pid 131438's current affinity list: 3
```

## ITP/ONP/09/02: CPU Pinning Container to multiple cores (comma separated list)

### Test Summary

This test will ensure that the deployed container will be pinned to multiple cores based on the value provided in the controller UI

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains images of a container with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_CPU_Pin_Container_Multiple_Cores_Comma
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app pinned to multiple cores on the host
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable container (not in scope of this test)*
      - Skip the port settings
      - EPA Feature:
        - **EPA Feature Key:** cpu_pin
        - **EPA Feature Value:** 3,5,7,8
    - Click *Upload Application*
    - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_CPU_Pin_Container_Multiple_Cores_Comma from the dropdown menu and click *DEPLOY*
    - Click *START* to start the container on the node
2. Log onto the node
    - Run `docker ps` to get the name of the deployed container
    - Once the container has been started, run `docker inspect <container_name>` and look for the entry labelled *Pid*
    - Run `taskset -pc <Pid>` to check the CPU pinning of the container, result should look like the following:
```
taskset -pc 132095
pid 132095's current affinity list: 3,5,7,8
```

## ITP/ONP/09/03: CPU Pinning Container to multiple cores (sequential cores)

### Test Summary

This test will ensure that the deployed container will be pinned to multiple sequential cores based on the value provided in the controller UI

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains images of a container with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_CPU_Pin_Container_Multiple_Cores_Sequential
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app pinned to multiple sequential cores on the host
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable container (not in scope of this test)*
      - Skip the port settings
      - EPA Feature:
        - **EPA Feature Key:** cpu_pin
        - **EPA Feature Value:** 3-6
    - Click *Upload Application*
    - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_CPU_Pin_Container_Multiple_Cores_Sequential from the dropdown menu and click *DEPLOY*
    - Click *START* to start the container on the node
2. Log onto the node
    - Run `docker ps` to get the name of the deployed container
    - Once the container has been started, run `docker inspect <container_name>` and look for the entry labelled *Pid*
    - Run `taskset -pc <Pid>` to check the CPU pinning of the container, result should look like the following:
```
taskset -pc 132597
pid 132597's current affinity list: 3-6
```

## ITP/ONP/09/04: CPU Pinning Container with unsupported core setting

### Test Summary

This test will ensure that the deployed container will still be running on all available cores when an incorrect core setting is provided in the controller UI.

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains images of a container with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_CPU_Pin_Container_Incorrect_Setting
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app with no CPU pinning on the host
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable container (not in scope of this test)*
      - Skip the port settings
      - EPA Feature:
        - **EPA Feature Key:** cpu_pin
        - **EPA Feature Value:** 0x5
    - Click *Upload Application*
    - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_CPU_Pin_Container_Incorrect_Setting from the dropdown menu and click *DEPLOY*
    - Click *START* to start the container on the node
2. Log onto the node
    - Run `docker ps` to get the name of the deployed container
    - Once the container has been started, run `docker inspect <container_name>` and look for the entry labelled *Pid*
    - Run `taskset -pc <Pid>` to check the CPU pinning of the container, result should look like the following:
```
taskset -pc 133093
pid 133093's current affinity list: 0-39
```

## ITP/ONP/09/05: CPU Pinning VM to single core

### Test Summary

This test will ensure that the cores of the deployed VM will be pinned to a single core based on the value provided in the controller UI.

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains a VM image that can be deployed

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
        - **Name:** EAC_App_CPU_Pin_VM_Single_Core
        - **Type:** vm
        - **Version:** 77
        - **Vendor:** Intel
        - **Description:** An app whose vCPUs are pinned to a single core of the host
        - **Cores:** 7
        - **Memory:** 1234
        - **Source:** *a suitable vm (not in scope of this test)*
        - Skip the port settings
        - EPA Feature:
          - **EPA Feature Key:** cpu_pin
          - **EPA Feature Value:** 3
    - Click *Upload Application*
    - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_CPU_Pin_VM_Single_Core from the dropdown menu and click *DEPLOY*
2. Log onto the node
    - Run `virsh list --all` to get the name of the deployed VM
    - Run `virsh vcpupin <vm_name>` to check the core pinning for the VM, the output should be similar to the following:
```bash
virsh vcpupin a2376856-0a61-4f79-8abf-fbf1ae56a949
VCPU: CPU Affinity

0: 3
1: 3
2: 3
3: 3
4: 3
5: 3
6: 3
```

## ITP/ONP/09/06: CPU Pinning VM to multiple cores (comma separated list)

### Test Summary

This test will ensure that the cores of the deployed VM will be pinned to multiple cores based on the value provided in the controller UI.

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains a VM image that can be deployed

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_CPU_Pin_VM_Multiple_Cores_Comma
      - **Type:** vm
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app whose vCPUs are pinned to multiple cores on the host
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable vm (not in scope of this test)*
      - Skip the port settings
      - EPA Feature:
        - **EPA Feature Key:** cpu_pin
        - **EPA Feature Value:** 3,5,7,8
    - Click *Upload Application*
    - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_CPU_Pin_VM_Multiple_Cores_Comma from the dropdown menu and click *DEPLOY*
2. Log onto the node
    - Run `virsh list --all` to get the name of the deployed VM
    - Run `virsh vcpupin <vm_name>` to check the core pinning for the VM, the output should be similar to the following:
```bash
virsh vcpupin b5826483-e793-4f80-93e5-4ddb6ab31141
VCPU: CPU Affinity

0: 3,5,7-8
1: 3,5,7-8
2: 3,5,7-8
3: 3,5,7-8
4: 3,5,7-8
5: 3,5,7-8
6: 3,5,7-8
7: 3,5,7-8
```

## ITP/ONP/09/07: CPU Pinning VM to multiple cores (sequential cores)

### Test Summary

This test will ensure that the cores of the deployed VM will be pinned to a multiple sequential cores based on the value provided in the controller UI.

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains a VM image that can be deployed

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_CPU_Pin_VM_Multiple_Core_Sequential
      - **Type:** vm
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app whose vCPUs are pinned to multiple sequential cores on the host
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable vm (not in scope of this test)*
      - Skip the port settings
      - EPA Feature:
        - **EPA Feature Key:** cpu_pin
        - **EPA Feature Value:** 3-6
    - Click *Upload Application*
    - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_CPU_Pin_VM_Multiple_Core_Sequential from the dropdown menu and click *DEPLOY*
2. Log onto the node
    - Run `virsh list --all` to get the name of the deployed VM
    - Run `virsh vcpupin <vm_name>` to check the core pinning for the VM, the output should be similar to the following:
```bash
virsh vcpupin 99ff299e-c162-45fe-9ba7-ddaf5001aa12
VCPU: CPU Affinity

0: 3-6
1: 3-6
2: 3-6
3: 3-6
4: 3-6
5: 3-6
6: 3-6
```

## ITP/ONP/09/08: CPU Pinning VM with unsupported core setting

### Test Summary

This test will ensure that the deployed VM will still be running on all available cores when an incorrect core setting is provided in the controller UI.

### Prerequisites

- Apache server with VM image that can be deployed

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_CPU_Pin_VM_Incorrect_Setting
      - **Type:** vm
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app with no CPU pinning on the host
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable container (not in scope of this test)*
      - Skip the port settings
      - EPA Feature:
        - **EPA Feature Key:** cpu_pin
        - **EPA Feature Value:** 0x5
    - Click *Upload Application*
    - Go to *Nodes* and click *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_CPU_Pin_VM_Incorrect_Setting from the dropdown menu and click *DEPLOY*
2. Log onto the node
    - Run `virsh list --all` to get the name of the deployed VM
    - Run `virsh vcpupin <vm_name>` to check the core pinning for the VM, output should be similar to the following:
```bash
virsh vcpupin f8ea1e10-b4c6-434a-ba32-f728a8a9eb05
VCPU: CPU Affinity

0: 0-39
1: 0-39
2: 0-39
3: 0-39
4: 0-39
5: 0-39
6: 0-39
```
