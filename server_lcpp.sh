#!/bin/bash
set -ex
source ./env.sh

HFR="${HFR:-microsoft/Phi-3-mini-4k-instruct-gguf}"
HFF="${HFF:-Phi-3-mini-4k-instruct-q4.gguf}"
HFR_LOCAL_PATH="$MODELS_DIR/${HFR_LOCAL_PATH:-$HFR}"
./snapshot_download.py --repo_id "$HFR" --local_dir "$HFR_LOCAL_PATH" --allow_patterns "$HFF"

MODEL_PATH="${MODEL_PATH:-$HFR_LOCAL_PATH/$HFF}"

source /venv-lcpp/bin/activate
python3 -m llama_cpp.server --host 127.0.0.1 --port $S_LCPP_PORT --model "$MODEL_PATH" \
    --n_gpu_layers -1 --flash_attn true \
    --type_k 8 --type_v 8 \
    --cache true --n_ctx 8192
