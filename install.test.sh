#!/usr/bin/env bash
#
# DahBox Installer - Test Programm



REGISTRY=docker.io
FROM=fedora
TAG=:34


container=$(buildah from ${REGISTRY}/${FROM}${TAG})
buildah run "$container" -- dnf install -y podman buildah

buildah run "$container" -- adduser test

buildah config --workingdir='/home/test' "$container"
buildah add "$container" install.sh

#buildah run "$container" -- dnf install
buildah run --user test "$container" -- ./install.sh
buildah run --user test "$container" -- bash --login -c 'dahbox version'
buildah rm "$container"
