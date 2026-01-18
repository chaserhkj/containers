#!/bin/bash

# For ubuntu, install missing deps
if [[ $(source /etc/os-release && echo $ID) == ubuntu ]]; then
    apt-get update && apt-get install -y libatomic1
fi

