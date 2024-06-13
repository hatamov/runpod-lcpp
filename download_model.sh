#!/bin/bash
set -ex

print_dir_size() {
    while kill -0 $1 2> /dev/null; do
        du -h -d 1 $MODELS_DIR
        sleep 5
    done
}

if [ -z "$HF_DOWNLOAD_ARGS" ]; then
    echo "HF_DOWNLOAD_ARGS is not set"
    exit 0
fi  

echo "Downloading model: $HF_DOWNLOAD_ARGS"
# huggingface-cli download $HF_DOWNLOAD_ARGS &
huggingface-cli download microsoft/Phi-3-mini-4k-instruct-gguf Phi-3-mini-4k-instruct-gguf &
download_pid=$!

print_dir_size $download_pid

# Wait for the download script to finish
wait $download_pid

echo "Downloading complete"
du -h -d 1 $MODELS_DIR
