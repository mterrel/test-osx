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
echo "$GOOGLE_SERVICE_KEY" | gcloud auth activate-service-account --key-file=-
popd
gcloud auth list
