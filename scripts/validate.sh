#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# A set LESS suppresses git's default LESS=FRX, so the pager blocks on empty
# output. Never page: this script must run unattended.
export GIT_PAGER=cat

git --no-pager diff --check

ruby scripts/validate.rb
"${PYTHON:-python3}" scripts/render_readme.py
