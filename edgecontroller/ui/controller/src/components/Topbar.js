// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019-2020 Intel Corporation

import React, { Component } from 'react';
import withStyles from '@material-ui/core/styles/withStyles';
import { Link, withRouter } from 'react-router-dom';
import Auth from './Auth';
import Grid from '@material-ui/core/Grid';
import Typography from '@material-ui/core/Typography';
import Toolbar from '@material-ui/core/Toolbar';
import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import MenuIcon from '@material-ui/icons/Menu';
import IconButton from '@material-ui/core/IconButton';
import List from '@material-ui/core/List';
import ListItem from '@material-ui/core/ListItem';
import ListItemText from '@material-ui/core/ListItemText';
import SwipeableDrawer from '@material-ui/core/SwipeableDrawer';
import AccountCircle from '@material-ui/icons/AccountCircle';
import NavigationList from './NavigationList';
import MenuList from '@material-ui/core/MenuList'
import MenuItem from '@material-ui/core/MenuItem';
import Popper from '@material-ui/core/Popper';
import Grow from '@material-ui/core/Grow';
import Paper from '@material-ui/core/Paper';
import ClickAwayListener from '@material-ui/core/ClickAwayListener';

const LANDING_URL = process.env.REACT_APP_LANDING_UI_URL

const styles = theme => ({
  appBar: {
    position: 'relative',
    boxShadow: 'none',
    borderBottom: `1px solid ${theme.palette.grey['100']}`,
    backgroundColor: 'white',

  },
  inline: {
    display: 'inline'
  },
  flex: {
    display: 'flex',
    grow: 1,
    [theme.breakpoints.down('sm')]: {
      display: 'flex',
      justifyContent: 'space-evenly',
      alignItems: 'center'
    }
  },
  link: {
    textDecoration: 'none',
    color: 'inherit'
  },
  productLogo: {
    display: 'inline-block',
    borderLeft: `1px solid ${theme.palette.grey['A100']}`,
    marginLeft: 32,
    paddingLeft: 24,
    [theme.breakpoints.up('md')]: {
      paddingTop: '1.5em'
    }
  },
  tagline: {
    display: 'inline-block',
    marginLeft: 10,
    [theme.breakpoints.up('md')]: {
      paddingTop: '0.8em'
    }
  },
  iconContainer: {
    display: 'none',
    [theme.breakpoints.down('sm')]: {
      display: 'block'
    }
  },
  iconButton: {
    float: 'right'
  },
  topBarWrapper: {
    'overflow': 'auto',
  },
  tabContainer: {
    [theme.breakpoints.down('sm')]: {
      display: 'none'
    }
  },
  tabItem: {
    paddingTop: 20,
    paddingBottom: 20,
    minWidth: 'auto',
  },
  topBarAvatar: {
    margin: '5px 5px 5px auto',
    width: '58px',
  }
});

class Topbar extends Component {

  state = {
    value: 0,
    menuDrawer: false,
    open: false,
  };

  handleMenuToggle = () => {
    this.setState(state => ({ open: !state.open }));
  };

  handleChange = (event, value) => {
    this.setState({ value });
  };

  mobileMenuOpen = (event) => {
    this.setState({ menuDrawer: true });
  };

  mobileMenuClose = (event) => {
    this.setState({ menuDrawer: false });
  };

  handleClose = event => {
    return !this.anchorEl.contains(event.target) ? this.setState({ open: false }) : '';
  };

  handleLogout = event => {
    Auth.logout(() => {
      return window.location.assign(`${LANDING_URL}/`);
    });

  };

  componentDidMount() {
    window.scrollTo(0, 0);
  }

  current = () => {
    const pathMatcher = (path) => {
      const matchRegExp = `${path}?.*`;
      return this.props.currentPath.match(matchRegExp)
    };
    if (pathMatcher('/nodes')) {
      return 0
    }
    if (pathMatcher('/apps')) {
      return 1
    }
    if (pathMatcher('/policies')) {
      return 2
    }
  };

  render() {

    const { classes } = this.props;
    const { open } = this.state;

    return (
      <AppBar position="absolute" color="default" className={classes.appBar}>
        <Toolbar>
          <Grid container spacing={24} alignItems="baseline">
            <Grid item xs={12} className={classes.flex}>
              <div className={classes.inline}>
                <Typography variant="h6" color="inherit" noWrap>
                  <Link to='/' className={classes.link}>
                    <span className={classes.tagline}>Controller CE</span>
                  </Link>
                </Typography>
              </div>
              {!this.props.noTabs && (
                <div className={classes.topBarWrapper}>
                  <div className={classes.iconContainer}>
                    <IconButton onClick={this.mobileMenuOpen} className={classes.iconButton} color="inherit" aria-label="Menu">
                      <MenuIcon />
                    </IconButton>
                  </div>
                  <div className={classes.tabContainer}>
                    <SwipeableDrawer anchor="right" open={this.state.menuDrawer} onClose={this.mobileMenuClose} onOpen={this.mobileMenuOpen}>
                      <AppBar title="Menu" />
                      <List>
                        {NavigationList.map((item, index) => (
                          <ListItem component={Link} to={{ pathname: item.pathname, search: this.props.location.search }} button key={item.label}>
                            <ListItemText primary={item.label} />
                          </ListItem>
                        ))}
                      </List>
                    </SwipeableDrawer>
                    <Tabs
                      value={this.current() || this.state.value}
                      indicatorColor="primary"
                      textColor="primary"
                      onChange={this.handleChange}
                      variant='scrollable'
                    >
                      {NavigationList.map((item, index) => (
                        <Tab key={index} component={Link} to={{ pathname: item.pathname, search: this.props.location.search }} classes={{ root: classes.tabItem }} label={item.label} />
                      ))}
                    </Tabs>
                  </div>
                </div>
              )}
              <IconButton
                buttonRef={node => {
                  this.anchorEl = node;
                }}
                aria-haspopup="true"
                aria-owns={open ? 'menu-list-grow' : undefined}
                color="inherit"
                className={classes.topBarAvatar}
                onClick={this.handleMenuToggle}
              >
                <AccountCircle />
              </IconButton>
              <Popper open={open} anchorEl={this.anchorEl} transition disablePortal>
                {({ TransitionProps, placement }) => (
                  <Grow
                    {...TransitionProps}
                    id="menu-list-grow"
                    style={{ transformOrigin: placement === 'bottom' ? 'center top' : 'center bottom' }}
                  >
                    <Paper>
                      <ClickAwayListener onClickAway={this.handleClose}>
                        <MenuList>
                          <MenuItem onClick={this.handleLogout}>Logout</MenuItem>
                        </MenuList>
                      </ClickAwayListener>
                    </Paper>
                  </Grow>
                )}
              </Popper>
            </Grid>
          </Grid>
        </Toolbar>
      </AppBar>
    )
  }
}

export default withRouter(withStyles(styles)(Topbar))
