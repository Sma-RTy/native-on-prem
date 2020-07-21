// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import { configure } from 'enzyme';
import 'jest-enzyme';
import Adapter from 'enzyme-adapter-react-16';
// react-testing-library renders your components to document.body,
// this will ensure they're removed after each test.
import 'react-testing-library/cleanup-after-each';
// this adds jest-dom's custom assertions
import 'jest-dom/extend-expect';
import 'jest-localstorage-mock';

configure({ adapter: new Adapter() });
