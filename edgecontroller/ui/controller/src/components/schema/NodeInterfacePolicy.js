// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

{/* 

GET /nodes/{node_id}/interfaces/{interface_id}/policy
Gets the traffic policy ID associated with a node network interface from the controller.

*/}

export default {
  schema: {
    type: "object",
    title: "Node Interface Policy",
    properties: {
      id: {
        title: "ID",
        type: "string",
        readonly: true
      }
    }
  },
  form: [
    "*"
  ]
};
