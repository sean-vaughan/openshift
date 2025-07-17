#!/bin/bash -x

# Fetch the latest sealed-secrets version using GitHub API
KUBESEAL_ARCH="${KUBESEAL_ARCH:-amd64}"
KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/tags | jq -r '.[0].name' | cut -c 2-)

# Check if the version was fetched successfully
if [ -z "$KUBESEAL_VERSION" ]; then
    echo "Failed to fetch the latest KUBESEAL_VERSION"
    exit 1
fi

curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-${KUBESEAL_ARCH}.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-${KUBESEAL_ARCH}.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
