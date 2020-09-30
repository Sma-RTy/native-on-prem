// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

package kubeovn_test

import (
	"fmt"
	"io"
	"net/http"
)

// apiClient is a Controller API client that automatically injects an auth token
// into the request headers of each HTTP request in the OAuth 2.0 Bearer Token
// standard format (https://tools.ietf.org/html/rfc6750).
type apiClient struct {
	// Token is a JSON Web Token.
	Token string
}

// Get sends a HTTP GET request with a token and returns an HTTP response.
func (cli apiClient) Get(url string) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}

	return new(http.Client).Do(cli.injectToken(req))
}

// Post sends a HTTP POST request with a token and returns an HTTP response.
func (cli apiClient) Post(url string, contentType string, body io.Reader) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodPost, url, body)
	if err != nil {
		return nil, err
	}

	return new(http.Client).Do(cli.injectToken(req))
}

// Patch sends a HTTP PATCH request with a token and returns an HTTP response.
func (cli apiClient) Patch(url string, contentType string, body io.Reader) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodPatch, url, body)
	if err != nil {
		return nil, err
	}

	return new(http.Client).Do(cli.injectToken(req))
}

// Delete sends a HTTP DELETE request with a token and returns an HTTP response.
func (cli apiClient) Delete(url string) (*http.Response, error) {
	req, err := http.NewRequest(http.MethodDelete, url, nil)
	if err != nil {
		return nil, err
	}

	return new(http.Client).Do(cli.injectToken(req))
}

func (cli apiClient) injectToken(r *http.Request) *http.Request {
	r.Header.Add("Authorization", fmt.Sprintf("Bearer %s", cli.Token))
	return r
}
