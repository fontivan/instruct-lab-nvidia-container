# It should be possible to build this on RHEL but it will require an active subscription due to the external dependencies for CUDA
ARG CONTAINER_BASE_IMAGE=docker.io/rockylinux/rockylinux:9-minimal
FROM ${CONTAINER_BASE_IMAGE}

# Can override via argument if desired
ARG CONTAINER_DIR=/work

# Configure user and working directory
USER root
RUN mkdir -p "${CONTAINER_DIR}"
WORKDIR "${CONTAINER_DIR}"

# Copy files
COPY config.yaml .
COPY entrypoint.sh .

# Install pre-reqs
RUN microdnf install -y \
    cmake \
    curl \
    gcc \
    git \
    make \
    python3 \
    python3-pip

# Install cuda
RUN curl -o /etc/yum.repos.d/cuda-rhel9.repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo  && \
    microdnf install -y cuda-toolkit-12-4 && \
    microdnf clean all

# Prepare the venv and ilab cli
RUN python3 -m venv venv-container && \
    source venv-container/bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install git+https://github.com/instructlab/instructlab.git@stable

# Recompile llama with cuda support
RUN source venv-container/bin/activate && \
    CUDACXX=/usr/local/cuda-12/bin/nvcc CMAKE_ARGS="-DLLAMA_CUBLAS=on -DCMAKE_CUDA_ARCHITECTURES=all-major" FORCE_CMAKE=1 pip install llama-cpp-python --no-cache-dir --force-reinstall --upgrade

# Set entrypoint
ENTRYPOINT [ "sh" ]
