FROM lcpp_build:latest as lcpp_build

FROM runpod/worker-vllm:stable-cuda11.8.0 as vllm
COPY --from=lcpp_build /llama.cpp/build/bin/server /llama-cpp-server
COPY --from=lcpp_build /usr/local/cuda/lib64/libcublas.so.11 /usr/local/cuda/lib64/libcublas.so.11
COPY --from=lcpp_build /usr/local/cuda/lib64/libcublasLt.so /usr/local/cuda/lib64/libcublasLt.so
RUN apt update && apt install -y libcurl4 curl git
ENV LD_LIBRARY_PATH="/usr/local/cuda-11.8/compat"
COPY . /repo
WORKDIR /repo
CMD ["bash", "/repo/start.sh"]
