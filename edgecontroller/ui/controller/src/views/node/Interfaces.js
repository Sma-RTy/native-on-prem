// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React, { Component } from 'react';
import { withSnackbar } from 'notistack';
import ApiClient from '../../api/ApiClient';
import Table from '@material-ui/core/Table';
import TableBody from '@material-ui/core/TableBody';
import TableCell from '@material-ui/core/TableCell';
import TableHead from '@material-ui/core/TableHead';
import TableRow from '@material-ui/core/TableRow';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogTitle from '@material-ui/core/DialogTitle';
import { SchemaForm, utils } from 'react-schema-form';
import InterfaceSchema from '../../components/schema/NodeInterface';
import PolicyControls from './PolicyControls';
import { Grid, Button } from '@material-ui/core';
import OrchestrationContext, {
  orchestrationModes,
} from '../../context/orchestrationContext';

class InterfacesView extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loaded: false,
      error: null,
      showErrors: true,
      open: false,
      nodeInterfaces: [],
      interfaceID: '',
      policies: [],
      policiesLoaded: false,
      selectedInterfaceID: '',
      hasInterfaceChanges: false,
    };
  }

  static contextType = OrchestrationContext;

  // GET /policies
  getTrafficPolicies = () => {
    ApiClient.get(`${this.context.apiClientPath}/policies`)
      .then((resp) => {
        this.setState({
          policiesLoaded: true,
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

  getNodeInterfaces = () => {
    const { nodeID } = this.props;

    ApiClient.get(`/nodes/${nodeID}/interfaces`)
      .then((resp) => {
        this.setState({
          loaded: true,
          hasInterfaceChanges: false,
          nodeInterfaces: resp.data.interfaces || [],
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

  // PATCH /nodes/:node_id/interfaces/:interface_id
  updateNodeInterface = () => {
    const { nodeID } = this.props;
    const { nodeInterfaces } = this.state;

    ApiClient.patch(`/nodes/${nodeID}/interfaces`, {
      interfaces: nodeInterfaces,
    })
      .then((resp) => {
        this.setState({
          loaded: true,
          nodeInterfaces: nodeInterfaces,
        });

        this.setState({ open: false });
        this.props.enqueueSnackbar(`Successfully updated node interfaces`, {
          variant: 'success',
        });
        this.getNodeInterfaces();
      })
      .catch((err) => {
        this.setState({
          loaded: true,
        });

        this.props.enqueueSnackbar(`${err.toString()}`, { variant: 'error' });
      });
  };

  getNodeInterface = (interfaceID) => {
    const { nodeInterfaces } = this.state;
    const { nodeID } = this.props;
    const filterValue = (obj, key, value) =>
      obj.filter((v) => v[key] === value);
    const foundInterface = filterValue(nodeInterfaces, 'id', interfaceID);

    if (foundInterface.length === 1) {
      return foundInterface[0];
    }

    return ApiClient.get(`/nodes/${nodeID}/interfaces/${interfaceID}`)
      .then((resp) => {
        return resp.data;
      })
      .catch((err) => {
        this.props.enqueueSnackbar(
          `${err.toString()}. Please try again later.`,
          { variant: 'error' }
        );

        this.setState({
          open: false,
        });
      });
  };

  onModelChange = (key, val) => {
    const { nodeInterface } = this.state;

    const newInterface = nodeInterface;

    utils.selectOrSet(key, newInterface, val);

    this.setState({ policy: newInterface });
  };

  handleOpen = async (interfaceID) => {
    const nodeInterface = await this.getNodeInterface(interfaceID);

    this.setState({
      open: true,
      nodeInterface,
    });
  };

  handleClose = () => {
    this.setState({ open: false });
  };

  handleUpdateInterface = () => {
    const { nodeInterface, nodeInterfaces } = this.state;
    // Construct payload by merging edited interface into existing list of node interfaces
    const newInterfaces = nodeInterfaces.map((i) => {
      if (i.id === nodeInterface.id) {
        return { ...i, ...nodeInterface };
      }
      return i;
    });

    this.setState({
      open: false,
      nodeInterfaces: newInterfaces,
      hasInterfaceChanges: true,
    });
    this.props.enqueueSnackbar(
      `Successfully staged node interface change, Please remember to Commit the changes`,
      { variant: 'success' }
    );
  };

  renderEditInterfaceDialog = () => {
    const { showErrors, nodeInterface } = this.state;

    return (
      <Dialog open={this.state.open} onClose={this.handleClose}>
        <DialogTitle id="form-dialog-title">Edit Interface</DialogTitle>
        <DialogContent>
          <SchemaForm
            schema={InterfaceSchema.schema}
            form={InterfaceSchema.form}
            model={nodeInterface}
            onModelChange={this.onModelChange}
            showErrors={showErrors}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={this.handleClose} color="primary">
            Cancel
          </Button>
          <Button onClick={this.handleUpdateInterface} color="primary">
            Save
          </Button>
        </DialogActions>
      </Dialog>
    );
  };

  renderTable = () => {
    const { nodeInterfaces, policies, policiesLoaded } = this.state;
    const { nodeID } = this.props;
    const isInKubeOVNMode =
      this.context.mode === orchestrationModes.kubernetes_ovn.name;

    return (
      <React.Fragment>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>ID</TableCell>
              <TableCell align="right">Description</TableCell>
              <TableCell align="right">Driver</TableCell>
              <TableCell align="right">Type</TableCell>
              {isInKubeOVNMode ? null : (
                <TableCell align="right">Traffic Policy</TableCell>
              )}
              <TableCell align="right">Action</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {nodeInterfaces.map((row) => (
              <TableRow key={row.id}>
                <TableCell component="th" scope="row">
                  {row.id}
                </TableCell>
                <TableCell align="right">{row.description}</TableCell>
                <TableCell align="right">{row.driver}</TableCell>
                <TableCell align="right">{row.type}</TableCell>
                {isInKubeOVNMode ? null : (
                  <TableCell align="right">
                    {policiesLoaded ? (
                      <PolicyControls
                        nodeId={nodeID}
                        resourceId={row.id}
                        policyType="interface"
                        policies={policies}
                      />
                    ) : (
                      `Loading...`
                    )}
                  </TableCell>
                )}
                <TableCell align="right">
                  <Button onClick={() => this.handleOpen(row.id)}>Edit</Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        {this.state.hasInterfaceChanges ? (
          <Grid container justify="center" alignItems="flex-end" spacing={24}>
            <Grid item xs={12} style={{ textAlign: 'right' }}>
              <Button onClick={this.getNodeInterfaces}>Cancel Changes</Button>
              <Button
                onClick={this.updateNodeInterface}
                variant="outlined"
                color="primary"
              >
                Commit Changes
              </Button>
            </Grid>
          </Grid>
        ) : null}
        {this.renderEditInterfaceDialog()}
      </React.Fragment>
    );
  };

  componentDidMount() {
    this.getNodeInterfaces();
    this.getTrafficPolicies();
  }

  render() {
    const { loaded } = this.state;

    if (!loaded) {
      return <React.Fragment>Loading ...</React.Fragment>;
    }

    return (
      <React.Fragment>
        <Grid container>
          <Grid item xs={12}>
            {this.renderTable()}
          </Grid>
        </Grid>
      </React.Fragment>
    );
  }
}

export default withSnackbar(InterfacesView);
