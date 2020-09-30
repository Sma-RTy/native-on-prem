// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package cce_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestApplicationClient(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Controller CE Suite")
}
