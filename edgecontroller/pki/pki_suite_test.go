// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package pki_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestPki(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "PKI Suite")
}
