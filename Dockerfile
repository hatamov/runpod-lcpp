FROM lcpp_build:12 as lcpp_build

FROM runpod/worker-vllm:stable-cuda12.1.0 as vllm
COPY --from=lcpp_build /llama.cpp/build/bin/server /llama-cpp-server
# COPY --from=lcpp_build /usr/local/cuda/lib64/libcublas.so.11 /usr/local/cuda/lib64/libcublas.so.11
# COPY --from=lcpp_build /usr/local/cuda/lib64/libcublasLt.so /usr/local/cuda/lib64/libcublasLt.so
# COPY --from=lcpp_build /usr/local/cuda-11.8/targets/x86_64-linux/lib/stubs/libcuda.so /usr/local/cuda/lib64/libcuda.so.1
RUN apt update && apt install -y libcurl4 curl git
# RUN apt-get install -y cuda-compat-12-1
COPY . /repo
WORKDIR /repo
ENV LD_LIBRARY_PATH="/usr/local/cuda-12.1/compat"
CMD ["bash", "/repo/update-and-start.sh"]
