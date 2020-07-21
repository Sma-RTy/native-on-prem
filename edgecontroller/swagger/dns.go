// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package swagger

// DNSSummary is a summary representation of DNS settings.
type DNSSummary struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// DNSDetail is a detailed representation of DNS settings.
type DNSDetail struct {
	DNSSummary
	Records        DNSRecords        `json:"records"`
	Configurations DNSConfigurations `json:"configurations"`
}

// DNSList is a list representation of DNS settings.
type DNSList struct {
	DNS []DNSSummary `json:"dns"`
}

// DNSRecords is a set of DNS records.
type DNSRecords struct {
	A []DNSARecord `json:"a"`
}

// DNSConfigurations is a set of DNS configurations.
type DNSConfigurations struct {
	Forwarders []DNSForwarder `json:"forwarders"`
}

// DNSARecord is a DNS A record entry.
type DNSARecord struct {
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Alias       bool     `json:"alias"`
	Values      []string `json:"values"`
}

// DNSFowarder is a DNS forwarder configuration entry.
type DNSForwarder struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Value       string `json:"value"`
}
