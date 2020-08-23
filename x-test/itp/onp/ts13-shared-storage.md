```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/13: Shared Storage for Containers](#itponp13-shared-storage-for-containers)
  - [ITP/ONP/13/01: Volume and bind mount](#itponp1301-volume-and-bind-mount)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test steps](#test-steps)

# ITP/ONP/13: Shared Storage for Containers

## ITP/ONP/13/01: Volume and bind mount

### Test Summary

Verify that volumes are successfully created and mounted to containers alongside with mounts of host directories.

### Prerequisites

- OpenNESS On-Prem setup with controller and one node with default configuration 
  
### Test steps

1. Go to Applications tab on Conroller UI and Add new application
   -  Create container application (APP1) with EPA Feature:
      -  EPA Feature Key: `mount`
      -  EPA Feature Value: `volume,testvol1,/vol1,false;volume,testvol2,/vol2,true`
   -  Create two directories on host machine to be used for bind mounts eg: `/home/dir1` and `/home/dir2`
   -  Create container application (APP2) with EPA Feature:
      -  EPA Feature Key: `mount`
      -  EPA Feature Value: `bind,/home/dir1,/drw,false;bind,/home/dir2,/dro,true`
   -  Create container application (APP3) with EPA Feature:
      -  EPA Feature Key: `mount`
      -  EPA Feature Value: `volume,testvol1,/vol1,false;bind,/home/dir2,/drw,false;invalidtype,/home/testdir,/testdir,false`
2. Go to Nodes tab on Controller UI and select Edit
   -  Go to Apps and Deploy APP1, APP2, APP3
      -  Verify if apps was deployed successfully
      -  Verify in cce container logs if while deploying APP3 error was logged: `Invalid mount type for: invalidtype,/home/testdir,/testdir,false skipping...`
3. Using `docker inspect` verify for all three containers if `Mounts` sections contain corresponding mount entries eg: 
```shell
   "Mounts": [
   {
         "Type": "bind",
         "Source": "/home/dir1",
         "Destination": "/drw",
         "Mode": "",
         "RW": true,
         "Propagation": "rprivate"
   }
```
4. Using `docker volume list` verify if both volumes used in APP1 were created:
```shell
   [root@edgenode ~] docker volume list
   DRIVER              VOLUME NAME
   local               testvol1
   local               testvol2
```
5. sh to APP1 container (`docker exec -it ID /bin/sh`)
   - Go to `/vol1` and verify if it's possible to create file there by eg `touch testvolfile`
   - Go to `/vol2` and verify if same action as above will return error
6. sh to APP2 container (`docker exec -it ID /bin/sh`)
   - Go to `/drw` and verify if it's possible to create file there by eg `touch testbindfile`
   - Go to `/dro` and verify if same action as above will return error
   - Verify if `/home/dir1` on host filesystem now contains `testbindfile`
7. sh to APP3 container (`docker exec -it ID /bin/sh`)
   - Verify if `/vol1` contains `testvolfile`
   - Go to `/drw` and verify if it's possible to create file there by eg `touch testbindfile2`
8. Verify in APP2 container if `/dro` directory now contains `testbindfile2`