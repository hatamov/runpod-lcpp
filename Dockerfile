### STAGE: Build stage for llama-cpp-python package ###
ARG COMPILE_CONCURRENCY=12
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04 AS llama_cpp_build

RUN apt-get update -y \
    && apt-get install -y python3-pip git libssl-dev cmake curl libcurl4-openssl-dev ccache

ENV CCACHE_DIR=/root/.cache/ccache
RUN --mount=type=cache,target=/root/.cache/ccache \
    CMAKE_BUILD_PARALLEL_LEVEL=${COMPILE_CONCURRENCY} CMAKE_ARGS="-DLLAMA_CUDA=on" python3 -m pip install --verbose llama-cpp-python llama-cpp-python[server]


### STAGE: Final stage ###
FROM runpod/worker-vllm:stable-cuda12.1.0 as vllm

RUN apt update && \
    apt install -y libcurl4 curl git entr python3.10-venv tree

### Installing llama-cpp-python package ###
# Copy `llama-cpp-python` package which includes built libllama.so and libllava.so libs.
# We also install llama-cpp-python requirements via manually defined requirements-lcpp.txt file (may not be the best way to do it, but it works).
# Note that we use venv with --system-site-packages to minimize the size of the image.
COPY --from=llama_cpp_build /usr/local/lib/python3.10/dist-packages/llama_cpp* /usr/local/lib/python3.10/dist-packages/llama_cpp
COPY ./requirements-lcpp.txt /tmp/requirements-lcpp.txt
RUN python3 -m venv --system-site-packages /venv-lcpp && \
    . /venv-lcpp/bin/activate && \
    python3 -m pip install -r /tmp/requirements-lcpp.txt

### Installing exllamav2 + tabbyAPI ###
# Here we install requirements from a custom requirements-exl2.txt because installing them normally
# from the `pyproject.tmol` into a venv created with --system-site-packages flag had some issues.
RUN git clone https://github.com/theroyallab/tabbyAPI /tabbyAPI
COPY ./requirements-exl2.txt /tmp/requirements-exl2.txt
RUN python3 -m venv --system-site-packages /venv-exl2 && \
    . /venv-exl2/bin/activate && \
    python3 -m pip install -r /tmp/requirements-exl2.txt

COPY . /repo
WORKDIR /repo

# llama_cpp depends on libcublas.so.12 and libcublasLt.so, but luckily they are present in our image already,
# in /usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:
ENV LD_LIBRARY_PATH="/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib"

CMD ["bash", "/repo/watch.sh"]
