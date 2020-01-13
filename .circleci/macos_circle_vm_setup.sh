#!/usr/bin/env bash

set -o errexit
set -x

# Docker desktop after 31259 refuses to install using root
DOCKER_URL=https://download.docker.com/mac/stable/31259/Docker.dmg
curl -O -sSL $DOCKER_URL
open -W Docker.dmg && cp -r /Volumes/Docker/Docker.app /Applications

sudo /Applications/Docker.app/Contents/MacOS/Docker --quit-after-install --unattended

# Start Docker running and then work on doing the rest of the setup while
# Docker starts up
nohup /Applications/Docker.app/Contents/MacOS/Docker --unattended &

npm install -g yarn markdown-clitest

while ! docker ps 2>/dev/null ; do
  sleep 5
  echo "Waiting for docker to come up: $(date)"
done
