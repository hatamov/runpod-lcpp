#!/bin/bash
set -ex
export VOLUME_PATH="/runpod-volume"
export MODELS_DIR="$VOLUME_PATH/models"
# 
HFR="${HFR:-Zoyd/failspy_Phi-3-mini-4k-geminified-2_5bpw_exl2}"
# HFF="${HFF:-Phi-3-mini-4k-instruct-q4.gguf}"
# MODEL="$MODELS_DIR/$HFR"

export S_EXL2_PORT=2015
export HF_DOWNLOAD_ARGS="$HFR"
export HF_HUB_ENABLE_HF_TRANSFER=0
./download_model.sh

# export MODEL=/runpod-volume/models/Phi-3-mini-4k-instruct-q4.gguf
cd /tabbyAPI
source ./venv/bin/activate
python3 ./start.py --help
# python3 ./start.py --host 127.0.0.1 --port $S_EXL2_PORT --disable-auth=true --model-dir "$MODELS_DIR" --model-name "$HFR"
python3 ./main.py --config /repo/server_exl2_config.yml --model-name "$HFR"
