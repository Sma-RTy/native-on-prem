// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React, { Component } from 'react';
import ApiClient from '../../api/ApiClient';
import { withSnackbar } from 'notistack';
import { Button } from '@material-ui/core';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogContentText from '@material-ui/core/DialogContentText';
import DialogTitle from '@material-ui/core/DialogTitle';
import FormControl from '@material-ui/core/FormControl';
import Select from '@material-ui/core/Select';
import CircularProgress from '@material-ui/core/CircularProgress';
import OrchestrationContext from '../../context/orchestrationContext';

class PolicyControls extends Component {
  constructor(props) {
    super(props);
    const { resourceId, policyType } = this.props;

    this.state = {
      isLoaded: false,
      deleteDialogShown: false,
      policyDialogShown: false,
      showDialogLoader: false,
      resourcePolicyId: '',
      selectedPolicyId: '',
      policyType,
      resourceId,
    };
  }

  static contextType = OrchestrationContext;

  getPolicy = () => {
    const { nodeId, resourceId, policyType } = this.props;

    return ApiClient.get(
      `/nodes/${nodeId}/${policyType}s/${resourceId}${this.context.apiClientPath}/policy`
    )
      .then((resp) => {
        this.setState({
          resourcePolicyId: resp.data.id || '',
        });
      })
      .catch((err) => {
        if (err.response.status === 404) {
          return;
        }

        this.props.enqueueSnackbar(
          `Error fetching Node ${policyType} Policy: ${err.toString()}. Please try again later.`,
          { variant: 'error' }
        );
      });
  };

  deletePolicy = () => {
    const { nodeId, resourceId, policyType } = this.props;
    const { showDialogLoader } = this.state;

    if (showDialogLoader === true) {
      return;
    }

    this.setState({ showDialogLoader: true });
    ApiClient.delete(
      `/nodes/${nodeId}/${policyType}s/${resourceId}${this.context.apiClientPath}/policy`
    )
      .then((resp) => {
        this.setState({
          resourcePolicyId: '',
          showDialogLoader: false,
          deleteDialogShown: false,
        });
        this.props.enqueueSnackbar(
          `Successfully deleted policy on ${policyType}`,
          { variant: 'success' }
        );
      })
      .catch((err) => {
        this.props.enqueueSnackbar(
          `${err.toString()}. Please try again later.`,
          { variant: 'error' }
        );
      });
  };

  handleAssignPolicy = () => {
    const { nodeId, resourceId, policyType } = this.props;
    const { selectedPolicyId, showDialogLoader } = this.state;

    if (showDialogLoader === true) {
      return;
    }

    this.setState({ showDialogLoader: true });
    ApiClient.patch(
      `/nodes/${nodeId}/${policyType}s/${resourceId}${this.context.apiClientPath}/policy`,
      { id: selectedPolicyId }
    )
      .then((resp) => {
        this.setState({
          loaded: true,
          resourcePolicyId: selectedPolicyId,
          showDialogLoader: false,
        });

        this.props.enqueueSnackbar(
          `Successfully added policy on ${policyType}`,
          { variant: 'success' }
        );
        this.handleClosePolicy();
      })
      .catch((err) => {
        this.setState({
          loaded: true,
          error: err,
        });

        this.props.enqueueSnackbar(
          `${err.toString()}. Please try again later.`,
          { variant: 'error' }
        );
      });
  };

  handleOpenPolicyDialog = () => {
    this.setState({
      policyDialogShown: true,
    });
  };

  handlePolicyDelete = () => {
    this.setState({
      deleteDialogShown: true,
    });
  };

  handleClosePolicy = () => {
    this.setState({ deleteDialogShown: false, policyDialogShown: false });
  };

  handleChangePolicy = (event) => {
    this.setState({ selectedPolicyId: event.target.value });
  };

  componentDidMount() {
    this.getPolicy().then(() => {
      this.setState({ isLoaded: true });
    });
  }

  renderTrafficPolicyDialog = () => {
    const { resourcePolicyId, policyType } = this.state;
    const { policies } = this.props;

    return (
      <Dialog
        open={this.state.policyDialogShown}
        onClose={this.handleClosePolicy}
      >
        <DialogTitle id="form-dialog-title">{`Assign Traffic Policy to ${policyType}`}</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Choose a traffic policy to assign:
          </DialogContentText>
          <form>
            <FormControl>
              <Select
                native
                onChange={this.handleChangePolicy}
                defaultValue={resourcePolicyId}
              >
                <option key="0" value="">
                  Select a Traffic Policy
                </option>
                {policies.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.name}
                  </option>
                ))}
              </Select>
            </FormControl>
          </form>
        </DialogContent>
        <DialogActions>
          {this.state.showDialogLoader ? <CircularProgress /> : ''}
          <Button onClick={this.handleClosePolicy} color="primary">
            Cancel
          </Button>
          <Button onClick={() => this.handleAssignPolicy()} color="primary">
            Assign
          </Button>
        </DialogActions>
      </Dialog>
    );
  };

  renderDeleteTrafficPolicyDialog = () => {
    const { policyType } = this.props;
    return (
      <Dialog
        open={this.state.deleteDialogShown}
        aria-labelledby="alert-dialog-title"
        aria-describedby="alert-dialog-description"
      >
        <DialogTitle id="alert-dialog-title">
          Remove Traffic Policy?
        </DialogTitle>
        <DialogContent>
          <DialogContentText id="alert-dialog-description">
            {`Doing so will remove the traffic policy from the selected ${policyType}`}
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          {this.state.showDialogLoader ? <CircularProgress /> : ''}
          <Button onClick={this.handleClosePolicy} color="primary">
            Cancel
          </Button>
          <Button onClick={this.deletePolicy} color="primary" autoFocus>
            Remove Policy
          </Button>
        </DialogActions>
      </Dialog>
    );
  };

  render() {
    const { isLoaded, resourcePolicyId } = this.state;
    if (isLoaded === false) {
      return `Loading....`;
    }

    return (
      <React.Fragment>
        <Button onClick={() => this.handleOpenPolicyDialog()}>
          {resourcePolicyId ? 'Edit' : 'Add'}
        </Button>
        {resourcePolicyId ? (
          <Button onClick={() => this.handlePolicyDelete()}>
            Remove Policy
          </Button>
        ) : null}
        {this.renderTrafficPolicyDialog()}
        {this.renderDeleteTrafficPolicyDialog()}
      </React.Fragment>
    );
  }
}

export default withSnackbar(PolicyControls);
