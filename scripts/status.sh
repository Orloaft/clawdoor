#!/usr/bin/env bash
set -euo pipefail

openclaw status
openclaw gateway status
openclaw channels status --probe || true
openclaw models status
openclaw agents list
