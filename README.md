# Instruct Lab NVIDIA Container

Prepare a container for running Instruct Lab with an NVIDIA GPU. This does *not* require the CUDA Toolkit installed on the host. This is useful because the CUDA toolkit is not super widely supported.

Note that this is a *hefty* container. The final image clocks in around 17 GB.

## Host Installation

1. You will need to install `nvidia-toolkit` and the NVIDIA proprietary driver on your host. For Fedora 40, a script is available in `host-prep/fc40.sh`. It may work on other systems but it is not widely tested.

## Host Verification

1. You will need to verify that the GPU is detected on both the host and inside a container. A test script is available in `scripts/host-verify.sh`

## Container Build

1. Prepare your environment with arguments for the container build:
    - (Required) INSTRUCT_LAB_TAXONOMY_PATH: The path to the git repo for taxonomy.
    - (Required) INSTRUCT_LAB_MODELS_PATH: The path to the download folder for models.
    - (Optional) CONTAINER_NAME: The name used for the container tag and deployed container name. The default is `instruct-lab-nvidia-container`.
    - (Optional) NVIDIA_DEVICE: The nvidia devices passed to the container. The default is `nvidia.com/gpu-all`. Specific identifies can be found in the output of `nvidia-ctk cdi list`.
    - (Optional) CONTAINER_DIR: The directory used inside the container. The default is `/work`.

2. Run the build:
```
make all
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
