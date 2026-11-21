# 写作与发布

一篇文章从建稿到线上的完整路径。← 返回 [README](../README.zh-CN.md)，英文版见 [README.md](../README.md)

Hugo 已装在 `~/.local/bin/hugo`（v0.168.0 extended，PATH 里可直接用）；CI 用的是同一个版本号。

## 1. 建稿

```bash
cd ~/projects/blog
scripts/new-post.sh my-slug "文章标题" "标签1,标签2"   # slug 决定 URL: /posts/my-slug/
# 等价手动方式：hugo new content posts/my-slug/index.md
```

生成的是 `content/posts/<slug>/index.md`，`draft: true`（**草稿不会被构建、不会被部署**）。

## 2. 写 + 预览

```bash
hugo server -D                 # http://127.0.0.1:1313，-D 让草稿也显示
```

常用 front matter：

| 字段                  | 作用                                                                             |
| --------------------- | -------------------------------------------------------------------------------- |
| `title` / `date`      | 标题、发布日（`date` 在未来且 `buildFuture=false` 时**不会构建**，等于定时发布） |
| `tags`                | 自动生成 `/tags/<tag>/` 归档页                                                   |
| `summary`             | 列表页摘要；不填则截取正文                                                       |
| `draft`               | `true` = 草稿                                                                    |
| `showTableOfContents` | 是否显示目录                                                                     |
| `cover` / `images`    | 特色图（写在 front matter，图片放同目录）                                        |

图片用 **page bundle**：放在 `content/posts/<slug>/` 里，正文写 `![说明](photo.png)`（同目录相对路径，构建时自动处理）。

数学公式要加短代码才会加载 KaTeX：

```markdown
{{</* katex */>}}
行内 $E=mc^2$，块级 $$\int_0^1 x^2 dx$$
```

## 3. 发布

```bash
# 1) 把 draft 改 false
hugo --minify --gc --cleanDestinationDir   # 本地先构建一遍，确认没报错
bash scripts/security-check.sh              # 顺手跑不变量自检

# 2) 提交（commit 格式：type(scope): English (中文关键词)）
git add -A && git commit -m "post(blog): add my-slug (新文章标题)"
git push origin main
```

> `--cleanDestinationDir` 别省：删掉或改名文章后，不加它 `public/` 里会留**僵尸页**（本地预览会看到已删的文章）。CI 是全新 checkout，不受影响。

## 4. 验证（3 条都过才算发完）

```bash
# a) Actions 两个 workflow 都绿（Deploy + Security checks）
curl -s "https://api.github.com/repos/VasantLong/blog/actions/runs?per_page=4" \
  | jq -r '.workflow_runs[] | "\(.name): \(.status)/\(.conclusion)"'

# b) 本地不变量自检
bash scripts/security-check.sh

# c) 线上真的能打开（CDN 生效通常几秒）
curl -s -o /dev/null -w '%{http_code}\n' https://vasantlong.de5.net/posts/my-slug/
```

## 5. 直接推 `main` 合规吗？

合规。分支保护只禁 **force-push / 删除分支**，不禁正常推送——单人博客不值得为每篇文章走 PR。
