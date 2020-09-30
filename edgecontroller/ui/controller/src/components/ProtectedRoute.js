// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React from 'react';
import { Route, Redirect, withRouter } from 'react-router-dom';
import Auth from './Auth';

const ProtectedRoute = ({ component: Component, ...rest }) => {
  return (
    <Route
      {...rest}
      render={(props) => {
        if (Auth.isAuthenticated()) {
          return <Component {...props} />;
        } else {
          return (
            <Redirect
              to={{
                pathname: '/login',
                state: {
                  from: props.location,
                },
              }}
            />
          );
        }
      }}
    />
  );
};

export default withRouter(ProtectedRoute);
