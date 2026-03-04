#!/bin/bash

set -eou pipefail

apt-get update
apt-get install -y --no-install-recommends \
    docker.io \
    docker-compose 

# Add the current user to the docker group
usermod -aG docker $USER

#install act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

#verify installation
echo "Docker version:"
docker --version
echo "Docker Compose version:"
docker-compose --version
echo "act version:"
act --version
