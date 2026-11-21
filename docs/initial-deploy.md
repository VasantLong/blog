# 首次上线（留档，换域名时复用）

← 返回 [README](../README.zh-CN.md)，英文版见 [README.md](../README.md)

| #   | 执行位置   | 动作                                                                                            | 判据                                         |
| --- | ---------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------- |
| 1   | 浏览器     | `github.com/new` 建仓 `VasantLong/blog`（Public，三项初始化都不勾）                             | 仓库有 quick setup 页                        |
| 2   | 本机       | `git remote add origin git@github.com:VasantLong/blog.git && git push -u origin main`           | push 成功                                    |
| 3   | API/浏览器 | 开 Pages：`POST /repos/{o}/{r}/pages` body `{"build_type":"workflow"}`                          | 返回 201，`build_type=workflow`              |
| 4   | —          | 等 Actions 首跑；失败看 `GET /repos/{o}/{r}/actions/runs`                                       | build + deploy 都 success                    |
| 5   | CF         | 子域 zone `vasantlong.de5.net` 加 4 条 A（Name `@`，灰云）                                      | `dig +short vasantlong.de5.net A` 出 4 个 IP |
| 6   | API        | **先** `PUT /repos/{o}/{r}/pages` body `{"cname":"vasantlong.de5.net"}`                         | 204                                          |
| 7   | API        | 轮询 `pages.https_certificate.state` 到 `approved`，**再** `PUT` body `{"https_enforced":true}` | 204，`https_enforced=true`                   |

> **坑**：第 6 步不要同时塞 `https_enforced: true`，否则报 404 `The certificate does not exist yet`（cert 还没签，API 拒绝）。必须 cname → cert approved → enforce 三步走。

第 5 步的 zone 归属与灰云硬要求见 [`infrastructure.md`](infrastructure.md)；上线后的巡检命令见 [`operations.md`](operations.md)。
