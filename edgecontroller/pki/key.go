// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package pki

import (
	"crypto"
	"crypto/x509"
	"encoding/pem"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/pkg/errors"
)

// StoreKey persists a private key on disk at the path.
func StoreKey(key crypto.PrivateKey, path string) error {
	var (
		err  error
		der  []byte
		file *os.File
	)

	if der, err = x509.MarshalPKCS8PrivateKey(key); err != nil {
		return errors.Wrap(err, "unable to marshal EC private key to DER")
	}

	if file, err = os.Create(path); err != nil {
		return errors.Wrap(err, "unable to create private key file")
	}
	defer file.Close()

	if err = file.Chmod(0600); err != nil {
		return errors.Wrap(err, "unable to set private key file permissions")
	}

	if err = pem.Encode(
		file,
		&pem.Block{
			Type:  "PRIVATE KEY",
			Bytes: der,
		},
	); err != nil {
		return errors.Wrap(err, "unable to store private key")
	}

	return nil
}

// LoadKey loads a private key from disk at path.
func LoadKey(path string) (crypto.PrivateKey, error) {
	var (
		err   error
		bytes []byte
		block *pem.Block
	)

	if bytes, err = ioutil.ReadFile(filepath.Clean(path)); err != nil {
		return nil, errors.Wrap(err, "unable to read key file")
	}

	if block, _ = pem.Decode(bytes); block == nil {
		return nil, errors.New("unable to decode key")
	}

	return x509.ParsePKCS8PrivateKey(block.Bytes)
}
