# Dahbox

Simple integration of [podman](https://podman.io/) and [buildah](https://github.com/containers/buildah/). Run any application in rootless container easily.

## Installation

First you need [buildah](https://github.com/containers/buildah/blob/master/install.md) and [podman](https://podman.io/getting-started/installation#linux-distributions).

Then copy `dahbox` in a PATH directory, who you are write permission. For example `$HOME/.local/bin`. Then grant executable permission to the script.

For exemple:

``` bash
sudo dnf install podman buildah
curl -o $HOME/.local/bin/dahbox https://gitlab.beezim.fr/jeci/dahbox/-/raw/master/dahbox
chmod +x $HOME/.local/bin/dahbox
```

## Usage

First, you create a script using `dahbox create`. The script will be create next to dahbox script (in `$HOME/.local/bin/`), so it become available in your PATH.

Then you call the script like any other program. At first run the container will be build.

## Warning

* the container is rootless (thanks to podman) don't try to use `sudo`
* the container is bind to you `$HOME`, so donc try to use it and file that is outside of your home directory

## Maintenance

DahBox will create container, so you must clean up images to free space.

``` bash
podman image ls
podman image prune
```

If you want to update a software, juste remove the corresponding image.

``` bash
podman image rm dahbox/shellcheck
```

## Examples

* A box based on alpine with shellcheck

``` bash
dahbox create shellcheck shellcheck
shellcheck --help
shellcheck $HOME/.local/bin/dahbox
```

* npm without installing Node or npm

``` bash
dahbox create npm --from node --tag current-buster
npm version
```


* Angular cli, without installing Node or npm

``` bash
dahbox create ng --from node --tag current-buster @angular/cli
ng version
```

* Maven without installing java

``` bash
dahbox create mvn --from maven --tag 3-openjdk-11
mvn --version
```

* Bash in Alpine

``` bash
dahbox create alpine --command bash bash
alpine
```

* Mongo

``` bash
dahbox create mongo --tag 3.9 mongodb
mongo
```

## Licensing

DahBox is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version

Copyright 2020 Jérémie Lesage, Jeci <https://jeci.fr/>
