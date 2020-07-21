// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

export default {
  schema: {
    type: "object",
    title: "Node Interface",
    properties: {
      id: {
        title: "ID",
        type: "string",
        readonly: true
      },
      description: {
        title: "Description",
        type: "string"
      },
      driver: {
        title: "Driver",
        type: "string",
        enum: [
          "kernel",
          "userspace"
        ]
      },
      type: {
        title: "Type",
        type: "string",
        enum: [
          "none",
          "upstream",
          "downstream",
          "bidirectional",
          "breakout"
        ]
      },
      mac_address: {
        title: "Mac Address",
        type: "string",
        readOnly: true
      },
      vlan: {
        title: "Vlan",
        type: "number",
        readOnly: true
      },
      zones: {
        title: "Zones",
        type: "array",
        items: {
          title: "Private Traffic",
          type: "string"
        }
      },
      fallback_interface: {
        title: "Fallback Interface",
        type: "string"
      }
    }
  },
  form: [
    "*"
  ]
};
