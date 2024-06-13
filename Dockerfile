FROM lcpp_build:cuda-12.1 as lcpp_build

FROM runpod/worker-vllm:stable-cuda12.1.0 as vllm

RUN apt update && apt install -y libcurl4 curl git entr python3.10-venv tree

COPY --from=lcpp_build /usr/local/lib/python3.10/dist-packages/llama_cpp* /usr/local/lib/python3.10/dist-packages/llama_cpp
COPY ./requirements.txt /tmp/requirements.txt
RUN python3 -m pip install -r /tmp/requirements.txt

# Bellow lines are not needed as cublas libs appear to be present in /usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib
# COPY --from=lcpp_build /usr/local/cuda/lib64/libcublas.so.12 /usr/local/cuda/lib64/libcublas.so.12
# COPY --from=lcpp_build /usr/local/cuda/lib64/libcublasLt.so /usr/local/cuda/lib64/libcublasLt.so

RUN git clone https://github.com/theroyallab/tabbyAPI /tabbyAPI
COPY ./requirements-exl2.txt /tmp/requirements-exl2.txt
RUN python3 -m venv --system-site-packages /tabbyAPI/venv
RUN cd /tabbyAPI && . venv/bin/activate && \
    # python3 -m pip install -U .[cu121]
    python3 -m pip install -r /tmp/requirements-exl2.txt

COPY . /repo
WORKDIR /repo
ENV LD_LIBRARY_PATH="/usr/local/cuda-12.1/compat:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib"
CMD ["bash", "/repo/watch.sh"]
