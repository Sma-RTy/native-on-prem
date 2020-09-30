// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import { mount } from 'enzyme';
import Routes from "./routes";
import NodesView from './views/NodesListing';
import AppsView from './views/AppsListing';
import { SnackbarProvider } from "notistack";

describe('Route tests', () => {
  const spyScrollTo = jest.fn();

  beforeEach(() => {
    // values stored in tests will also be available in other tests unless you run
    sessionStorage.clear();
    document.getElementsByTagName('html')[0].innerHTML = '';

    Object.defineProperty(global.window, 'scrollTo', { value: spyScrollTo });
    spyScrollTo.mockClear();
  });

  // describe('Unprotected Routes', () => {
  //   it('should show Login component when not logged in', () => {
  //     const component = mount(<MemoryRouter initialEntries={['/']} >
  //       <Routes />
  //     </MemoryRouter>
  //     );
  //     expect(component.find(Login)).toHaveLength(1);
  //     expect(component.find(Home)).toHaveLength(0);

  //     expect(
  //       component.find('Router').prop('history').location.pathname
  //     ).toEqual('/login');

  //     // Unmount to prevent affecting other tests
  //     component.unmount();
  //   });
  // });

  describe('Protected Routes', () => {
    beforeEach(() => {
      sessionStorage.__STORE__['JWT'] = "FAKEJWTTOKEN";
    });

    // it('Should show Login component when not logged in', () => {
    //   sessionStorage.__STORE__['JWT'] = null;

    //   const component = mount(<MemoryRouter initialEntries={['/home']} >
    //     <Routes />
    //   </MemoryRouter>
    //   );

    //   expect(sessionStorage.getItem).toHaveBeenLastCalledWith('JWT');
    //   expect(component.find(Login)).toHaveLength(1);

    //   expect(
    //     component.find('Router').prop('history').location.pathname
    //   ).toEqual('/login');

    //   component.unmount();
    // });

    it('should show the NodesView when logged in', () => {
      const component = mount(
        <SnackbarProvider maxSnack={3}>
          <MemoryRouter initialEntries={['/nodes']}>
            <Routes />
          </MemoryRouter>
        </SnackbarProvider>
      );

      expect(sessionStorage.getItem).toHaveBeenLastCalledWith('JWT');
      expect(component.find(NodesView)).toHaveLength(1);

      expect(
        component.find('Router').prop('history').location.pathname
      ).toEqual('/nodes');

      component.unmount();
    });

    it('should show the AppsView when logged in', () => {
      const component = mount(
        <SnackbarProvider maxSnack={3}>
          <MemoryRouter initialEntries={['/apps']} >
            <Routes />
          </MemoryRouter>
        </SnackbarProvider>
      );

      expect(sessionStorage.getItem).toHaveBeenLastCalledWith('JWT');
      expect(component.find(AppsView)).toHaveLength(1);

      expect(
        component.find('Router').prop('history').location.pathname
      ).toEqual('/apps');

      component.unmount();
    });
  });
});
