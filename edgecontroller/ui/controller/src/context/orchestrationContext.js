// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React from 'react';

export const orchestrationModes = {
  native: {
    name: 'native',
    path: '',
  },
  kubernetes_ovn: {
    name: 'kubernetes-ovn',
    path: '/kube_ovn',
  },
  kubernetes: {
    name: 'kubernetes',
    path: '',
  },
};
const defaultOrchestrationValue = {
  mode: orchestrationModes.native.name,
  apiClientPath: orchestrationModes.native.path,
};

export const initialOrchestrationValue = {
  mode: process.env.REACT_APP_ORCHESTRATION_MODE,
  apiClientPath:
    process.env.REACT_APP_ORCHESTRATION_MODE ===
    orchestrationModes.kubernetes_ovn.name
      ? orchestrationModes.kubernetes_ovn.path
      : orchestrationModes.native.path,
};

const orchestrationContext = React.createContext(defaultOrchestrationValue);

export default orchestrationContext;
