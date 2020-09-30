// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React, { Component } from 'react';
import ApiClient from "../../api/ApiClient";
import { withSnackbar } from 'notistack';
import TableCell from '@material-ui/core/TableCell';
import TableRow from '@material-ui/core/TableRow';
import { Button } from '@material-ui/core';
import CircularProgress from "@material-ui/core/CircularProgress";
import PolicyControls from "./PolicyControls";

class NodeApp extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loaded: false,
      appRemoved: false,
      error: null,
      open: false,
      nodeAppStatus: '',
      selectedAppID: '',
      openPolicyDialog: false,
    };
  }

  getNodeAppStatus = () => {
    const { nodeId, nodeApp } = this.props;

    ApiClient.get(`/nodes/${nodeId}/apps/${nodeApp.id}`)
      .then((resp) => {
        const status = resp.data.status;
        this.setState({
          nodeAppStatus: status
        })
      })
      .catch((err) => {
        this.setState({
          error: err,
        });

        this.props.enqueueSnackbar(`${err.toString()}. Please try again later.`, { variant: 'error' });
      });
  };

  // DELETE /nodes/:node_id/apps/:app_id
  deleteNodeApp = () => {
    const { nodeId, nodeApp } = this.props;

    ApiClient.delete(`/nodes/${nodeId}/apps/${nodeApp.id}`)
      .then((resp) => {
        this.setState({
          loaded: true,
          appRemoved: true,
        });

        this.props.enqueueSnackbar(`Application has been removed from edge node`, { variant: 'success' });
      })
      .catch((err) => {
        this.setState({
          loaded: true,
        });

        this.props.enqueueSnackbar(`${err.toString()}. Please try again later.`, { variant: 'error' });
      });
  };

  // PATCH /nodes/:node_id/apps/:app_id
  commandNodeApp = (command) => {
    const { nodeId, nodeApp } = this.props;

    ApiClient.patch(`/nodes/${nodeId}/apps/${nodeApp.id}`, {command})
      .then((resp) => {
        this.props.enqueueSnackbar(`Application ${command} was successful`, { variant: 'success' });
      })
      .catch((err) => {
        this.props.enqueueSnackbar(`${err.toString()}. Please try again later.`, { variant: 'error' });
      });
  };

  componentDidMount() {
    this.getNodeAppStatus();
  }

  renderNodeAppRow() {
    const {nodeApp, nodeId, policies} = this.props;
    const {nodeAppStatus} = this.state;
    return (
      <React.Fragment>
        <TableRow key={nodeApp.id} >
          <TableCell component="th" scope="row">
            {nodeApp.id}
          </TableCell>
          <TableCell align="right">
            {nodeAppStatus}
          </TableCell>
          <TableCell align="right">{nodeApp['type']}</TableCell>
          <TableCell align="right">{nodeApp['name']}</TableCell>
          <TableCell align="right">
            <PolicyControls nodeId={nodeId} resourceId={nodeApp.id} policyType="app" policies={policies}/>
          </TableCell>
          <TableCell align="right">
            <Button onClick={() => this.commandNodeApp( 'start')}>
              Start
            </Button>
            <Button onClick={() => this.commandNodeApp('stop')}>
              Stop
            </Button>
            <Button onClick={() => this.commandNodeApp( 'restart')}>
              Restart
            </Button>
          </TableCell>
          <TableCell align="right">
            <Button onClick={() => this.deleteNodeApp()}>
              Delete
            </Button>
          </TableCell>
        </TableRow>
      </React.Fragment>
    )
  }

  render() {
    const { nodeApp } = this.props;
    const { appRemoved, nodeAppStatus } = this.state;

    if(appRemoved) {
      return null;
    }

    return (!appRemoved && nodeAppStatus ? (
      this.renderNodeAppRow()
    ) : (
      <TableRow key={nodeApp.id}>
        <CircularProgress />
      </TableRow>
    ));
  }

}

export default withSnackbar(NodeApp);
