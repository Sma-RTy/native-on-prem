// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package cce

import (
	"fmt"
	"strings"
)

// NodeGRPCTarget is a node's GRPC target.
type NodeGRPCTarget struct {
	ID         string `json:"id"`
	NodeID     string `json:"node_id"`
	GRPCTarget string `json:"grpc_target"`
}

// GetTableName returns the name of the persistence table.
func (*NodeGRPCTarget) GetTableName() string {
	return "node_grpc_targets"
}

// GetID gets the ID.
func (t *NodeGRPCTarget) GetID() string {
	return t.ID
}

// SetID sets the ID.
func (t *NodeGRPCTarget) SetID(id string) {
	t.ID = id
}

// GetNodeID gets the node ID.
func (t *NodeGRPCTarget) GetNodeID() string {
	return t.NodeID
}

// FilterFields returns the filterable fields for this model.
func (t *NodeGRPCTarget) FilterFields() []string {
	return []string{
		"node_id",
	}
}

func (t *NodeGRPCTarget) String() string {
	return fmt.Sprintf(strings.TrimSpace(`
NodeGRPCTarget[
    ID: %s
    NodeID: %s
    GRPCTarget: %s
]`),
		t.ID,
		t.NodeID,
		t.GRPCTarget)
}
