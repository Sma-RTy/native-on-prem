// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React,  { Component } from 'react';
import withStyles from '@material-ui/core/styles/withStyles';
import CircularProgress from '@material-ui/core/CircularProgress'
import Grid from "@material-ui/core/Grid";

const styles = theme => ({
  container: {
    position: 'absolute',
    width: '100%',
    height: '100%',
  },
  flexGrow: {
    height: '100%',
  }
});

class FullSizeCircularLoader extends Component {

  render() {
    const { classes } = this.props;
    return (
      <div className={classes.container}>
        <Grid container className={classes.flexGrow} direct="column" alignItems="center" justify="center">
          <CircularProgress className={classes.progress} />
        </Grid>
      </div>
    )
  }
}

export default withStyles(styles)(FullSizeCircularLoader)
