// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package cce

import (
	"time"
)

// MaxBodySize is the maximum size (in bytes) of an acceptable request body
const MaxBodySize = 64 * 1024

// MaxHTTPRequestTime is the maximum time to request HTTP data before timing out
const MaxHTTPRequestTime = 2 * time.Minute

// MaxDBRequestTime is the maximum time to request database data before timing out
const MaxDBRequestTime = 10 * time.Second

// MaxCores is the maximum number of cores that an application can use.
const MaxCores = 8

// MaxMemory is the maximum memory (in MB) that an application can use.
const MaxMemory = 16 * 1024

// MaxPort is the maximum port allowed in the TCP/IP stack
const MaxPort = 65535

// LifecycleStatus is an application's status.
type LifecycleStatus int

const (
	// Unknown is an unknown lifecycle status
	Unknown LifecycleStatus = iota
	// Deploying is deploying to a node
	Deploying
	// Deployed is deployed to a node
	Deployed
	// Starting is starting
	Starting
	// Running is running
	Running
	// Stopping is stopping
	Stopping
	// Stopped is stopped
	Stopped
	// Error is an error status
	Error
)

func (s LifecycleStatus) String() string {
	switch s {
	case Deploying:
		return "deploying"
	case Deployed:
		return "deployed"
	case Starting:
		return "starting"
	case Running:
		return "running"
	case Stopping:
		return "stopping"
	case Stopped:
		return "stopped"
	case Error:
		return "error"
	case Unknown:
		fallthrough
	default:
		return "unknown"
	}
}
