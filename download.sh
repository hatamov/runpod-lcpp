#!/bin/bash
set -e

if [ "$SHOULD_DOWNLOAD" != "1" ]; then
    exit 0
fi

DL_REPO_ID_DASHED="${DL_REPO_ID//\//--}" # Replace '/' with '--'
DL_LOCAL_DIR="$MODELS_DIR/$DL_REPO_ID_DASHED"

./snapshot_download.py --repo_id="$DL_REPO_ID" --revision="$DL_REVISION" \
    --local_dir="$DL_LOCAL_DIR" --allow_patterns="$DL_ALLOW_PATTERNS"
