// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

{/* 

GET /apps
List of applications.

*/}

export default {
  schema: {
    type: "object",
    title: "Node Apps",
    properties: {
      apps: {
        type: "array",
        title: "Apps",
        items: {
          type: "object",
          title: "App",
          required: [
            "type",
            "name",
            "version",
            "vendor"
          ],
          properties: {
            id: {
              type: "string",
              title: "ID",
              readonly: true
            },
            type: {
              type: "string",
              title: "Type",
              enum: [
                "container",
                "vm"
              ]
            },
            name: {
              type: "string",
              title: "Name"
            },
            version: {
              type: "string",
              title: "Version"
            },
            vendor: {
              type: "string",
              title: "Vendor"
            },
            description: {
              type: "string",
              title: "Description"
            }
          }
        }
      }
    },
  },
  form: [
    "*"
  ]
};
