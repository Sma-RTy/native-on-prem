// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import React from 'react';
import ApiClient from '../api/ApiClient';
import Auth from './Auth';
import MockAdapter from 'axios-mock-adapter';

describe('Auth Test', () => {
  it('Successful Login will store the Token...', async(done) => {
    const axiosMock = new MockAdapter(ApiClient.axiosInstance);

    axiosMock.onPost('/auth').reply(200, {
     'token': 'SUCCESS_TOKEN',
    });

    await Auth.login('test@email.org', '1234');
    expect(sessionStorage.setItem).toHaveBeenLastCalledWith('JWT', 'SUCCESS_TOKEN');
    expect(sessionStorage.__STORE__['JWT']).toEqual('SUCCESS_TOKEN');
    expect(Auth.isAuthenticated()).toEqual(true);
    expect(sessionStorage.getItem).toHaveBeenLastCalledWith('JWT');

    done();
  });

  it('Calling logout will remove the stored token', () => {
    sessionStorage.__STORE__['JWT'] = 'EXPIRED_TOKEN';
    expect(Auth.isAuthenticated()).toEqual(true);

    const mockFn = jest.fn();

    Auth.logout(mockFn);
    expect(Auth.isAuthenticated()).toEqual(false);
    expect(mockFn).toBeCalledTimes(1);
    expect(sessionStorage.removeItem).toHaveBeenCalledWith('JWT');
    expect(sessionStorage.__STORE__['JWT']).toBeUndefined()
  });
});
