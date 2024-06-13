# FROM lcpp_build:12 as lcpp_build

FROM runpod/worker-vllm:stable-cuda12.1.0 as vllm

RUN apt update && apt install -y libcurl4 curl git entr python3.10-venv tree

RUN --mount=type=cache,target=/root/.cache/pip \
  python3 -m pip install llama-cpp-python --prefer-binary --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu121 

RUN --mount=type=cache,target=/root/.cache/pip \
  python3 -m pip install llama-cpp-python[server] --prefer-binary --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu121

# RUN MAKEFLAGS="-j12" CMAKE_ARGS="-DLLAMA_CUDA=on" pip install llama-cpp-python \
#   --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu121

# RUN MAKEFLAGS="-j12" CMAKE_ARGS="-DLLAMA_CUDA=on" pip install llama-cpp-python[server] \
#   --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu121

RUN --mount=type=cache,target=/root/.cache/pip \
    git clone https://github.com/theroyallab/tabbyAPI /tabbyAPI && \
    cd /tabbyAPI && \
    python3 -m venv --system-site-packages venv && \
    . venv/bin/activate && \
    pip install -U .[cu121]

# COPY --from=lcpp_build /llama.cpp/build/bin/server /llama-cpp-server
# COPY --from=lcpp_build /usr/local/cuda/lib64/libcublas.so.11 /usr/local/cuda/lib64/libcublas.so.11
# COPY --from=lcpp_build /usr/local/cuda/lib64/libcublasLt.so /usr/local/cuda/lib64/libcublasLt.so
# COPY --from=lcpp_build /usr/local/cuda-11.8/targets/x86_64-linux/lib/stubs/libcuda.so /usr/local/cuda/lib64/libcuda.so.1
# RUN apt-get install -y cuda-compat-12-1

COPY . /repo
WORKDIR /repo
ENV LD_LIBRARY_PATH="/usr/local/cuda-12.1/compat"
CMD ["bash", "/repo/watch.sh"]
