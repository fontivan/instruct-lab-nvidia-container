# It should be possible to run this on RHEL or UBI base images.
# It will require an active subscription due to the external dependencies for CUDA.
ARG CONTAINER_BASE_IMAGE="docker.io/rockylinux/rockylinux:9-minimal"

# Can override via argument if desired
ARG CONTAINER_DIR="/work"
ARG CUDA_MAJOR_VERSION="12"
ARG CUDA_MINOR_VERSION="4"
ARG CUDA_VERSION="${CUDA_MAJOR_VERSION}-${CUDA_MINOR_VERSION}"
ARG CUDA_YUM_REPO_FILE_PATH="/etc/yum.repos.d/cuda-rhel9.repo"

# Venv variables
ARG VENV_NAME="venv-container"
ARG VENV_PATH="${CONTAINER_DIR}/${VENV_NAME}"
ARG VENV_ACTIVATE_PATH="${VENV_PATH}/bin/activate"

# Use a builder to prepare the venv since the compile dependencies for cuda are large
# hadolint ignore=DL3006
FROM "${CONTAINER_BASE_IMAGE}" as builder

# Redefine args to inheirit defaults from above
ARG CONTAINER_DIR
ARG CUDA_MAJOR_VERSION
ARG CUDA_MINOR_VERSION
ARG CUDA_VERSION
ARG CUDA_YUM_REPO_FILE_PATH
ARG VENV_NAME
ARG VENV_PATH
ARG VENV_ACTIVATE_PATH

# Configure user and working directory
# hadolint ignore=DL3002
USER root
RUN mkdir -p "${CONTAINER_DIR}"
WORKDIR "${CONTAINER_DIR}"

# Install pre-reqs
# hadolint ignore=DL3041
RUN microdnf install -y \
    cmake \
    curl \
    gcc \
    git \
    make \
    python3 \
    python3-pip && \
    microdnf clean all

# Install cuda toolkit
RUN curl -o "${CUDA_YUM_REPO_FILE_PATH}" "https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo"  && \
    microdnf install -y "cuda-toolkit-${CUDA_VERSION}" && \
    microdnf clean all

# Prepare the venv and ilab cli
# hadolint ignore=DL3013
RUN python3 -m venv "${VENV_NAME}" && \
    . "${VENV_ACTIVATE_PATH}" && \
    pip3 --no-cache-dir install "git+https://github.com/instructlab/instructlab.git@stable"

# Recompile llama with cuda support
# hadolint ignore=DL3013
RUN . "${VENV_ACTIVATE_PATH}" && \
    CUDACXX="/usr/local/cuda-${CUDA_MAJOR_VERSION}/bin/nvcc" \
    CMAKE_ARGS="-DLLAMA_CUBLAS=on -DCMAKE_CUDA_ARCHITECTURES=all-major" \
    FORCE_CMAKE=1 \
    pip install llama-cpp-python --no-cache-dir --force-reinstall --upgrade

# Restart to finish the final container without compile dependencies
# hadolint ignore=DL3006
FROM "${CONTAINER_BASE_IMAGE}"

# Redefine args to inheirit defaults from above
ARG CONTAINER_DIR
ARG CUDA_MAJOR_VERSION
ARG CUDA_MINOR_VERSION
ARG CUDA_VERSION
ARG CUDA_YUM_REPO_FILE_PATH
ARG VENV_NAME
ARG VENV_PATH
ARG VENV_ACTIVATE_PATH

# Configure user and working directory
# hadolint ignore=DL3002
USER root
RUN mkdir -p "${CONTAINER_DIR}"
WORKDIR "${CONTAINER_DIR}"

# Copy repofile from builder
COPY --from=builder "${CUDA_YUM_REPO_FILE_PATH}" "${CUDA_YUM_REPO_FILE_PATH}"

# Copy the venv from the builder with the ilab cli and recompiled llama-cpp-python
COPY --from=builder "${VENV_PATH}" "${VENV_PATH}"

# Copy files
COPY config.yaml .
COPY entrypoint.sh .

# Install pre-reqs
# hadolint ignore=DL3041
RUN microdnf install -y \
    git \
    python3 \
    python3-pip && \
    microdnf clean all

# Install cuda runtime
RUN microdnf install -y "cuda-runtime-${CUDA_VERSION}" && \
    microdnf clean all

# Set entrypoint
ENTRYPOINT [ "sh" ]
