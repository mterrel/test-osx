---
id: requirements
title: "Installing & Updating Requirements for Adapt"
---
<!-- DOCTOC SKIP -->

## NodeJS with npm

You'll need to have [NodeJS](https://nodejs.org) installed.
Adapt requires at least NodeJS version 10 and is currently tested on NodeJS versions 10 (LTS), 12 (LTS), and 13.

Note that the default version of NodeJS that is installed by your system's package manager (apt, yum, etc.) may be an older version of NodeJS.

To check your currently installed version of NodeJS:
```console
node --version
```

If you need to install a different version of NodeJS, we recommend using [nvm](https://github.com/creationix/nvm), which allows you to manage multiple versions of NodeJS. For other installation and updating options, take a look at the [NodeJS documentation](https://nodejs.org/en/download/).

### Install nvm
The [nvm](https://github.com/creationix/nvm) tool makes it easy to to install and manage one or multiple versions of NodeJS. This guide summarizes the steps to install nvm and NodeJS 10 for `bash` users. For more detailed instructions on nvm, including usage with other shells, see [the nvm README](https://github.com/creationix/nvm).

This installs nvm for only your user, not system-wide.
```console
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
```
When nvm is installed, it adds its setup script to your .bashrc, which will
take effect on your next login. To start using nvm immediately:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

### Set up NodeJS 10

```console
nvm install 10
nvm use 10
```
NodeJS 10 should now be installed and activated as your current version of
node. To verify:
```console
node --version
```
You should see output similar to:
```console
v10.15.1
```
