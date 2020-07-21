// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package k8s

// LifecycleStatus is a kubernetes deployment's status.
type LifecycleStatus string

const (
	// Unknown means status of the pod is currently unknown
	Unknown LifecycleStatus = "unknown"

	// Deployed means the deployment is created, but no pod is running
	Deployed LifecycleStatus = "deployed"

	// Pending means the deployment is created and pod is yet to be created
	Pending LifecycleStatus = "pending"

	// Starting means the pod is starting
	Starting LifecycleStatus = "starting"

	// Running means the pod is currently running
	Running LifecycleStatus = "running"

	// Terminating means the pod is being terminated
	Terminating LifecycleStatus = "terminating"

	// Error means error occurred
	Error LifecycleStatus = "error"
)
