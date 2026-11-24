# 界面双语与站脚

← 返回 [README](../README.zh-CN.md)，英文版见 [README.md](../README.md)

站点的「双语」只覆盖**界面外壳**（导航、标签、页脚、搜索框、TOC、分页、404 等），正文与文章标题永远保持中文原文。这一页说明它怎么实现、改文案时改哪里、以及它明确不做的事。

## 为什么不走 Hugo 原生多语言

原生多语言会给每篇文章生成 `/en/` 副本，于是同一篇中文正文有两种语言的 URL：

- Blowfish 的 `head.html` 会为 `.AllTranslations` 输出 `<link rel="alternate" hreflang>`，等于对搜索引擎声明「这两个 URL 是同一内容的不同语言版本」，而实际正文完全一样 → 重复内容 + 假语言信号。
- 正文不翻译，第二套 URL 没有任何检索价值，却要维护两棵内容树。

结论：**单 URL + 客户端界面语言层**。URL 不变、`sitemap.xml` 不变、`<html lang>` 保持 `zh-cn`（正文是中文，不给屏幕阅读器错误信号）。

## 组成

| 文件                                   | 作用                                                                                              |
| -------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `layouts/partials/extend-head.html`    | `<head>` 里的引导脚本 + 显隐 CSS：首帧前读 `localStorage.uiLang`，把 `data-ui-lang` 写到 `<html>` |
| `layouts/partials/extend-footer.html`  | 把字典与切换脚本**内联**进页面（`window.__UI_I18N__`），避免额外请求造成闪烁                      |
| `layouts/partials/ui-lang-switch.html` | 顶栏的「中 / EN」两个按钮（`data-ui-skip`，自己豁免翻译）                                         |
| `layouts/partials/header/basic.html`   | 主题版原样复制，唯一改动是插入切换器（见下）                                                      |
| `assets/js/ui-lang.js`                 | 遍历文本节点与 `title/aria-label/placeholder/alt`，按字典替换；切回中文时按存的原文回滚           |
| `assets/data/ui-i18n.json`             | **生成物**，勿手改                                                                                |
| `scripts/gen-ui-dict.py`               | 生成上述字典；`--check` 与主题表比对（漂移则非零退出）                                            |
| `data/ui-i18n-overlay.yaml`            | 手写补充：主题 i18n 表里没有的界面文案（菜单名、作者简介、404 标题）                              |
| `layouts/partials/footer.html`         | 标准站脚（版权 / 许可 / 链接），中英两段靠 `data-ui-zh`、`data-ui-en` 切换                        |

切换器为什么挂在 `header/basic.html` 而不是主题的 `header/components/translations.html`：后者只在 `hugo.IsMultilingual` 为真时被 `mobile-menu.html` 调用，本站单语，移动端会没有入口。

关键约束：`SKIP = ".article-content,.article-link__summary,article h1,pre,code,kbd,samp,textarea,script,style,[data-ui-skip]"`——正文、摘要、文章标题、代码与切换器自身永不替换。

## 字典怎么来

```bash
python3 scripts/gen-ui-dict.py           # 重新生成 assets/data/ui-i18n.json
python3 scripts/gen-ui-dict.py --check   # 只比对，漂移则 exit 1（security-check.sh 会调它）
```

- 源：`themes/blowfish/i18n/zh-CN.yaml` ↔ `en.yaml` 的逐键对照（`admonition.*` 属正文语气，已排除）。
- 带 Go 插值的串（如 `"{{ .Count }} 分钟"`）会被编译成客户端正则 + 模板（`^(\d+)\ 分钟$` → `$1 min`/`$1 mins`），复数按 `.one`/`.other` 选。
- 中文键是**渲染后的实际文本**，所以 `找不到网页 :confused:` 这种 emoji 短代码要在 overlay 里按渲染结果（`找不到网页 😕`）重新登记。

**主题升级后必须重跑生成器**——否则新版本新增/改写的界面键在英文界面里仍是中文，而 `security-check.sh` 会把它判成漂移。

## 页脚

标准两行结构：左列 `© 年份 作者` + 许可声明（中英两段，随语言切换），右列 GitHub / RSS / 许可链接。

刻意不写 `All rights reserved`：正文是 CC BY-NC-SA 4.0、代码是 MIT，保留所有权利与这两张许可自相矛盾。

右列间距、顶栏切换器与搜索框之间的间距都写在 `extend-head.html` 的原生 CSS 里（`.site-footer-links`、`.ui-lang-switch`），**不用 Tailwind utility**。

## 别在站点模板里用新的 Tailwind 类

Blowfish 的 Tailwind 只扫主题源码，站点级 `layouts/partials/` 里新写的类不会进 `public/css/main.bundle.min.*.css`——能用的只有主题自己也用到的那些。实测踩过的坑：`gap-x-4` / `gap-y-1` / `ms-1` / `me-7` / `p-0.5` / `sm:justify-end` 在产物里计数为 0，页面照常渲染但间距全丢，且不报任何错。

判定方法：

```bash
grep -c 'gap-x-4' public/css/main.bundle.min.*.css   # 0 = 这个类不会生效
```

需要站点独有的排版时，写进 `extend-head.html` 的 `<style>`（那段是手写 CSS，不经过 Tailwind，永远生效），或在 `assets/` 里加站点 CSS。

## 关于页

`content/about/index.md` 是**正文双语**的唯一例外：它的两段正文用 `<div data-ui-zh>` / `<div data-ui-en lang="en">` 并排写，靠 `extend-head.html` 的属性选择器显隐（无 JS 时显示中文），而 `ui-lang.js` 的 `SKIP` 含 `.article-content`，不会去翻译它们。

两点约束：

- 两段都要手写成 HTML——goldmark 不解析 raw HTML 块里的 markdown，写进去的 `##` 和 `-` 会原样显示。
- 大标题走 `layouts/about/single.html`（关于页专用的站点级布局，只保留 header + 正文骨架）：h1 里并列 `<span data-ui-zh>{{ .Title }}>` 与 `<span data-ui-en lang="en">{{ .Params.titleEn | default .Title }}>`，英文界面显示 frontmatter 的 `titleEn: "About"`。为什么另起布局而不改主题：主题 `_default/single.html` 的标题写死在模板里，没有 partial 接缝，而主题模板不可手改（升级会丢）。
- `<title>` 与 og/description 仍是中文「关于 · Vasant Long」——SEO 元数据不属界面，属既定取舍（见下节）。

## 明确不做的事

- **正文、文章标题、摘要、标签名不翻译。**唯一例外是「关于」页（见上），它写死了中英两段。
- **`<html lang>` 不随界面语言改**：正文是中文，改成 `en` 会让屏幕阅读器用英文音库念中文。代价是英文界面下 `lang` 不精确（已知取舍）。
- **SEO 元数据（`<title>`、`description`、og:）保持中文**：它们是内容的镜像，不属界面。
- **404 页的随机格言不翻译**（`themes/blowfish/data/quotes404.json`，纯装饰）。
- **面包屑在中文界面显示 `Posts` / `Tags`**：来自 section 页标题而非菜单名，属既有不一致，未处理。

## 验证

```bash
hugo --minify --gc --cleanDestinationDir
bash scripts/security-check.sh          # 含「界面语言层已注入」「顶栏含切换器」「字典无漂移」三项
```

浏览器里点一下顶栏 `EN`：导航/页脚/TOC/搜索框应转英文，正文与文章标题必须保持原样；刷新后仍是英文（`localStorage.uiLang=en`）；点 `中` 完全还原。
