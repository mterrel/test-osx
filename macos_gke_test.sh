#!/usr/bin/env bash

set -o errexit
set -x

# Add gcloud to path
. ./google-cloud-sdk/path.bash.inc

gcloud config set project $MYPROJECTID

npm install -g yarn markdown-clitest

DEBUG=clitest:output,clitest:commands markdown-clitest blog/2020-01-10-simple-hosting-react-app-on-google-cloud.md
