# Dahbox

Simple integration of [podman](https://podman.io/) and [buildah](https://github.com/containers/buildah/). Run any application in rootless container easily.

## Installation

First you need [buildah](https://github.com/containers/buildah/blob/master/install.md) and [podman](https://podman.io/getting-started/installation#linux-distributions).

Then copy `dahbox` in a PATH directory, who you are write permission. For example `$HOME/.local/bin`. Then grant executable permission to the script.

### Quick setup on Fedora

``` bash
sudo dnf install podman buildah
curl -o $HOME/.local/bin/dahbox https://gitlab.beezim.fr/jeci/dahbox/-/raw/master/dahbox
chmod +x $HOME/.local/bin/dahbox
```

## Usage

First create a script using `dahbox create`. The script will be create next to dahbox script (in `$HOME/.local/bin/`), so it become available in your PATH.

``` bash
dahbox create shellcheck shellcheck

whereis shellcheck
  shellcheck: /home/jeci/.local/bin/shellcheck
```

Then call the script like any other program. On first run, the container is build then run.

``` bash
shellcheck --help
```

## Limit

* the container is rootless (thanks to podman) don't try to use `sudo`
* the container is bind to you `$HOME`, so don't try to use it on file that is outside of your home directory

## Maintenance

DahBox will create container, so you must clean up images to free space. If you want to update a software, juste remove the corresponding image.

``` bash
podman image ls --filter 'reference=localhost/dahbox/'
podman image rm dahbox/shellcheck
```

You can also remove all image made by DahBox:

``` bash
dahbox prune
```

## How to create boxes


### Box based on alpine image

Without parameters, DahBox create a container based on alpine and install package in parameters (`apk add`)

``` bash
#dahbox create [name]    [packages]
dahbox create shellcheck shellcheck
shellcheck --help
shellcheck $HOME/.local/bin/dahbox
```

Box to use `bash` in Alpine :

``` bash
dahbox create alpine --command bash bash
alpine
```

Box to use `mongo` version 3.9 :

``` bash
dahbox create mongo --tag 3.9 mongodb
mongo
```


### Box based on node image

Simple box with node to use npm. Without `--command` parameter, the container start with the program of the container name.

Here image `node:current-buster` is run with `npm`.

``` bash
dahbox create npm --from node --tag current-buster
# is equivalent to
dahbox create npm --from node --tag current-buster --command npm

npm version
```

You can add a list of software to install with `npm install`

``` bash
dahbox create ng --from node --tag current-buster @angular/cli
# is equivalent to
dahbox create ng --from node --tag current-buster --command ng --install-cmd "npm install -g @angular/cli"

ng version
```


### Box based on maven image

It's a more complexe box, here we choose the version of maven to use `3-openjdk-11` and define an env. This permit to use `.m2` maven local repository that is outside of container.

``` bash
dahbox create mvn --from maven --tag 3-openjdk-11 -e USER_HOME_DIR=\$HOME/.m2 --command "mvn -Duser.home=\$HOME/.m2"
mvn --version
```


## Licensing

DahBox is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version

Copyright 2020 Jérémie Lesage, Jeci <https://jeci.fr/>
