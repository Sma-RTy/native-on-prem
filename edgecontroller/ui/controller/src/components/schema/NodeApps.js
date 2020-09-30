// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

{/* 

GET /nodes/{node_id}/apps
Gets a list of applications on a node from the controller.

*/}

export default {
  schema: {
    type: "object",
    title: "Node Apps",
    properties: {
      apps: {
        type: "array",
        title: "Node Apps",
        items: {
          type: "object",
          title: "Node App",
          required: [
            "id"
          ],
          properties: {
            id: {
              title: "ID",
              type: "string",
              readOnly: true
            }
          }
        }
      }
    }
  },
  form: [
    "*"
  ]
};
