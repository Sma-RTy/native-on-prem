```text
SPDX-License-Identifier: Apache-2.0
Copyright (c) 2020 Intel Corporation
```
- [Overview](#overview)
- [Technology](#technology)
  - [Robot Framework](#robot-framework)
  - [Test Environment](#test-environment)
- [Configuration](#configuration)
  - [Configure Test Master machine](#configure-test-master-machine)
  - [Install packages for python3](#install-packages-for-python3)
  - [Prepare base VM](#prepare-base-vm)
  - [Create network bridge (optional)](#create-network-bridge-optional)
  - [Test repo](#test-repo)
    - [env.json file](#envjson-file)
- [Resource Manager](#resource-manager)
  - [Available DB backends](#available-db-backends)
  - [Object pools](#object-pools)
- [Physical Nodes Configuration](#physical-nodes-configuration)
  - [LVM](#lvm)
  - [Environment Configuration](#environment-configuration)
  - [Network bridge](#network-bridge)
- [Execution](#execution)
  - [run_tests.py](#run_testspy)
    - [Arguments](#arguments)
  - [scripts/robot_job.py](#scriptsrobot_jobpy)
    - [Arguments](#arguments-1)
    - [Environment variables](#environment-variables)
- [Directory structure](#directory-structure)
- [Test Suites](#test-suites)
  - [Test Setup](#test-setup)


## Overview

This is OpenNESS environment for functional and integration tests implemented with the usage of Robot Framework. Its main goal is to verify product's functionalities and interactions between different components. It aims to cover all of the test scenarios described in 'itp' directory. In the future it is planned to introduce performance and other, more specific tests as well.

## Technology

### Robot Framework

All tests are written in [Robot Framework](https://robotframework.org/). It is a high level generic test automation framework that produces great reports and logs, provides possibility to directly use Python code and libraries, enables fast implementation of test cases and is open source.

### Test Environment

In order to to run the test suites a Test Master machine is required. It must at least support VT and have *kvm_intel* module loaded for VM management. The detailed configuration is described [here](#configuration).

OpenNESS requires minimum two machines in simplest test scenarios - one controller and one (or more) worker nodes (to learn more on OpenNESS subsystem, see [architecture overview](https://github.com/otcshare/native-on-prem/blob/master/specs/doc/architecture.md#overview)). Both Virtual and Physical machines can be used as nodes and controllers.

Physical machines should be configured to use [LVM](https://en.wikipedia.org/wiki/Logical_Volume_Manager_(Linux)) and should have their root filesystem mounted on a LV.

Virtual Machines are managed by [libvirt](https://libvirt.org/) and qemu. At least one preconfigured VM with an OS compliant version ([supported operating systems](https://github.com/otcshare/native-on-prem/blob/master/specs/openness_releasenotes.md#supported-operating-systems)) and meeting OpenNESS requirements shall be available on Test Machine. It will act as a base for creating virtual machines for tests, that will take role of either EdgeController or EdgeNode. All VMs will be created directly on a Test Master machine.

![Component Diagram](diagrams/components.jpg)

_Figure - Component Diagram_

## Configuration

Following guide details all dependencies and instructions needed to prepare Test Master machine for robot tests execution.

### Configure Test Master machine

 - Install CentOS operating system
 - Upgrade CentOS packages with "yum upgrade" command
 - Configure OS proxy (if needed)
 - Install the following packages with yum

 - Import repository containing Ansible binary
```
# yum install -y epel-release
```

 - Install required packages for virtualization
```
# yum install -y libvirt libvirt-devel epel-release git gcc qemu-kvm libguestfs-tools virt-install python3 python3-devel ansible wget
```

 - Generate root user SSH key pair
```
# ssh-keygen -t rsa
```

 - Load *kvm_intel* module with support for nested virtualization

```
# modprobe -r kvm_intel
# modprobe kvm_intel nested=1
```

Nested virtualization is enabled until the host is rebooted. To make such change permanent, add the following line to file: */etc/modprobe.d/kvm.conf*

```
options kvm_intel nested=1
```

 - Enable and start libvirt service

```
# systemctl enable libvirtd
# systemctl start libvirtd
```

 - Configure default virsh network

```
# virsh net-edit default
```

 - Change subnet:

In below example, we change default dhcp network to 192.168.52.0/24 and virbr0 own IP address (192.168.52.1).
> WARNING: Do NOT use subnet 192.168.122.0/24 because it is used internally by OpenNESS.

```
<network>
  <name>default</name>
  <uuid>7e9edb30-a4df-4f8b-8e95-44e3c45c2041</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:40:41:79'/>
  <ip address='192.168.52.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.52.2' end='192.168.52.254'/>
    </dhcp>
  </ip>
</network>
```

 - Next restart network

```
# virsh net-destroy default
# virsh net-start default
```

### Install packages for python3

```
pip3 install robotframework
pip3 install libvirt-python
pip3 install paramiko
pip3 install scp
pip3 install robotframework-sshlibrary
pip3 install robotframework-yamllibrary
pip3 install pymysql
pip3 install SQLAlchemy
```

### Prepare base VM

Before any test can be run, at least one VM (so called template VM) needs to be already present on Test Master machine and known to libvirt.

There are two ways of fulfilling this precondition:
1) Install virt-manager and create VM. Give it a meaningful name, like "centos7-minimal". Use Centos7 Minimal ISO image and install a basic operating system. Enable network interface to boot at start, set disk size 30 GB.
2) Install *qemu-guest-agent* on a VM (please omit *http_proxy* if it's not needed for internet connectivity on your network):
```
http_proxy=<proxy_address> yum install -y qemu-guest-agent
```
3) Shut down this VM. It will now be known to libvirt/Robot and listed using the following command:
```
# virsh list --all
 Id    Name                           State
----------------------------------------------------
 -     centos7-minimal                   shut off

```
4) Import xml file containing VM definition and copy disk image file (.qcow2) to the following folder: */var/lib/libvirt/images/*
This step is not covered in this howto. Please refer to the official libvirt documentation on the exact steps to take for importing VM from .xml file.

> NOTE: You do not need to copy the Test Master host ssh keys to VM manually. It will be done automatically by Robot Virtualization library **but you must allow SSH daemon to accept root user login and also allow login with a password and ssh keys** (some cloud images prevent this login method by default). This can be done by modifying SSH service config file (/etc/ssh/sshd_config) and setting parameter PermitRootLogin to "yes" value.

### Create network bridge (optional)

By default all VMs will use NAT based connectivity. It's fine unless VMs need to access any external machine - e.g. a controller is deployed on a VM and edgenode is deployed on a PM (topology obtained when **--use-physical-nodes** argument is passed to [run_tests.py](#run_testspy)). In such scenario the PMs and VMs will only be accesible from each other when a network bridge is created and provided for the VMs.

The fact that the Test Master machine needs to have a connectivity to Physical Machines makes it possible to create a bridge as described [here](https://wiki.libvirt.org/page/Networking#Bridged_networking_.28aka_.22shared_physical_device.22.29).

The name of the bridge then needs to be provided in [env.json](#envjson-file) in *network_bridge* field.

### Test repo

 - Download the test repo from github:

```
# git clone https://github.com/otcshare/native-on-prem.git
```
- Then enter to "test" directory

#### env.json file
Environment specific variables must be provided in file ***test/robot/resources/variables/env.json***. You should provide a name of the base VM that you prepared in the previous step along with user and password credentials. Provide proxy settings (if necessary) for ansible scripts. Lastly don’t forget to type in github token.

In env.json file you can also specify which branch of edgenode, edgecontroller or openness experience kits repository you want to test.

*env.json* fields documentation:

- proxy

  Proxy settings.

- github_token

  Token used for cloning private repositories from github.

- edgeapps

  URL and branch of [edgeapps](https://github.com/otcshare/native-on-prem/blob/master/specs/doc/applications/openness_appguide.md) repository.

- workdir

  Working directory on test machines.

- vm

  Base VM configuration including its name (as seen in using *virsh list --all*), username and password.

- resource_db

  DB configuration dictionary for Resource Manager. Options:

  - backend

    DB backend choice. Possible values are listed [here](#available-db-backends).

  - url

    Database URL. In case of SQLite backend it is a file path (this file will be created if it doesn't exist). If left empty, a default SQLite file path will be used: */robot/db/resource.db*.

- nic_vfs_pool

  Here you can specify a list of NIC VF PCI addresses which can be used during testing.

- network_bridge

  Name of a bridge created during the [bridge setup](#create-network-bridge-optional). When provided, NAT connectivity device will be substituted with a given bridge in VMs.

- physical_machines

  A dictionary with available physical machines for this Test Master machine. Each entry should be composed of a machine name as a key and a dictionary with the following fields:

  - hostname

    Machine hostname (output of `hostnamectl --static`)

  - username

  - vg

    Root logical volume's volume group

  - root_lv

    Root Logical Volume of this machine

  - type

    Type of a machine that needs to be reserved. Currently there are 2 types used in Test Suites: 'controller' and 'edgenode' which map to OEK groups.

```
Example:

"physical_machines": {
  "common-machine": {
    "hostname": "host1",
    "username": "root",
    "vg": "centos",
    "root_lv": "root",
    "type": "controller"
  },
  "hddl-machine": {
    "hostname": "1.2.3.4",
    "username": "user",
    "vg": "centos",
    "root_lv": "primary_lv",
    "type": "edgenode"
  }
}
```

> WARNING: Machine name (dictionary key of each Physical Machines entry, *common-machine* and *hddl-machine* in the above example) is used as a DNS-1123 subdomain - it must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')

## Resource Manager

Some of the shared resources are managed by Resource Manager. It is a DB-backed, high level module that enables multiple users to use a single pool of resources. [SQLAlchemy](https://www.sqlalchemy.org/) framework was chosen as a SQL toolkit to make DB backend switching possible without the need for rewriting the code. Object Relational Mapping is another advantage of SQLAlchemy.

Specific backend can be configured in [env.json](#envjson-file) in *resource_db* dictionary.

### Available DB backends
 - 'sqlite': SQLite3 (default)

### Object pools
 - VM MAC addresses used for the [network bridge](#create-network-bridge-optional) connection

## Physical Nodes Configuration

In order to use a physical machine as an OpenNESS node it needs to be configured.

### LVM

1) For a normal OpenNess Nodes operation, servers do not require any specific disk partition layout. Only when operator wants to run Robot tests on such machine, a different partition layout is required.

   **If using virtual machines for testing, please skip this chapter.**
2) At least two partitions are required to be present for Robot on disk and need to be set up during CentOS operating system installation.
     ```
     boot partition (/boot) - to contain kernel and initrd files
     root partition (/) - created using LVM way, not as a standalone partition
     ```
3) During operating system setup, create partitions as follows:
   - first partition - standard type, filesystem as XFS, size 1GiB or more, mounted under /boot directory
   - second partition - LVM type, filesystem as XFS, size 200GiB or more, with logical volume size set to policy "As large as possible" as it guarantees that Robot tests will be able to create filesystem snapshots when running tests, and restore original filesystem state before each test run.
   After OS installation is complete, running `lvs` command should give similiar output:

    ```
    # lvs
      LV    VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      root  centos owi-aos--- 200.00g
    ```

   Here VG is named *centos* and root LV is named *root*.

4) Next step is to [set the hostname](https://github.com/otcshare/native-on-prem/blob/master/specs/doc/getting-started/controller-edge-node-setup.md#setup-static-hostname) and [set the time](https://github.com/otcshare/native-on-prem/blob/master/specs/doc/getting-started/controller-edge-node-setup.md#configuring-time).

5) From the Test Master run `ssh-copy-id <physical node hostname>`.

6) Root LV snapshot named *clean* should be created on a physical node using `lvcreate -s -c 64k -n clean /dev/<VG name>/<Root LV name> --size <SIZE>` e.g.:
    ```
    # lvcreate -s -c 64k -n clean /dev/centos/root --size 40G
    ```

7) On a physical node run ```echo "/boot/vmlinuz-`uname -r`" > /boot/kernel.presnap.clean```

### Environment Configuration

Configured physical machine needs to be added to *env.json* as described [here](#envjson-file) under *physical_machines*.

### Network bridge

When a mix of PMs and VMs will be present in deployment topology (e.g. when **--use-physical-nodes** or **--use-physical-controllers** flag is passed to [run_tests.py](#run_testspy)) a network bridge needs to be set up as described [here](#create-network-bridge-optional).

## Execution

There are two ways to run the tests:

- immediate execution with [run_tests.py](#runtestspy)
- scheduled execution with [robot_job.py](#scriptsrobotjobpy)

For each execution a timestamp is generated which is used as an unique identifier.

All test artifacts are stored in directory *test/robot/workdir/<execution_timestamp>/* (e.g. *test/robot/workdir/2020-03-23---15-50-20-048/*).

### run_tests.py

This script can be used to directly run the tests. It gives a user a lot of flexibility but it also requires some manual work to prepare the *env.json* file.

In order to use this script a user needs to clone and configure the ***test*** repo (as described [here](#test-repo)) and then execute the *run_tests.py*.

In order to skip the deployment phase of Suite Setup (which can take a while to complete) each time the same Test Suite is run and there are no changes in setup (this is a common situation during the development process) a user can start the script with **--devel-dump** flag in the first execution. It will prevent the Teardown and will dump a config file to *test/robot/workdir/<execution_timestamp>/machines_info.json* that can be later used with **--devel-vms-conf** parameter in consecutive iterations.

> WARNING: When using --devel* params you can only run tests from ONE Test Suite.


Switching between VMs and PMs is achievable by using **--use-physical-(machines|controllers|nodes)**.


Sample execution of a single Network Edge test in developer mode:

```
# cd test/robot/
# ./run_tests.py -t ITP/NED/01/01 --devel-dump
```

Consecutive runs:

```
# ./run_tests.py -t ITP/NED/01/01 --devel-vms-conf workdir/<execution_timestamp>/machines_info.json
```

![Execution Sequence Diagram](diagrams/run_tests_sequence.jpg)

_Figure: Sequence diagram of immediate execution_

#### Arguments

- -t TAGS [TAGS ...], --tags TAGS [TAGS ...]

  Specifies tags to run

- --devel-dump

  Skip cleanup step and dump VMs config for use with --devel-vms-conf

- --devel-vms-conf DEVEL_VMS_CONF

  Skip successfully finished setup stages, retry unfinished recoverable stages and use the Machines from the config dumped by --devel-dump

- --force-cleanup

  Forces cleanup of VMs

- --use-physical-nodes

  PMs will be used for Edge Nodes

- --use-physical-controllers

  PMs will be used for Edge Controllers

- --use-physical-machines

  Only PMs will be used

- --non-rt-kernel

  Disable RT kernel for EdgeNodes

### scripts/robot_job.py

This script can be used in case someone needs more automated approach (e.g. as a Jenkins/Cron job).

It automatically clones the *test* repo and checks out a specified branch, configures [env.json](#envjson-file) file according to the environment variables, executes the tests and gathers the output.

#### Arguments

- -t TAGS [TAGS ...], --tags TAGS [TAGS ...]

  Specifies tags to run

- -b BRANCH, --branch BRANCH

  Checkout 'test' to a given branch

#### Environment variables

- github_token
- http_proxy
- https_proxy
- ftp_proxy
- no_proxy
- vm_default_name

  Base VM name as configured [here](#prepare-base-vm)


## Directory structure

```
robot/
├── docs
│   └── ...
├── keywords
│   └── ...
├── libraries
|   └── ...
├── resources
│   ├── variables
│   │   └── ...
│   ├── xml
│   |   └── ...
│   └── ...
├── run_tests.py
├── scripts
│   └── robot_job.py
│── testsuites
│   └── ...
└── workdir
```

- docs

  Documentation files.

- keywords

  Robot files with keywords that can be used across multiple Test Suites.

- libraries

  Custom Python libraries. Most of them were created to be able to directly use other Python modules that are not exposed to the Robot Framework or to write a function that would be hard to implement in the Framework because of its syntax limitations.

- resources

   - variables

     Files which define common variables.

   - xml

     XML definitions for libvirt (domains and volumes).

- testsuites

  All test suite files are kept here.

- workdir

  All test artifacts are stored here: e.g. configurations, logs, etc.

## Test Suites

For each distinct setup configuration a different Test Suite is created. For example for a setup consisting of 1 controller and 1 worker node in On-Prem mode with default deployment roles there's a *OnPrem_1_node_1_controller_defaults.robot* Suite.

This approach was used instead of having smaller Suites, each defined for a single functionality, because of the lengthy deployment. This way we can create a setup once per Suite and reuse it in every test which needs this particular environment.

### Test Setup

Each Test Suite needs to add Setup Stages by calling *CommonSetupTeardown.Add Setup Stage* keyword. Stage can be marked as recoverable or unrecoverable (unrecoverable by default).
When a test fails during a recoverable Stage in developer mode it can be retried using **--devel-vms-conf** [run_test.py argument](#arguments).
