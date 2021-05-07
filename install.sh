#!/usr/bin/env bash
#
# DahBox Installer

set -o pipefail

if [ -z "$HOME" ]; then
  HOME=$(awk -F : '/^'"$(id -un)"':/ {print $6}' /etc/passwd)
fi

if [ -z "$SHELL" ]; then
  SHELL=$(awk -F : '/^'"$(id -un)"':/ {print $7}' /etc/passwd)
fi

DAHBOX_HOME="$HOME/.local/share/dahbox"

function echoerr() {
  echo "$@" 1>&2
}

function check_os() {
  eval "OS_$(grep ID /etc/os-release)"
  if [ "$OS_ID" == "fedora" ]; then
    echo "--- Installing on Fedora"
  else
    echoerr "This installer is only supported fedora"
    exit 1
  fi
}

function missing_dependencies() {
  if [ "$OS_ID" == "fedora" ]; then
    echo "sudo dnf install -y podman buildah"
  fi
}

function check_dependencies() {
  if ! command -v podman >/dev/null 2>&1; then
    echoerr "Podman is missing"
    missing_dependencies
    exit 1
  elif ! command -v buildah >/dev/null 2>&1; then
    echoerr "Buildah is missing"
    missing_dependencies
    exit 1
  fi
}

function dahbox_dir() {
  echoerr "Create directory $DAHBOX_HOME"
  mkdir -p "$DAHBOX_HOME"



  PROFILE_FILE="$HOME/.profile"
  if [[ "$SHELL" == "/bin/bash" ]]; then
    PROFILE_FILE="$HOME/.bashrc"
  elif [[ "$SHELL" == "/bin/zsh" ]]; then
    PROFILE_FILE="$HOME/.zshrc"
  fi

  if [[ ! ":$PATH:" == *":$DAHBOX_HOME:"* ]]; then
    echoerr "Your path is missing $DAHBOX_HOME."
    echoerr "We will add it into $PROFILE_FILE"
    echo "export PATH=\$PATH:$DAHBOX_HOME" >> "$PROFILE_FILE"
  fi



}

function dahbox_script() {
  curl -sSL -o "$DAHBOX_HOME/dahbox" https://jeci.fr/dahbox
  chmod +x "$DAHBOX_HOME/dahbox"
}

check_os
check_dependencies
dahbox_dir
dahbox_script

echo "
Buildah is install in $DAHBOX_HOME
You have to restart your shell to update the \$PATH
"
