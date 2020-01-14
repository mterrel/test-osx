#!/usr/bin/env bash

set -o errexit
set -x

# Add gcloud to path
. ./google-cloud-sdk/path.bash.inc

#export MYPROJECTID=macos-gke-$(echo $RANDOM$RANDOM | tr '[0-9]' '[a-z]')
#gcloud projects create --set-as-default $MYPROJECTID --organization 170061401321
export MYPROJECTID=adapt-testing

npm install -g yarn markdown-clitest

DEBUG=clitest:output,clitest:commands markdown-clitest blog/2020-01-10-simple-hosting-react-app-on-google-cloud.md
