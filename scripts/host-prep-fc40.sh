#!/usr/bin/env bash

set -eou pipefail

URL="https://nvidia.github.io/libnvidia-container/\
stable/rpm/nvidia-container-toolkit.repo"

curl -s -L "${URL}" | \
    sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo yum-config-manager --enable nvidia-container-toolkit-experimental

sudo yum install -y nvidia-container-toolkit

sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
