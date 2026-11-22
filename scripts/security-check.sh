#!/usr/bin/env bash
# 站点安全/可用性不变量自检。本地: bash scripts/security-check.sh（需先 hugo --minify 构建出 public/）
# 依赖: curl, openssl；dig 可选。外部网络抖动时有重试，不会因一次超时误报。
set -uo pipefail

HOST="vasantlong.de5.net"
EXPECT_A="185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153"
FAILS=0
fail() { printf 'FAIL  %s\n' "$*"; FAILS=$((FAILS + 1)); }
ok()   { printf 'ok    %s\n' "$*"; }
warn() { printf 'warn  %s\n' "$*"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 带重试的 HTTP 请求：echo 状态码；失败最终给 000
fetch() { # fetch <url> [outfile]
  local url=$1 out=${2:-/dev/null} code="" t
  for t in 1 2 3; do
    code=$(curl -sS -o "$out" -w '%{http_code}' --max-time 25 "$url" 2>/dev/null) || true
    if [ -n "$code" ] && [ "$code" != "000" ]; then printf '%s' "$code"; return 0; fi
    sleep 2
  done
  printf '000'
}

# ---------- 1. 线上可用性 ----------
code=$(fetch "https://$HOST/" "$TMP/idx.html")
[ "$code" = "200" ] && ok "https 首页 200" || fail "https 首页返回 $code"
grep -q '<title>Vasant Long</title>' "$TMP/idx.html" 2>/dev/null && ok "首页标题正确" || fail "首页标题缺失/不符"

# ---------- 2. HTTPS 强制 ----------
red=""
for t in 1 2 3; do
  red=$(curl -sS -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 25 "http://$HOST/" 2>/dev/null) || true
  case "$red" in 30*"https://$HOST/"*) break ;; esac
  sleep 2
done
case "$red" in
  30*"https://$HOST/"*) ok "http → https 跳转 (${red%% *})" ;;
  *) fail "http 未正确跳转: ${red:-无响应}" ;;
esac

# ---------- 3. 证书 ----------
cert=$(echo | timeout 20 openssl s_client -connect "$HOST:443" -servername "$HOST" 2>/dev/null)
subj=$(printf '%s' "$cert" | openssl x509 -noout -subject 2>/dev/null)
end=$(printf '%s' "$cert" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
subj_norm=$(printf '%s' "$subj" | tr -d '[:space:]') # openssl 3.x: "CN = host"；1.x: "CN=host"
case "$subj_norm" in
  *"CN=$HOST"*) ok "证书 CN = $HOST" ;;
  *) fail "证书主题不符: ${subj:-取不到}" ;;
esac
if [ -n "$end" ]; then
  days=$(( ( $(date -d "$end" +%s) - $(date +%s) ) / 86400 ))
  [ "$days" -gt 14 ] && ok "证书剩余 ${days} 天" || fail "证书仅剩 ${days} 天（<14，需处理）"
else
  fail "取不到证书到期时间"
fi

# ---------- 4. DNS ----------
if command -v dig >/dev/null 2>&1; then
  got=$(dig +short "$HOST" A 2>/dev/null | sort | tr '\n' ' ' | sed 's/ *$//')
  want=$(printf '%s\n' $EXPECT_A | sort | tr '\n' ' ' | sed 's/ *$//')
  [ "$got" = "$want" ] && ok "A 记录 = 4 个 Pages IP" || fail "A 记录异常: [$got] 期望 [$want]"
  cn=$(dig +short "$HOST" CNAME 2>/dev/null)
  [ -z "$cn" ] && ok "无 CNAME（直连 A，少一跳解析）" || warn "存在 CNAME: $cn"
  ns=$(dig +short "$HOST" NS 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')
  [ -n "$ns" ] && ok "子域 NS 委派: $ns" || warn "未检测到 NS 委派（应指向 CF）"
else
  warn "未安装 dig，跳过 DNS 检查"
fi

# ---------- 5. 构建产物 ----------
if [ -d public ]; then
  if [ -f public/CNAME ] && [ "$(tr -d '[:space:]' < public/CNAME)" = "$HOST" ]; then
    ok "public/CNAME 正确"
  else
    fail "public/CNAME 缺失或内容不符"
  fi
  [ -f public/404.html ] && ok "404.html 存在" || fail "缺少 404.html"
  extjs=$(grep -rhoE '<script[^>]+src="https?://[^"]+' public --include='*.html' 2>/dev/null | grep -v "$HOST" | head -3)
  extcss=$(grep -rhoE '<link[^>]+rel="stylesheet"[^>]+href="https?://[^"]+' public --include='*.html' 2>/dev/null | grep -v "$HOST" | head -3)
  if [ -z "$extjs$extcss" ]; then ok "运行时无第三方 script/styles（攻击面窄）"; else fail "发现第三方运行时资源: $extjs $extcss"; fi
  integ=$(grep -o 'integrity=' public/index.html 2>/dev/null | wc -l | tr -d ' ')
  [ "${integ:-0}" -ge 1 ] && ok "关键资源带 SRI integrity ($integ 处)" || warn "首页无 integrity 属性"
  # 界面语言层（UI i18n）：字典、切换脚本、<html data-ui-lang> 引导都必须进产物
  if grep -q '__UI_I18N__' public/index.html 2>/dev/null && grep -q 'data-ui-lang' public/index.html 2>/dev/null; then
    ok "界面语言层已注入（字典 + 切换脚本 + 引导）"
  else
    fail "界面语言层缺失：查 layouts/partials/extend-head.html 与 extend-footer.html"
  fi
  if grep -qE 'data-ui-lang-btn="?en' public/index.html 2>/dev/null; then
    ok "顶栏含中/EN 切换器"
  else
    fail "顶栏缺少中/EN 切换器"
  fi
  # 字典是生成物：主题 i18n 表变了而字典没重生成 → 英文界面漏译
  if python3 -c 'import yaml' 2>/dev/null; then
    if python3 scripts/gen-ui-dict.py --check >/dev/null 2>&1; then
      ok "界面字典与主题 i18n 表一致"
    else
      fail "界面字典漂移：跑 python3 scripts/gen-ui-dict.py 重新生成"
    fi
  else
    warn "未安装 PyYAML，跳过界面字典漂移检查（本地务必跑 gen-ui-dict.py --check）"
  fi
else
  fail "public/ 不存在（先 hugo --minify 构建）"
fi

# ---------- 6. 结构提醒 ----------
warn "GitHub Pages 不支持自定义响应头 → 无 HSTS/CSP/XCTO/Referrer-Policy（结构限制，非本检查可修）"

if [ "$FAILS" -gt 0 ]; then
  printf '\n== %d 项失败 ==\n' "$FAILS"
  exit 1
fi
printf '\n== 全部通过 ==\n'
