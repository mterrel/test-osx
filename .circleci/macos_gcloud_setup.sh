#!/usr/bin/env bash

set -o errexit
set -x

GCTEMP=$(mktemp -d -t gcloud)

python -V
pushd $GCTEMP
curl -o gcloud.tgz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-276.0.0-darwin-x86_64.tar.gz
tar -xf gcloud.tgz
./google-cloud-sdk/install.sh -q
. ./google-cloud-sdk/path.bash.inc
echo "$GCLOUD_SERVICE_KEY" > key.json
gcloud auth activate-service-account --key-file=key.json
popd
gcloud auth list
