// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package telemetry_test

import (
	"crypto"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"math/big"
	"testing"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestTelemetry(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Telemetry Suite")
}

func newTLSConf(sni string) *tls.Config {
	tlsKey, err := ecdsa.GenerateKey(elliptic.P384(), rand.Reader)
	Expect(err).NotTo(HaveOccurred())
	tlsCert := generateRootCA(tlsKey, sni)
	tlsRoots := x509.NewCertPool()
	tlsRoots.AddCert(tlsCert)
	return &tls.Config{
		Certificates: []tls.Certificate{{
			Certificate: [][]byte{tlsCert.Raw},
			PrivateKey:  tlsKey,
			Leaf:        tlsCert,
		}},
		ClientCAs:    tlsRoots,
		RootCAs:      tlsRoots,
		MinVersion:   tls.VersionTLS12,
		CipherSuites: []uint16{tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256},
	}
}

// generateRootCA creates a root CA from the private key valid for 3 years.
func generateRootCA(key crypto.PrivateKey, sni string) *x509.Certificate {
	k, ok := key.(crypto.Signer)
	Expect(ok).To(BeTrue(), "Key should fulfill interface crypto.Signer")

	serial, err := rand.Int(rand.Reader, big.NewInt(100))
	Expect(err).NotTo(HaveOccurred())
	template := &x509.Certificate{
		SerialNumber: serial,
		Subject: pkix.Name{
			CommonName:   sni,
			Organization: []string{"Controller Authority"},
		},
		NotBefore:             time.Now().Add(-15 * time.Second),
		NotAfter:              time.Now().Add(3 * 365 * 24 * time.Hour),
		IsCA:                  true,
		KeyUsage:              x509.KeyUsageKeyEncipherment | x509.KeyUsageCertSign,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageAny},
		MaxPathLen:            0,
		MaxPathLenZero:        true,
		BasicConstraintsValid: true,
	}
	der, err := x509.CreateCertificate(rand.Reader, template, template, k.Public(), key)
	Expect(err).NotTo(HaveOccurred())
	cert, err := x509.ParseCertificate(der)
	Expect(err).NotTo(HaveOccurred())
	return cert
}
