#!/usr/bin/env bash

set -o errexit
set -x

# Add gcloud to path
. ./google-cloud-sdk/path.bash.inc

if gcloud container clusters describe "${MYPROJECTID}" >& /devnull ; then
    gcloud container clusters delete "${MYPROJECTID}"
fi
