// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019-2020 Intel Corporation

import React, { Component } from 'react';
import withStyles from '@material-ui/core/styles/withStyles';
import CssBaseline from '@material-ui/core/CssBaseline';
import Grid from '@material-ui/core/Grid';
import Topbar from '../components/Topbar';
import SectionHeader from '../components/typo/SectionHeader';
import TabContainer from '../components/tabs/TabContainer';
import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import DashboardView from './node/Dashboard';
import AppsView from './node/NodeApps';
import InterfacesView from './node/Interfaces';
import DNSView from './node/DNS';
import NFDView from './node/NFD';

const styles = theme => ({
  root: {
    flexGrow: 1,
    backgroundColor: theme.palette.grey['A500'],
    overflow: 'hidden',
    backgroundSize: 'cover',
    backgroundPosition: '0 400px',
    marginTop: 20,
    padding: 20,
    paddingBottom: 200
  },
  grid: {
    width: '90%'
  },
  divTabContainer: {}
});

class NodesView extends Component {
  constructor(props) {
    super(props);

    this.state = {
      tabValue: 0,
    };
  }

  handleTabChange = (event, tabValue) =>
    this.setState({ tabValue });

  renderDashboardTab = () =>
    <DashboardView nodeID={this.props.match.params.id} />

  renderAppsTab = () =>
    <AppsView nodeID={this.props.match.params.id} />

  renderDNSTab = () =>
    <DNSView nodeID={this.props.match.params.id} />

  renderInterfacesTab = () =>
    <InterfacesView nodeID={this.props.match.params.id} />

  renderNFDTab = () =>
    <NFDView nodeID={this.props.match.params.id} />

  render() {
    const { classes, match } = this.props;
    const currentPath = this.props.location.pathname;
    const { tabValue } = this.state;

    return (
      <React.Fragment>
        <CssBaseline />
        <Topbar currentPath={currentPath} />
        <div className={classes.root}>
          <Grid container justify="center">
            <Grid spacing={24} alignItems="center" justify="center" container className={classes.grid}>
              <Grid item xs={12}>
                <SectionHeader title="Edge Node" subtitle={`ID: ${match.params.id}`} />
              </Grid>
              <Grid item xs={12}>
                <div>
                  <AppBar position="static">
                    <Tabs value={tabValue} onChange={this.handleTabChange} variant="fullWidth">
                      <Tab label="Dashboard" />
                      <Tab label="Apps" />
                      <Tab label="Interfaces" />
                      <Tab label="DNS" />
                      <Tab label="NFD" />
                    </Tabs>
                  </AppBar>
                  <div className={classes.divTabContainer}>
                    {tabValue === 0 && <TabContainer>{this.renderDashboardTab()}</TabContainer>}
                    {tabValue === 1 && <TabContainer>{this.renderAppsTab()}</TabContainer>}
                    {tabValue === 2 && <TabContainer>{this.renderInterfacesTab()}</TabContainer>}
                    {tabValue === 3 && <TabContainer>{this.renderDNSTab()}</TabContainer>}
                    {tabValue === 4 && <TabContainer>{this.renderNFDTab()}</TabContainer>}
                  </div>
                </div>
              </Grid>
            </Grid>
          </Grid>
        </div>
      </React.Fragment>
    )
  }
}

export default withStyles(styles)(NodesView);
