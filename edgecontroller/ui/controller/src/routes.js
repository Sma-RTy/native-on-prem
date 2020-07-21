// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019-2020 Intel Corporation

import React from 'react'
import { Switch, Route, Redirect } from 'react-router-dom'
import NodesView from './views/NodesListing'
import NodeView from './views/Node'
import AppsView from './views/AppsListing'
import AppView from './views/AppView'
import LoginForm from './components/Login'

// import Dns from './views/dns/Main'
// import DnsEdit from './views/dns/Edit'

import Policies from './views/policies/Main'
import PoliciesEdit from './views/policies/Edit'

import ProtectedRoute from './components/ProtectedRoute'
import Auth from './components/Auth'

export default props => (
  <div>
    <Switch>
      <Route
        exact
        path='/'
        render={() => (
          Auth.isAuthenticated()
          ? <Redirect to="/nodes" />
          : <Redirect to="/login" />
        )}
      />

      <Route exact path='/login' component={LoginForm} />

      <ProtectedRoute exact path='/nodes' component={NodesView} />
      <ProtectedRoute path='/nodes/:id' component={NodeView} />

      <ProtectedRoute exact path='/apps' component={AppsView} />
      <ProtectedRoute path='/apps/:id' component={AppView} />

      <ProtectedRoute exact path='/policies' component={Policies} />
      <ProtectedRoute exact path='/policies/add' component={PoliciesEdit} />
      <ProtectedRoute path='/policies/:id/edit' component={PoliciesEdit} />

      <Route render={() => <div>404 Not Found</div>} />
    </Switch>
  </div>
)
