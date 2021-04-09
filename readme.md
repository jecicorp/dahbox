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
dahbox create ng --from node --tag current-buster --command ng --install-cmd "npm install -g" @angular/cli

ng version
```

More complexe example, we fix the node version and add some specific parameter to npm install.

``` bash
dahbox create yo_14 --from node --tag 14.16.0 -e HOME --command "yo --no-insight" --install-cmd "npm install -g --unsafe-perm" yo generator-alfresco-adf-app@4.2.0

yo_14 --help
```

#### Troubleshooting

If you are this problem `Error: EACCES: permission denied, scandir ...` when you execute the command `npm`.
It is possible that SELinux is enforcing mode. Switch in permissive mode `sudo setenforce 0`.


### Box based on maven image

It's a more complexe box, here we choose the version of maven to use `3-openjdk-11` and define an env. This permit to use `.m2` maven local repository that is outside of container.

``` bash
dahbox create mvn --from maven --tag 3-openjdk-11 -e USER_HOME_DIR=\$HOME --command "mvn -Duser.home=\$HOME"
mvn --version
```


### Box based on gradle image

Box with gradle (jdk8) and nodejs

``` bash
dahbox create gradlenode --update --from gradle --tag jdk8 \
  -e "GRADLE_USER_HOME=$HOME/.gradle" \
  --install-init "apt-get update" \
  --install-cmd "apt-get install -y" nodejs npm \
  --command gradle
```

## DirEnv

Ce coolest feature is to use DahBox with [DirEnv](direnv.net/) so you can define box per project.

`dahbox direnv` will init a .dahbox folder and .envrc file to load a local dahbox.

``` bash
mkdir .dahbox
echo "PATH_add $PWD/.dahbox" > .envrc
direnv allow
```

## Debug

To see what DahBox do, you can read scripts generate by DahBox.

``` bash
$ whereis shellcheck
 shellcheck: /home/jeci/.local/bin/shellcheck
$ cat /home/jeci/.local/bin/shellcheck
#!/usr/bin/env bash
# =-=
# =-= DahBox shellcheck =-= #
# =-=

# 1. Check Image
image_id=$(podman image ls --filter 'label=fr.jeci.dahbox.name=shellcheck' --noheading --quiet)

# 2. Build Image
if [[ -z "$image_id" ]]; then
  echo "=-= DahBox Build shellcheck =-="
  container=$(buildah from docker.io/library/alpine:latest)

  buildah run "$container" -- apk add shellcheck

  ## Include some buildtime annotations
  buildah config --label "fr.jeci.dahbox.name=shellcheck" "$container"
  buildah commit "$container" "dahbox/shellcheck"
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
fi

# 3. Run container
podman run --rm \
  -v "$HOME:$HOME" -w "$PWD" \
  -it --net host \
  "dahbox/shellcheck" shellcheck "$@"
```

You can also add `--debug` parameter that `set -x` on bash script (echo each command).

## Licensing

DahBox is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version

Copyright 2020 Jérémie Lesage, Jeci <https://jeci.fr/>
