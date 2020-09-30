// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

export default {
  schema: {
    type: "object",
    title: "DNS Config",
    required: [
      "name"
    ],
    properties: {
      name: {
        title: "Name",
        type: "string"
      },
      records: {
        type: "object",
        title: "Records",
        properties: {
          a: {
            type: "array",
            title: "A Records",
            items: {
              type: "object",
              title: "A Record",
              properties: {
                name: {
                  "title": "Name",
                  "type": "string"
                },
                description: {
                  "title": "Description",
                  "type": "string"
                },
                alias: {
                  "title": "Alias",
                  "type": "boolean"
                },
                values: {
                  "title": "Values",
                  type: "array",
                  items: {
                    "type": "string"
                  }
                }
              }
            }
          }
        }
      },
      // configurations: {
      //   type: "object",
      //   properties: {
      //     forwarders: {
      //       type: "array",
      //       items: {
      //         type: "object",
      //         properties: {
      //           name: {
      //             type: "string",
      //           },
      //           description: {
      //             type: "string",
      //           },
      //           value: {
      //             type: "string",
      //           },
      //         },
      //       },
      //     },
      //   },
      // },
    }
  },
  form: [
    "*"
  ]
};
