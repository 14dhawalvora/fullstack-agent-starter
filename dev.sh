#!/usr/bin/env bash
# Git Bash wrapper: ./dev.sh  |  ./dev.sh -Stop  |  ./dev.sh -Restart
cd "$(dirname "$0")" && exec powershell -NoProfile -ExecutionPolicy Bypass -File ./dev.ps1 "$@"
