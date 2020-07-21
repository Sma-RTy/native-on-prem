#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2020 Intel Corporation

HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= exec ./nfd-master -dsn "root:$MYSQL_ROOT_PASSWORD@tcp(mysql:3306)/controller_ce"
