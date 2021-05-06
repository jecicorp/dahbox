#!/usr/bin/env bash
#
# DahBox Installer

set -o pipefail

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

  USRLGN=$(grep -E "^$(id -un)" /etc/passwd)

  PROFILE_FILE="$HOME/.profile"
  if [[ "$USRLGN" == *"/bin/bash" ]]; then
    PROFILE_FILE="$HOME/.BASH_SOURCE"
  elif [[ "$USRLGN" == *"/bin/zsh" ]]; then
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
