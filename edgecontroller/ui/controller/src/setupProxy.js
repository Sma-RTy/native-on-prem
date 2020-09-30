// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

const proxy = require('http-proxy-middleware');

module.exports = function(app) {
  app.use(proxy('/api',
    {
      target: process.env.REACT_APP_CONTROLLER_API,
      pathRewrite: {'^/api' : ''}
    })
  );
};
