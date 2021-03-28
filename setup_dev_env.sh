#!/usr/bin/env bash

echo "Starting setup of E.V.A development environment"

function get_current_os() {
  case "$OSTYPE" in
  darwin*)
    echo "OSX - not supported"
    exit 1
    ;;
  linux*)
    os="LINUX"
    ;;
  msys*)
    os="WINDOWS"
    ;;
  *)
    echo "unknown: $OSTYPE - not supported"
    exit 1
    ;;
  esac

  echo "Current OS: $os"
}

function install_pkg_manager() {
  if [ $os == "WINDOWS" ]; then
    ## Checks if chocolatey is installed
    if ! [ -x "$(command -v choco)" ]; then
      echo 'Warn: Chocolatey is not installed.' >&2
      curl --output .temp-install-files/installChocolatey.cmd --url https://chocolatey.org/installchocolatey.cmd
      local chocoInstallFile
      chocoInstallFile="$(pwd)/.temp-install-files/installChocolatey.cmd"
      echo "Trying to install chocolatey - running: $chocoInstallFile"
      $(command echo $chocoInstallFile)
    else
      ## Upgrades chocolatey
      echo "Trying to upgrade chocolatey"
      choco upgrade chocolatey
    fi
  fi
}

function add_to_bashrc() {
  local bashrcFile=~/.bashrc
  if [ -f "$bashrcFile" ]; then
    echo "$1" >>~/.bashrc
  fi
}

function add_to_zshrc() {
  local zshrcFile=~/.zshrc
  if [ -f "$zshrcFile" ]; then
    echo "$1" >>~/.zshrc
  fi
}

function install_kubectl_autocomplete() {

  echo "Trying to install kubectl autcomplete"

  ## If bashrc file exists then add support for kubectl autocomplete in all sessions
  add_to_bashrc 'source <(kubectl completion bash)'

  ## If zshrc file exists then add support for kubectl autocomplete in all sessions
  add_to_zshrc 'source <(kubectl completion zsh)'

  ## If cmder is installed then add support for kubectl autocomplete in all bash sessions
  local cmderDir
  cmderDir="$(command type -P cmder)"
  if [ -n "$cmderDir" ]; then
    echo "cmder is installed: $cmderDir"
    local cmderUserProfile
    cmderUserProfile="$(echo $cmderDir | sed 's/\(.*\)cmder/\1config\/user-profile.sh/')"
    echo 'source <(kubectl completion bash)' >>$cmderUserProfile
    echo "alias kubectl=kubectl" >>$cmderUserProfile
    source <(kubectl completion bash)
  fi
}

function install_kubectl() {

  ## Checks if kubectl is installed
  if ! [ -x "$(command -v kubectl)" ]; then
    echo 'Warn: kubectl is not installed.' >&2
    echo "Trying to install kubectl"
    if [ $os == "WINDOWS" ]; then
      choco install kubernetes-cli
    elif [ $os == "LINUX" ]; then
      sudo apt-get update
      sudo apt-get install -y apt-transport-https ca-certificates curl
      sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
      echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
      sudo apt-get update
      sudo apt-get install -y kubectl
      echo "Trying to install bash-completion"
      apt-get install bash-completion
    fi
    ## Prints kubectl client version
    kubectl version --client

    ## Installs kubectl autocomplete
    install_kubectl_autocomplete
  else
    echo "Trying to upgrade kubectl"
    if [ $os == "WINDOWS" ]; then
      choco upgrade kubernetes-cli
    elif [ $os == "LINUX" ]; then
      sudo apt-get update
      sudo apt-get install -y kubectl
    fi
  fi
}

function check_docker_installation() {
  if ! [ -x "$(command -v docker)" ]; then
    echo 'Error: Docker is not installed, cannot proceed.' >&2
    exit 1
  fi
}

## https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
function get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

function install_kind() {

  ## Checks if kind is installed
  if ! [ -x "$(command -v kind)" ]; then
    echo 'Warn: kind is not installed.' >&2
    echo "Trying to install kind"
    if [ $os == "WINDOWS" ]; then
      choco install kind
    elif [ $os == "LINUX" ]; then
      local latestKindVersion
      latestKindVersion="$(get_latest_release kubernetes-sigs/kind)"
      curl -Lo .temp-install-files/./kind https://kind.sigs.k8s.io/dl/"$latestKindVersion"/kind-linux-amd64
      chmod +x .temp-install-files/./kind
      mv .temp-install-files/./kind ~/kind/kind

      add_to_bashrc "export PATH=\"$HOME/kind:$PATH\""
      add_to_zshrc "export PATH=\"$HOME/kind:$PATH\""
    fi

    ## Prints kind version
    kind --version

  else
    echo "Trying to upgrade kind"
    if [ $os == "WINDOWS" ]; then
      choco upgrade kind
    elif [ $os == "LINUX" ]; then
      local latestKindVersion
      latestKindVersion="$(get_latest_release kubernetes-sigs/kind)"
      curl -Lo .temp-install-files/./kind https://kind.sigs.k8s.io/dl/"$latestKindVersion"/kind-linux-amd64
      chmod +x .temp-install-files/./kind
      mv .temp-install-files/./kind ~/kind/kind
    fi
  fi
}

## Install required softwared

get_current_os

check_docker_installation

mkdir .temp-install-files

install_pkg_manager

install_kubectl

install_kind

echo "Instalation done. Happy coding!!!"
