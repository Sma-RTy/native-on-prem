// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2020 Intel Corporation

package nfd

import (
	"fmt"
	"strings"
)

// NodeFeatureNFD is a representation of NFD feature on the node
type NodeFeatureNFD struct {
	ID       string `json:"id"`
	NodeID   string `json:"node_id"`
	NfdID    string `json:"nfd_id"`
	NfdValue string `json:"nfd_value"`
}

// GetTableName returns persistence table name for NodeFeatureNFD entities
func (*NodeFeatureNFD) GetTableName() string {
	return "nodes_nfd_features"
}

// GetID returns ID of NodeFeatureNFD entity
func (nf *NodeFeatureNFD) GetID() string {
	return nf.ID
}

// SetID sets ID for NodeFeatureNFD entity
func (nf *NodeFeatureNFD) SetID(id string) {
	nf.ID = id
}

// String reutrns string representation of NodeFeatureNFD entity
func (nf *NodeFeatureNFD) String() string {
	return fmt.Sprintf(strings.TrimSpace(`
NodeFeatureNFD[
	ID: %s
	NodeID: %s
	NfdID: %s
	NfdValue: %s
]`),
		nf.ID,
		nf.NodeID,
		nf.NfdID,
		nf.NfdValue)
}

// FilterFields returns the filterable fields of NodeFeatureNFD
func (nf *NodeFeatureNFD) FilterFields() []string {
	return []string{
		"id",
		"node_id",
		"nfd_id",
		"nfd_value",
	}
}
