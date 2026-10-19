# blog

个人博客：**Hugo + Blowfish** → 构建产物由 **GitHub Actions** 推 **GitHub Pages** → 域名
**<https://vasantlong.de5.net>**（DNS 在 DNSHE，A 记录直指 Pages IP，无 CDN/代理）。

## 结构

```
config/_default/      params.toml / markup.toml / languages.zh-cn.toml / menus.zh-cn.toml（站点主配置在根 hugo.toml）
content/              _index.md(首页) / about/ / posts/<slug>/index.md
static/CNAME          vasantlong.de5.net（Pages 自定义域名，产物里必须有）
themes/blowfish/      主题 v3.9.0，**裁剪后 vendored**（非 submodule），见 scripts/update-theme.sh
scripts/dev.sh        本地预览
scripts/update-theme.sh  换主题版本
.github/workflows/pages.yml  构建 + 部署
```

## 日常写作

```bash
hugo new content posts/my-post/index.md   # 生成 posts/my-post/index.md（draft: true）
# 写正文 → draft 改 false → 提交推送 main → Actions 自动部署
```

本地预览（需 hugo **extended** ≥ 0.162；本机二进制在 `~/tmp/hugo/hugo`，不进仓库）：

```bash
HUGO=~/tmp/hugo/hugo scripts/dev.sh          # http://127.0.0.1:1313
# 或 docker: docker run --rm -it -p 1313:1313 -v "$PWD":/src -w /src klakegg/hugo:ext server -D
```

数学公式：页面里加 `{{</* katex */>}}` 短代码才会加载 KaTeX（否则 `$...$` 保持原文）。

## 上线 runbook（一次性，按顺序执行）

| # | 执行位置 | 动作 | 完成判据 |
|---|---|---|---|
| 1 | 浏览器 | <https://github.com/new> 建空仓 `VasantLong/blog`，**Public**，不勾 README/gitignore/license | 仓库页显示 quick setup |
| 2 | 本机 | `git remote add origin git@github.com:VasantLong/blog.git && git push -u origin main` | push 无报错 |
| 3 | 浏览器 | 仓库 → **Settings → Pages → Build and deployment → Source = GitHub Actions** | Source 显示 GitHub Actions |
| 4 | 浏览器 | 仓库 → **Actions** 看首次 “Deploy Hugo site to Pages” | build + deploy 两步 ✅，环境给出 `*.github.io` 临时地址可访问 |
| 5 | DNSHE 控制台 | 给 `de5.net` 加 **4 条 A 记录**：主机记录 `vasantlong`，值 `185.199.108.153` / `185.199.109.153` / `185.199.110.153` / `185.199.111.153`，TTL 默认。**不要加 CNAME**，不要加 AAAA | `dig +short vasantlong.de5.net A` 返回这 4 个 IP |
| 6 | 浏览器 | 仓库 → Settings → Pages → **Custom domain** 填 `vasantlong.de5.net` → Save | DNS check 变绿 |
| 7 | 浏览器 | 同页勾 **Enforce HTTPS**（证书签发通常 5–15 分钟，期间勾选框可能灰） | 勾选成功且 https 无证书告警 |

## 验收（本机执行）

```bash
dig +short vasantlong.de5.net A                    # 期望: 185.199.108.153 …111.153 四条
dig +short de5.net CAA; dig +short vasantlong.de5.net CAA   # 期望: 都为空（无 CAA 即不限制 Let's Encrypt）
curl -sI https://vasantlong.de5.net | head -3      # 期望: HTTP/2 200
curl -s https://vasantlong.de5.net | grep -o '<title>[^<]*</title>'   # 期望: <title>Vasant Long</title>
curl -sI https://vasantlong.de5.net/posts/hello-world/ | head -1      # 期望: 200
```

再在移动网络 / 无代理浏览器各开一次，确认首屏（目标是不走代理也能看）。

## 主题更新

```bash
scripts/update-theme.sh v3.10.0        # 下载 → 裁剪 → 替换 themes/blowfish（旧版进 ~/tmp/quarantine）
~/tmp/hugo/hugo --minify --gc          # 本地先确认构建通过
git diff --stat themes/blowfish | tail -3
```

## 取舍记录

- **主题 vendored 而非 submodule**：`github.com` 的 git clone 在当前链路实测 134s 仍超时，但 `codeload.github.com` 下载打包稳定可用；vendored 后 CI 不需要 `submodules: true`，也不受上游 retag 影响。代价：约 12MB 主题进仓库，升级走脚本。
- **不加 Cloudflare**：`lexigraph.de5.net` 曾整子域委派到 CF；本站在 CF 边缘实测半通，且多一次可能被污染的解析，因此 A 记录直指 Pages IP。
- **关掉 Firebase views/likes**：避免页面挂外部请求，首屏更干净。
- **单语（zh-cn）**：加双语只需新增 `config/_default/languages.en.toml` + `menus.en.toml` 并落定 `defaultContentLanguage`。
