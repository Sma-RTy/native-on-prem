// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package cce

import (
	"crypto/md5" //nolint:gosec
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"errors"
	"fmt"
	"strings"
)

// Credentials defines a response for a request to obtain authentication
// credentials. These credentials may be used to further communicate with
// endpoint(s) that are protected by a form of authentication.
type Credentials struct {
	// ID is the base64-encoded MD5 hash of the certificate's public key.
	ID string `json:"id"`
	// Certificate is a PEM-encoded X.509 certificate.
	Certificate string `json:"certificate"`
}

// GetTableName returns the name of the table this entity is saved in.
func (c *Credentials) GetTableName() string {
	return "credentials"
}

// GetID gets the ID.
func (c *Credentials) GetID() string {
	return c.ID
}

// SetID sets the ID.
func (c *Credentials) SetID(id string) {
	c.ID = id
}

// Validate validates the model.
func (c *Credentials) Validate() error {
	if c.ID == "" {
		return errors.New("id cannot be empty")
	}
	if c.Certificate == "" {
		return errors.New("certificate cannot be empty")
	}

	block, _ := pem.Decode([]byte(c.Certificate))
	if block == nil {
		return errors.New("certificate not PEM-encoded")
	}

	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return errors.New("certificate not a valid certificate")
	}

	pubKey, err := x509.MarshalPKIXPublicKey(cert.PublicKey)
	if err != nil {
		return errors.New("certificate public key not a valid public key")
	}

	// gosec: not hashing user input/passwords
	hash := md5.Sum(pubKey) //nolint:gosec

	if c.ID != base64.RawURLEncoding.EncodeToString(hash[:]) {
		return errors.New("id not derived from certificate public key")
	}

	return nil
}

func (c *Credentials) String() string {
	return fmt.Sprintf(strings.TrimSpace(`
Credentials[
    ID: %s
    Certificate: %s
]`),
		c.ID,
		c.Certificate,
	)
}
