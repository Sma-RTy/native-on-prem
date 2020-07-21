// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package pki

import (
	"bytes"
	"crypto"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"math/big"
	rdm "math/rand"
	"os"
	"path/filepath"
	"time"

	"github.com/pkg/errors"
)

// RootCA manages digital certificates.
type RootCA struct {
	Cert *x509.Certificate
	Key  crypto.PrivateKey
}

// InitRootCA creates a RootCA by loading the CA certificate and key from the
// certificates directory. If they do not exist or the certificate was not
// signed with the key, a new certificate and key will generated.
func InitRootCA(certsDir string) (*RootCA, error) {
	var (
		err error

		keyFile string
		key     crypto.PrivateKey

		certFile string
		cert     *x509.Certificate
		certDER  []byte
	)

	if err = os.MkdirAll(certsDir, 0700); err != nil {
		return nil, errors.Wrap(err, "unable to create CA directory")
	}

	keyFile = filepath.Join(certsDir, "key.pem")

	if key, err = LoadKey(keyFile); err != nil {
		if key, err = ecdsa.GenerateKey(elliptic.P384(), rand.Reader); err != nil {
			return nil, errors.Wrap(err, "unable to generate CA key")
		}

		if err = StoreKey(key, keyFile); err != nil {
			return nil, errors.Wrap(err, "unable to store CA key")
		}

		log.Debugf("Generated and stored CA key at: %s", keyFile)
	}

	certFile = filepath.Join(certsDir, "cert.pem")

	if cert, err = LoadCertificate(certFile); err != nil {
		if cert, err = generateRootCA(key); err != nil {
			return nil, errors.Wrap(err, "unable to generate root CA")
		}

		if err = StoreCertificate(certFile, cert); err != nil {
			return nil, errors.Wrap(err, "unable to store CA certificate")
		}

		log.Debugf("Generated and stored CA certificate at: %s", certFile)
	}

	if certDER, err = x509.MarshalPKIXPublicKey(key.(crypto.Signer).Public()); err != nil {
		return nil, errors.Wrap(err, "unable to marshal public key")
	}

	// Verify the certificate was signed with the private key
	if !bytes.Equal(cert.RawSubjectPublicKeyInfo, certDER) {
		if err = os.Remove(certFile); err != nil {
			return nil, errors.Wrap(err, "unable to remove invalid cert")
		}

		return InitRootCA(certsDir)
	}

	return &RootCA{
		Cert: cert,
		Key:  key,
	}, nil
}

// CAChain returns the root CA certificate wrapped in a slice to satisfy the
// interface. Since the root CA is the issuing CA and there are no intermediate
// CAs, we only need to return the root CA certificate.
func (ca *RootCA) CAChain() ([]*x509.Certificate, error) {
	return []*x509.Certificate{ca.Cert}, nil
}

// SignCSR signs a ASN.1 DER encoded certificate signing request.
func (ca *RootCA) SignCSR(der []byte, template *x509.Certificate) (*x509.Certificate, error) {
	csr, err := x509.ParseCertificateRequest(der)
	if err != nil {
		return nil, errors.Wrap(err, "unable to parse CSR")
	}

	// Pick random serial number
	source := rdm.NewSource(time.Now().UnixNano())
	serial := big.NewInt(int64(rdm.New(source).Uint64()))

	// Sign certificate request
	tmpl := &x509.Certificate{
		SerialNumber: serial,
		Subject:      template.Subject,
		NotBefore:    time.Now(),
		NotAfter:     ca.Cert.NotAfter, // Valid until CA expires
	}
	certDER, err := x509.CreateCertificate(
		rand.Reader,
		tmpl,
		ca.Cert,
		csr.PublicKey,
		ca.Key,
	)
	if err != nil {
		return nil, errors.Wrap(err, "unable to sign certificate")
	}

	return x509.ParseCertificate(certDER)
}

// NewTLSClientCert creates a new TLS client certificate with a given SNI.
func (ca *RootCA) NewTLSClientCert(key crypto.PrivateKey, sni string) (*x509.Certificate, error) {
	return ca.newTLSCert(key, sni, x509.ExtKeyUsageClientAuth)
}

// NewTLSServerCert creates a new TLS server certificate with a given SNI.
func (ca *RootCA) NewTLSServerCert(key crypto.PrivateKey, sni string) (*x509.Certificate, error) {
	return ca.newTLSCert(key, sni, x509.ExtKeyUsageServerAuth)
}

func (ca *RootCA) newTLSCert(
	key crypto.PrivateKey,
	sni string,
	extKeyUsage ...x509.ExtKeyUsage,
) (*x509.Certificate, error) {
	pkey, ok := key.(crypto.Signer)
	if !ok {
		return nil, errors.Errorf("invalid private key type: %T", key)
	}

	// Pick random serial number
	source := rdm.NewSource(time.Now().UnixNano())
	serial := big.NewInt(int64(rdm.New(source).Uint64()))

	// Generate certificate
	template := &x509.Certificate{
		SerialNumber: serial,
		Subject:      pkix.Name{CommonName: sni},
		KeyUsage:     x509.KeyUsageDigitalSignature,
		ExtKeyUsage:  extKeyUsage,
		NotBefore:    time.Now(),
		NotAfter:     ca.Cert.NotAfter, // Valid until CA expires
	}
	certDER, err := x509.CreateCertificate(
		rand.Reader,
		template,
		ca.Cert,
		pkey.Public(),
		ca.Key,
	)
	if err != nil {
		return nil, errors.Wrap(err, "unable to sign certificate")
	}

	return x509.ParseCertificate(certDER)
}

// generateRootCA creates a root CA from the private key valid for 3 years.
func generateRootCA(key crypto.PrivateKey) (*x509.Certificate, error) {
	var (
		err      error
		k        crypto.Signer
		ok       bool
		source   rdm.Source
		serial   *big.Int
		template *x509.Certificate
		der      []byte
	)

	if k, ok = key.(crypto.Signer); !ok {
		return nil, errors.Wrap(err, "unable to parse key")
	}

	source = rdm.NewSource(time.Now().UnixNano())

	serial = big.NewInt(int64(rdm.New(source).Uint64()))

	template = &x509.Certificate{
		SerialNumber: serial,
		Subject: pkix.Name{
			Organization: []string{"Controller Authority"},
		},
		NotBefore:             time.Now().Add(-15 * time.Second),
		NotAfter:              time.Now().Add(3 * 365 * 24 * time.Hour),
		IsCA:                  true,
		KeyUsage:              x509.KeyUsageCertSign,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageAny},
		MaxPathLen:            0,
		MaxPathLenZero:        true,
		BasicConstraintsValid: true,
	}

	if der, err = x509.CreateCertificate(rand.Reader, template, template, k.Public(), key); err != nil {
		return nil, errors.Wrap(err, "unable to create CA certificate")
	}

	return x509.ParseCertificate(der)
}
