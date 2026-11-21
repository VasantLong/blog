# 托管与 DNS

线上由 GitHub Pages 提供，域名与 DNS 记录在 Cloudflare，父域在 DNSHE。← 返回 [README](../README.md)

## DNS 拓扑（改之前先看懂这张图）

```text
registrar/DNSHE  zone de5.net  (a/b.ns.dnshe.org)      ← de5.net 整域权威在这里
  └─ NS 委派: vasantlong.de5.net → ian/tina.ns.cloudflare.com
       └─ CF zone vasantlong.de5.net                   ← 这个子域的记录都在 CF 里改
            └─ A @ → 185.199.108.153 / .109 / .110 / .111   （Proxy = DNS only 灰云！）
                 └─ GitHub Pages（构建产物 = .github/workflows/pages.yml 产出的 public/）
```

- **菜单里唯一的外部入口是「花园」**（`config/_default/menus.zh-cn.toml`，`url = https://notes.vasantlong.de5.net`）：Blowfish 对 `http(s)` 开头的 `url` 自动加 `target="_blank"`，桌面与手机菜单都生效，主题不用改；两站分工与"花园不引用博客"的例外见 `CONTEXT.md`
- **站点内容/记录相关改动去 CF**：`vasantlong.de5.net` 这个 zone（灰云，不要开橙云——橙云会让 Pages 证书签发失败，且多一次可能被污染的边缘解析）
- **委派本身要改才去 DNSHE**：那 2 条 NS 记录
- `lexigraph.de5.net`：CF 里另有一个它的子域 zone（旧 wordnet 站），与本博客无关；若不再恢复 wordnet，建议把它的 A 记录/zone 清掉，避免指着一台已释放的机器
- **`de5.net` 是 DNSHE 的免费子域服务**：整域不归我们所有，名下只有 `vasantlong` 与 `lexigraph` 两个名字。因此下面这些**都改不了**：父域 `_dmarc.de5.net`、父域 CAA、父域 DNSSEC(DS)。
- 免费子域服务的区里还能看到别人的名字（`www`/`test`/`dev`/`admin`/`cdn` 分别委派到不同的 CF zone，`blog` 指向一台已失联的腾讯云 IP）——**都不是我们的，无需处理**，也别把它们当成自己的资产。

## 托管侧行为

- 构建产物 = `.github/workflows/pages.yml` 产出的 `public/`；`static/CNAME` 决定自定义域名，产物里必须有
- Pages **不下发自定义响应头**，安全头缺失是产品限制，见 [`security.md`](security.md)
- 定时 workflow 在仓库 60 天无活动后被 GitHub 自动停用，见 [`operations.md`](operations.md)
