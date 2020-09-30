// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React, { Component } from 'react';
import ApiClient from "../../api/ApiClient";
import { SchemaForm, utils } from 'react-schema-form';
import DNSSchema from '../../components/schema/NodeDnsConfigApply';
import { withSnackbar } from 'notistack';
import {
  Grid,
  Button,
  Typography
} from '@material-ui/core';
import DialogTitle from "@material-ui/core/DialogTitle";
import DialogContent from "@material-ui/core/DialogContent";
import DialogContentText from "@material-ui/core/DialogContentText";
import DialogActions from "@material-ui/core/DialogActions";
import CircularProgress from "@material-ui/core/CircularProgress";
import Dialog from "@material-ui/core/Dialog";

class DNSView extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loaded: false,
      dns: {},
      dialogShown: false,
      showDialogLoader: false,
    };
  }

  // GET /nodes/:node_id/dns
  getNodeDNSConfig = () => {
    const { nodeID } = this.props;

    ApiClient.get(`/nodes/${nodeID}/dns`)
      .then((resp) => {
        this.setState({
          loaded: true,
          dns: resp.data || {},
        })
      })
      .catch((err) => {
        this.setState({
          loaded: true,
        });

        if (err.response.status === 404) {
          this.setState({dns: {}});
          return;
        }

        this.props.enqueueSnackbar(`${err.toString()}. Please try again later.`, { variant: 'error' });
      });
  };

  // PATCH /nodes/:node_id/dns
  applyDNSConfig = () => {
    const { nodeID } = this.props;
    const { dns } = this.state;

    ApiClient.patch(`/nodes/${nodeID}/dns`, dns)
      .then((resp) => {
        this.setState({
          loaded: true,
        });

        this.getNodeDNSConfig();
        this.props.enqueueSnackbar('Successfully applied DNS Config to node', { variant: 'success' })
      })
      .catch((err) => {
        this.setState({
          loaded: true,
        });

        this.props.enqueueSnackbar(`${err.toString()}`, { variant: 'error' });
      });
  };

  showDeleteDialog = () => {
    this.setState({dialogShown: true});
  };

  closeDeleteDialog = () => {
    this.setState({ dialogShown: false });
  };

  // DELETE /nodes/:node_id/dns/:dns_id
  deleteDNSConfig = () => {
    const { nodeID } = this.props;
    const { dns } = this.state;
    this.setState({ showDialogLoader: true });

    if(!dns.hasOwnProperty('id')) {
      this.setState({dialogShown: false, showDialogLoader: false});
      return;
    }

    if (this.state.showDialogLoader === true) {
      return;
    }

    ApiClient.delete(`/nodes/${nodeID}/dns`)
      .then((resp) => {
        this.setState({
          loaded: true,
          dialogShown: false,
          showDialogLoader: false,
        });

        this.getNodeDNSConfig();
        this.props.enqueueSnackbar('Successfully deleted DNS Config on node', { variant: 'success' })
      })
      .catch((err) => {
        this.setState({
          loaded: true,
        });

        this.props.enqueueSnackbar(`${err.toString()}. Please try again later.`, { variant: 'error' });
      });
  };

  onModelChange = (key, val) => {
    const { dns } = this.state;

    const newDNS = dns;

    utils.selectOrSet(key, newDNS, val);

    this.setState({ dns: newDNS });
  };

  componentDidMount() {
    this.getNodeDNSConfig();
  }

  render() {
    const {
      loaded,
      showErrors,
      dns,
    } = this.state;

    if (!loaded) {
      return <React.Fragment>Loading ...</React.Fragment>
    }

    return (
      <React.Fragment>
        <Grid
          container
          justify="center"
          alignItems="flex-end"
          spacing={24}
        >
          <Grid item xs={12}>
            <SchemaForm
              schema={DNSSchema.schema}
              form={DNSSchema.form}
              model={dns}
              onModelChange={this.onModelChange}
              showErrors={showErrors}
            />
            <Typography style={{marginTop: '10px'}}>
              Custom DNS forwarder configuration is not currently supported. The DNS forwarder on the Edge Node defaults to 8.8.8.8.
            </Typography>
          </Grid>
          <Grid item xs={12} style={{ textAlign: 'right' }}>
            {
              this.state.dns.id ? (
                <Button onClick={this.showDeleteDialog}>
                  Delete
                </Button>
              ) : null
            }
            <Button
              onClick={this.applyDNSConfig}
              variant="outlined"
              color="primary"
            >
              Save
            </Button>
          </Grid>
        </Grid>
        <Dialog
          open={this.state.dialogShown}
          onClose={this.closeDeleteDialog}
          aria-labelledby="alert-dialog-title"
          aria-describedby="alert-dialog-description"
        >
          <DialogTitle id="alert-dialog-title">Delete DNS Configuration?</DialogTitle>
          <DialogContent>
            <DialogContentText id="alert-dialog-description">
              Doing so will delete ALL DNS configurations on this particular Edge Node
            </DialogContentText>
          </DialogContent>
          <DialogActions>
            {this.state.showDialogLoader ? (<CircularProgress />) : ""}
            <Button onClick={this.closeDeleteDialog} color="primary">
              Cancel
            </Button>
            <Button onClick={this.deleteDNSConfig} color="primary" autoFocus>
              Delete
            </Button>
          </DialogActions>
        </Dialog>
      </React.Fragment>
    );
  }
};

export default withSnackbar(DNSView);
