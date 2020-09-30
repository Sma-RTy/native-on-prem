// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019-2020 Intel Corporation

module github.com/open-ness/native-on-prem/edgenode

go 1.14

require (
	github.com/blang/semver v3.5.1+incompatible // indirect
	github.com/containernetworking/cni v0.8.0
	github.com/containernetworking/plugins v0.8.6
	github.com/digitalocean/go-openvswitch v0.0.0-20191122155805-8ce3b4218729
	github.com/docker/distribution v2.7.1+incompatible // indirect
	github.com/docker/docker v1.13.1
	github.com/docker/go-connections v0.4.0
	github.com/docker/go-units v0.3.3 // indirect
	github.com/fsnotify/fsnotify v1.4.9 // indirect
	github.com/gogo/protobuf v1.2.1 // indirect
	github.com/golang/protobuf v1.4.2
	github.com/google/go-cmp v0.4.0 // indirect
	github.com/gopherjs/gopherjs v0.0.0-20200217142428-fce0ec30dd00 // indirect
	github.com/gorilla/mux v1.7.0
	github.com/gorilla/websocket v1.4.0
	github.com/grpc-ecosystem/grpc-gateway v1.9.0
	github.com/kata-containers/runtime v0.0.0-20190505030513-a7e2bbd31c56
	github.com/kr/text v0.2.0 // indirect
	github.com/libvirt/libvirt-go v5.1.0+incompatible
	github.com/libvirt/libvirt-go-xml v5.1.0+incompatible
	github.com/miekg/dns v1.1.8
	github.com/niemeyer/pretty v0.0.0-20200227124842-a10e7caefd8e // indirect
	github.com/onsi/ginkgo v1.12.0
	github.com/onsi/gomega v1.9.0
	github.com/opencontainers/go-digest v1.0.0-rc1 // indirect
	github.com/opencontainers/image-spec v1.0.1 // indirect
	github.com/open-ness/native-on-prem/common v0.0.0-20200930153831-c5c3e82b5b38
	github.com/pkg/errors v0.8.1
	github.com/sirupsen/logrus v1.6.0 // indirect
	github.com/smartystreets/assertions v1.1.0 // indirect
	github.com/smartystreets/goconvey v1.6.4 // indirect
	github.com/vishvananda/netlink v1.1.0
	go.etcd.io/bbolt v1.3.5
	google.golang.org/genproto v0.0.0-20200722002428-88e341933a54
	google.golang.org/grpc v1.30.0
	gopkg.in/ini.v1 v1.42.0
)

replace github.com/docker/docker => github.com/docker/engine v0.0.0-20190423201726-d2cfbce3f3b0
