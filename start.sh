#!/bin/bash
set -ex

mkdir -p /models
huggingface-cli download microsoft/Phi-3-mini-4k-instruct-gguf Phi-3-mini-4k-instruct-q4.gguf --local-dir /models --resume-download

export LD_LIBRARY_PATH="/usr/local/cuda-12.1/compat"

exec python3 ./src/handler.py
