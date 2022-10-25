# test-go-container-images

During various experiences with container image vulnerability scanners, I've found their accuracy to be... well... varied. Especially when you add Go binaries to the mix.

This repository contains the sources, configurations, and build scripts for a collection of Go binaries and associated container images intended for testing container vulnerability scanners.

They are intended to help perform some basic accuracy tests for any given scanner, by exposing a small and specific set of vulnerabilities for each Go binary and associated container image.

## Why The Variance?

There are various possible factors, and I'm not an expert, but some observations from experience:

 - Scanner support for container images appears to vary, with some seemingly more capable of truly inspecting a container image while others rely on data associated with known base images, known vulnerable layers, package management tooling, etc.

 - Scanner support for binaries within a container filesystem appears to vary, with some focusing only on known-vulnerable layers while others look at individual files within those layers.

 - Scanner support for scratch images appears to vary, with some scanners which depend on container/shell execution or on package management tools/metadata being available not executing correctly.

 - Scanner support for Golang varies, fullstop.

 - Scanner deployment and configuration can also affect results. Running scans against a container registry, vs deployed container images, vs the filesystem on which the container images are stored can cause variance in results.

## Test Images / Binaries

### hello-*

"Hello world" Go binary with no known vulnerabilities (the code has minimal function calls, and no dependencies).

Tests a scanner's ability to complete a clean baseline scan against a benign Go binary.

Scanners should probably not be identifying any vulnerabilities.

### hello2-*

Same as above, but with 2 copies of the benign Go binary.

Tests a scanner's behavior regarding duplication of content / issues.

Scanners may report a varying number of vulnerabilities, depending on how they handle this.

### gnutls-*

"Hello world" Go binary with no known vulnerabilities, as above.

However, package management has been used to install an outdated gnutls package that is known vulnerable to CVE-2022-2509.

Scanners should probably be identifying multiple vulnerabilities.

### joinpath-*

Go binary which includes a call to url.JoinPath, succeptible to CVE-2022-32190 (https://groups.google.com/g/golang-announce/c/x49AQzIVX-s) _only in Go 1.19.0_ (that's when the function was introduced, and the vulnerability was remediated in 1.19.1).

Tests a scanner's ability to detect vulnerabilities associated with the version of Go used to build a Go binary.

Scanners should probably be identifying 1 vulnerability _when the binary is built with Go 1.19.0_, and 0 otherwise.

### jwtgo-*

Go binary which depends on https://github.com/dgrijalva/jwt-go, succeptible to CVE-2020-26160 (https://github.com/dgrijalva/jwt-go/pull/426).

Tests a scanner's ability to detect vulnerablities associated with a Go dependency for a Go binary.

Scanners should probably be identifying 1 vulnerability (maybe more depending on how they report vulnerabilities from different data sources; as noted at https://github.com/golang/vulndb/blob/master/data/osv/GO-2020-0017.json, there's another GHSA identifier that may be flagged and/or double-counted).

### dockersdk-*

Go binary which depends on the Docker SDK available from https://github.com/docker/docker. The 20.10.10 version of this Go SDK does not have any known CVEs, but the Docker release with the same version number does.

Tests a scanner's (and underlying datasource's) ability to distinguish between released product (Docker binary) and similarly-named Go module (no known vulnerabilities).

Scanners should probably not be identifying any vulnerabilities.

## Test Case Naming

Generally, the pattern is `[testcase]-[goversion]-[baseimage]`:

 - `[testcase]` should be one of those listed above.

 - `[goversion]` may just be `go`, in which case we're floating on `latest` or equivalent. In the cases where the test is pinned to a specific, probably older, Go version then it'll be included in the string.

 - `[baseimage]` is currently one of `alpine` or `scratch`, but may expand to cover over distributions or specific base image versions.

## Scanning And Results

The `manage.sh` script includes several commands for running a few common vulnerability scanners, saving results as JSON output.

The `results.sh` script has some (very) basic jq-based parsing for extacting vulnerability counts from vulnerability scanner output. (Very basic, needs some work!)

## Usage

If you want to scan the existing images, they're pullable from `ghcr.io/chair6/test-go-container-image`.

Otherwise, clone / modify and use `manage.sh` to build your own images as needed.
