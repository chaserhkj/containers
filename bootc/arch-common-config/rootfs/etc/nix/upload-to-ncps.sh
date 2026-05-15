#!/bin/bash
[[ -z "${OUT_PATHS}" ]] && exit 0
nix copy --to https://$(cat /etc/nix/ncps.cred.txt)@ncps.0.zt/upload ${OUT_PATHS} || :