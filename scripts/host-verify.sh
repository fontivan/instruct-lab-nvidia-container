#!/usr/bin/env bash

if [[ $(nvidia-ctk cdi list | wc -l) -eq 0 ]]; then
    echo "Unable to detect NVIDIA gpu"
    exit 1
fi

result=$(podman run \
        --rm --device nvidia.com/gpu=all \
        --security-opt=label=disable \
        registry.access.redhat.com/ubi9/python-311 \
        nvidia-smi -L)
if ! grep "NVIDIA" <<< $result; then
    echo "NVIDIA gpu not detected in container"
    exit 1
fi

echo "Your host looks ready!"
exit 0
