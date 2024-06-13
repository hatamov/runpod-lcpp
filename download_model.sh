#!/bin/bash
set -ex

if [ -n "$SKIP_DOWNLOAD" ]; then
    echo "Skipping download"
    exit 0
fi

if [ -z "$HF_DOWNLOAD_ARGS" ]; then
    echo "HF_DOWNLOAD_ARGS is not set"
    exit 0
fi  

print_dir_size() {
    # du -h -d 1 $VOLUME_PATH
    tree -h -L 3 $VOLUME_PATH
}

print_loop() {
    while kill -0 $1 2> /dev/null; do
        print_dir_size
        sleep 5
    done
}

echo "Downloading model: $HF_DOWNLOAD_ARGS"
huggingface-cli download --local-dir $MODELS_DIR $HF_DOWNLOAD_ARGS &
download_pid=$!

print_loop $download_pid

# Wait for the download script to finish
wait $download_pid

echo "Downloading complete"
print_dir_size
