// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import {createMuiTheme} from "@material-ui/core";
import {blue, indigo} from "@material-ui/core/colors";

const theme = createMuiTheme({
  palette: {
    secondary: {
      main: blue[900]
    },
    primary: {
      main: indigo[700]
    },
    grey: {
      '100': '#F8F8F8',
    }
  },
  typography: {
    useNextVariants: true,
    // Use the system font instead of the default Roboto font.
    fontFamily: [
      '"Lato"',
      'sans-serif'
    ].join(',')
  }
});

export default theme
