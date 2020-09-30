// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React, { Component } from 'react';
import { BrowserRouter } from 'react-router-dom';
import { MuiThemeProvider } from '@material-ui/core/styles';
import './App.css';
import Routes from './routes';
import MuiTheme from './MuiTheme';
import '@material-ui/icons';
import 'typeface-lato';
import 'typeface-roboto';
import { SnackbarProvider } from 'notistack';
import CssBaseline from '@material-ui/core/CssBaseline';
import ErrorBoundary from './components/common/ErrorBoundary';
import OrchestrationContext, {
  initialOrchestrationValue,
} from './context/orchestrationContext';

class App extends Component {
  render() {
    return (
      <React.Fragment>
        <CssBaseline />
        <SnackbarProvider
          maxSnack={3}
          anchorOrigin={{
            vertical: 'top',
            horizontal: 'right',
          }}
        >
          <div>
            <ErrorBoundary>
              <MuiThemeProvider theme={MuiTheme}>
                <BrowserRouter>
                  <OrchestrationContext.Provider
                    value={initialOrchestrationValue}
                  >
                    <Routes />
                  </OrchestrationContext.Provider>
                </BrowserRouter>
              </MuiThemeProvider>
            </ErrorBoundary>
          </div>
        </SnackbarProvider>
      </React.Fragment>
    );
  }
}

export default App;
