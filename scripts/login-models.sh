#!/usr/bin/env bash
set -euo pipefail

echo "Logging in OpenAI/Codex provider. Follow the browser/device-code prompt."
openclaw models auth login --provider openai --device-code --set-default

cat <<'MSG'

Claude Opus fallback setup is subscription/account dependent.
If you have an Anthropic API key, run:

  openclaw models auth login --provider anthropic

If you want OpenClaw to reuse Claude Code subscription auth, run:

  openclaw configure

Then choose the Claude/Anthropic auth option offered by the wizard.

The configured Claude fallback/review model is:

  anthropic/claude-opus-4-7
MSG

openclaw models status
