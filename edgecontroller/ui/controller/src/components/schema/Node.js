// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

export default {
  schema: {
    type: "object",
    title: "Node",
    required: [
      "name",
      "serial",
      "location",
    ],
    properties: {
      id: {
        type: "string",
        title: "ID",
        readonly: true
      },
      name: {
        type: "string",
        title: "Name"
      },
      location: {
        type: "string",
        title: "Location"
      },
      serial: {
        type: "string",
        title: "Serial"
      }
    },
  },
  form: [
    "*"
  ]
};
