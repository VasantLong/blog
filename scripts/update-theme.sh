#!/usr/bin/env bash
# 更新 vendored 主题（themes/blowfish 是裁剪后提交进仓库的副本，不是 submodule）
# 用法: scripts/update-theme.sh v3.9.0
set -euo pipefail

VER="${1:-}"
[ -n "$VER" ] || { echo "用法: $0 <tag，例如 v3.9.0>" >&2; exit 1; }

REPO="nunocoracao/blowfish"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# github.com 的 git/下载在部分网络下不通，codeload 通常可用
URL="https://codeload.github.com/$REPO/tar.gz/refs/tags/$VER"
echo "下载 $URL"
curl -fsSL --retry 3 "$URL" -o "$TMP/theme.tgz"
tar -xzf "$TMP/theme.tgz" -C "$TMP"
SRC="$TMP/blowfish-${VER#v}"

# 裁剪：只留运行必需（exampleSite/images 占 ~110MB，文档站专用）
rm -rf "$SRC"/{exampleSite,images,.github,.claude,.claude-plugin,node_modules}
rm -f "$SRC"/{package.json,package-lock.json,tailwind.config.js,lighthouserc.js,netlify.toml,config.toml,go.mod}
rm -f "$SRC"/{findMissingTranslations.js,genArticle.js,genLang.js,genLangLinks.js,processUsers.js,update-github-data.sh,FUNDING.yml,CLAUDE.md,CONTRIBUTING.md}
rm -f "$SRC"/README.*.md

TRASH="${TRASH_DIR:-$HOME/tmp/quarantine}/blowfish-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$(dirname "$TRASH")"
mv "$ROOT/themes/blowfish" "$TRASH"
cp -a "$SRC" "$ROOT/themes/blowfish"
echo "已替换 themes/blowfish → $VER（旧版移到 $TRASH）"
echo "下一步: 本地 hugo 构建确认无报错，然后把版本号写进 README 与 commit message"
