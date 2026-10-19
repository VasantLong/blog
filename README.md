# blog

个人博客：**Hugo + Blowfish** → **GitHub Actions** 构建 → **GitHub Pages** → 域名 **<https://vasantlong.de5.net>**

状态（2026-10-19）：已上线。Actions run #1 build/deploy 双绿，证书 `CN=vasantlong.de5.net`（Let's Encrypt，至 2027-01-17），`http → https` 301，Enforce HTTPS 已开。

## DNS 拓扑（改之前先看懂这张图）

```
registrar/DNSHE  zone de5.net  (a/b.ns.dnshe.org)      ← de5.net 整域权威在这里
  └─ NS 委派: vasantlong.de5.net → ian/tina.ns.cloudflare.com
       └─ CF zone vasantlong.de5.net                   ← 这个子域的记录都在 CF 里改
            └─ A @ → 185.199.108.153 / .109 / .110 / .111   （Proxy = DNS only 灰云！）
                 └─ GitHub Pages（构建产物 = .github/workflows/pages.yml 产出的 public/）
```

- **站点内容/记录相关改动去 CF**：`vasantlong.de5.net` 这个 zone（灰云，不要开橙云——橙云会让 Pages 证书签发失败，且多一次可能被污染的边缘解析）
- **委派本身要改才去 DNSHE**：那 2 条 NS 记录
- `lexigraph.de5.net`：CF 里另有一个它的子域 zone（旧 wordnet 站），与本博客无关；若不再恢复 wordnet，建议把它的 A 记录/zone 清掉，避免指着一台已释放的机器
- **`de5.net` 是 DNSHE 的免费子域服务**：整域不归我们所有，名下只有 `vasantlong` 与 `lexigraph` 两个名字。因此下面这些**都改不了**：父域 `_dmarc.de5.net`、父域 CAA、父域 DNSSEC(DS)。
- 免费子域服务的区里还能看到别人的名字（`www`/`test`/`dev`/`admin`/`cdn` 分别委派到不同的 CF zone，`blog` 指向一台已失联的腾讯云 IP）——**都不是我们的，无需处理**，也别把它们当成自己的资产。

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

## 日常写作（发一篇的完整路径）

Hugo 已装在 `~/.local/bin/hugo`（v0.168.0 extended，PATH 里可直接用）；CI 用的是同一个版本号。

### 1. 建稿

```bash
cd ~/projects/blog
scripts/new-post.sh my-slug "文章标题" "标签1,标签2"   # slug 决定 URL: /posts/my-slug/
# 等价手动方式：hugo new content posts/my-slug/index.md
```

生成的是 `content/posts/<slug>/index.md`，`draft: true`（**草稿不会被构建、不会被部署**）。

### 2. 写 + 预览

```bash
hugo server -D                 # http://127.0.0.1:1313，-D 让草稿也显示
```

常用 front matter：

| 字段 | 作用 |
|---|---|
| `title` / `date` | 标题、发布日（`date` 在未来且 `buildFuture=false` 时**不会构建**，等于定时发布） |
| `tags` | 自动生成 `/tags/<tag>/` 归档页 |
| `summary` | 列表页摘要；不填则截取正文 |
| `draft` | `true` = 草稿 |
| `showTableOfContents` | 是否显示目录 |
| `cover` / `images` | 特色图（写在 front matter，图片放同目录） |

图片用 **page bundle**：放在 `content/posts/<slug>/` 里，正文写 `![说明](photo.png)`（同目录相对路径，构建时自动处理）。

数学公式要加短代码才会加载 KaTeX：

```markdown
{{</* katex */>}}
行内 $E=mc^2$，块级 $$\int_0^1 x^2 dx$$
```

### 3. 发布

```bash
# 1) 把 draft 改 false
hugo --minify --gc --cleanDestinationDir   # 本地先构建一遍，确认没报错
bash scripts/security-check.sh              # 顺手跑不变量自检

# 2) 提交（commit 格式：type(scope): English (中文关键词)）
git add -A && git commit -m "post(blog): add my-slug (新文章标题)"
git push origin main
```

> `--cleanDestinationDir` 别省：删掉或改名文章后，不加它 `public/` 里会留**僵尸页**（本地预览会看到已删的文章）。CI 是全新 checkout，不受影响。

### 4. 验证（3 条都过才算发完）

```bash
# a) Actions 两个 workflow 都绿（Deploy + Security checks）
curl -s "https://api.github.com/repos/VasantLong/blog/actions/runs?per_page=4" \
  | jq -r '.workflow_runs[] | "\(.name): \(.status)/\(.conclusion)"'

# b) 本地不变量自检
bash scripts/security-check.sh

# c) 线上真的能打开（CDN 生效通常几秒）
curl -s -o /dev/null -w '%{http_code}\n' https://vasantlong.de5.net/posts/my-slug/
```

### 5. 直接推 `main` 合规吗？

合规。分支保护只禁 **force-push / 删除分支**，不禁正常推送——单人博客不值得为每篇文章走 PR。

> 定时 `Security checks` 在仓库连续 **60 天无活动**后会被 GitHub 自动停用；正常写文章就够保持活跃，长期不写记得手动 `workflow_dispatch` 唤醒一次。


## 首次上线的完整流程（留档，换域名时复用）

| # | 执行位置 | 动作 | 判据 |
|---|---|---|---|
| 1 | 浏览器 | `github.com/new` 建仓 `VasantLong/blog`（Public，三项初始化都不勾） | 仓库有 quick setup 页 |
| 2 | 本机 | `git remote add origin git@github.com:VasantLong/blog.git && git push -u origin main` | push 成功 |
| 3 | API/浏览器 | 开 Pages：`POST /repos/{o}/{r}/pages` body `{"build_type":"workflow"}` | 返回 201，`build_type=workflow` |
| 4 | — | 等 Actions 首跑；失败看 `GET /repos/{o}/{r}/actions/runs` | build + deploy 都 success |
| 5 | CF | 子域 zone `vasantlong.de5.net` 加 4 条 A（Name `@`，灰云） | `dig +short vasantlong.de5.net A` 出 4 个 IP |
| 6 | API | **先** `PUT /repos/{o}/{r}/pages` body `{"cname":"vasantlong.de5.net"}` | 204 |
| 7 | API | 轮询 `pages.https_certificate.state` 到 `approved`，**再** `PUT` body `{"https_enforced":true}` | 204，`https_enforced=true` |

> **坑**：第 6 步不要同时塞 `https_enforced: true`，否则报 404 `The certificate does not exist yet`（cert 还没签，API 拒绝）。必须 cname → cert approved → enforce 三步走。

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

## 主题更新

```bash
scripts/update-theme.sh v3.10.0        # 下载 → 裁剪 → 替换 themes/blowfish（旧版进 ~/tmp/quarantine）
~/tmp/hugo/hugo --minify --gc          # 本地先确认构建通过
git diff --stat themes/blowfish | tail -3
```

## 安全基线（2026-10-19 审查）

**已开**

- HTTPS 强制（Enforce HTTPS）+ Let's Encrypt 证书；`http → https` 301
- `main` 分支保护：禁 force-push、禁删除，**admin 同样受限**（enforce_admins=true）
- Actions 全部钉 commit SHA（不再是可变 tag `@v4/@v5`）
- Actions 默认 `GITHUB_TOKEN` 权限 = read-only；workflow 自身最小权限（`contents: read` + `pages: write` + `id-token: write`）
- secret scanning + push protection（公开仓默认开启）
- 仓库 Issues 已关闭（公开仓任何人可提交，少一个垃圾/社工入口）
- Dependabot alerts + security updates 已开启（无 npm 依赖，主要盯 actions 版本）
- 站点**零第三方运行时资源**：无 CDN、无外部字体、无统计、无表单提交、无 cookie；本地资源全部带 `integrity`

**结构性限制（改不了，记录在案）**

GitHub Pages **不下发自定义响应头** → 没有 HSTS / CSP / X-Content-Type-Options / Referrer-Policy。
要安全头只能二选一：① 换 Cloudflare Pages（支持 `_headers` 文件）；② 经 CF 代理注入 —— **不可取**，橙云会让 Pages 自定义域名校验与证书签发失败，且 CF 边缘在国内实测半通。

**账号/DNS 侧待办**（不在本仓，见 `~/projects/vps/TODO.md`）

- [x] GitHub 2FA（本人已确认开启）
- [x] 一次性 PAT `pi-blog-once` 已吊销、文件已 trash
- [x] `minihub-pi` SSH key 已带口令；`minihub-vps-ops`（root@wg-vps 那把）已补口令并在 agent 中重新加载
- [ ] `lexigraph.de5.net` 若不再恢复：清掉 CF zone 的记录/zone，别指向已释放的机器
- ~~`_dmarc.de5.net`~~ **作废**：父域在服务商手里，我们只能管 `vasantlong.de5.net` 这个名字
- ~~DNSSEC~~ **作废**：父域不给我们放 DS，子域开 DNSSEC 无法形成信任链
- 共享父域带来的固有风险（记录在案，不可修）：同区其他用户的名字与本站在同一父域下，无法影响彼此的 cookie/声誉；本站不设 cookie、无表单，因此无跨子域数据暴露面



## 取舍记录

- **DNS 走子域委派而不是 DNSHE 直连 A 记录**：`de5.net` 整域在 DNSHE，但 DNS 希望在 Cloudflare 统一管（与旧 `lexigraph` 一致）。代价：多一层 NS 委派 + 多一个 CF zone 维护。收益：以后加记录/换目标都在 CF 一个界面。
- **灰云（DNS only）不是可选项而是硬要求**：橙云时 Pages 的 Let's Encrypt 校验会失败，且 CF 边缘在国内实测半通。
- **主题 vendored 而非 submodule**：本机到 `github.com:443` 实测持续不通（git clone 134s 超时），但 `codeload.github.com` 可下载打包；vendored 后 CI 不需要 `submodules: true`，也不受上游 retag 影响。代价：约 12MB 主题进仓库，升级走脚本。
- **关掉 Firebase views/likes**：避免页面挂外部请求，首屏更干净。
- **单语（zh-cn）**：加双语只需新增 `config/_default/languages.en.toml` + `menus.en.toml` 并落定 `defaultContentLanguage`。
