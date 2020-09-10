```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/10: Tunable Exec](#itponp10-tunable-exec)
  - [ITP/ONP/10/01: Tunable Exec positive test](#itponp1001-tunable-exec-positive-test)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test steps](#test-steps)
  - [ITP/ONP/10/02: Tunable Exec negative test](#itponp1002-tunable-exec-negative-test)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test steps](#test-steps-1)
  
# ITP/ONP/10: Tunable Exec

## ITP/ONP/10/01: Tunable Exec positive test

### Test Summary
This test will validate if we can properly override the initial / startup / exec
command of a container when all of our setup and configuration is correct.

### Prerequisites
- Controller API, UI and database installed and up.
- Apache server serving container images setup properly and up.
- Image of a working docker container present on the container image server.

### Test steps
1. Login to the controller UI
2. Select Applications -> Add Application
3. Fill in the fields
	- **Name:** Tunexec Positive
	- **Type:** Container
	- **Version:** 1
	- **Vendor:** me
	- **Description:** testing
	- **Cores:** 1
	- **Memory:** 64
	- **Source:** *a suitable container (not in scope of this test)*
	- **EPA Feature Key:** cmd
	- **EPA Feature Value:** /bin/echo it's working!
4. Go to *Nodes* -> (select 1 node) *EDIT* -> *APPS*
5. Click *DEPLOY APP* -> Select *Tunexec Positive* -> click *DEPLOY*
6. Wait around 30 seconds, click *DASHBOARD* then *APPS* again to refresh the view
7. Confirm the app state is now *deployed*
8. Copy the app *ID* from the first column into the clipboard
9. Login to the Edge Node via ssh
10. Execute `docker logs APP_ID` (from the clipboard)
11. If you see the following string, then the test is successful:
> it's working!


## ITP/ONP/10/02: Tunable Exec negative test

### Test Summary
This test will confirm we will get an error when trying to run an invalid command.

### Prerequisites
- Controller API, UI and database installed and up.
- Apache server serving container images setup properly and up.
- Image of a working docker container present on the container image server.

### Test steps
1. Login to the controller UI
2. Select Applications -> Add Application
3. Fill in the fields
	- **Name:** Tunexec Negative
	- **Type:** Container
	- **Version:** 1
	- **Vendor:** me
	- **Description:** testing
	- **Cores:** 1
	- **Memory:** 64
	- **Source:** *a suitable container (not in scope of this test)*
	- **EPA Feature Key:** cmd
	- **EPA Feature Value:** it does not exist ;(
4. Go to *Nodes* -> (select 1 node) *EDIT* -> *APPS*
5. Click *DEPLOY APP* -> Select *Tunexec Negative* -> click *DEPLOY*
6. Wait around 30 seconds, click *DASHBOARD* then *APPS* again to refresh the view
7. Confirm the app state is now *deployed*
8. Copy the app *ID* from the first column into the clipboard
9. Login to the Edge Node via ssh
10. Execute `docker logs APP_ID` (from the clipboard)
11. You should see an error similar to the one below 
> /usr/local/bin/docker-entrypoint.sh: line 11: exec: : not found
