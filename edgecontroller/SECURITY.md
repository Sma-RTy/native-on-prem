```text
SPDX-License-Identifier: Apache-2.0
Copyright (c) 2019 Intel Corporation
```

# Security Overview

This document is intended to provide an overview of details relevant to the
security of the Controller Community Edition.

## HTTP API: Token Authentication

The Controller CE API requires a signed JSON Web Token (JWT) issued by the
Controller CA for all HTTP requests to API endpoints with the exception of the
login endpoint.

The login endpoint `POST /auth` is used to acquire an authentication token for
secured endpoints. Tokens are valid for a 24 hour period. Issued tokens are
digitally signed by the Controller to provide integrity protection as described
in [RFC-7515](https://www.rfc-editor.org/rfc/rfc7515.txt).

Secured endpoints require a bearer token in the HTTP request's `Authorization`
header as specified in [RFC-6750](https://tools.ietf.org/html/rfc6750). Any
request sent to a secured endpoint with a token with either an invalid signature
or validity period will be rejected.

## HTTP API: Default Administrator User

In the current iteration, the Controller CE supports only one user, `admin`. The
password for `admin` is supplied via the `-adminPass` flag when running the
Controller CE service. The `admin` password is stored in-memory and never
written to disk. The `-adminPass` must be passed on the command line every time
the Controller CE service is started.

## HTTP API: Transport Security

It is __highly encouraged__ that a TLS-terminating proxy be deployed in front of
the Controller HTTP API server to provide encrypted transport of payloads for
Controller API users.

## Service Networking

The following table describes the internal and external networking of the
Controller CE services.

### External Services

The following service(s) are expected to be externally routable.

| Service  | Protocol     | Port  | Direction |
| -------- | ------------ | ----  | --------- |
| Web UI   | TCP          | 3000  | INPUT     |
| CUPS UI  | TCP          | 3010  | INPUT     |
| HTTP API | TCP          | 8080  | INPUT     |
| gRPC API | TCP (TLS)    | 8081  | INPUT     |
| Syslog   | TCP (TLS)    | 6514  | INPUT     |
| StatsD   | TCP (TLS)    | 8125  | INPUT     |
| ELA API  | TCP (TLS)    | 42101 | OUTPUT    |
| EVA API  | TCP (TLS)    | 42102 | OUTPUT    |

### Internal Services

The following service(s) are used for internal Controller CE operations and
__should never be exposed publicly__ on the host. Inbound and outbound access to
these services should be completely restricted by a firewall with the exception
of interprocess communication within the Controller host.

| Service | Protocol | Port |
| ------- | -------- | ---- |
| MySQL   | TCP      | 8083 |

## Third Party Dependencies

The Controller CE uses language specific package managers to manage its direct
and indirect dependencies. As dependencies are added, an entry is automatically
created in the project's dependency "lock" file containing the cryptographic
checksum of the dependency's content along with versioning information pertinent
to attaining reproducible builds.

### API Server (Go)

The API server uses [Go modules](https://github.com/golang/go/wiki/Modules) to
manage its Go dependencies. This project's dependency
[go.sum](https://github.com/smartedgemec/controller-ce/blob/master/go.sum) lock
file is located in the project's root directory and will always contain the
latest list of third-party Go dependencies.

### UI Client (JavaScript)

The UI client uses [Yarn](https://yarnpkg.com/) to manage its JavaScript
dependencies. This project's dependency
[yarn.lock](https://github.com/smartedgemec/controller-ce/blob/master/ui/yarn.lock)
lock file is located in the project's `ui` directory and will always contain the
latest list of third-party JavaScript dependencies.

## Example Security Scripts

An example security script (TODO) has been provided. The script is not
exhaustive but is merely intended to demonstrate a possible approach to securing
the Controller CE host.
