// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import axios from 'axios';
import Auth from '../components/Auth';

class ApiClient {
  _CONTROLLER_API_ = process.env.REACT_APP_CONTROLLER_API;

  axiosConfig = {
    baseURL: (process.env.NODE_ENV === 'production') ? this._CONTROLLER_API_ : '/api',
    timeout: 1000 * 120, // 120seconds/2minutes
    headers: {
      contentType: 'application/json',
      accept: 'application/json',
      'Authorization': `Bearer ${this.getJWT()}`,
    }
  };

  interceptorEnabled = false;
  axiosInstance = axios.create(this.axiosConfig);

  setupInterceptor() {
    // Response Interceptor
    if (this.interceptorEnabled === true) {
      return true;
    }

    this.axiosInstance.interceptors.response.use(function (response) {
      // Do something with response data
      return response;
    }, function (err) {

      if (!err || !err.hasOwnProperty('response')) {
        return Promise.reject(err);
      }

      if (err.response.status === 401) {
        Auth.logout(() => {
          window.location.href = "/login";
        });
      }

      if (err.response && err.response.data && err.response.data !== '') {
        return Promise.reject(err.response.data)
      }
      // Do something with response error
      return Promise.reject(err);
    });

    this.interceptorEnabled = true;
  }
  /**
   *
   * @returns string - The AuthToken if present
   */
  getJWT() {
    return sessionStorage.getItem('JWT');
  }

  /**
   *
   * @param Token
   */
  setJWT(Token) {
    sessionStorage.setItem('JWT', Token);

    // Whenever setJWT is called we need to update the axios instance
    this.updateAxios();
  }

  updateAxios() {
    this.axiosConfig = {
      ...this.axiosConfig, headers: {
        contentType: 'application/json',
        accept: 'application/json',
        'Authorization': `Bearer ${this.getJWT()}`,
      }
    };

    this.axiosInstance = axios.create(this.axiosConfig);
    this.setupInterceptor();
  }

  /**
   * @async
   * @param username
   * @param password
   * @returns {Promise<AxiosResponse>}
   */
  async login(username, password) {
    return await this.axiosInstance.post('/auth', { username, password });
  }

  /**
   * @async
   * @param {string} path - The Path
   * @param {*} options - Axios options
   * @returns {Promise<AxiosResponse>}
   */
  async get(path, options = {}) {
    if (this.interceptorEnabled === false) { this.setupInterceptor() }
    return await this.axiosInstance.get(path, options);
  }

  /**
   * @async
   * @param {string} path - The Path
   * @param {*} data - Post Body
   * @returns {Promise<AxiosResponse>}
   */
  async post(path, data = {}) {
    if (this.interceptorEnabled === false) { this.setupInterceptor() }
    return await this.axiosInstance.post(path, data);
  }

  /**
 * @async
 * @param {string} path - The Path
 * @param {*} data - Patch Body
 * @returns {Promise<AxiosResponse>}
 */
  async patch(path, data = {}) {
    if (this.interceptorEnabled === false) { this.setupInterceptor() }
    return await this.axiosInstance.patch(path, data);
  }

  /**
   * @async
   * @param {string} path - The Path
   * @param {*} options - Axios options
   * @returns {Promise<AxiosResponse>}
   */
  async delete(path, options = {}) {
    if (this.interceptorEnabled === false) { this.setupInterceptor() }
    return await this.axiosInstance.delete(path, options);
  }
}

export default new ApiClient();
