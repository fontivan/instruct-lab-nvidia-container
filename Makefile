# Makefile derived from https://web.archive.org/web/20240205205603/https://venthur.de/2021-03-31-python-makefiles.html

# Get the directory this Makefile is sitting in
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# system python interpreter. used only to create virtual environment
PY = python3
VENV = venv
BIN=$(ROOT_DIR)/$(VENV)/bin

SHELL_FILES := $(shell find $(ROOT_DIR)  -type f -name "*.sh" | grep -v $(VENV))

# These can be overwritten by shell environment
CONTAINER_BACKEND ?= podman
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
all: bashate shellcheck yamllint

# Container target
container: clean-container build-container deploy-container

# venv used for ci purposes
$(VENV): requirements/ci.txt
	$(PY) -m venv $(VENV)
	$(BIN)/pip install --upgrade -r requirements/ci.txt
	touch $(VENV)

.PHONY: bashate
bashate: $(VENV)
	$(BIN)/bashate $(SHELL_FILES)

.PHONY: shellcheck
shellcheck: $(VENV)
	$(BIN)/shellcheck -x $(SHELL_FILES)

.PHONY: yamllint
yamllint: $(VENV)
	$(BIN)/yamllint .

# Build the container using podman
.PHONY: build-container
build-container:
	${CONTAINER_BACKEND} build \
	--tag $(CONTAINER_NAME) \
	--build-arg CONTAINER_BASE_IMAGE="$(CONTAINER_BASE_IMAGE)" \
	--build-arg CONTAINER_DIR="$(CONTAINER_DIR)" \
	--build-arg CUDA_MAJOR_VERSION="$(CUDA_MAJOR_VERSION)" \
	--build-arg CUDA_MINOR_VERSION="$(CUDA_MINOR_VERSION)" \
	.

# Deploy the latest built image using podman
.PHONY: deploy-container
deploy-container:
	@echo "Checking if INSTRUCT_LAB_TAXONOMY_PATH is defined in environment"
	test -n "${INSTRUCT_LAB_TAXONOMY_PATH}"
	${CONTAINER_BACKEND} run \
		-it \
		-d \
		--name $(CONTAINER_NAME) \
		--user root \
		-p "${LAB_LISTEN_IF}:${LAB_LISTEN_PORT}:${LAB_LISTEN_PORT}" \
		--volume "${INSTRUCT_LAB_TAXONOMY_PATH}:$(CONTAINER_DIR)/taxonomy:rw,Z" \
		--volume "${HUGGINGFACE_CACHE_DIR}:/root/.cache/huggingface:rw,Z" \
		--device $(NVIDIA_DEVICE) \
		--security-opt=label=disable \
		localhost/$(CONTAINER_NAME):latest \
		$(CONTAINER_DIR)/entrypoint.sh

# Remove any existing container, if one exists
.PHONY: clean-container
clean-container:
	${CONTAINER_BACKEND} container rm -f $(CONTAINER_NAME)

# Open an interactive shell into the container
.PHONY: exec-container
exec-container:
	${CONTAINER_BACKEND} exec -it --user root $(CONTAINER_NAME) $(CONTAINER_DIR)/entrypoint.sh

# Clean venv and related files
clean:
	rm -rf $(VENV)
	find . -type f -name *.pyc -delete
	find . -type d -name __pycache__ -delete
