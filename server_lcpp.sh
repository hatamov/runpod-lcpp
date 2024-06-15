#!/bin/bash
set -ex

./download.sh

source /venv-lcpp/bin/activate
python3 -m llama_cpp.server --host 127.0.0.1 --port $S_LCPP_PORT --model "$LLCP_MODEL_PATH" \
    --n_gpu_layers -1 --flash_attn true \
    --type_k 8 --type_v 8 \
    --cache true --n_ctx 8192
