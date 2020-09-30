// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation
package k8s_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestK8S(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "K8S Suite")
}
