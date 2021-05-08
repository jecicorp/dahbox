# Dahbox

Simple integration of [podman](https://podman.io/) and [buildah](https://github.com/containers/buildah/). Run any application in rootless container easily.

## Installation

First you need [buildah](https://github.com/containers/buildah/blob/master/install.md) and [podman](https://podman.io/getting-started/installation#linux-distributions).

Then copy `dahbox` in a PATH directory, who you are write permission. Then grant executable permission to the script.

The install script create a new directory to host all boxes `$HOME/.local/share/dahbox` and add it tou your `PATH`

``` bash
curl https://jeci.fr/dahbox-install.sh | bash
```

## Usage

First create a box using `dahbox create`. A box is a shell script create in `DAHBOX_HOME` (in `$HOME/.local/share/dahbox`). You must check that this directory is in your PATH.

``` bash
echo $PATH | grep  'share/dahbox'
```

``` bash
dahbox create shellcheck shellcheck

whereis shellcheck
  shellcheck: /home/jeci/.local/share/dahbox/shellcheck
```

Then call the script like any other program. On first run, the container is build then run.

``` bash
shellcheck --help
```
## Boxes per projet

### DirEnv

Ce coolest feature is to use DahBox with [DirEnv](direnv.net/) so you can define box per project.

`dahbox direnv` will init a .dahbox folder and .envrc file to load a local dahbox.

``` bash
mkdir .dahbox
echo "PATH_add $PWD/.dahbox" > .envrc
direnv allow
```

For example you can have a global version of npm :

``` bash
dahbox create npm --from node
  =-= Script created : /home/jlesage/git/js-console/.dahbox/npm =-=

whereis npm                    
  npm: /home/jeci/.local/share/dahbox/npm

npm --version                  
  =-= DahBox Build npm =-=
  ...
  7.11.2
```

And use a specific version of npm for your project.

``` bash
mkdir .dahbox
echo "PATH_add $PWD/.dahbox" > .envrc
direnv allow

dahbox create npm --from node --tag 14-stretch --command npm
  =-= Script created : /home/jlesage/git/js-console/.dahbox/npm =-=

whereis mvn
  mvn: /home/jeci/git/my-cool-project/.dahbox/npm /home/jlesage/.local/share/dahbox/npm

npm --version
  =-= DahBox Build npm =-=
  ...
  6.14.12
```

You can make the same thing without direnv but you need to add the `$PWD/.dahbox` in your path manually


## Limit

* the container is rootless (thanks to podman) don't try to use `sudo`
* the container is bind to you `$HOME`, so don't try to use it on file that is outside of your home directory

## SELinux

Has DahBox bind your home directory in a container, SELinux will block you from reading or writing files. You have many solutions to solve this problem.

1. Deactivate SELinux (`sudo setenforce 0`) it's a bad solution but permit to prov that your problem is cause by selinux
2. Deactivate SELinux for each container `--security-opt label=disable`, less bad but still bad
3. Use generic label `--security-opt label=type:container_runtime_t`
4. Relabelling, by addin `:z` or `:Z` on the mount volume. It's not a good idea because this will relabelling all your home directory. This is slow and may have side effect.
5. Install a SE Module (using udica), it's the best but more complex solution.

In DahBox we use `container_runtime_t` as default solution.

## Maintenance

### Update

The update command will pull (refresh) the source image (`FROM`) of the box and remove the current local image. This will provoque the rebuild of the box.


``` bash
buildah update mvn
  =-= Pull docker.io/library/maven:3-openjdk-8 =-=
  87963037f00b802f79ad30181efa0603f9146519d8175216c57d1dc4f62f8b45
  =-= Remove dahbox mvn =-=
  c47b31b53e62a6fc4f31a9deb6cda8c7f4ed27261a147ea991e094c0d035d130

mvn --version
  =-= DahBox Build mvn =-=
  Getting image source signatures
  ...  
```

### Prune

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
shellcheck $HOME/.local/share/dahbox/dahbox
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
dahbox create gradlenode --from gradle --tag jdk8 \
  -e "GRADLE_USER_HOME=$HOME/.gradle" \
  --install-init "apt-get update" \
  --install-cmd "apt-get install -y" nodejs npm \
  --command gradle
```


## Debug

To see what DahBox do, you can read scripts generate by DahBox.

``` bash
$ whereis shellcheck
 shellcheck: /home/jeci/.local/share/dahbox/shellcheck
$ cat /home/jeci/.local/share/dahbox/shellcheck
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
