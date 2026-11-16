# 花园独立成站，博客保持 Hugo

想在博客之外发布 Obsidian 笔记。实测 Hugo + Blowfish：排版层通（callout、任务列表、折叠、脚注、块级公式），链接层不通（`[[..]]` 不被 goldmark 解析、render hook 不被调用，`%%私有注释%%` 会原样泄漏），补齐需 200–300 行构建前预处理脚本，且换不来反链与嵌入。Quartz 5.1.0 探针验证：用 Obsidian 自己的解析器，双链/嵌入/高亮/行内脚注/图片尺寸全部原生可用，并有构建期发布闸门（`explicit-publish` 白名单）可证明私密内容不进产物。博客主题是 vendored 的 Blowfish（禁改）且带 12 项安全不变量自检，不宜为笔记语法改造。

决定：花园做成独立站点 `notes.vasantlong.de5.net`（独立 GitHub 仓 + Quartz 5 + GitHub Actions → Pages），博客继续 Hugo + Blowfish 原地不动。两站只以绝对 URL 互相指认（跨站 `[[..]]` 无法解析）；花园 URL 无结尾斜杠，博客有，跨站链接不得补斜杠。

## 考虑过的选项

- **A. 留在 Hugo，加预处理层**：一处 CI、一份安全基线；代价是 200–300 行自维护的语法垫片，且永远拿不到反链、笔记嵌入与图谱。
- **C. 全盘换 Quartz**：语法一次到位；代价是丢主题定制、12 项安全自检大半失效、URL 带斜杠形态改变导致存量链接断、笔记全量进搜索索引。

## 后果

- 两条 CI、两套前端、两种内容模型（post bundle vs 扁平 vault）要各自维护。
- 花园的内容必须落在 GitHub 可达的仓里：GitHub Actions 摸不到 Gitea / minihub，所以任何"从知识库直出"的方案都得先解决单向导出。
- 中文全文搜索在 Quartz 默认配置下只能做词首前缀命中（FlexSearch `tokenize: "forward"`），属于已知降级而非缺陷。
