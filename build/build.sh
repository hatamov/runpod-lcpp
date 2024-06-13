#!/bin/bash
docker build -t lcpp_build:cuda-12.1 --platform linux/amd64 --progress plain . -f ./Dockerfile.lcpp
# docker build -t exl2_build:cuda-12.1 --platform linux/amd64 --progress plain . -f ./Dockerfile.exl2
