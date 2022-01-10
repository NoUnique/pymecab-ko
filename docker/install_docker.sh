#!/bin/bash
# shell script to install Docker and Docker-compose
# at container-based development environment.
# (for DooD (Docker out of Docker)
#
# Author : Taehwan Yoo (kofmap@gmail.com)
# Copyright 2022 Taehwan Yoo. All Rights Reserved

# essential functions
# (omit 'function' keyword to distinguish them from major functions)
exist() {
    local EXECUTABLE=$1
    [[ $(${EXECUTABLE} 2> /dev/null) ]]
}
verlt() {
    [ "$1" = "$2" ] && return 1 || [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}
sudo_exec() {
    local EXECUTABLE=${1:-"-k"}
    local ERROR_MESSAGE=${2:-"Failed to acquire root privileges"}
    echo "Root privileges is needed. Please enter your password if you are sudoer"
    sudo -k # make sure to ask for password on next sudo
    if sudo true; then
        sudo ${EXECUTABLE}
    else
        echo ${ERROR_MESSAGE}
        exit 1
    fi
}

function fn_init() {
    # set working directory
    SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    cd ${SCRIPT_DIR}
}

function fn_remove_old_docker() {
    sudo apt-get purge -y \
                 docker \
                 docker-engine \
                 docker.io \
                 lxc-docker 
}

function fn_install_requirements() {
    sudo apt-get install -y
                 curl \
                 apt-transport-https \
                 ca-certificates \
                 software-properties-common
}

function fn_import_gpg_keys() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
}

function fn_add_docker_repository() {
    sudo add-apt-repository \
         "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) stable"
    sudo apt-get update
}

function fn_install_docker_and_compose() {
    sudo apt-get install -y
                 docker-ce \
                 docker-ce-cli \
                 containerd.io \
                 docker-compose
}

function fn_give_permissions_to_user() {
    # use `id -nu $UID` instead of `USER` because it is sometimes wrong.
    # sudo usermod -aG docker $USER
    sudo usermod -aG docker $(id -nu $UID)
}

function fn_upgrade_compose() {
    CURRENT_COMPOSE_VERSION=$(docker-compose --version | sed 's/.*version\ //g' | sed 's/,.*//g')
    if verlt ${CURRENT_COMPOSE_VERSION} ${COMPOSE_VERSION}; then
        # compare current version to target version
        echo "Upgrade docker-compose version from '${CURRENT_COMPOSE_VERSION}' to '${COMPOSE_VERSION}'"
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    fi
}

function fn_main() {
    fn_init
    sudo_exec
    fn_remove_old_docker
    fn_install_requirements
    fn_import_gpg_keys
    fn_add_docker_repository
    fn_install_docker_and_compose
    fn_give_permissions_to_user
    fn_upgrade_compose
}

fn_main
