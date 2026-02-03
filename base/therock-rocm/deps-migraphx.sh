#!/bin/bash

# For ubuntu
if [[ $(source /etc/os-release && echo $ID) == ubuntu ]]; then
    apt-get update && apt-get install -y git build-essential cmake
fi