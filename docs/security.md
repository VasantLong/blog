# 安全基线（2026-10-19 审查）

← 返回 [README](../README.md)

## 已开

- HTTPS 强制（Enforce HTTPS）+ Let's Encrypt 证书；`http → https` 301
- `main` 分支保护：禁 force-push、禁删除，**admin 同样受限**（enforce_admins=true）
- Actions 全部钉 commit SHA（不再是可变 tag `@v4/@v5`）
- Actions 默认 `GITHUB_TOKEN` 权限 = read-only；workflow 自身最小权限（`contents: read` + `pages: write` + `id-token: write`）
- secret scanning + push protection（公开仓默认开启）
- 仓库 Issues 已关闭（公开仓任何人可提交，少一个垃圾/社工入口）
- Dependabot alerts + security updates 已开启（无 npm 依赖，主要盯 actions 版本）
- 站点**零第三方运行时资源**：无 CDN、无外部字体、无统计、无表单提交、无 cookie；本地资源全部带 `integrity`

## 结构性限制（改不了，记录在案）

GitHub Pages **不下发自定义响应头** → 没有 HSTS / CSP / X-Content-Type-Options / Referrer-Policy。
要安全头只能二选一：① 换 Cloudflare Pages（支持 `_headers` 文件）；② 经 CF 代理注入 —— **不可取**，橙云会让 Pages 自定义域名校验与证书签发失败，且 CF 边缘在国内实测半通。

## 账号 / DNS 侧待办（不在本仓，见 `~/projects/vps/TODO.md`）

- [x] GitHub 2FA（本人已确认开启）
- [x] 一次性 PAT `pi-blog-once` 已吊销、文件已 trash
- [x] `minihub-pi` SSH key 已带口令；`minihub-vps-ops`（root@wg-vps 那把）已补口令并在 agent 中重新加载
- [ ] `lexigraph.de5.net` 若不再恢复：清掉 CF zone 的记录/zone，别指向已释放的机器
- ~~`_dmarc.de5.net`~~ **作废**：父域在服务商手里，我们只能管 `vasantlong.de5.net` 这个名字
- ~~DNSSEC~~ **作废**：父域不给我们放 DS，子域开 DNSSEC 无法形成信任链
- 共享父域带来的固有风险（记录在案，不可修）：同区其他用户的名字与本站在同一父域下，无法影响彼此的 cookie/声誉；本站不设 cookie、无表单，因此无跨子域数据暴露面
