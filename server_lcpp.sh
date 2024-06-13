#!/bin/bash
set -ex

HFR="${HFR:-microsoft/Phi-3-mini-4k-instruct-gguf}"
HFF="${HFF:-Phi-3-mini-4k-instruct-gguf}"
MODEL="$MODELS_DIR/$HFF"

export S_LCPP_PORT=1515
export HF_DOWNLOAD_ARGS="$HFR $HFF"
./download_model.sh

python3 -m llama_cpp.server --host 127.0.0.1 --port $S_LCPP_PORT --model "$MODEL" --ngl 100 --fa --ctk q8_0 --ctv q8_0
