#!/usr/bin/env bash
# Git Bash wrapper: ./diagnose.sh
cd "$(dirname "$0")" && exec powershell -NoProfile -ExecutionPolicy Bypass -File ./diagnose.ps1 "$@"
