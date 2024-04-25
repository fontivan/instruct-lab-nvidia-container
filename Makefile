
# These can be overwritten by shell environment
CONTAINER_BASE_IMAGE ?= docker.io/rockylinux/rockylinux:9-minimal
CONTAINER_DIR ?= /work
CONTAINER_NAME ?= instruct-lab-nvidia-container
CUDA_MAJOR_VERSION ?= 12
CUDA_MINOR_VERSION ?= 4
HUGGINGFACE_CACHE_DIR ?= ${HOME}/.cache/huggingface
LAB_LISTEN_IF ?= 0.0.0.0
NVIDIA_DEVICE ?= nvidia.com/gpu=all

# If you want to change the port you need to change it in config.yaml too
LAB_LISTEN_PORT := 8000

# By default we will clean any existing container, build a new container, and deploy it
all: clean-container build-container deploy-container

# Build the container using podman
.PHONY: build-container
build-container:
	podman build \
	--tag $(CONTAINER_NAME) \
	--build-arg CONTAINER_BASE_IMAGE="$(CONTAINER_BASE_IMAGE)" \
	--build-arg CONTAINER_DIR="$(CONTAINER_DIR)" \
	--build-arg CUDA_MAJOR_VERSION="$(CUDA_MAJOR_VERSION)" \
	--build-arg CUDA_MINOR_VERSION="$(CUDA_MINOR_VERSION)" \
	.

# Deploy the freshly built container using podman
.PHONY: deploy-container
deploy-container:
	@echo "Checking if INSTRUCT_LAB_TAXONOMY_PATH is defined in environment"
	test -n "${INSTRUCT_LAB_TAXONOMY_PATH}"
	@echo "Checking if INSTRUCT_LAB_MODELS_PATH is defined in environment"
	test -n "${INSTRUCT_LAB_MODELS_PATH}"
	podman run \
		-it \
		-d \
		--name $(CONTAINER_NAME) \
		--user root \
		-p "${LAB_LISTEN_IF}:${LAB_LISTEN_PORT}:${LAB_LISTEN_PORT}" \
		--volume "${INSTRUCT_LAB_TAXONOMY_PATH}:$(CONTAINER_DIR)/taxonomy:rw,Z" \
		--volume "${INSTRUCT_LAB_MODELS_PATH}:$(CONTAINER_DIR)/models:rw,Z" \
		--volume "${HUGGINGFACE_CACHE_DIR}:/.cache/huggingface:rw,Z" \
		--device $(NVIDIA_DEVICE) \
		--security-opt=label=disable \
		localhost/$(CONTAINER_NAME):latest \
		$(CONTAINER_DIR)/entrypoint.sh

# Remove any existing container, if one exists
.PHONY: clean-container
clean-container:
	podman container rm -f $(CONTAINER_NAME)

# Open an interactive shell into the container
.PHONY: exec-container
exec-container:
	podman exec -it --user root $(CONTAINER_NAME) $(CONTAINER_DIR)/entrypoint.sh
