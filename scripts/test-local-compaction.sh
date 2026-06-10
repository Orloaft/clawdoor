#!/usr/bin/env bash
# Gate for switching compaction to local ollama (qwen3:4b).
#
# Telegram /compact runs synchronously with compaction.timeoutSeconds=120, so
# the local model must summarize well inside that budget. The llama3.1:8b
# attempt "hung" because ollama was silently running on CPU — CUDA init was
# failing while the scheduler planned full GPU offload (see README, GPU
# troubleshooting). Run this after fixing the GPU; it refuses to pass on CPU.
#
# Usage: scripts/test-local-compaction.sh [model]   # default qwen3:4b
set -uo pipefail

MODEL="${1:-qwen3:4b}"
BUDGET_SECS=60   # half the 120s gateway timeout, leaves headroom for big transcripts

if ! systemctl is-active --quiet ollama; then
  echo "FAIL: ollama service not active"; exit 1
fi
if ! ollama list | grep -q "^${MODEL}"; then
  echo "FAIL: model ${MODEL} not pulled (ollama pull ${MODEL})"; exit 1
fi

prompt="Summarize this transcript into a compact context summary, preserving \
key decisions, file paths, and constraints: $(head -c 4000 "$(dirname "$0")/../docs/token-optimization.md" | tr '\n' ' ')"

echo "Running ${MODEL} summarization (budget ${BUDGET_SECS}s)..."
start="$(date +%s)"
out="$(timeout "$BUDGET_SECS" ollama run "$MODEL" --think=false --verbose "$prompt" 2>&1)"
rc=$?
elapsed=$(( $(date +%s) - start ))

if (( rc != 0 )); then
  echo "FAIL: did not finish within ${BUDGET_SECS}s (rc=${rc})."
  ollama ps
  echo "If 'PROCESSOR' above says CPU, fix the GPU first (see README)."
  exit 1
fi

processor="$(ollama ps | sed -n 2p | grep -oE '[0-9]+% *(CPU|GPU)' | head -1)"
echo "${out}" | grep -E 'eval rate|total duration' || true
echo "Finished in ${elapsed}s on ${processor:-?}."

if [[ "$processor" == *CPU* ]]; then
  echo "FAIL: ran on CPU — too slow for large real transcripts. Fix GPU first."
  exit 1
fi

cat <<MSG
PASS. To switch compaction to local (zero-cost):
  1. Edit config/baseline.json5: compaction.model -> "ollama/${MODEL}"
  2. ./scripts/apply-baseline.sh
  3. From Telegram: send a message, then /compact — confirm it completes.
MSG
