# 运维：验收、主题升级、workflow 维护

← 返回 [README](../README.md)

## 验收（可随时重跑）

```bash
dig +short vasantlong.de5.net A          # 4 个 185.199.x.153
dig +short vasantlong.de5.net CAA; dig +short de5.net CAA    # 均为空 → 不限制 Let's Encrypt
curl -sI https://vasantlong.de5.net | head -3                # HTTP/2 200
curl -s https://vasantlong.de5.net | grep -o '<title>[^<]*</title>'   # <title>Vasant Long</title>
for p in / /about/ /tags/ /posts/hello-world/ /sitemap.xml /robots.txt; do
  printf '%-20s %s\n' "$p" "$(curl -s -o /dev/null -w '%{http_code}' https://vasantlong.de5.net$p)"
done
curl -s -o /dev/null -w '%{http_code}\n' https://vasantlong.de5.net/no-such-page/   # 404
openssl s_client -connect vasantlong.de5.net:443 -servername vasantlong.de5.net </dev/null 2>/dev/null | openssl x509 -noout -subject -dates
```

2026-10-19 实测：首页 200 / total 0.52s（TLS 建连 0.42s）、CSS 200（131KB）、文章页表格与 KaTeX 正常。

机器可读的那 12 项不变量在 `scripts/security-check.sh`（`security.yml` 每跑同一套）；基线与结构性限制见 [`security.md`](security.md)。

## 主题升级

```bash
scripts/update-theme.sh v3.10.0        # 下载 → 裁剪 → 替换 themes/blowfish（旧版进 ~/tmp/quarantine）
~/tmp/hugo/hugo --minify --gc          # 本地先确认构建通过
git diff --stat themes/blowfish | tail -3
```

升级后把新版本号写进本文件与 commit message，并同步 [`../README.md`](../README.md)「仓库结构」里的 vX.Y.Z。

## Workflow 维护

- 定时 `Security checks` 在仓库连续 **60 天无活动**后会被 GitHub 自动停用；正常写文章就够保持活跃，长期不写记得手动 `workflow_dispatch` 唤醒一次。
- 改 Hugo 版本要两处一起改：`pages.yml` 的 `HUGO_VERSION` 与 `with.hugo-version`。
