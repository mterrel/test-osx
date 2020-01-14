#!/usr/bin/env bash

set -o errexit
set -x

curl -o - https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-276.0.0-darwin-x86_64.tar.gz | tar -xf-
./google-cloud-sdk/install.sh -q
. ./google-cloud-sdk/path.bash.inc
echo "$GOOGLE_SERVICE_KEY" | gcloud auth activate-service-account --key-file=-
gcloud auth list
