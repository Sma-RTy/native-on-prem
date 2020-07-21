// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2019 Intel Corporation

import ApiClient from '../api/ApiClient';

class Auth {
  static async login(email, password) {

    try {
      const authResp = await ApiClient.login(email, password);

      if (!authResp.data.token) {
        return false;
      }

      ApiClient.setJWT(authResp.data.token);
      return { success: true };
    } catch (err) {
      if (err.response && "data" in err.response) {
        return { success: false, errorText: err.response.data };
      }

      return { success: false, errorText: "Login Failed Try again Later" };
    }
  }

  static logout(cb) {
    return cb(sessionStorage.removeItem('JWT'));
  }

  static isAuthenticated() {
    return !!sessionStorage.getItem('JWT');
  }
}
export default Auth;
