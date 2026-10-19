#!/usr/bin/env bash
# 本地预览：优先用 HUGO 环境变量指定的二进制，其次 PATH 里的 hugo（需 extended ≥ 0.162）
set -euo pipefail
HUGO_BIN="${HUGO:-hugo}"
exec "$HUGO_BIN" server -D --port "${PORT:-1313}" --bind "${BIND:-127.0.0.1}"
