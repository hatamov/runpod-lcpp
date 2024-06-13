ARG WORKER_CUDA_VERSION=12.1.0
FROM nvidia/cuda:${WORKER_CUDA_VERSION}-devel-ubuntu22.04 AS cuda_devel

RUN apt-get update -y \
    && apt-get install -y python3-pip git libssl-dev cmake curl libcurl4-openssl-dev ccache

RUN echo test
ENV CCACHE_DIR=/root/.cache/ccache
RUN --mount=type=cache,target=/root/.cache/ccache \
    CMAKE_BUILD_PARALLEL_LEVEL=12 CMAKE_ARGS="-DLLAMA_CUDA=on" python3 -m pip install --verbose llama-cpp-python llama-cpp-python[server]
