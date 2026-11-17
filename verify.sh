#!/usr/bin/env bash
# Git Bash wrapper: ./verify.sh  |  ./verify.sh -SkipE2E
cd "$(dirname "$0")" && exec powershell -NoProfile -ExecutionPolicy Bypass -File ./verify.ps1 "$@"
