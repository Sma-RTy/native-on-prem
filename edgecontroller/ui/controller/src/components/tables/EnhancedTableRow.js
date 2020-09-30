// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019-2020 Intel Corporation

import React from "react";
import TableRow from "@material-ui/core/TableRow";
import TableCell from "@material-ui/core/TableCell";
import Button from "@material-ui/core/Button";
import { Link } from "react-router-dom";

class EnhancedTableRow extends React.Component {

  render() {
    const { tableData } = this.props;
    const isSelected = this.props.isSelected;
    const editButton = this.props.editable;

    const editLink = (props) => <Link to={tableData.editUrl} {...props} />;

    return (
      <TableRow
        hover
        aria-checked={isSelected}
        tabIndex={-1}
        key={tableData.id}
        selected={isSelected}
      >
        {Object.keys(tableData).map(key => {
          return key !== 'editUrl' ? (
            <TableCell align="left">{tableData[key]}</TableCell>
          ) : "";
        })}
        { editButton &&
        <TableCell align="left">
          <Button
            style={{ marginRight: '15px' }}
            variant="contained"
            color="primary"
            component={editLink}
            className={'classes.button'}
          >
            Edit
          </Button>
        </TableCell>
        }
      </TableRow>
    );
  }
};

export default EnhancedTableRow
