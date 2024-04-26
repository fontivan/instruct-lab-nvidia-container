# Instruct Lab NVIDIA Container

Prepare a container for running Instruct Lab with an NVIDIA GPU. This does *not* require the CUDA Toolkit installed on the host. This is useful because the CUDA toolkit is not super widely supported.

The build is set up in a two stage process using a builder with the compile dependencies and the final image with just runtime dependencies.

The builer image is around 17GB, and the final image is around 9GB.

## Host Installation

1. You will need to install `nvidia-toolkit` and the NVIDIA proprietary driver on your host. For Fedora 40, a script is available in `host-prep/fc40.sh`. It may work on other systems but it is not widely tested.

## Host Verification

1. You will need to verify that the GPU is detected on both the host and inside a container. A test script is available in `scripts/host-verify.sh`

## Container Build

1. Prepare your environment with arguments for the container build:

    - (Required) INSTRUCT_LAB_TAXONOMY_PATH: The path to the git repo for taxonomy.
    - (Optional) CONTAINER_BACKEND: The container backend to use. The default is `podman`.
    - (Optional) CONTAINER_NAME: The name used for the container tag and deployed container name. The default is `instruct-lab-nvidia-container`.
    - (Optional) NVIDIA_DEVICE: The nvidia devices passed to the container. The default is `nvidia.com/gpu-all`. Specific identifiers can be found in the output of `nvidia-ctk cdi list`.
    - (Optional) CONTAINER_BASE_IMAGE: The base image to use for the container build. The default is `docker.io/rockylinux/rockylinux:9-minimal`.
    - (Optional) CONTAINER_DIR: The directory used inside the container. The default is `/work`.
    - (Optional) CUDA_MAJOR_VERSION: The major version of CUDA. Default is `12`.
    - (Optional) CUDA_MINOR_VERSION: The minor version of CUDA. Default is `4`.
    - (Optional) HUGGINGFACE_CACHE_DIR: The directory that is used to cache model downloads. The default is `${HOME}/.cache/huggingface`.

2. Run the container build:
```
make container
```

## Container Installation

1. Connect to the detached container.
```
make exec-container
```

2. Download an existing model to get started:
```
ilab download
```

3. Start by serving the model:
```
ilab serve
```

## Container Verification

1. Back on the host, open another terminal into the existing container:
```
make exec-container
```

2. Begin a chat:
```
ilab chat
```

3. Back on the host in a third terminal, check that the NVIDIA GPU is in use while chat serves you a response.
```
nvidia-smi
```
