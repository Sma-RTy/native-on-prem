```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/02: Worker Microservice](#itponp02-worker-microservice)
  - [ITP/ONP/02/01: Consumer & Producer Sample Apps deployment in OnPrem Mode with Stand Alone EAA](#itponp0201-consumer--producer-sample-apps-deployment-in-onprem-mode-with-stand-alone-eaa)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test steps](#test-steps)
  - [ITP/ONP/02/02: Verify OpenNESS services name resolution in a container and a VM](#itponp0202-verify-openness-services-name-resolution-in-a-container-and-a-vm)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test steps](#test-steps-1)
  - [ITP/ONP/02/03: Verify that internet names resolution works](#itponp0203-verify-that-internet-names-resolution-works)
    - [Test Summary](#test-summary-2)
    - [Prerequisites](#prerequisites-2)
    - [Test steps](#test-steps-2)
  - [ITP/ONP/02/04: Verify that entries added to EdgeDNS through Controller UI can be resolved](#itponp0204-verify-that-entries-added-to-edgedns-through-controller-ui-can-be-resolved)
    - [Test Summary](#test-summary-3)
    - [Prerequisites](#prerequisites-3)
    - [Test steps](#test-steps-3)
  - [ITP/ONP/02/05: Verify that extra DNS entries that do not match local.mec domain are not resolved](#itponp0205-verify-that-extra-dns-entries-that-do-not-match-localmec-domain-are-not-resolved)
    - [Test Summary](#test-summary-4)
    - [Prerequisites](#prerequisites-4)
    - [Test steps](#test-steps-4)
  - [ITP/ONP/02/06: Get Edge Node's interfaces](#itponp0206-get-edge-nodes-interfaces)
    - [Test Summary](#test-summary-5)
    - [Prerequisites](#prerequisites-5)
    - [Test steps](#test-steps-5)
  - [ITP/ONP/02/07: Configure interface with traffic policy & start NTS](#itponp0207-configure-interface-with-traffic-policy--start-nts)
    - [Test Summary](#test-summary-6)
    - [Prerequisites](#prerequisites-6)
    - [Test steps](#test-steps-6)
  - [ITP/ONP/02/08: Assign Traffic Policy to App](#itponp0208-assign-traffic-policy-to-app)
    - [Test Summary](#test-summary-7)
    - [Prerequisites](#prerequisites-7)
    - [Test steps](#test-steps-7)
  - [ITP/ONP/02/09: Remove Traffic Policy](#itponp0209-remove-traffic-policy)
    - [Test Summary](#test-summary-8)
    - [Prerequisites](#prerequisites-8)
    - [Test steps](#test-steps-8)

# ITP/ONP/02: Worker Microservice

Test suite original definition: https://openness.atlassian.net/wiki/spaces/INTEL/pages/50298995/ITP+2019+12+ONP+2+Worker+Microservice+Test+Suite

## ITP/ONP/02/01: Consumer & Producer Sample Apps deployment in OnPrem Mode with Stand Alone EAA

### Test Summary

Verify if Consumer and Producer Sample Apps are able to communicate to Stand Alone EAA and  EAA is able to communicate with EVA in Appliance (in OnPrem Mode)

### Prerequisites

- Edge Controller in OnPrem Mode set-up and running as described in [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
- Edge Node in OnPrem Mode set-up, running and enrolled as described in [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)
- Consumer and Producer Sample Apps images (docker images build on controller machine using command `make build-docker`[on that path](https://github.com/otcshare/native-on-prem/tree/master/sample-app)) available in Apache HTTP Server

### Test steps

1. Create valid container application in APPLICATIONS tab for
   - Consumer Sample App
   - Producer Sample App
2. Deploy both apps to Edge Node (edit NODE, go to APPS, click DEPLOY APP and select created application)
   - UI: While image is being downloaded, status should be **unknown**
   - UI: After image is downloaded (check node's logs), status should be **deployed** (refresh page/tab)
   - Edge Node: App's container should exist and its status should be Created (`docker ps -a`)
     - look for container with NAME and IMAGE equal to UUID presented on the page)
3. Start the Producer App
   - UI: Refresh node's apps page - for a brief moment, status of the app should be **starting**, and eventually **running**
   - Edge Node: Docker container should be running (`docker ps -a`)
   - Verify logs:
     1. Producer Sample App: verify that following logs are visible
     `The Example Producer eaa.openness  [{ExampleNotification 1.0.0 Description for Event #1 by Example Producer}]}]}`
     `Sending notification`
     2. Stand Alone EAA: verify that following error print is **not** visible
     `Cannot get App ID from EVA`
     3. Appliance EVA logs: verify that **no error** prints are visible
4. Start the Consumer App
   - UI: Refresh node's apps page - for a brief moment, status of the app should be **starting**, and eventually **running**
   - Edge Node: Docker container should be running (docker ps -a)
   - Verify logs:
     1. Producer Sample App: verify that following logs are visible
     `Received notification`
     2. Stand Alone EAA: verify that following error print is **not** visible
     `Cannot get App ID from EVA`
     3. Appliance EVA logs: verify that **no error** prints are visible

## ITP/ONP/02/02: Verify OpenNESS services name resolution in a container and a VM

### Test Summary

Name resolution of eaa.community.appliance.mec and syslog.community.appliance.mec

### Prerequisites

- OnPrem OpenNESS platform ready as described in
  -  [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
  -  [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)
- Interfaces are configured(NTS and EdgeDNS are running)

### Test steps

1. Deploy a VM using the controller UI
2. Log in to the VM and using verify the name resoultion of OpenNESS services works(IP address of `192.168.122.1` is shown):
    - VM ip can be extracted from the following command:
    `virsh net-dhcp-leases default`
    - Commands to verify that the name resolution is working:
    `nslookup eaa.openness`
    `nslookup syslog.openness`
3. Deploy a container using the Controller UI
4. Using `docker exec` and commands: `nslookup eaa.openness`, `nslookup syslog.openness` verify that the name resolution works

## ITP/ONP/02/03: Verify that internet names resolution works

### Test Summary

Name resolution google.com for VMs and containers

### Prerequisites

- OnPrem OpenNESS platform ready as described in
  -  [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
  -  [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)
- Interfaces are configured(NTS and EdgeDNS are running)

### Test steps

1. Deploy a VM using the controller UI
2. Log in to the VM and using verify the name resoultion of OpenNESS services works(IP address of google.com is shown):
    - VM ip can be extracted from the following command:
    `virsh net-dhcp-leases default`
    - Command to verify that the name resolution is working:
    `nslookup google.com`
3. Deploy a container using the Controller UI
4. Using `docker exec` and commands `nslookup google.com` verify that the name resolution works

## ITP/ONP/02/04: Verify that entries added to EdgeDNS through Controller UI can be resolved

### Test Summary

Name resolution for entries added through Controller UI and matching local.mec domain

### Prerequisites

- OnPrem OpenNESS platform ready as described in
  -  [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
  -  [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)
- Interfaces are configured(NTS and EdgeDNS are running)
- Change nameserver to `192.168.122.1` on VM in `/etc/resolv.conf`

### Test steps

1. Add a DNS entry in Controller ui that ends with `local.mec` (e.g `test.edgenode1.local.mec`)
2. Deploy a VM using the controller UI
3. Log in to the VM and using verify the name resoultion of OpenNESS services works:
    - VM ip can be extracted from the following command:
    `virsh net-dhcp-leases default`
    - Command to verify that the name resolution is working:
    `nslookup test.edgenode1.local.mec`
4. Deploy a container using the Controller UI
5. Using `docker exec` and command `nslookup test.edgenode1.local.mec` verify that the name resolution works

## ITP/ONP/02/05: Verify that extra DNS entries that do not match local.mec domain are not resolved

### Test Summary

Name resolution for entries added through Controller UI and not matching local.mec domain

### Prerequisites

- OnPrem OpenNESS platform ready as described in
  -  [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
  -  [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)
- Interfaces are configured(NTS and EdgeDNS are running)
- Change nameserver to `192.168.122.1` on VM in `/etc/resolv.conf`

### Test steps

1. Add a DNS entry in Controller ui that does not end with `local.mec` (e.g `test.edgenode1.com`)
2. Deploy a VM using the controller UI
3. Log in to the VM and using verify the name resolution of OpenNESS services fails:
    - VM ip can be extracted from the following command:
    `virsh net-dhcp-leases default`
    - Command to verify that the name resolution is failing: `nslookup test.edgenode1.com`
4. Deploy a container using the Controller UI
5. Using `docker exec` and command `nslookup test.edgenode1.com` verify that the name resolution fails the same way

## ITP/ONP/02/06: Get Edge Node's interfaces

### Test Summary

Get interfaces available on Edge Node

### Prerequisites

- OnPrem OpenNESS platform ready as described in
  -  [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
  -  [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)

### Test steps

1. Open Controller's UI, log in if needed
2. Go to tab *NODES*
3. Go to Node's *INTERFACES*
4. Verify expected outcome
    - Interfaces/network devices should be presented and matching interfaces actually present on the node

## ITP/ONP/02/07: Configure interface with traffic policy & start NTS

### Test Summary

Configure interface with traffic policy & start NTS

### Prerequisites

- OnPrem OpenNESS platform ready as described in
  -  [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
  -  [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)

### Test steps

1. Open Controller's UI, log in if needed
2. Create traffic policy
    - Go to *TRAFFIC POLICIES* tab
    - Click *ADD POLICY*
    - Fill name: "policy1"
    - Click on *ADD* next to "Traffic Rules"
    - Fill fields:
        - Description: "desc"
        - Priority: 99
        - Source→IP Filter→Address: 1.1.1.1
        - Source→IP Filter→Mask: 24
        - Source→IP Filter→Begin Port: 10
        - Source→IP Filter→End Port: 20
        - Source→IP Filter→Protocol: all
        - Target→Action: accept
        - Destination→IP Filter→Address: 0.0.0.0
3. Assign traffic policy to interface
    - Go to tab *NODES*
    - Click *EDIT* on the Node
    - Go to Node's *INTERFACES*
    - Click *ADD* next to interface that is going to be used by NTS (e.g. 10 Gb Ethernet)
    - Choose previously added traffic policy, click *ASSIGN*
4. Configure interface
    - Click *EDIT* next to interface that is going to be used by NTS (e.g. 10 Gb Ethernet)
    - Make changes:
        - Driver: userspace
        - Type: upstream
        - Fallback interface: PCI of the other interface, e.g. 0000:02:00.1
    - Click *SAVE*
5. Click *COMMIT CHANGES*
6. Verify expected outcome after 20-40 seconds
    - UI reports: "Successfully updated node interfaces"
    - NTS container is running
    - Edge DNS is running
    - Configured interface is in /var/lib/appliance/nts/nts.cfg file and values from UI should match values in file
      - name & pci-address = ID in UI
      - description - description in UI
      - traffic-type = IP (because only IP filter was set)
      - traffic-direction = upstream (as set in UI)
      - egress-port = 0 (because there's only 1 port configured)
      - route = prio:99,ue_ip:1.1.1.1/24,ue_port:10-20,encap_proto:noencap
    - Verify that rule is present in NTS:
      - `export NES_SERVER_CONF=/var/lib/appliance/nts/nts.cfg`
      - `cd appliance-ce/internal/nts/client/build`
      - `./nes_client`
      - `Enter command: connect`
      - `Enter command: route list`
      - Verify route list output - two rules should be added with data consistent with created traffic policy, example:

        ```shell
        +-------+------------+--------------------+--------------------+--------------------+--------------------+-------------+-------------+--------+----------------------+
        | ID    | PRIO       | ENB IP             | EPC IP             | UE IP              | SRV IP             | UE PORT     | SRV PORT    | ENCAP  | Destination          |
        +-------+------------+--------------------+--------------------+--------------------+--------------------+-------------+-------------+--------+----------------------+
        | 0     | 99         | n/a                | n/a                | 1.1.1.1/24         | *                  | 10-20       | *           | IP     | 00:00:00:00:00:00    |
        ```

## ITP/ONP/02/08: Assign Traffic Policy to App

### Test Summary

Check if new Traffic Policy is successfully assigned to application

### Prerequisites

- OnPrem OpenNESS platform ready as described in
  -  [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
  -  [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)
- Edge Application successfully added
- Edge Application successfully deployed and started on Edge Node

### Test steps

1. Create new traffic policy
    - In Controller UI click on *TRAFFIC POLICIES* tab
    - Click on *ADD POLICY* button
    - Type traffic rule name
    - Click *ADD*
    - Fill the form that will appear (see example below)

        ```shell
        Priority: 99

        Source
        GTP Address: 192.168.219.179
        Mask: 32

        Destination
        IP Address: 10.30.40.2
        Mask: 24
        Protocol: all

        Target
        Action: accept
        ```

    - Click *Create* and verify the status returned by UI
    - A new entry should appear on the Traffic Policies list
2. Assign traffic policy to application
    - Go to Node's list, *EDIT* Node
    - Go to *APPS* page
    - Click *ADD* under Traffic Policy next to the deployed app
    - Select traffic policy and click *ASSIGN*
3. Verify expected outcome:
    - UI reports: Successfully added policy on app
    - Edge node logs:
        - `[eda] Received new SET request for application traffic policy ID <<UUID>>`
        - verify that no error logs present
4. Verify that rule is present in NTS:
    - `export NES_SERVER_CONF=/var/lib/appliance/nts/nts.cfg`
    - `cd appliance-ce/internal/nts/client/build`
    - `./nes_client`
    - `Enter command: connect`
    - `Enter command: route list`
    - Verify route list output - two rules should be added with data consistent with created traffic policy, example:

        ```shell
        | 4     | 99         | 192.168.219.179/32 | *                  | *                  | 10.30.40.2/24      | *           | *           | GTPU   | 12:96:96:89:43:93    |
        | 5     | 99         | *                  | 192.168.219.179/32 | 10.30.40.2/24      | *                  | *           | *           | GTPU   | 12:96:96:89:43:93    |
        +-------+------------+--------------------+--------------------+--------------------+--------------------+-------------+-------------+--------+----------------------+
        ```

## ITP/ONP/02/09: Remove Traffic Policy

### Test Summary

Check if existing Traffic Policy is removed successfully

### Prerequisites

- OnPrem OpenNESS platform ready as described in
  -  [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode)
  -  [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](https://github.com/otcshare/native-on-prem/test/blob/master/itp/onp/ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)
- Edge Application successfully added
- Edge Application successfully deployed and started on Edge Node
- Traffic Policy assigned to Edge Application

### Test steps

1. Remove traffic policy from application
    - Go to Node's list, *EDIT* Node
    - Go to *APPS* page
    - Click *REMOVE POLICY* under Traffic Policy next to the deployed app
2. Verify expected outcome:
    - UI reports: Successfully remove policy on app
    - Edge node logs:
        - `[eda] Received new SET request for application traffic policy ID <<UUID>>`
        - `[eda] Removing existing traffic policy for application ID <<UUID>>`
        - verify that no error logs present
    - Verify that rule is **absent** in NTS:
        - `export NES_SERVER_CONF=/var/lib/appliance/nts/nts.cfg`
        - `cd appliance-ce/internal/nts/client/build`
        - `./nes_client`
        - `Enter command: connect`
        - `Enter command: route list`
