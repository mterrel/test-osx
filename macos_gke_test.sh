#!/usr/bin/env bash

set -o errexit
set -x

GKETEMP=$(mktemp -d -t gcloud)
pushd $GKETEMP

export MYPROJECTID=macos-gke-$(echo $RANDOM$RANDOM | tr '[0-9]' '[a-z]')
gcloud projects create --set-as-default $MYPROJECTID

DEBUG=clitest:output,clitest:commands markdown-clitest blog/2020-01-10-simple-hosting-react-app-on-google-cloud.md
