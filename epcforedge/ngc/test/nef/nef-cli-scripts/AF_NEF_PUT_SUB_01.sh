#! /bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2019 Intel Corporation


setup_dir=${PWD}
echo "$setup_dir"

set -e

curl -X PUT -i "Content-Type: application/json" --data @./json/AF_NEF_PUT_01.json http://localhost:8091/3gpp-traffic-influence/v1/AF_01/subscriptions/11113

exit 0

