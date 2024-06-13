#!/bin/bash
docker build -t lcpp_build:cuda-12.1 --platform linux/amd64 --progress plain .
