# blog

[English](README.md) | [简体中文](README.zh-CN.md)

个人博客：**Hugo + Blowfish** → **GitHub Actions** 构建 → **GitHub Pages** → 域名 **<https://vasantlong.de5.net>**

状态（2026-10-19）：已上线。Actions run #1 build/deploy 双绿，证书 `CN=vasantlong.de5.net`（Let's Encrypt，至 2027-01-17），`http → https` 301，Enforce HTTPS 已开。

## 快速开始

```bash
scripts/new-post.sh my-slug "文章标题" "tag1,tag2"   # 起稿（slug 决定 URL）
hugo server -D                                      # 本地预览，草稿也显示
```

发一篇文章的完整路径见 [`docs/writing.md`](docs/writing.md)。

## 文档地图

| 文档                                               | 回答什么问题                                                                |
| -------------------------------------------------- | --------------------------------------------------------------------------- |
| [`docs/writing.md`](docs/writing.md)               | 怎么发一篇文章：建稿、front matter、page bundle、KaTeX、发布与 3 条验证     |
| [`docs/infrastructure.md`](docs/infrastructure.md) | DNS 拓扑、CF 与 DNSHE 各改什么、父域边界、托管侧行为                        |
| [`docs/initial-deploy.md`](docs/initial-deploy.md) | 首次上线 / 换域名的 7 步流程，以及 Enforce HTTPS 的坑                       |
| [`docs/operations.md`](docs/operations.md)         | 巡检验收命令、主题升级、workflow 维护                                       |
| [`docs/ui-language.md`](docs/ui-language.md)       | 界面双语（单 URL，不生成 `/en/`）：字典怎么生成、站脚、以及刻意不翻译的部分 |
| [`docs/security.md`](docs/security.md)             | 已开的安全项、Pages 结构性限制、账号与 DNS 侧待办                           |
| [`docs/decisions.md`](docs/decisions.md)           | 取舍记录（DNS 委派、灰云、vendored 主题…）                                  |
| [`CONTEXT.md`](CONTEXT.md)                         | 领域术语：博客与花园的分工、发布态词汇                                      |
| [`docs/adr/`](docs/adr/)                           | 架构决策：花园独立成站、花园只从专用 vault 出                               |
| [`AGENTS.md`](AGENTS.md)                           | AI 贡献者规则手册（不读就会犯错的那几条）                                   |

## 仓库结构

```text
config/_default/      params.toml / markup.toml / languages.zh-cn.toml / menus.zh-cn.toml（站点主配置在根 hugo.toml）
content/              _index.md(首页) / about/ / posts/<slug>/index.md
static/CNAME          vasantlong.de5.net（Pages 自定义域名，产物里必须有）
themes/blowfish/      主题 v3.9.0，**裁剪后 vendored**（非 submodule），见 scripts/update-theme.sh
scripts/              dev.sh / new-post.sh / security-check.sh / update-theme.sh
.github/workflows/    pages.yml（构建 + 部署）、security.yml（不变量自检）
docs/                 运维文档（中文）与 ADR
CONTEXT.md            领域术语；AGENTS.md 是 AI 贡献者规则
```

## 许可证

三个范围，刻意分开：

| 范围                                                               | 许可                                                                             |
| ------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| `content/` —— 文章正文                                             | [CC BY-NC-SA 4.0](LICENSE-CONTENT)：可转载、可改编，需署名、非商用、相同方式共享 |
| 其余全部 —— 脚本、配置、文档、workflow、`hugo.toml`、`archetypes/` | [MIT](LICENSE)                                                                   |
| `themes/blowfish/` —— vendored 的上游主题                          | 上游 MIT，© 2022 Nuno Coração；遵循其自带许可，见 [NOTICE](NOTICE)               |

根许可是 MIT、内容不是，因此 GitHub 仓库页头会显示 "View license" 而不是单一标识——这是代码/内容分许可的正常结果，不是配置错。别删 `themes/blowfish/LICENSE`：那是主题自身的 MIT 授权，每次升级都要保留。
