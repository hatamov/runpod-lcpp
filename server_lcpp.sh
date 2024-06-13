#!/bin/bash
set -ex

HFR="${HFR:-microsoft/Phi-3-mini-4k-instruct-gguf}"
HFF="${HFF:-Phi-3-mini-4k-instruct-q4.gguf}"
MODEL="$MODELS_DIR/$HFF"

export S_LCPP_PORT=1515
export HF_DOWNLOAD_ARGS="$HFR $HFF"
./download_model.sh

# export MODEL=/runpod-volume/models/Phi-3-mini-4k-instruct-q4.gguf
python3 -m llama_cpp.server --host 127.0.0.1 --port $S_LCPP_PORT --model "$MODEL" \
    --n_gpu_layers -1 --flash_attn true \
    --type_k 8 --type_v 8 \
    --cache true --n_ctx 8192

