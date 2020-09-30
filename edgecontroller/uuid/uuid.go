// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package uuid

import "github.com/satori/go.uuid"

// New returns a new V4 UUID as a string.
func New() string {
	return uuid.NewV4().String()
}

// IsValid returns true if id is a valid V4 UUID.
func IsValid(id string) bool {
	return uuid.FromStringOrNil(id) != uuid.Nil
}
