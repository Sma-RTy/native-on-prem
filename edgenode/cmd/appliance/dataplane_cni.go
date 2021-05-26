// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2020 Intel Corporation

// +build cni

package main

import (
	"github.com/Sma-RTy/native-on-prem/edgenode/pkg/ela"
	"github.com/Sma-RTy/native-on-prem/edgenode/pkg/eva"
	"github.com/Sma-RTy/native-on-prem/edgenode/pkg/service"
)

// EdgeServices array contains function pointers to services start functions
var EdgeServices = []service.StartFunction{eva.Run, ela.Run}
