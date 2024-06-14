#!/bin/bash
set -ex
source ./env.sh

HFR="${HFR:-kaitchup/Phi-3-mini-4k-instruct-gptq-4bit}"
HFF="${HFF:-}"
HFR_LOCAL_PATH="$MODELS_DIR/${HFR_LOCAL_PATH:-$HFR}"
./snapshot_download.py --repo_id "$HFR" --local_dir "$HFR_LOCAL_PATH" --allow_patterns "$HFF"


python3 -m vllm.entrypoints.openai.api_server --host 127.0.0.1 --port $S_VLLM_PORT  --model "$HFR_LOCAL_PATH" --dtype auto 
