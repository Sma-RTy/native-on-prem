// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

const helpers = {
  sortDesc: (a, b, orderBy) => {
    if (b[orderBy] < a[orderBy]) {
      return -1;
    }
    if (b[orderBy] > a[orderBy]) {
      return 1;
    }
    return 0;
  },

  getSorting: (order, orderBy) => {
    return order === 'desc' ? (a, b) => helpers.sortDesc(a, b, orderBy) : (a, b) => -helpers.sortDesc(a, b, orderBy);
  },

  stableSort: (array, cmp) => {
    const stabilizedThis = array.map((el, index) => [el, index]);
    stabilizedThis.sort((a, b) => {
      const order = cmp(a[0], b[0]);
      if (order !== 0) return order;
      return a[1] - b[1];
    });
    return stabilizedThis.map(el => el[0]);
  },


};

export default helpers;
