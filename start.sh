#!/bin/bash
set -ex
git pull origin master -f
mkdir -p /models
huggingface-cli download -hfr microsoft/Phi-3-mini-4k-instruct-gguf -hff Phi-3-mini-4k-instruct-q4.gguf --local-dir ./models --resume-download
exec python3 ./src/handler.py
