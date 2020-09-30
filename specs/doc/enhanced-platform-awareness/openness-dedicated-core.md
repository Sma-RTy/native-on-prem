```text
SPDX-License-Identifier: Apache-2.0
Copyright (c) 2019-2020 Intel Corporation
```
<!-- omit in toc -->
# Dedicated CPU core for workload support in OpenNESS
- [Overview](#overview)
  - [OnPremises Usage](#onpremises-usage)

## Overview

Multi-core COTS platforms are typical in any cloud or Cloudnative deployment. Parallel processing on multiple cores helps achieve better density. On a Multi-core platform, one challenge for applications and network functions that are latency and throughput density is deterministic compute. To achieve deterministic compute allocating dedicated resources is important. Dedicated resource allocation avoids interference with other applications (Noisy Neighbor). When deploying on a cloud native platform, applications are deployed as containers, therefore, providing required information to the container orchestrator on dedicated CPU cores is key.

Below are the typical usage of this feature.

- Let's consider an edge application that is using an AI library like OpenVINO for inference. This library will use a special instruction set on the CPU to get higher performance of the AI algorithm. To achieve a deterministic inference rate, the application thread executing the algorithm needs a dedicated CPU core so that there is no interference from other threads or other application pods (Noisy Neighbor).

### OnPremises Usage

Dedicated core pinning is also supported for container and virtual machine deployment in OnPremises mode. This is done using the EPA Features section provided when creating applications for onboarding. For more details on application creation and onboarding in OnPremises mode, please see the [Application Onboarding Document](https://github.com/open-ness/native-on-prem/blob/master/specs/doc/applications-onboard/on-premises-applications-onboarding.md).

To set dedicated core pinning for an application, *EPA Feature Key* should be set to `cpu_pin` and *EPA Feature Value* should be set to one of the following options:

1. A single core e.g. `EPA Feature Value = 3` if pinning to core 3 only.
2. A sequential series of cores, e.g. `EPA Feature Value = 2-7` if pinning to cores 2 to 7 inclusive.
3. A comma separated list of cores, e.g. `EPA Feature Value = 1,3,6,7,9` if pinning to cores 1,3,6,7 and 9 only.
