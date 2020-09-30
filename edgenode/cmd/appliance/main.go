// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019-2020 Intel Corporation

package main

import (
	"flag"
	"github.com/open-ness/native-on-prem/edgenode/pkg/auth"
	"github.com/open-ness/native-on-prem/edgenode/pkg/service"
	"os"
	"time"
)

const enrollBackoff = time.Second * 10

func main() {
	flag.Parse()
	if err := service.InitConfig(); err != nil {
		service.Log.Errf("InitConfig failed %v\n", err)
		os.Exit(1)
	}
	for {
		if err := auth.Enroll(service.Cfg.Enroll.CertsDir, service.Cfg.Enroll.Endpoint,
			service.Cfg.Enroll.ConnTimeout.Duration, auth.EnrollClient{}); err != nil {
			service.Log.Errf("Enrollment failed %v\n", err)
			service.Log.Infof("Retrying enrollment in %s...", enrollBackoff)
			time.Sleep(enrollBackoff)
		} else {
			service.Log.Info("Successfully enrolled")
			break
		}
	}

	if !service.RunServices(EdgeServices) {
		os.Exit(1)
	}

	service.Log.Infof("Services stopped gracefully")
}
