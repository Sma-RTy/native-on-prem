```text
SPDX-License-Identifier: Apache-2.0
Copyright © 2020 Intel Corporation
```
- [ITP/ONP/08: Environment Variables](#itponp08-environment-variables)
  - [ITP/ONP/08/01: Environment Variables positive test](#itponp0801-environment-variables-positive-test)
    - [Test Summary](#test-summary)
    - [Prerequisites](#prerequisites)
    - [Test Steps](#test-steps)
  - [ITP/ONP/08/02: Environment Variables Single Variable Incorrectly Set](#itponp0802-environment-variables-single-variable-incorrectly-set)
    - [Test Summary](#test-summary-1)
    - [Prerequisites](#prerequisites-1)
    - [Test Steps](#test-steps-1)
  - [ITP/ONP/08/03: Environment Variables Missing Separation between Variables Test](#itponp0803-environment-variables-missing-separation-between-variables-test)
    - [Test Summary](#test-summary-2)
    - [Prerequisites](#prerequisites-2)
    - [Test Steps](#test-steps-2)

# ITP/ONP/08: Environment Variables

Test suite original definition: https://openness.atlassian.net/wiki/spaces/INTEL/pages/119537669/ITP+2020+03+ONP+4+EAC+tests

## ITP/ONP/08/01: Environment Variables positive test

### Test Summary

This test will ensure that the environment variables are present in the container if they are requested through the controller UI

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains images of a container with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_Env_Vars_set
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app with environment variables provided
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable container (not in scope of this test)*
      - Skip port settings
      - EPA Features:
        - **EPA Feature Key:** env_vars
        - **EPA Feature Value:** TestVar1=test;TestVar2=sample
      - Click *Upload Application*
    - Go to *Nodes* and select *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_Env_Vars_set from the dropdown menu and click *DEPLOY*
    - Click *Start* to start the container on the node
2. Log onto the node:
    - `docker exec -it CONTAINER_NAME env`
    - `TestVar1=test` and `TestVar2=sample` should be present

## ITP/ONP/08/02: Environment Variables Single Variable Incorrectly Set

### Test Summary

This test will ensure that an environment variable which has not been provided in the expected format by EAC will not be set in the container when it is deployed.

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains images of a container with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_Env_Vars_Single_Incorrect_Var
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app with environment variables provided but one missing an equals sign
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable container (not in scope of this test)*
      - Skip port settings
      - EPA Features:
        - **EPA Feature Key:** env_vars
        - **EPA Feature Value:** TestVar1test;TestVar2=sample
      - Click *Upload Application*
    - Go to *Nodes* and select *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_Env_Vars_Single_Incorrect_Var from the dropdown menu and click *DEPLOY*
2. Log onto the node:
    - `docker exec -it CONTAINER_NAME env`
    - Only `TestVar2=sample` should be present

## ITP/ONP/08/03: Environment Variables Missing Separation between Variables Test

### Test Summary

This test will ensure that the environment variables are not present in the container if the semi-colon is missing between two variables from the provided string in the controller UI

### Prerequisites

- Controller API, UI and database installed and up.
- Apache server has been set up with the ansible scripts and contains images of a container with a working shell.

### Test Steps

1. Go to *Applications* and click *Add Application*
    - Add the following input:
      - **Name:** EAC_App_Env_Vars_Missing_Separation
      - **Type:** container
      - **Version:** 77
      - **Vendor:** Intel
      - **Description:** An app with environment variables provided but with a missing semi-colon between the entries
      - **Cores:** 7
      - **Memory:** 1234
      - **Source:** *a suitable container (not in scope of this test)*
      - Skip port settings
      - EPA Features:
        - **EPA Feature Key:** env_vars
        - **EPA Feature Value:** TestVar1=testTestVar2=sample
      - Click *Upload Application*
    - Go to *Nodes* and select *EDIT* on the node that the application will be deployed on
    - Select *Apps*, click *DEPLOY APP*, select EAC_App_Env_Vars_Missing_Separation from the dropdown menu and click *DEPLOY*
2. Log onto the node:
    - `docker exec -it CONTAINER_NAME env`
    - Neither variable should be present
