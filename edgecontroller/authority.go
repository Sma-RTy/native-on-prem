// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package cce

import "crypto/x509"

// AuthorityService manages digital certificates.
type AuthorityService interface {
	// CAChain returns the certificate authority chain, starting with the
	// issuing CA and ending with the root CA (inclusive).
	CAChain() ([]*x509.Certificate, error)
	// SignCSR signs a ASN.1 DER encoded certificate signing request.
	SignCSR(der []byte, template *x509.Certificate) (*x509.Certificate, error)
}
