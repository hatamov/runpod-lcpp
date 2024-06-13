#!/bin/bash
set -ex

print_dir_size() {
    du -h -d 1 $VOLUME_PATH
}

print_loop() {
    while true; do
        print_dir_size
        sleep 5
    done
}

if [ -z "$HF_DOWNLOAD_ARGS" ]; then
    echo "HF_DOWNLOAD_ARGS is not set"
    exit 0
fi  

echo "Downloading model: $HF_DOWNLOAD_ARGS"
huggingface-cli download --local-dir $MODELS_DIR $HF_DOWNLOAD_ARGS &
download_pid=$!

print_loop $download_pid

# Wait for the download script to finish
wait $download_pid

echo "Downloading complete"
print_dir_size
