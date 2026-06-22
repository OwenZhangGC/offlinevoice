#!/usr/bin/env bash
# Starts the local SenseVoice ASR service for OfflineVoice.
# Switch the app to it by setting "asrEngine": "sensevoice" in
# ~/.config/offlinevoice/config.json
set -euo pipefail
cd "$(dirname "$0")"
exec .venv/bin/python server.py
