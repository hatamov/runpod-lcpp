#!/bin/bash
set -ex

./download.sh

python3 -m vllm.entrypoints.openai.api_server --host 127.0.0.1 --port $S_VLLM_PORT  --model "$VLLM_MODEL_PATH" --dtype auto 
