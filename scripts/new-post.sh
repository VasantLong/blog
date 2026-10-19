#!/usr/bin/env bash
# 新建文章：scripts/new-post.sh <slug> "标题" [tag1,tag2]
# slug 用英文/连字符（决定 URL：/posts/<slug>/）
set -euo pipefail

if [ $# -lt 1 ]; then
  echo '用法: scripts/new-post.sh <slug> "标题" [tag1,tag2]' >&2
  exit 1
fi
slug=$1
title=${2:-$1}
tags=${3:-}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
dir="$ROOT/content/posts/$slug"

if [ -e "$dir" ]; then
  echo "已存在: $dir（换个 slug）" >&2
  exit 1
fi

mkdir -p "$dir"

tags_yaml='[]'
if [ -n "$tags" ]; then
  tags_yaml="[$(printf '%s' "$tags" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$' | sed 's/.*/"&"/' | paste -sd ', ' -)]"
fi

{
  printf -- '---\n'
  printf 'title: "%s"\n' "$title"
  printf 'date: %s\n' "$(date +%Y-%m-%dT%H:%M:%S%:z)"
  printf 'draft: true\n'
  printf 'tags: %s\n' "$tags_yaml"
  printf 'summary: ""\n'
  printf 'showTableOfContents: true\n'
  printf -- '---\n\n'
  printf '正文从这里开始。\n'
} > "$dir/index.md"

echo "已创建 content/posts/$slug/index.md（draft: true）"
echo "预览: hugo server -D      发布: draft 改 false 后 commit + push"