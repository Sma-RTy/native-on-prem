```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```

- [ITP/ONP/04: Enhanced Application Configuration (EAC)](#itponp04-enhanced-application-configuration-eac)
  - [ITP/ONP/04/01: Test generic EAC data save/load functionality](#itponp0401-test-generic-eac-data-saveload-functionality)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test Steps](#test-steps)
  - [ITP/ONP/04/02: HDDL positive test](#itponp0402-hddl-positive-test)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test Steps](#test-steps-1)
  - [ITP/ONP/04/03: HDDL negative test](#itponp0403-hddl-negative-test)
    - [Test Summary](#test-summary-2)
    - [Prerequisites](#prerequisites-2)
    - [Test Steps](#test-steps-2)

# ITP/ONP/04: Enhanced Application Configuration (EAC)

Test suite original definition: https://openness.atlassian.net/wiki/spaces/INTEL/pages/50954341/ITP+2019+12+ONP+4+EAC+tests

## ITP/ONP/04/01: Test generic EAC data save/load functionality

### Test Summary

Test if the database interface is properly saving the EAC data.

### Prerequisites

- Controller API, UI and database installed and up.

### Test Steps

1. Open the Controller UI
    - Go to *Applications* and click *Add Application*
    - Input:
      - **Name:** EAC_App
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** My first EAC App
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** https://eac
      - Skip port settings
      - EPA Feature
        - **EPA Feature Key:** Test key
        - **EPA Feature Value:** Test value
    - Click *Upload Application*
2. Load the Application and check
    - Go to *Applications*
    - Select *EDIT* under the EAC_App entry
    - Make sure the EPA Feature section contains:
      - **EPA Feature Key:** Test key
      - **EPA Feature Value:** Test value
    - If it’s empty or contains other data, consider this test failed

## ITP/ONP/04/02: HDDL positive test

### Test Summary

This test will make sure that the HDDL device file is present in the container if the HDDL functionality is requested through the UI.

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains images of a container with a working shell.

### Test Steps

1. Open the Controller UI
    - Go to *Applications* and click *Add Application*
    - input:
      - **Name:** EAC_App_HDDL_on
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app with HDDL enabled
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable container (not in scope of this test)*
      - Skip port settings
      - EPA Feature
        - **EPA Feature Key:** hddl
        - **EPA Feature Value:** true
    - Click *Upload Application*
2. Deploy this application to the Appliance
    - Open the Controller UI
    - Go to *Nodes* and click *EDIT* for the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select the EAC_App_HDDL_on from the dropdown menu and click *DEPLOY*
3. Log onto the node
    - Run `docker inspect CONTAINER_NAME`
    - **/var/tmp** and **/var/shm** should be present in Binds and Mounts sections

## ITP/ONP/04/03: HDDL negative test

### Test Summary

This test will verify the the HDDL device file is absent in the container if the HDDL functionality was set to off in the UI.

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains images of a container with a working shell.

### Test Steps

1. Open the Controller UI
    - Go to *Applications* and click *Add Application*
    - input:
      - **Name:** EAC_App_HDDL_off
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app with HDDL disabled
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable container (not in scope of this test)*
      - Skip port settings
      - EPA Feature
        - **EPA Feature Key:** hddl
        - **EPA Feature Value:** false
      - Click *Upload Application*
2. Deploy this application to the Appliance
    - Open the Controller UI
    - Go to *Nodes* and click *EDIT* for the node that the application will be deployed on
    - Select *Apps*, click on *DEPLOY APP*, select the EAC_APP_HDDL_off from the dropdown menu and click *DEPLOY*
3. Log onto the node
    - Run `docker inspect CONTAINER_NAME`
    - **/var/tmp** and **/var/shm** should be absent in Binds and Mounts sections
