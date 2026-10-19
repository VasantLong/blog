---
title: "第一篇：这个站点怎么来的"
date: 2026-10-19
draft: false
tags: ["meta", "hugo"]
summary: "搭建骨架 + 上线流程说明，顺便压测一下渲染管线（代码块、表格、数学公式）。"
showTableOfContents: true
---

站点用 [Hugo](https://gohugo.io/) + [Blowfish](https://blowfish.page/) 主题，构建产物由 GitHub Actions 推到 GitHub Pages，域名 `vasantlong.de5.net`。

## 一篇文怎么发

```bash
# 新建
hugo new content posts/my-new-post/index.md
# 本地预览（草稿也显示）
hugo server -D
```

改完推 `main`，Actions 自动构建部署。

{{< katex >}}

## 渲染管线自检

行内代码：`hugo --minify`；代码块：

```python
def ping_loss(samples: list[float]) -> float:
    return sum(1 for s in samples if s is None) / len(samples)
```

表格：

| 项 | 值 |
|---|---|
| 静态产物 | `public/` |
| 构建 | GitHub Actions |
| 域名 | vasantlong.de5.net |

数学公式（需 `{{</* katex */>}}` 短代码把 KaTeX 拉进来）：行内 $E = mc^2$，块级：

$$
\int_0^1 x^2 \, dx = \frac{1}{3}
$$
