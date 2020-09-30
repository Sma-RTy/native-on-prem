// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019-2020 Intel Corporation

module github.com/open-ness/native-on-prem/edgecontroller

go 1.14

require (
	github.com/go-sql-driver/mysql v1.5.0
	github.com/golang/protobuf v1.4.2
	github.com/gorilla/handlers v1.4.2
	github.com/gorilla/mux v1.7.4
	github.com/grpc-ecosystem/grpc-gateway v1.14.5
	github.com/joho/godotenv v1.3.0
	github.com/onsi/ginkgo v1.12.2
	github.com/onsi/gomega v1.10.1
	github.com/open-ness/native-on-prem/common v0.0.0-20200930153831-c5c3e82b5b38
	github.com/pkg/errors v0.8.1
	github.com/satori/go.uuid v1.2.0
	golang.org/x/sync v0.0.0-20200317015054-43a5402ce75a
	google.golang.org/genproto v0.0.0-20190927181202-20e1ac93f88c
	google.golang.org/grpc v1.30.0
	gopkg.in/square/go-jose.v2 v2.5.1
	k8s.io/api v0.0.0-20190515023547-db5a9d1c40eb
	k8s.io/apimachinery v0.0.0-20190515023456-b74e4c97951f
	k8s.io/client-go v0.0.0-20190501104856-ef81ee0960bf
	k8s.io/utils v0.0.0-20190520173318-324c5df7d3f0 // indirect
	sigs.k8s.io/node-feature-discovery v0.5.0
)
