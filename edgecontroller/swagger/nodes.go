// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package swagger

// NodeSummary is a summary representation of the node.
type NodeSummary struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Location string `json:"location"`
	Serial   string `json:"serial"`
}

// NodeDetail is a detailed representation of the node.
type NodeDetail struct {
	NodeSummary
}

// NodeList is a list representation of nodes.
type NodeList struct {
	Nodes []NodeSummary `json:"nodes"`
}
