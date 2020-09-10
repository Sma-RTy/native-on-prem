```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/01: Platform Setup Automation](#itponp01-platform-setup-automation)
  - [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](#itponp0101-deploy-edge-controller-in-onprem-mode)
    - [Test summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test steps](#test-steps)
  - [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test steps](#test-steps-1)
  - [ITP/ONP/01/03: Verify newer RT kernel, grub and tuned customization](#itponp0103-verify-newer-rt-kernel-grub-and-tuned-customization)
    - [Test summary](#test-summary-2)
    - [Prerequisites](#prerequisites-2)
    - [Test steps](#test-steps-2)
  - [ITP/ONP/01/04: Verify newer non-RT kernel, grub and tuned customization](#itponp0104-verify-newer-non-rt-kernel-grub-and-tuned-customization)
    - [Test summary](#test-summary-3)
    - [Prerequisites](#prerequisites-3)
    - [Test steps](#test-steps-3)
  
# ITP/ONP/01: Platform Setup Automation

Original definition: https://openness.atlassian.net/wiki/spaces/INTEL/pages/121569283/ITP+2020+03+ONP+1+Platform+Setup+Automation+Test+Suite

> **Hosts/inventory preparation**
>
> Ansible uses inventory.ini file for setting up hosts for playbooks execution.
>
> openness-experience-kits repository contains such file in top directory. The file features two groups: edgenode_group and controller_group. Please add your hosts to the inventory using example hosts that are already in the file (use IP address for controller, using domain name for controller is not supported).

## ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode

### Test summary
Test walks through controller deployment procedure and asserts that

* edgecontroller repository is checked out
* docker is installed and configured
* openness containers are running

### Prerequisites

* Repository `otcshare/native-on-prem` checked out
* One host added to the *controller_group* in `oek/inventory.ini` file (refer to “Hosts/inventory preparation” information above)
* `oek/group_vars/all/10-default.yml` is set up according to the network (proxy_* and git_repo_token vars)
* ssh key must be copied to host (`ssh-copy-id root@<edgecontroller_ip_from_inventory>`)

### Test steps

1. From `oek` directory execute script: `./deploy_onprem.sh controller`
2. Script should finish with success
3. If script was successful, check following things on the controller:
   - Verification of os_setup role
      1. /etc/environment should contain shell vars for proxy according to the one set in group_vars/all/10-default.yml

   - Verification of docker role
     1. Docker service should be enabled and running:<br>
        `systemctl status docker | grep -e enabled -e active`

     2. Docker service should have proxy set up. `systemctl status docker | grep 'Drop-In' -A1` should report:
        ```
        Drop-In: /etc/systemd/system/docker.service.d
                  └─ http-proxy.conf
        ```

     3. `cat /etc/systemd/system/docker.service.d/http-proxy.conf` should contain output similar to:
        ```
        [Service]
        Environment="HTTP_PROXY=http://proxy-dmz.intel.com:911"
        Environment="HTTPS_PROXY=http://proxy-dmz.intel.com:911"
        Environment="NO_PROXY=10.103.102.77,localhost,127.0.0.1,10.244.0.0/16,10.96.0.0/24,10.103.102.0/25"
        ```

     4. `cat ~/.docker/config.json` should contain output similar to:
        ```
        {
          "proxies": {
            "default": {
                "httpProxy": "http://proxy-dmz.intel.com:911",
                "httpsProxy": "http://proxy-dmz.intel.com:911",
                "noProxy": "10.103.102.77,localhost,127.0.0.1,10.244.0.0/16,10.96.0.0/24,10.103.102.0/25"
            }
          }
        }
        ```

   - Verification of openness role
     1. docker images should contain output similar to:
        ```
        docker images
        REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
        cce                 latest              d160ccdfbaf2        17 hours ago        979MB
        cnca                latest              258304f542b6        17 hours ago        432MB
        ui                  latest              d34ae394e050        17 hours ago        483MB
        cups                latest              b5d842c27e7d        17 hours ago        432MB
        mysql               8.0                 d435eee2caa5        2 weeks ago         456MB
        node                lts-alpine          3fb8a14691d9        2 weeks ago         80.2MB
        ```

     2. openness containers should be running, docker ps should contain output similar to:
        ```
        CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                                              NAMES
        ce3d3f47635f        cnca:latest         "docker-entrypoint.s…"   16 hours ago        Up 16 hours         0.0.0.0:3020->80/tcp                                                               edgecontroller_cnca-ui_1
        7513f8a22d02        cups:latest         "docker-entrypoint.s…"   16 hours ago        Up 16 hours         0.0.0.0:3010->80/tcp                                                               edgecontroller_cups-ui_1
        1c9d14ee0d96        ui:latest           "docker-entrypoint.s…"   16 hours ago        Up 16 hours         0.0.0.0:3000->80/tcp                                                               edgecontroller_ui_1
        3398512321f2        cce:latest          "/cce -adminPass pas…"   16 hours ago        Up 16 hours         0.0.0.0:6514->6514/tcp, 0.0.0.0:8080-8081->8080-8081/tcp, 0.0.0.0:8125->8125/tcp   edgecontroller_cce_1
        0dea6b4756e9        mysql:8.0           "docker-entrypoint.s…"   16 hours ago        Up 16 hours         33060/tcp, 0.0.0.0:8083->3306/tcp                                                  edgecontroller_mysql_1
        ```

     3. check if UI is running by putting CONTROLLER_IP:3000 to web browser and verify that it is possible to log in to controller UI

   - Verification of git_repo role
     1. `edgecontroller` folder should be available in `/opt/edgecontroller`.

---

## ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode

### Test Summary

Test walks through node deployment procedure and asserts that

* edgenode repository is checked out
* docker is installed and configured
* openness containers are running
* Edge Node is enrolled

### Prerequisites

* Repository `otcshare/native-on-prem` checked out
* One host added to the *edgenodes_group* in `oek/inventory.ini` file (refer to “Hosts/inventory preparation” information above)
* `oek/group_vars/all/10-default.yml` is set up according to the network (proxy_* and git_repo_token vars)
* ssh key must be copied to host (`ssh-copy-id root@<edgenode_ip_from_inventory>`))
* Controller deployment done as in [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](#itponp0101-deploy-edge-controller-in-onprem-mode)

### Test steps

1. From `oek` directory execute script: `./deploy_onprem.sh node`
2. Script should finish with success
3. If script was successful, check following things on the worker/node:
   - os_setup role verification
     1. `/etc/environment` should contain shell vars for proxy according to the one set in `oek/group_vars/all/10-default.yml`

   - git_repo role verification

     1. `edgenode` folder should be available in `/opt/edgenode`.

   - verification of docker role
     1. Docker service should be enabled and running:<br> `systemctl status docker | grep -e enabled -e active`
     2. Docker service should have proxy set up<br>
        `systemctl status docker | grep 'Drop-In' -A1` should report:
        ```
        Drop-In: /etc/systemd/system/docker.service.d
                  └─ http-proxy.conf
        ```
     3. `cat /etc/systemd/system/docker.service.d/http-proxy.conf` should contain output similar to:
        ```
        [Service]
        Environment="HTTP_PROXY=http://proxy-dmz.intel.com:911"
        Environment="HTTPS_PROXY=http://proxy-dmz.intel.com:911"
        Environment="NO_PROXY=10.103.102.77,localhost,127.0.0.1,10.244.0.0/16,10.96.0.0/24,10.103.102.0/25"
        ```
     4. `cat ~/.docker/config.json` should contain output similar to:
        ```
        {
          "proxies": {
            "default": {
                "httpProxy": "http://proxy-dmz.intel.com:911",
                "httpsProxy": "http://proxy-dmz.intel.com:911",
                "noProxy": "10.103.102.77,localhost,127.0.0.1,10.244.0.0/16,10.96.0.0/24,10.103.102.0/25"
            }
          }
        }
        ```
   - openness/onprem/worker role verification

     1. docker images for appliance, nts, edgednssvr and eaa should be built, docker images should contain output similar to:
        ```
        REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
        appliance           1.0                 2c95db4d2544        7 hours ago         322MB
        nts                 1.0                 a800b5d3ddaa        7 hours ago         396MB
        edgednssvr          1.0                 329620150685        7 hours ago         22.1MB
        eaa                 1.0                 8cd8826e6b3e        7 hours ago         245MB
        alpine              latest              965ea09ff2eb        7 weeks ago         5.55MB
        centos              7.6.1810            f1cb7c7d58b7        9 months ago        202MB
        balabit/syslog-ng   3.19.1              004fddc9c299        11 months ago       469MB
        ```
     2. openness docker containers should be running, docker ps should contain output similar to:
        ```
        CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                                  NAMES
        6dd2773a3510        004fddc9c299        "/usr/sbin/syslog-ng…"   7 hours ago         Up 7 hours          601/tcp, 514/udp, 6514/tcp                                             edgenode_syslog-ng_1
        9a8b1bc4c509        appliance:1.0       "sudo ./entrypoint.sh"   7 hours ago         Up 7 hours          0.0.0.0:42101-42102->42101-42102/tcp, 192.168.122.1:42103->42103/tcp   edgenode_appliance_1
        b3b5ea6099f5        eaa:1.0             "sudo ./entrypoint_e…"   7 hours ago         Up 7 hours          192.168.122.1:80->80/tcp, 192.168.122.1:443->443/tcp                   edgenode_eaa_1
        ```

4. Verify if Edge Node enrollment is successful:
   - go to Controller's UI and log in
   - got to "Nodes" tab and verify that the Node exists on the list.
   - verify Edge Node's logs `docker logs <appliance_container_id>` (on the Edge Node), output should contain:
     1. "Successfully enrolled"
     2. "Starting services"

---

## ITP/ONP/01/03: Verify newer RT kernel, grub and tuned customization

### Test summary

Setup node with different RT kernel, grub parameters & tuned profiles.

### Prerequisites

* Repository `otcshare/native-on-prem` checked out
* Edge Controller already set up
* Inventory: one node (`node01`) added.
* Nodes should be CentOS 18.10 minimal
* `oek/group_vars/all/10-default.yml` is set up according to the network (`proxy_*` and `git_repo_token` vars)
* SSH key must be copied to host (`ssh-copy-id`)

### Test steps

1. Configure node - newer realtime kernel, no tuned profile, additional debug parameter and less hugepages.<br>
   Insert following lines to `oek/host_vars/node01.yml` file:
   ```yaml
   kernel_version: 3.10.0-1062.9.1.rt56.1033.el7.x86_64
   tuned_skip: true
   additional_grub_params: "debug"
   hugepage_amount: "500"
   ```

2. From `oek` directory execute script `./deploy_onprem.sh node` and wait until script finishes. It should end with success.
3. Verify deployment of the node
   - `uname -r` should display `3.10.0-1062.9.1.rt56.1033.el7.x86_64`
   - `tuned-adm active` **should not** display `Current active profile: realtime` (it might be `virtual-guest` if it's a VM or different if it's a physical machine)
   - `cat /proc/cmdline` should contain: `debug hugepagesz=2M hugepages=500 intel_iommu=on iommu=pt`

---

## ITP/ONP/01/04: Verify newer non-RT kernel, grub and tuned customization

### Test summary

Setup node with different non-RT kernel, grub parameters & tuned profiles.

### Prerequisites

* same prerequisites fulfilled as in 
[ITP/ONP/01/03: Verify newer RT kernel, grub and tuned customization](#prerequisites-2)
### Test steps


1. Configure node - newer non-rt kernel, balanced tuned profile, no intel iommu and less hugepages<br>
   Insert following lines to `oek/host_vars/node01.yml` file:
    ```yaml
    kernel_repo_url: ""
    kernel_package: kernel
    kernel_devel_package: kernel-devel
    kernel_version: 3.10.0-1062.el7.x86_64

    tuned_packages:
    - http://linuxsoft.cern.ch/cern/centos/7/updates/x86_64/Packages/tuned-2.11.0-5.el7_7.1.noarch.rpm
    tuned_profile: balanced
    tuned_vars: ""

    hugepage_amount: "200"
    default_grub_params: "hugepagesz={{ hugepage_size }} hugepages={{ hugepage_amount }}"

    dpdk_kernel_devel: ""
    ```

2. From `oek` directory execute script `./deploy_onprem.sh node` and wait until script finishes. It should end with success.
3. Verify deployment of the node
   - `uname -r` should display `3.10.0-1062.el7.x86_64`
   - `tuned-adm active` should display `Current active profile: balanced`
   - `tuned-adm --version` should display: `tuned-adm 2.11.0`
   - `cat /proc/cmdline` should contain: `hugepagesz=2M hugepages=200` and **should not** contain `intel_iommu=on iommu=pt`

---
