```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/14: Port Forward](#itponp14-port-forward)
  - [ITP/ONP/14/01: Port Forward positive test](#itponp1401-port-forward-positive-test)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test steps](#test-steps)
  
# ITP/ONP/14: Port Forward

## ITP/ONP/14/01: Port Forward positive test

### Test Summary
This test will validate if we can properly set the exposed network ports
command of a container when all of our setup and configuration is correct.

### Prerequisites
- Controller API, UI and database installed and up.
- Apache server serving container images setup properly and up.
- Image of a working docker container present on the container image server.

### Test steps
1. Login to the controller UI
2. Select Applications -> Add Application
3. Fill in the fields
	- **Name:** Port Forward Positive
	- **Type:** Container
	- **Version:** 1
	- **Vendor:** me
	- **Description:** testing
	- **Cores:** 1
	- **Memory:** 64
	- **Source:** *a suitable container (not in scope of this test)*
	- **Port:** 1234
	- **Protocol:** tcp

4. Go to *Nodes* -> (select 1 node) *EDIT* -> *APPS*
5. Click *DEPLOY APP* -> Select *Port Forward Positive* -> click *DEPLOY*
6. Wait around 30 seconds, click *DASHBOARD* then *APPS* again to refresh the view
7. Confirm the app state is now *deployed*
8. Copy the app *ID* from the first column into the clipboard
9. Login to the Edge Node via ssh
10. Execute `docker inspect APP_ID | grep -B 1 1234` (from the clipboard)
11. If you see the following string, then the test is successful:
>            "ExposedPorts": {  
>                "1234/tcp": {} 
