// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package pki

import (
	"crypto/x509"
	"encoding/pem"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/pkg/errors"
)

// StoreCertificate persists a certificate chain to disk.
func StoreCertificate(path string, certs ...*x509.Certificate) error {
	if len(certs) == 0 {
		return nil
	}

	file, err := os.Create(path)
	if err != nil {
		return errors.Wrap(err, "unable to create file")
	}
	defer file.Close()

	for _, cert := range certs {
		if err = pem.Encode(
			file,
			&pem.Block{
				Type:  "CERTIFICATE",
				Bytes: cert.Raw,
			},
		); err != nil {
			return errors.Wrapf(err, "unable to store certificate at %s", path)
		}
	}

	if err = file.Chmod(0600); err != nil {
		return errors.Wrap(err, "unable to set certificate file permissions")
	}

	return nil
}

// LoadCertificate loads a certificate from disk.
func LoadCertificate(path string) (*x509.Certificate, error) {
	var (
		err   error
		bytes []byte
		block *pem.Block
	)

	if bytes, err = ioutil.ReadFile(filepath.Clean(path)); err != nil {
		return nil, errors.Wrap(err, "unable to read certificate file")
	}

	if block, _ = pem.Decode(bytes); block == nil {
		return nil, errors.New("unable to decode certificate")
	}

	return x509.ParseCertificate(block.Bytes)
}
