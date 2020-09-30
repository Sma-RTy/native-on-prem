// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package http

import (
	"net"
	"net/http"
)

// Server wraps http.Server.
type Server = http.Server

// NewServer creates a new Server.
func NewServer(handler http.Handler) *Server {
	return &Server{
		Handler: handler,
	}
}

// Serve wraps http.Serve.
func Serve(l net.Listener, handler http.Handler) error {
	return http.Serve(l, handler)
}
