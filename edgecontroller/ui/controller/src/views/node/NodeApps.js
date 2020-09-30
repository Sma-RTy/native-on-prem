// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React, { Component } from 'react';
import ApiClient from '../../api/ApiClient';
import { withSnackbar } from 'notistack';
import Table from '@material-ui/core/Table';
import TableBody from '@material-ui/core/TableBody';
import TableCell from '@material-ui/core/TableCell';
import TableHead from '@material-ui/core/TableHead';
import TableRow from '@material-ui/core/TableRow';
import NodeApp from './NodeApp';
import { Grid, Button } from '@material-ui/core';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogContentText from '@material-ui/core/DialogContentText';
import DialogTitle from '@material-ui/core/DialogTitle';
import FormControl from '@material-ui/core/FormControl';
import Select from '@material-ui/core/Select';
import { Add } from '@material-ui/icons';
import CircularProgress from '@material-ui/core/CircularProgress';
import OrchestrationContext from '../../context/orchestrationContext';

class NodeApps extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loaded: false,
      error: null,
      open: false,
      apps: [],
      policies: [],
      nodeApps: [],
      selectedAppId: '',
    };
  }

  static contextType = OrchestrationContext;

  getApps = () => {
    return ApiClient.get(`/apps`)
      .then((resp) => {
        this.setState({
          apps: resp.data.apps || [],
        });
      })
      .catch((err) => {
        this.props.enqueueSnackbar(
          `${err.toString()}. Please try again later.`,
          { variant: 'error' }
        );
      });
  };

  getTrafficPolicies = () => {
    ApiClient.get(`${this.context.apiClientPath}/policies`)
      .then((resp) => {
        this.setState({
          policies: resp.data.policies || [],
        });
      })
      .catch((err) => {
        this.props.enqueueSnackbar(
          `${err.toString()}. Please try again later.`,
          { variant: 'error' }
        );
      });
  };

  getNodeApps = () => {
    const { nodeID } = this.props;

    return ApiClient.get(`/nodes/${nodeID}/apps`)
      .then((resp) => {
        this.setState({
          nodeApps: resp.data.apps,
        });
      })
      .catch((err) => {
        if (err.response.status === 404) {
          this.setState({
            nodeApps: [],
          });

          return;
        }

        this.props.enqueueSnackbar(
          `${err.toString()}. Please try again later.`,
          { variant: 'error' }
        );
      });
  };

  deployNodeApp = () => {
    const { nodeID } = this.props;
    const { selectedAppId } = this.state;

    this.setState({ loaded: false });

    return ApiClient.post(`/nodes/${nodeID}/apps`, { id: selectedAppId })
      .then((resp) => {
        this.refreshNodeAppsView().then(() => {
          this.props.enqueueSnackbar(
            `Successfully deployed app ${selectedAppId}.`,
            { variant: 'success' }
          );
          this.setState({ loaded: true });
        });
      })
      .catch((err) => {
        this.setState({
          loaded: true,
        });
        this.props.enqueueSnackbar(
          `${err.toString()}. Please try again later.`,
          { variant: 'error' }
        );
      });
  };

  handleOpen = () => {
    this.setState({ open: true });
  };

  handleClose = () => {
    this.setState({ open: false });
  };

  handleDeployApp = () => {
    this.deployNodeApp();
    this.handleClose();
  };

  handleChangeApp = (event) => {
    this.setState({ selectedAppId: event.target.value });
  };

  refreshNodeAppsView() {
    return Promise.all([
      this.getApps(),
      this.getNodeApps(),
      this.getTrafficPolicies(),
    ]);
  }

  componentDidMount() {
    this.refreshNodeAppsView().then(() => {
      this.setState({ loaded: true });
    });
  }

  renderDeployDialog = () => {
    const { apps, selectedAppId } = this.state;

    return (
      <Dialog open={this.state.open} onClose={this.handleClose}>
        <DialogTitle id="form-dialog-title">
          Deploy Application to Node
        </DialogTitle>
        <DialogContent>
          <DialogContentText>
            Choose an application to deploy:
          </DialogContentText>
          <form>
            <FormControl>
              <Select
                native
                value={selectedAppId}
                onChange={this.handleChangeApp}
              >
                <option key="0" value="">
                  Select an Application
                </option>
                {apps.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.name}
                  </option>
                ))}
              </Select>
            </FormControl>
          </form>
        </DialogContent>
        <DialogActions>
          <Button onClick={this.handleClose} color="primary">
            Cancel
          </Button>
          <Button onClick={this.handleDeployApp} color="primary">
            Deploy
          </Button>
        </DialogActions>
      </Dialog>
    );
  };

  renderTable = () => {
    const { apps, nodeApps, policies } = this.state;

    const { nodeID } = this.props;

    return (
      <React.Fragment>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>ID</TableCell>
              <TableCell align="right">Status</TableCell>
              <TableCell align="right">Type</TableCell>
              <TableCell align="right">Name</TableCell>
              <TableCell align="right">Traffic Policy</TableCell>
              <TableCell align="right">Lifecycle</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {nodeApps.map((nodeApp) => {
              const nodeAppWithDetails = apps.find((obj) => {
                return obj.id === nodeApp.id;
              });
              return (
                <NodeApp
                  key={nodeApp.id}
                  nodeId={nodeID}
                  nodeApp={nodeAppWithDetails}
                  policies={policies}
                />
              );
            })}
          </TableBody>
        </Table>
      </React.Fragment>
    );
  };

  render() {
    const { loaded } = this.state;

    return (
      <React.Fragment>
        <Grid container>
          <Grid item xs={12} style={{ textAlign: 'right' }}>
            <Button
              onClick={this.handleOpen}
              variant="outlined"
              color="primary"
            >
              Deploy App
              <Add />
            </Button>
          </Grid>
          <Grid item xs={12}>
            {loaded ? this.renderTable() : <CircularProgress />}
          </Grid>
        </Grid>
        {this.renderDeployDialog()}
      </React.Fragment>
    );
  }
}

export default withSnackbar(NodeApps);
