#!/bin/bash
set -ex
git fetch origin master
git checkout origin/master -f
mkdir -p /models
huggingface-cli download microsoft/Phi-3-mini-4k-instruct-gguf Phi-3-mini-4k-instruct-q4.gguf --local-dir /models --resume-download
apt-get install -y cuda-compat-12-1
export LD_LIBRARY_PATH="/usr/local/cuda-12.1/compat"
exec python3 ./src/handler.py
