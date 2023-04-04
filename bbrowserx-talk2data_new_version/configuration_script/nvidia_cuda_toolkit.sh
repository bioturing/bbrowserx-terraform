#!/bin/bash

set -x 

echo "install NVIDIA CUDA Toolkit 11.7"

wget https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_linux.run

sudo sh cuda_11.7.1_515.65.01_linux.run  --no-drm --silent


