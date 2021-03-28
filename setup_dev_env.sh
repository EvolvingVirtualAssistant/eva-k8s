#!/usr/bin/env bash

echo "Starting setup of E.V.A development environment"

function get_current_os () {
    case "$OSTYPE" in
      darwin*)  
        echo "OSX - not supported" 
        exit 1 ;; 
      linux*)
        os="LINUX" ;; 
      msys*)
        os="WINDOWS";; 
      *)        
        echo "unknown: $OSTYPE - not supported" 
        exit 1 ;;
    esac

    echo "Current OS: $os"
}

function install_pkg_manager () {
    if [ $os == "WINDOWS" ]; then
      #checks if chocolatey is installed
      if ! [ -x "$(command -v choco)" ]; then
        echo 'Warn: Chocolatey is not installed.' >&2
        mkdir .temp-install-files
        curl --output .temp-install-files/installChocolatey.cmd --url https://chocolatey.org/installchocolatey.cmd
        local chocoInstallFile="$(pwd)/.temp-install-files/installChocolatey.cmd"
        echo "Trying to install chocolatey - running: $chocoInstallFile"
        $(command echo $chocoInstallFile)
      else
        #upgrades chocolatey
        echo "Trying to upgrade chocolatey"
        choco upgrade chocolatey
      fi
    fi  
}

function install_kubectl_autocomplete () {
    #if bashrc file exists then add support for kubectl autocomplete in all sessions
    local bashrcFile=~/.bashrc
    if [ -f "$bashrcFile" ]; then
      echo "bashrc found"
      echo 'source <(kubectl completion bash)' >>~/.bashrc
    fi
    #if zshrc file exists then add support for kubectl autocomplete in all sessions
    local zshrcFile=~/.zshrc
    if [ -f "$zshrcFile" ]; then
      echo "zshrc found"
      echo 'source <(kubectl completion zsh)' >>~/.zshrc
    fi
    #if cmder is installed then add support for kubectl autocomplete in all bash sessions
    local cmderDir="$(command type -P cmder)"
    if [ -n "$cmderDir" ]; then
      echo "cmder is installed: $cmderDir"
      source <(kubectl completion bash)
    fi
}

function install_kubectl () {

    #checks if kubectl is installed
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
        echo "Trying to install kubectl autocomplete"
        apt-get install bash-completion
      fi

      kubectl version --client
      #mkdir ~/.kube
   
      install_kubectl_autocomplete
    fi

}

get_current_os

install_pkg_manager

install_kubectl


