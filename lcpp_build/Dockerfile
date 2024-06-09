ARG WORKER_CUDA_VERSION=11.8.0
FROM nvidia/cuda:${WORKER_CUDA_VERSION}-devel-ubuntu22.04 AS cuda_devel

RUN apt-get update -y \
    && apt-get install -y python3-pip git libssl-dev cmake curl libcurl4-openssl-dev

RUN git clone https://github.com/ggerganov/llama.cpp.git /llama.cpp
RUN cd /llama.cpp && mkdir ./build && cd ./build && \
    cmake -DLLAMA_CURL=ON -DLLAMA_SERVER_SSL=ON -DLLAMA_CUDA=ON -DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS .. && \
    cmake --build . --config Release -j 12
