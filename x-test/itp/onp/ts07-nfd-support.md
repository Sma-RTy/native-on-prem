```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/07: NFD Support](#itponp07-nfd-support)
  - [ITP/ONP/07/01: NFD Setup Verification](#itponp0701-nfd-setup-verification)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test steps](#test-steps)
  - [ITP/ONP/07/02: NFD Multinode Setup Verification](#itponp0702-nfd-multinode-setup-verification)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test steps](#test-steps-1)
  - [ITP/ONP/07/03: NFD as EAC feature for Container](#itponp0703-nfd-as-eac-feature-for-container)
    - [Test Summary](#test-summary-2)
    - [Prequisites](#prequisites)
    - [Test steps](#test-steps-2)
  - [ITP/ONP/07/04: NFD as EAC feature for VM](#itponp0704-nfd-as-eac-feature-for-vm)
    - [Test Summary](#test-summary-3)
    - [Prequisites](#prequisites-1)
    - [Test steps](#test-steps-3)

# ITP/ONP/07: NFD Support

## ITP/ONP/07/01: NFD Setup Verification

### Test Summary

Verify that Node Feature Discovery is installed after running automated setup of Edge Node and Edge Controller. On Edge Node nfd-worker image is downloaded from [NFD repository](https://github.com/kubernetes-sigs/node-feature-discovery) and started as docker container. On Edge Controller OpenNESS nfd-master is built and started as docker container. Feature information is sent from nfd-worker and received by nfd-master.

### Prerequisites

- For Edge Controller prerequisites check test case: [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
- For Edge Node prerequisites check test case: [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)

### Test steps

1. Configure ansible for NFD (NFD feature is enabled by default):
    - Make sure that `onprem_nfd_enable` is set to "True" in `group_vars/all/10-default.yml`

2. Deploy OpenNESS platform in OnPrem mode as in test cases: [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode), Edge Node in OnPrem Mode set-up, running and enrolled as described in [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)

3. Verify on Edge Node if:
   - nfd-worker image is pulled and present: `docker images` should report:

     ```shell
     REPOSITORY                                            TAG           IMAGE ID            CREATED             SIZE
     quay.io/kubernetes_incubator/node-feature-discovery  v0.5.0        7f353e085ef5        2 days ago          92.5MB
     ```

   - nfd-worker container is running: `docker ps` should report:

     ```shell
     CONTAINER ID        IMAGE                                                        COMMAND                  CREATED             STATUS              PORTS                                                                  NAMES
     efe098502820        quay.io/kubernetes_incubator/node-feature-discovery:v0.5.0   "nfd-worker --ca-fil…"   7 seconds ago       Up 6 seconds                                                                               nfd-worker
     ```

   - `nfd-worker` container logs (`docker logs  CONTAINER_ID`) contain:

     ```shell
     2020/02/07 14:35:51 Sending labeling request to nfd-master
     ```

4. Verify on Edge Controller if:
   - nfd-master is compiled and output is present in directory: `/opt/edgecontroller/dist/nfd-master`
   - nfd-master image is present: `docker images` should report:

     ```shell
     REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
     nfd-master              latest              0ea3738add0f        4 hours ago         266MB
     ```

   - nfd-master container is running: `docker ps` should report:

     ```shell
     CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                               NAMES
     6f4aeb89e494        nfd-master:latest   "sudo ./entrypoint.sh"   12 minutes ago      Up 12 minutes       0.0.0.0:8082->8082/tcp              edgecontroller_nfd-master_1
     ```

   - nfd-master receives information from nfd-worker:
     
     1. Go to Controller's UI and log in ( localhost:3000 )
     2. Go to "Nodes" tab and select the "EDIT" button on existing Node.
     3. Select "NFD" tab.
     4. NFD table data should be similar to:
        &nbsp;  
        ![NFD table](images/itp_onp_07_01.png)

## ITP/ONP/07/02: NFD Multinode Setup Verification

### Test Summary

Use two machines as Edge Nodes and verify that Node Feature Discovery plugin is installed (on both nodes) and working after running automated OpenNESS setup scripts.

### Prerequisites

- At least two machines used as Edge Nodes
- Clean Centos 7.6 machine / VM
- Proxy setup done

### Test steps

The same as in [ITP/ONP/07/01](#itponp0701-nfd-setup-verification) except verification steps for Edge Node should be done for both nodes used in set up:

- in step 3. perform verification on both Edge Nodes
- in step 4. verify if nfd-master receives information from both nfd-workers

## ITP/ONP/07/03: NFD as EAC feature for Container

### Test Summary

Use NFD values as EAC (EPA values in application form) and verify if it's validated during containter application deployment on node.

### Prequisites

- OnPrem setup from [ITP/ONP/07/01](#itponp0701-nfd-setup-verification)

### Test steps

1. Go to Applications tab on Conroller UI and Add new application
   -  Create container application (APP1) with EPA Feature matching node NFD feature eg:
      -  EPA Feature Key: `nfd:cpu-cpuid.ADX`
      -  EPA Feature Value: `true`
   -  Create container application (APP2) with EPA Feature missmatching node NFD feature eg:
      -  EPA Feature Key: `nfd:cpu-cpuid.ADX`
      -  EPA Feature Value: `false`
   -  Create container application (APP3) with EPA Feature missing on node eg:
      -  EPA Feature Key: `nfd:test.TEST`
      -  EPA Feature Value: `true`
2. Go to Nodes tab on Controller UI and select Edit
   -  Go to Apps and Deploy APP1
      -  Verify if app was deployed successfully
   -  Deploy APP2
      -  Verify if deployment failed
      -  Check in cce container logs if `EPA Feature [cpu-cpuid.ADX] value required: [true] provided by node: [false]` appeared
   -  Deploy APP3
      -  Verify if deployment failed
      -  Check in cce container logs if `Missing EPA Feature: [test.TEST] required by app` appeared

## ITP/ONP/07/04: NFD as EAC feature for VM

### Test Summary

Use NFD values as EAC (EPA values in application form) and verify if it's validated during VM application deployment on node.

### Prequisites

- OnPrem setup from [ITP/ONP/07/01](#itponp0701-nfd-setup-verification)

### Test steps

1. Go to Applications tab on Conroller UI and Add new application
   -  Create VM application (APP1) with EPA Feature matching node NFD feature eg:
      -  EPA Feature Key: `nfd:cpu-cpuid.ADX`
      -  EPA Feature Value: `true`
   -  Create VM application (APP2) with EPA Feature missmatching node NFD feature eg:
      -  EPA Feature Key: `nfd:cpu-cpuid.ADX`
      -  EPA Feature Value: `false`
   -  Create VM application (APP3) with EPA Feature missing on node eg:
      -  EPA Feature Key: `nfd:test.TEST`
      -  EPA Feature Value: `true`
2. Go to Nodes tab on Controller UI and select Edit
   -  Go to Apps and Deploy APP1
      -  Verify if app was deployed successfully
   -  Deploy APP2
      -  Verify if deployment failed
      -  Check in cce container logs if `EPA Feature [cpu-cpuid.ADX] value required: [true] provided by node: [false]` appeared
   -  Deploy APP3
      -  Verify if deployment failed
      -  Check in cce container logs if `Missing EPA Feature: [test.TEST] required by app` appeared
