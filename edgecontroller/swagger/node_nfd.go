// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2020 Intel Corporation

package swagger

// NodeNfdSummary is a representation of the node nfd tag.
type NodeNfdTag struct {
	ID    string `json:"id"`
	Value string `json:"value"`
}

// NodeNfdList is a list of all nfd tags for a given node.
type NodeNfdList struct {
	List []NodeNfdTag `json:"nodenfds"`
}
