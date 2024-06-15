#!/usr/bin/python3
"""
This is a wrapper script around the `huggingface_hub.snapshot_download` function.
"""
import os
import argparse
from huggingface_hub import snapshot_download
import json

parser = argparse.ArgumentParser()

parser.add_argument("--repo_id", type=str, required=True)
parser.add_argument("--revision", type=str, default=None)
parser.add_argument("--cache_dir", type=str, default=None)
parser.add_argument("--allow_patterns", type=str, default=None)
parser.add_argument("--resume_download", type=bool, default=True)
parser.add_argument("--local_dir", type=str, default=None)
args = parser.parse_args()


if __name__ == "__main__":
    if os.environ.get("SKIP_DOWNLOAD", "0") == "1":
        print("Skipping download")
        exit(0)

    print(f"snapshot_download: args = {args}")

    allow_patterns = args.allow_patterns or None
    if allow_patterns and "," in allow_patterns:
        allow_patterns = allow_patterns.split(",")

    print(f"snapshot_download: allow_patterns = {allow_patterns}")

    snapshot_download(
        args.repo_id,
        revision=args.revision,
        cache_dir=args.cache_dir,
        local_dir=args.local_dir,
        allow_patterns=allow_patterns,
        resume_download=args.resume_download,
    )
