```text
SPDX-License-Identifier: Apache-2.0
Copyright (c) 2019 Intel Corporation
```

# Cryptography, TLS & PKI (Public Key Infrastructure)
## Overview of PKI architecture
In the community edition, we've tried to strike a balance between encouraging best security practices and reducing contribution learning curve.

That's why for PKI, we've aimed for a more minimalistic approach than an enterprise-grade platform would adopt. If you're new to PKI, even our minimal implementation may feel a bit intimidating (talk about an understatement.)

This guide should help explain some high level PKI concepts that we chose to adopt.

## Design of the architecture
We want the different components of our platform to securely communicate. We had to consider the tradeoffs between the different ways you can provide authentication:

- No authentication
    - Pros: Zero implementation changes
    - Cons: Transport of payloads are sent in the clear
- Token / pre-shared key authentication
    - Pros: More familiar to developers, easy to implement
    - Cons: Requires pre-sharing credentials and is symmetric & online
- Public key authentication
    - Pros: Asymmetric and offline
    - Cons: Slightly more complicated, no metadata besides the key itself
- Certificate authentication
    - Pros: Asymmetric and offline, plus contains metadata about peers
    - Cons: Tough to implement correctly, requires domain knowledge

What we ended up settling on was the following:

- Certificate authentication for...
    - Controller <-> Node communication
    - Node <-> App communication
- Token authentication for...
    - User <-> Controller communication

This is a nice middleground, where the internal components leverage the advantages of certificate authentication, but external parties are exposed to token auth which may be more familiar. This guide focuses on the certificate authentication.

## Creation of a trust chain
In order to reduce complexity in the trust chain, we decided to do the following:
- Sign all certificates (client, server, etc.) from a single root certificate authority (CA)
- Issue all certificates a very long validity period
- Encourage web certificate encryption using existing solutions like NGINX with certbot

The trust chain is as flat as possible. You'll find that we generate just one (1) self-signed root CA, and sign everything directly from that. Generally, this isn't a scalable solution, but for an open source project, this is plenty sufficient. It looks like the following:

```
                 [ Root CA ]
                     |
    |----------------|----------------|
[ Node Cert ] [ Controller Cert ] [ Other Certs ]
```

This means that client and server certificates that need to communicate within the platform are all signed from a singular root CA. This allows us to use the assymetric benefits of PKI without forcing too much on the implementation. The great news is that most languages (specifically Go) have great HTTP and gRPC client and server support for certificate authentication.

## Identification of CSRs from Nodes (Appliances)
The root CA is maintained in the Controller, so signing the Controller certificate is easy. For signing the Node certificates, there is a gRPC endpoint where the Node provides its identity as a certificate signing request (CSR) and gets back a certificate.

### Adding the Node to the Controller
When a user wants a Node to become activated in the Controller, they should add it to the Controller with the REST API. Without the Node in the Controller, the gRPC endpoint will reject the CSR.

### Figuring out the Node's identity (serial)
So how does the user know what to input when they're adding the Node to the Controller? Since the Node generates its CSR when it is initialized, a user should look up the "serial" from the Node after it is initialized. They then should navigate to the Controller and add the Node by its serial. This same "serial" is checked against the gRPC request from the Node, and the Node is issued a certificate if there's a match.

### Computing the Node's identity (serial)
We want to give the user something relatively compact to input into the Controller when adding the Node. Normally, the public key of the Node would be a great candidate for an identifier, since it's unique. Unfortunately, public keys are not super portable as plain text (they're better in TLS transport). As such, we perform a computation of the public key of the Node to generate the Node's "serial." The following is the computation performed:

1. Compute the md5 sum of the raw DER-encoded public key
2. Compute the base 64 URL-encoding (_without padding_) of the results from above

This results in a URL-friendly serial identifier of the node. Both the Node and the Controller need to use the same computation so that it can check for a match.

Having the "serial" derived from the Node's public key has some positive side effects:
- It does not require the Node to submit the serial plainly in the CSR (such as in the CSR subject). This means we can basically ignore all fields in a CSR besides the public key
- If a bad actor somehow spoofed a CSR, they wouldn't be able to do much with the resulting certificate since they don't own the private key for the public key we authorized
