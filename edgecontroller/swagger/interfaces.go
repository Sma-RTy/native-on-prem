// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package swagger

// InterfaceSummary is a summary representation of the interface.
type InterfaceSummary struct {
	ID                string   `json:"id"`
	Description       string   `json:"description"`
	Driver            string   `json:"driver"`
	Type              string   `json:"type"`
	MACAddress        string   `json:"mac_address"`
	VLAN              int      `json:"vlan"`
	Zones             []string `json:"zones"`
	FallbackInterface string   `json:"fallback_interface"`
}

// InterfaceDetail is a detailed representation of the interface.
type InterfaceDetail struct {
	InterfaceSummary
}

// NodeAppList is a list representation of interfaces.
type InterfaceList struct {
	Interfaces []InterfaceSummary `json:"interfaces"`
}
