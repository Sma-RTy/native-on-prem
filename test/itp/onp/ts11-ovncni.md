```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/11: OVN CNI Dataplane](#itponp11-ovn-cni-dataplane)
  - [ITP/ONP/11/01: Setup deployment](#itponp1101-setup-deployment)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test steps](#test-steps)
  - [ITP/ONP/11/02: Sample edge apps deployment](#itponp1102-sample-edge-apps-deployment)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test steps](#test-steps-1)
  - [ITP/ONP/11/03: VM deployment](#itponp1103-vm-deployment)
    - [Test Summary](#test-summary-2)
    - [Prerequisites](#prerequisites-2)
    - [Test steps](#test-steps-2)
  - [ITP/ONP/11/04: Microservices tests](#itponp1104-microservices-tests)
    - [Test Summary](#test-summary-3)
    - [Prerequisites](#prerequisites-3)
    - [Test steps](#test-steps-3)

# ITP/ONP/11: OVN CNI Dataplane

## ITP/ONP/11/01: Setup deployment

### Test Summary

Edge Controller and Edge Nodes in On Premises mode are deployed with OVN CNI as a dataplane instead of NTS.

### Prerequisites

- 1 clean physical or virtual machine for Edge Controller
- 1 clean physical or virtual machine for Edge Node
- 1 clean physical for Edge Node

### Test steps

1. Modify `onprem_dataplane` variable in `oek/group_vars/all/10-default.yml`:
   ```yaml
   onprem_dataplane: "ovncni"
   ```
2. Perform deployment of On Premises mode
   (refer to [ITP/ONP/01/01: Deploy Edge Controller in OnPrem mode](./ts01-platform-setup.md#itponp0101-deploy-edge-controller-in-onprem-mode) and
   [ITP/ONP/01/02: Deploy and Enroll Edge Node in OnPrem mode](./ts01-platform-setup.md#itponp0102-deploy-and-enroll-edge-node-in-onprem-mode)).
3. Verify Edge Controller deployment
   - `/opt/edgecontroller/artifacts/controller/cni/` should contain two non-empty files: `cni_args.json` and `cni.conf`.
   - `ovs-ovn` container should be running:
     ```
     # docker ps --filter "name=ovs-ovn"
     CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
     6be7001f7bdc        ovs-ovn             "/bin/bash start_ovs…"   43 hours ago        Up 43 hours                             ovs-ovn
     ```
4. Verify Edge Node deployment
   - EVA should be configured to use CNI:
     ```
     # grep UseCNI /var/lib/appliance/configs/eva.json
      "UseCNI": true
     ```
   - `/opt/cni/bin/ovn` executable should exist
     ```
     # ls /opt/cni/bin/ovn
     /opt/cni/bin/ovn
     ```
   - `ovs-ovn` container should be running:
     ```
     # docker ps --filter "name=ovs-ovn"
     CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
     82cbf096e293        ovs-ovn             "/bin/bash start_ovs…"   42 hours ago        Up About an hour                        ovs-ovn
     ```
   - `/etc/environment` should contain line `OVN_NB_DB=tcp:<controller ip>:6641`


---

## ITP/ONP/11/02: Sample edge apps deployment

### Test Summary

Sample Edge Apps are deployed on the Edge Node **#1** and verified if OVN CNI is a drop-ip replacement for NTS.

### Prerequisites

- [ITP/ONP/11/01: Setup deployment](#itponp1101-setup-deployment) successfully performed

### Test steps

1. Perform [ITP/ONP/02/01](ts01-platform-setup.md#itponp0201-consumer--producer-sample-apps-deployment-in-onprem-mode-with-stand-alone-eaa)
2. Additionally check:
   - `docker ps` should show two infrastructure containers (for both consumer and producer).
     Infrastructure container's name has a format: `OPENNESS-CNI-INFRASTRUCTURE_<app container id>`:
   - Run command to obtain container's ip: `docker exec <CONTAINER> ip a`. Note the IP of non-`lo` inteface, e.g. `10.100.0.3`

---

## ITP/ONP/11/03: VM deployment

### Test Summary

VM is deployed and started on the Edge Node **#2**.

### Prerequisites

- [ITP/ONP/11/01: Setup deployment](#itponp1101-setup-deployment) successfully performed
- [ITP/ONP/11/02: Sample edge apps deployment](#itponp1102-sample-edge-apps-deployment) successfully performed
- VM qcow2 image prepared (make sure it has automatic DHCP on boot, e.g. `dhcpcd` service installed and enabled)

### Test steps

1. Deploy and start the VM on the **#2** Edge Node
2. SSH to the VM
   > You can obtain VM's IP by running following command on the edge node:<br>
   > `docker exec ovs-ovn ovn-nbctl wait-until logical_switch_port <APP_ID> dynamic_addresses!=[] -- get logical_switch_port <APP_ID> dynamic-addresses`
   - `ping 10.100.0.1 -w 3` - no packet should be lost
   - Ping the container from previous test `ping <container ip> -w 3` - no packet should be lost

---

## ITP/ONP/11/04: Microservices tests

### Test Summary

Several tests from Microservice Test Suite are performed.

### Prerequisites

- Tests successfully performed:
  - [ITP/ONP/11/01: Setup deployment](#itponp1101-setup-deployment)
  - [ITP/ONP/11/02: Sample edge apps deployment](#itponp1102-sample-edge-apps-deployment)
  - [ITP/ONP/11/03: VM deployment and lifecycle](#itponp1103-vm-deployment-and-lifecycle)

### Test steps

> You can obtain VM's IP by running following command on the edge node:<br>
> `docker exec ovs-ovn ovn-nbctl wait-until logical_switch_port <APP_ID> dynamic_addresses!=[] -- get logical_switch_port <APP_ID> dynamic-addresses`

> Before verifying DNS resolution, edit /etc/resolv.conf to point to the 192.168.122.1
1. Perform [ITP/ONP/02/02: Verify OpenNESS services name resolution in a container and a VM](./ts02-microservice.md#itponp0202-verify-openness-services-name-resolution-in-a-container-and-a-vm)
2. Perform [ITP/ONP/02/03: Verify that internet names resolution works](./ts02-microservice.md#itponp0203-verify-that-internet-names-resolution-works)
3. Perform [ITP/ONP/02/04: Verify that entries added to EdgeDNS through Controller UI can be resolved](./ts02-microservice.md#itponp0204-verify-that-entries-added-to-edgedns-through-controller-ui-can-be-resolved)
3. Perform [ITP/ONP/02/05: Verify that extra DNS entries that do not match local.mec domain are not resolved](./ts02-microservice.md#itponp0205-verify-that-extra-dns-entries-that-do-not-match-localmec-domain-are-not-resolved)
