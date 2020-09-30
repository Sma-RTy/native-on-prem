```text
SPDX-License-Identifier: Apache-2.0
Copyright (c) 2019 Intel Corporation
```

# Controller CE - UI


## Features
- Forked from: [Material Sense](https://github.com/alexanmtz/material-sense)
- Responsive
- Include a Graph using [recharts](https://github.com/recharts/recharts)
- With [Router](https://github.com/ReactTraining/react-router) included
- A docker container for production build
- Created with [Create react app](https://github.com/facebook/create-react-app)

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Prerequisites
- Node & NPM installed (v10.15.3, or V10 LTS)
  - recommended to use NVM https://github.com/nvm-sh/nvm to manage your Node versions
- Yarn installed globally `npm install -g yarn`
- Install dependencies via `yarn install` within the project

## Environment Setup

### Development
A development .env under `.env.development` is already configured with the default URLs
for the controller UI local development.

The local development server is proxied via create-react-app's proxy functionality.
This is to resolve CORS local dev concerns.

### Production

**Any client web browser using the Controller CE web user interface must have network access 
to the listening address and port of the Controller CE REST API.**

## Available Scripts

In the project directory, you can run:

### `yarn start`

Runs the app in the development mode.<br>
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

The page will reload if you make edits.<br>
You will also see any lint errors in the console.

### `yarn test`

Launches the test runner in the interactive watch mode.<br>
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `yarn build`

Builds the app for production to the `build` folder.<br>
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.<br>
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `yarn eject`

**Note: this is a one-way operation. Once you `eject`, you can’t go back!**

If you aren’t satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (Webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you’re on your own.

You don’t have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn’t feel obligated to use this feature. However we understand that this tool wouldn’t be useful if you couldn’t customize it when you are ready for it.

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).

## Docker

This project works in a docker container as well

First run:
`docker build . -t cce-ui`

Then:
`docker run -p 3000:80 cce-ui`

## Publish at Github pages
`yarn deploy`
