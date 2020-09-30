// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package swagger

// NodeAppSummary is a summary representation of the node app.
type NodeAppSummary struct {
	ID string `json:"id"`
}

// NodeAppDetail is a detailed representation of the node app.
type NodeAppDetail struct {
	NodeAppSummary
	Status  string `json:"status"`
	Command string `json:"command"`
}

// NodeAppList is a list representation of node apps.
type NodeAppList struct {
	NodeApps []NodeAppSummary `json:"apps"`
}
