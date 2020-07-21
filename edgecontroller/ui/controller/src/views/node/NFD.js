// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2020 Intel Corporation

import React, { Component } from 'react';
import ApiClient from '../../api/ApiClient';

import withStyles from '@material-ui/core/styles/withStyles';
import Grid from '@material-ui/core/Grid';
import Topbar from '../../components/Topbar';
import Table from '../../components/tables/EnhancedTable';
import AddIcon from '@material-ui/icons/Add';
import { withSnackbar } from 'notistack';
import CircularLoader from '../../components/progressbars/FullSizeCircularLoader';
import CssBaseline from '@material-ui/core/CssBaseline';
import OrchestrationContext from '../../context/orchestrationContext';

import { Typography, Button } from '@material-ui/core';

const styles = (theme) => ({
  root: {
    flexGrow: 1,
    backgroundColor: theme.palette.grey['A500'],
    overflow: 'hidden',
    backgroundSize: 'cover',
    backgroundPosition: '0 400px',
    marginTop: 20,
    padding: 20,
    paddingBottom: 200,
  },
  grid: {
    width: 1000,
  },
  addButton: {
    float: 'right',
  },
});

class NFDView extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loaded: false,
      nfds: [],
      editable: false,
    };
  }

  static contextType = OrchestrationContext;

  componentDidMount = () => {
    return this.getData();
  };

  getData = () => {
    const { nodeID } = this.props;
    ApiClient.get(`/nodes/${nodeID}/nfd`)
      .then((resp) => {
        this.setState({
          loaded: true,
          nfds: resp.data.nodenfds || [],
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

  renderTable = () => {
    const {
      loaded,
      nfds,
    } = this.state;

    const tableHeaders = [
      { id: 'id', numeric: true, disablePadding: false, label: 'ID' },
      { id: 'value', numeric: false, disablePadding: false, label: 'Value' },
    ];

    const tableData = {
      order: 'asc',
      orderBy: 'id',
      selected: [],
      data: nfds,
      page: 0,
      rowsPerPage: 10,
    };

    return <Table rows={tableHeaders} tableState={tableData} editable={this.state.editable} />;
  };

  render() {
    const { classes } = this.props;

    const circularLoader = () => <CircularLoader />;

    const NFDGrid = () => (
      <Grid
        spacing={24}
        alignItems="center"
        justify="center"
        container
        className={classes.grid}
      >
        <Grid item xs={12}>
          <Grid
            container
            direction="row"
            justify="space-between"
            alignItems="flex-start"
            className={classes.sectionContainer}
          >
            <Grid item>
              <Typography variant="subtitle1" className={classes.title}>
              </Typography>
              <Typography
                variant="body1"
                gutterBottom
                className={classes.subtitle}
              >
                Node Features Discovery list
              </Typography>
            </Grid>
          </Grid>
          {this.renderTable()}
        </Grid>
      </Grid>
    );

    return (
      <React.Fragment>
        <CssBaseline />
        <div className={classes.root}>
          <Grid container justify="center">
            {this.state.loaded ? NFDGrid() : circularLoader()}
          </Grid>
        </div>
      </React.Fragment>
    );
  }
}

export default withSnackbar(withStyles(styles)(NFDView));

