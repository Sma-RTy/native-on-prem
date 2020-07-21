// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React, { Component } from 'react';
import withStyles from '@material-ui/core/styles/withStyles';
import { withRouter } from 'react-router-dom';
import CssBaseline from '@material-ui/core/CssBaseline';
import Grid from '@material-ui/core/Grid';
import Topbar from './Topbar';

const styles = theme => ({
  root: {
    flexGrow: 1,
    backgroundColor: theme.palette.grey['100'],
    overflow: 'hidden',
    backgroundSize: 'cover',
    backgroundPosition: '0 400px',
    paddingBottom: 200
  },
  grid: {
    width: 1200,
    marginTop: 40,
    [theme.breakpoints.down('sm')]: {
      width: 'calc(100% - 20px)'
    }
  },
});

class Main extends Component {
  render() {
    const { location: { pathname: currentPath }, classes } = this.props;
    return (
      <React.Fragment>
        <CssBaseline />
        <Topbar currentPath={currentPath} />
        <div className={classes.root}>
          <Grid container justify="center">
            <Grid item>
              TODO: Home or redirect to nodes
            </Grid>
          </Grid>

        </div>
      </React.Fragment>
    )
  }
}

export default withRouter(withStyles(styles)(Main));
