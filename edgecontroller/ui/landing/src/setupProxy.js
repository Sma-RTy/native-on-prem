/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright (c) 2020 Intel Corporation
 */

const proxy = require('http-proxy-middleware');

module.exports = function (app) {
  console.log("PROXY " + process.env.REACT_APP_CONTROLLER_API);
  app.use(proxy('/api', { target: process.env.REACT_APP_CONTROLLER_API, pathRewrite: { '/api': '' } }));
};
