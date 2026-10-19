# blog — AGENTS.md

Hugo + Blowfish → GitHub Actions → GitHub Pages → <https://vasantlong.de5.net>。
**唯一权威文档是本仓 `README.md`**（DNS 拓扑、上线 runbook、验收命令、取舍记录都在里面）。本文件只写「不读就会犯错」的规则。

## 命令速查

```bash
scripts/new-post.sh <slug> "标题" "tag1,tag2"   # 起稿（slug 决定 URL）
hugo server -D                                  # 本地预览，草稿也显示
hugo --minify --gc --cleanDestinationDir        # 构建（CI 用同一命令但不带 --cleanDestinationDir）
bash scripts/security-check.sh                  # 12 项不变量自检
scripts/update-theme.sh v3.10.0                 # 换主题版本
```

`hugo` 已装 `~/.local/bin/hugo`（v0.168.0 extended）；CI 钉同名版本，改版本号要两处一起改（workflow 的 `HUGO_VERSION` + `with.hugo-version`）。

## 硬规则

- **不手改 `themes/blowfish/`**：主题是裁剪后 vendored 的，改动会在下次 `update-theme.sh` 时丢；定制走 `assets/`、`layouts/` 的站点级 override。
- **不提交 `public/`、`resources/`**（`.gitignore` 已覆盖）；部署只走 Actions 产物。
- **不动 `static/CNAME`**：内容必须是 `vasantlong.de5.net`，否则 Pages 自定义域名失效。
- **不动 `config/_default/markup.toml` 的 goldmark/highlight/tableOfContents 段**：主题硬依赖（缺 `passthrough` 数学公式失效、缺 `noClasses=false` 代码高亮失效）。
- **不在 `de5.net` 父域上做任何配置**：`de5.net` 是 DNSHE 免费子域服务，我们只有 `vasantlong` / `lexigraph` 两个名字的权限；父域 `_dmarc`/CAA/DNSSEC 一律改不了。
- **不给 Pages 开 Cloudflare 橙云**：会让自定义域名校验与证书签发失败。记录永远是灰云 + A 直指 `185.199.108-111.153`。
- 直推 `main` 合规（分支保护只禁 force-push / 删除）；commit 用 `type(scope): English (中文关键词)`。

## 会再踩的坑

- **删/改文章后本地构建必须加 `--cleanDestinationDir`**，否则 `public/` 留僵尸页（本地预览仍能看到已删文章）。CI 全新 checkout 不受影响。
- **Pages REST 开 Enforce HTTPS 要分三步**：先 `PUT {cname}` → 轮询 `https_certificate.state == approved` → 再 `PUT {https_enforced:true}`。合并成一次会 404 `The certificate does not exist yet`。
- **openssl 3.x 输出 `CN = host`（等号带空格）**，1.x 是 `CN=host`；解析证书主题必须先去空白。`security-check.sh` 已处理。
- **GitHub 定时 workflow 在仓库 60 天无活动后自动停用**，长期不写文章要手动 `workflow_dispatch` 唤醒。
- 本机 `github.com:443` 不通（`git clone` 会超时），下载 GitHub 资源走 `codeload.github.com` 或 `api.github.com` 的 asset 端点，详见 kb `infrastructure/minihub-pi-部署.md` 出网矩阵。

## 站点能力边界

- 没有安全响应头（HSTS/CSP/XCTO/Referrer-Policy）——GitHub Pages 不下发自定义头，这是产品限制，不是配置漏项。别去加 meta 假装解决。
- 无 cookie、无表单、无第三方运行时资源，这是刻意的攻击面控制；加评论/统计前先回到本仓 README「安全基线」评估。
