# Container-based Development Environment

This repository contains a Container-based development environment /

It can be easily used just by adding it as a submodule 
under the project folder of the target code.

Only one container is created and the name is automatically generated.

<br>

## Prerequisites
Tested environment
- Ubuntu LTS (16.04 or 18.04)
- docker-ce (>= 18.09)
- docker-compose (>= 1.25.4) - This script will automatically upgrade docker-compose if necessary
- nvidia-docker2 (>= 2.0.3)

<br>

## How to use
   
- Build docker image
    ```bash
    {PJT_DIR}$ ./docker/compose.sh -b
    ```
    -b : build an image \
    -r : run a container \
    -s : connect to shell(bash) \
    -k : kill container (attach and kill) \
    -d : down container (kill container and remove container, network and volumes) \
    --no-cache : build image from scratch(use no cache)
    
    **This script makes ONLY 1 CONTAINER**

- Attach the container using docker-compose
    ```bash
    {PJT_DIR}$ ./docker/compose.sh -s
    ```
  
- This script supports multiple argument
    ```bash
    {PJT_DIR}$ bash ./compose.sh -brs
    ```
    build -> run -> attach to shell (Automatically executed sequentially)

<br>
    
example) <br>
ubuntu user ID: nounique <br>
directory name : `_GIT_REPO` <br>
location: `_GIT_REPO/docker` <br>
buuild & run result:

    $ docker ps
    CONTAINER ID  IMAGE             COMMAND      NAMES
    78487a99355e  gitrepo:nounique  "/bin/bash"  nounique_gitrepo_dev_1
 
<br>

### Installation (Docker on host)

1. Remove default docker packages(old versions)
    ```bash
    sudo apt-get purge docker \
                       docker-engine \
                       docker.io \
                       lxc-docker 
    ```

2. Install required packages for installing docker
    ```bash
    sudo apt-get install curl \
                         apt-transport-https \
                         ca-certificates \
                         software-properties-common
    ```

3. Import docker GPG key to verified packages signiture
    ```bash
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    ```

4. Add docker repository
    ```bash
    sudo add-apt-repository \
         "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) stable"
    sudo apt-get update
    ```

5. Install docker(docker-ce) and docker-compose
    ```bash
    sudo apt-get install docker-ce \
                         docker-ce-cli \
                         containerd.io \
                         docker-compose
    ```
    
    Give user a root permission
    ```bash
    sudo usermod -aG docker $USER
    ```

6. Install nvidia-docker2
    Remove nvidia-docker1.0
    ```bash
    docker volume ls -q -f driver=nvidia-docker | \
    xargs -r -I{} -n1 docker ps -q -a -f volume={} | \
    xargs -r docker rm -f
    sudo apt-get purge nvidia-docker
    ```
    
    Add nvidia-docker repository
    ```bash
    curl -sL https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    dist=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -sL https://nvidia.github.io/nvidia-docker/$dist/nvidia-docker.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo apt-get update
    ```
    
    Install nvidia-docker2
    ```bash
    sudo apt-get install nvidia-docker2
    sudo pkill -SIGHUP dockerd
    ```
    
    Set nvidia-docker as default-runtime of docker
    ```bash
    sudo vi /etc/docker/daemon.json
    ```
    ```json
    {
        "default-runtime": "nvidia",
        "runtimes": {
            "nvidia": {
                "path": "nvidia-container-runtime",
                "runtimeArgs": []
            }
        }
    }
    ```
    ```bash
    sudo systemctl restart docker
    ```
    
    ```bash
    sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
    sudo chmod g+rwx "/home/$USER/.docker" -R
    ```
    
    Re-login is required

    Test nvidia-docker
    ```bash
    docker run --rm -it nvidia/cuda nvidia-smi
    ```
