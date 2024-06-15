
# OpenShift Ingress MTLS Use Case Demonstration

This project demonstrates the OpenShift Ingress MTLS use-case for validating
client certificates generated from a private root certificate authority before
allowing access to a web service.

## Configure MTLS Ingress Controller

Follow these procedures to configure your cluster for this demonstration:

1. Bring up an OpenShift cluster >= v4.14.

2. Login to the OpenShift cluster: `oc login ...`

3. Apply the configurations in this directory: `oc apply -k .`

# Client Certificate Validation Scenarios

There are three client validation scenarios. The MTLS ingress controller has
been configured to allow client certificates that match the following subject:
`/C=US/ST=Washington/L=Mukilteo/O=Sean\\ Vaughan\\ Systems/OU=Platform`.

## Setup: Port Forward MTLS Service

Since the MTLS ingress controller likely isn't configured with your DNS domain,
and there could be a firewall blocking access to cluster node ports, we'll use
port-forwarding to connect to the MTLS ingress router.

Run the following command to forward the MTLS ingress service port to your
localhost, and keep running in the background:

    oc port-forward -n openshift-ingress svc/router-nodeport-mtls 32680:443 &

You should see output like:

    Forwarding from 127.0.0.1:32680 -> 443
    Forwarding from [::1]:32680 -> 443

## Scenario 1: Valid Client Certificate

The client1 certificate information can be shown with the `openssl x509 -text
-in client1.crt -noout`. The subject of the client1 certificate is `C = US, ST =
Washington, L = Mukilteo, O = Sean Vaughan Systems, OU = Platform, CN = Sean
Vaughan, emailAddress = sean@vaughan.cc`. Since the Country, STate,
municipaLity, and Organization match the configured pattern in the ingress
controller, the client1 certificate is trusted.

To demonstrate that the client1 certificate is authorized to read from the web
service, run the following `curl` command:

    curl --cacert ca.crt --cert client1.crt --key client1.key -vvvv --connect-to sample-app-mtls.mtls.k8s-sno.vaughan.cc:443:localhost:32680 https://sample-app-mtls.mtls.k8s-sno.vaughan.cc

Verify the output includes the default web content from Red Hat httpd:

    * Connecting to hostname: localhost
    * Connecting to port: 32680
    *   Trying 192.168.86.24:32680...
    * TCP_NODELAY set
    * Connected to localhost (192.168.86.24) port 32680 (#0)
    * ALPN, offering h2
    * ALPN, offering http/1.1
    * successfully set certificate verify locations:
    *   CAfile: ca.crt
    CApath: /etc/ssl/certs
    * TLSv1.3 (OUT), TLS handshake, Client hello (1):
    * TLSv1.3 (IN), TLS handshake, Server hello (2):
    * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
    * TLSv1.3 (IN), TLS handshake, Request CERT (13):
    * TLSv1.3 (IN), TLS handshake, Certificate (11):
    * TLSv1.3 (IN), TLS handshake, CERT verify (15):
    * TLSv1.3 (IN), TLS handshake, Finished (20):
    * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
    * TLSv1.3 (OUT), TLS handshake, Certificate (11):
    * TLSv1.3 (OUT), TLS handshake, CERT verify (15):
    * TLSv1.3 (OUT), TLS handshake, Finished (20):
    * SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
    * ALPN, server did not agree to a protocol
    * Server certificate:
    *  subject: C=US; ST=Washington; L=Mukilteo; O=Sean Vaughan Systems; OU=Platform; CN=mtls.k8s-sno.vaughan.cc
    *  start date: Jun  6 18:31:12 2024 GMT
    *  expire date: Mar  3 18:31:12 2027 GMT
    *  subjectAltName: host "sample-app-mtls.mtls.k8s-sno.vaughan.cc" matched cert's "*.mtls.k8s-sno.vaughan.cc"
    *  issuer: C=US; ST=Washington; L=Mukilteo; O=Sean Vaughan Systems; OU=Platform; CN=root.vaughan.cc; emailAddress=sean@vaughan.cc
    *  SSL certificate verify ok.
    > GET / HTTP/1.1
    > Host: sample-app-mtls.mtls.k8s-sno.vaughan.cc
    > User-Agent: curl/7.68.0
    > Accept: */*
    > 
    * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
    * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
    * old SSL session ID is stale, removing
    * Mark bundle as not supporting multiuse
    < HTTP/1.1 403 Forbidden
    < date: Fri, 14 Jun 2024 20:16:05 GMT
    < server: Apache/2.4.57 (Red Hat Enterprise Linux) OpenSSL/3.0.7
    < last-modified: Mon, 09 Aug 2021 11:43:42 GMT
    < etag: "1715-5c91ee59c9780"
    < accept-ranges: bytes
    < content-length: 5909
    < content-type: text/html; charset=UTF-8
    < set-cookie: 6fb4ec2e216266fa43f25e7da4e4f30e=2ae2b81a49802a17840ccd344d3ffe61; path=/; HttpOnly; Secure; SameSite=None
    < 
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
            <head>
                    <title>Test Page for the HTTP Server on Red Hat Enterprise Linux</title>
    .
    .
    .

## Scenario 2: Client Certificate Doesn't Meet Criteria

The subject of the client2 certificate is `C = US, ST =
Washington, L = Mukilteo, O = Sean Vaughan Systems, OU = Administration, CN =
Marlo Vaughan, emailAddress = marlo@vaughan.cc`. Since the Organization is
`Administration` instead of `Platform`, the client2 certificate does not match
the configured pattern in the ingress controller, and the client2 certificate is
*not* trusted.

To demonstrate that the client2 certificate is authorized to read from the web
service, run the following `curl` command:

    curl --cacert ca.crt --cert client2.crt --key client2.key -vvvv --connect-to sample-app-mtls.mtls.k8s-sno.vaughan.cc:443:localhost:32680 https://sample-app-mtls.mtls.k8s-sno.vaughan.cc

Verify the output shows the request is not permitted:

    * Connecting to hostname: localhost
    * Connecting to port: 32680
    *   Trying 192.168.86.24:32680...
    * TCP_NODELAY set
    * Connected to localhost (192.168.86.24) port 32680 (#0)
    * ALPN, offering h2
    * ALPN, offering http/1.1
    * successfully set certificate verify locations:
    *   CAfile: ca.crt
    CApath: /etc/ssl/certs
    * TLSv1.3 (OUT), TLS handshake, Client hello (1):
    * TLSv1.3 (IN), TLS handshake, Server hello (2):
    * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
    * TLSv1.3 (IN), TLS handshake, Request CERT (13):
    * TLSv1.3 (IN), TLS handshake, Certificate (11):
    * TLSv1.3 (IN), TLS handshake, CERT verify (15):
    * TLSv1.3 (IN), TLS handshake, Finished (20):
    * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
    * TLSv1.3 (OUT), TLS handshake, Certificate (11):
    * TLSv1.3 (OUT), TLS handshake, CERT verify (15):
    * TLSv1.3 (OUT), TLS handshake, Finished (20):
    * SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
    * ALPN, server did not agree to a protocol
    * Server certificate:
    *  subject: C=US; ST=Washington; L=Mukilteo; O=Sean Vaughan Systems; OU=Platform; CN=mtls.k8s-sno.vaughan.cc
    *  start date: Jun  6 18:31:12 2024 GMT
    *  expire date: Mar  3 18:31:12 2027 GMT
    *  subjectAltName: host "sample-app-mtls.mtls.k8s-sno.vaughan.cc" matched cert's "*.mtls.k8s-sno.vaughan.cc"
    *  issuer: C=US; ST=Washington; L=Mukilteo; O=Sean Vaughan Systems; OU=Platform; CN=root.vaughan.cc; emailAddress=sean@vaughan.cc
    *  SSL certificate verify ok.
    > GET / HTTP/1.1
    > Host: sample-app-mtls.mtls.k8s-sno.vaughan.cc
    > User-Agent: curl/7.68.0
    > Accept: */*
    > 
    * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
    * TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
    * old SSL session ID is stale, removing
    * Mark bundle as not supporting multiuse
    < HTTP/1.1 403 Forbidden
    < content-length: 93
    < cache-control: no-cache
    < content-type: text/html
    < 
    <html><body><h1>403 Forbidden</h1>
    Request forbidden by administrative rules.
    </body></html>
    * Connection #0 to host localhost left intact

## Scenario 3: Expired Client Certificate

The subject of the client3 certificate is `C = US, ST = Washington, L =
Mukilteo, O = Sean Vaughan Systems, OU = Platform, CN = Gus Vaughan,
emailAddress = gus@vaughan.cc`. In this scenario, the subject matches, but the
certificate has expired, therefore the client3 certificate is *not* trusted.

To demonstrate that the client3 certificate is not authorized to read from the
web service, run the following `curl` command:

    curl --cacert ca.crt --cert client3.crt --key client3.key -vvvv --connect-to sample-app-mtls.mtls.k8s-sno.vaughan.cc:443:localhost:32680 https://sample-app-mtls.mtls.k8s-sno.vaughan.cc

Note at the bottom that a TLS connection is not negotiated because the client certificate has expired (`alert certificate expired` in the last line):

    * Connecting to hostname: localhost
    * Connecting to port: 32680
    *   Trying 192.168.86.24:32680...
    * TCP_NODELAY set
    * Connected to localhost (192.168.86.24) port 32680 (#0)
    * ALPN, offering h2
    * ALPN, offering http/1.1
    * successfully set certificate verify locations:
    *   CAfile: ca.crt
    CApath: /etc/ssl/certs
    * TLSv1.3 (OUT), TLS handshake, Client hello (1):
    * TLSv1.3 (IN), TLS handshake, Server hello (2):
    * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
    * TLSv1.3 (IN), TLS handshake, Request CERT (13):
    * TLSv1.3 (IN), TLS handshake, Certificate (11):
    * TLSv1.3 (IN), TLS handshake, CERT verify (15):
    * TLSv1.3 (IN), TLS handshake, Finished (20):
    * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
    * TLSv1.3 (OUT), TLS handshake, Certificate (11):
    * TLSv1.3 (OUT), TLS handshake, CERT verify (15):
    * TLSv1.3 (OUT), TLS handshake, Finished (20):
    * SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
    * ALPN, server did not agree to a protocol
    * Server certificate:
    *  subject: C=US; ST=Washington; L=Mukilteo; O=Sean Vaughan Systems; OU=Platform; CN=mtls.k8s-sno.vaughan.cc
    *  start date: Jun  6 18:31:12 2024 GMT
    *  expire date: Mar  3 18:31:12 2027 GMT
    *  subjectAltName: host "sample-app-mtls.mtls.k8s-sno.vaughan.cc" matched cert's "*.mtls.k8s-sno.vaughan.cc"
    *  issuer: C=US; ST=Washington; L=Mukilteo; O=Sean Vaughan Systems; OU=Platform; CN=root.vaughan.cc; emailAddress=sean@vaughan.cc
    *  SSL certificate verify ok.
    > GET / HTTP/1.1
    > Host: sample-app-mtls.mtls.k8s-sno.vaughan.cc
    > User-Agent: curl/7.68.0
    > Accept: */*
    > 
    * TLSv1.3 (IN), TLS alert, certificate expired (557):
    * OpenSSL SSL_read: error:14094415:SSL routines:ssl3_read_bytes:sslv3 alert certificate expired, errno 0
    * Closing connection 0
    curl: (56) OpenSSL SSL_read: error:14094415:SSL routines:ssl3_read_bytes:sslv3 alert certificate expired, errno 0

# Certificate Generation

The `make-ca-and-certs` bash script creates the root ca, server, client1,
client2, and client3 keys, certificate signing requests, and certificates.
