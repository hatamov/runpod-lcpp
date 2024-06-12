#!/bin/bash
set -ex

mkdir -p /models

if [ -n "$HFR" ]; then
    # HFR=microsoft/Phi-3-mini-4k-instruct-gguf
    # HFF=Phi-3-mini-4k-instruct-q4.gguf

    echo "Downloading model: $HFR $HFF"
    huggingface-cli download --local-dir /models --resume-download $HFR $HFF
    echo "Downloading complete"
fi


if [ -n "$CUSTOM_INIT_COMMAND" ]; then
    $CUSTOM_INIT_COMMAND
fi

exec python3 ./src/handler.py
