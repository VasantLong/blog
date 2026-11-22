# 取舍记录

跨模块、有明确代价的结构性取舍记在这里。单条决策被翻案、且需要论证备选方案时，才升级成 `docs/adr/NNNN-*.md`（花园站的两条架构决策已是 ADR）。

← 返回 [README](../README.zh-CN.md)，英文版见 [README.md](../README.md)

- **DNS 走子域委派而不是 DNSHE 直连 A 记录**：`de5.net` 整域在 DNSHE，但 DNS 希望在 Cloudflare 统一管（与旧 `lexigraph` 一致）。代价：多一层 NS 委派 + 多一个 CF zone 维护。收益：以后加记录/换目标都在 CF 一个界面。
- **灰云（DNS only）不是可选项而是硬要求**：橙云时 Pages 的 Let's Encrypt 校验会失败，且 CF 边缘在国内实测半通。
- **主题 vendored 而非 submodule**：本机到 `github.com:443` 实测持续不通（git clone 134s 超时），但 `codeload.github.com` 可下载打包；vendored 后 CI 不需要 `submodules: true`，也不受上游 retag 影响。代价：约 12MB 主题进仓库，升级走脚本。
- **关掉 Firebase views/likes**：避免页面挂外部请求，首屏更干净。
- **代码与内容分许可**：`content/` 走 CC BY-NC-SA 4.0（允许转载/翻译，禁商用，要求同许可回馈），其余走 MIT；vendored 主题保留上游 MIT 并单列 `NOTICE`。代价：GitHub 仓库页头只显示 "View license" 而非单一标识，且新增文件时要判断落在哪个范围。收益：正文不被当成代码授权，主题归属不留模糊地带。
- **界面双语走客户端语言层，不走 Hugo 原生多语言**：原生方案会给每篇中文正文生成 `/en/` 副本，而 `head.html` 的 `hreflang` 会对搜索引擎声明「两种语言版本」，正文却完全一样 → 重复内容与假语言信号。改为单 URL + `data-ui-lang` 客户端替换界面文案（`docs/ui-language.md`）。代价：字典是主题 i18n 表的生成物，主题升级后必须重跑 `scripts/gen-ui-dict.py`，否则漏译；`<html lang>` 不随之变化（已知 a11y 取舍）。收益：URL 稳定、无重复内容、正文零改动。

花园站分工与内容来源的架构决策见 [`adr/`](adr/)。
