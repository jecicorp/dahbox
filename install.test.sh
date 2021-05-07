#!/usr/bin/env bash
#
# DahBox Installer - Test Programm

set -x

TARGET_VERSION=beta

sudo setsebool -P daemons_use_tty 1


_runAsRoot() {
  sudo systemd-run -M "$1" -t /bin/bash -c "$2"
}
_runAsTest() {
  sudo systemd-run -M "$1" --uid 1000 -t /bin/bash -l -c "$2"
}

_copyTo() {
  sudo machinectl copy-to "$@"
}

_testFedora() {
  MACHINE_NAME=$1
  MACHINE_SOURCE=$2

  sudo machinectl pull-raw --verify=no "$MACHINE_SOURCE" "$MACHINE_NAME"

  sudo nohup systemd-nspawn -M "$MACHINE_NAME" \
  --system-call-filter="@keyring" \
  -b --console=read-only &

  ( tail -f -n0 nohup.out & ) | grep -q "localhost login:"

  _runAsRoot "$MACHINE_NAME" 'dnf install -y podman buildah '
  _runAsRoot "$MACHINE_NAME" 'dnf reinstall -y shadow-utils'
  _runAsRoot "$MACHINE_NAME" 'podman info'
  _runAsRoot "$MACHINE_NAME" 'adduser test'

  _runAsRoot "$MACHINE_NAME" 'rm -f /home/test/install.sh'
  _copyTo "$MACHINE_NAME" install.sh /home/test/install.sh

  _runAsRoot "$MACHINE_NAME" 'loginctl enable-linger 1000'
  _runAsTest "$MACHINE_NAME" '/home/test/install.sh'
  _runAsTest "$MACHINE_NAME" 'dahbox version' | grep -q "$TARGET_VERSION"
  _runAsTest "$MACHINE_NAME" 'dahbox create shellcheck shellcheck'
  _runAsTest "$MACHINE_NAME" 'shellcheck ~/.local/share/dahbox/dahbox'
  _runAsTest "$MACHINE_NAME" 'dahbox list'

  sudo machinectl poweroff "$MACHINE_NAME"
  sudo machinectl remove "$MACHINE_NAME"
}

testFedora() {
  echo "-== Tests Fedora ==-"
  _testFedora Fedora-Cloud-Base-33-1.2.x86-64 \
    https://download.fedoraproject.org/pub/fedora/linux/releases/33/Cloud/x86_64/images/Fedora-Cloud-Base-33-1.2.x86_64.raw.xz

}


_testUbuntu() {
  MACHINE_NAME=$1
  MACHINE_SOURCE=$2

  sudo machinectl pull-tar "$MACHINE_SOURCE" "$MACHINE_NAME"

  sudo nohup systemd-nspawn -M "$MACHINE_NAME" \
  --system-call-filter="@keyring" \
  -b --console=read-only > "nohup.$MACHINE_NAME" &

  ( sudo tail -f "nohup.$MACHINE_NAME" & ) | grep -q "Ubuntu 20.04.2 LTS ubuntu console"


  _runAsRoot "$MACHINE_NAME" 'echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list'
  _runAsRoot "$MACHINE_NAME" 'curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/devel_kubic_libcontainers_stable.gpg > /dev/null'
  _runAsRoot "$MACHINE_NAME" 'apt update'
  _runAsRoot "$MACHINE_NAME" 'apt install -y podman buildah '

  _runAsRoot "$MACHINE_NAME" 'podman info'
  _runAsRoot "$MACHINE_NAME" 'useradd -m test'

  _runAsRoot "$MACHINE_NAME" 'rm -f /home/test/install.sh'
  _copyTo "$MACHINE_NAME" install.sh /home/test/install.sh

  _runAsRoot "$MACHINE_NAME" 'loginctl enable-linger 1000'
  _runAsTest "$MACHINE_NAME" '/home/test/install.sh'
  _runAsTest "$MACHINE_NAME" 'dahbox version' | grep -q "$TARGET_VERSION"
  _runAsTest "$MACHINE_NAME" 'dahbox create shellcheck shellcheck'
  _runAsTest "$MACHINE_NAME" 'shellcheck ~/.local/share/dahbox/dahbox'
  _runAsTest "$MACHINE_NAME" 'dahbox list'

  sudo machinectl poweroff "$MACHINE_NAME"
  sudo machinectl remove "$MACHINE_NAME"
}

testUbuntu() {
  _testUbuntu focal-server-cloudimg-amd64 \
    https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-root.tar.xz
}

testFedora
testUbuntu
