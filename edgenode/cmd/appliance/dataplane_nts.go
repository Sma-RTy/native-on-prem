// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2020 Intel Corporation

// +build nts

package main

import (
	"github.com/Sma-RTy/native-on-prem/edgenode/pkg/eda"
	"github.com/Sma-RTy/native-on-prem/edgenode/pkg/ela"
	"github.com/Sma-RTy/native-on-prem/edgenode/pkg/eva"
	"github.com/Sma-RTy/native-on-prem/edgenode/pkg/service"
)

// EdgeServices array contains function pointers to services start functions
var EdgeServices = []service.StartFunction{ela.Run, eva.Run, eda.Run}
