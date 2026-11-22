# blog

[English](README.md) | [简体中文](README.zh-CN.md)

Personal blog — **Hugo + Blowfish** → built by **GitHub Actions** → served by **GitHub Pages** at **<https://vasantlong.de5.net>**

Status (2026-10-19): live. Actions run #1 green on both build and deploy; certificate `CN=vasantlong.de5.net` (Let's Encrypt, valid until 2027-01-17); `http → https` 301; Enforce HTTPS on.

## Quick start

```bash
scripts/new-post.sh my-slug "Post title" "tag1,tag2"   # scaffold a post (slug becomes the URL)
hugo server -D                                         # preview at 127.0.0.1:1313, drafts included
```

The full path from scaffold to live is in [`docs/writing.md`](docs/writing.md).

## Documentation map

| Document                                           | Answers                                                                                                                    |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| [`docs/writing.md`](docs/writing.md)               | How to publish a post: scaffolding, front matter, page bundles, KaTeX, release, the three verification checks              |
| [`docs/infrastructure.md`](docs/infrastructure.md) | DNS topology, what to change in Cloudflare vs. DNSHE, parent-domain limits, hosting behaviour                              |
| [`docs/initial-deploy.md`](docs/initial-deploy.md) | The 7-step first deploy (reusable when changing domains) and the Enforce HTTPS trap                                        |
| [`docs/operations.md`](docs/operations.md)         | Acceptance commands, theme upgrade, workflow upkeep                                                                        |
| [`docs/ui-language.md`](docs/ui-language.md)       | Bilingual UI (single URL, no `/en/`): how the dictionary is generated, the footer, and what is deliberately not translated |
| [`docs/security.md`](docs/security.md)             | Enabled security controls, Pages structural limits, account/DNS follow-ups                                                 |
| [`docs/decisions.md`](docs/decisions.md)           | Trade-offs: DNS delegation, the grey-cloud requirement, vendored theme, …                                                  |
| [`CONTEXT.md`](CONTEXT.md)                         | Domain glossary: blog vs. garden, publication states                                                                       |
| [`docs/adr/`](docs/adr/)                           | Architecture decisions: garden as a separate site, garden fed by a dedicated vault                                         |
| [`AGENTS.md`](AGENTS.md)                           | Rule sheet for AI contributors                                                                                             |

Operational docs (`docs/*.md`, `CONTEXT.md`, `AGENTS.md`) are **Chinese-only** — this README and [`README.zh-CN.md`](README.zh-CN.md) are the bilingual pair. The Chinese README plus the Chinese docs are authoritative; this page is a translation of it.

## Repository layout

```text
config/_default/      params.toml / markup.toml / languages.zh-cn.toml / menus.zh-cn.toml (site config lives in hugo.toml)
content/              _index.md (home) / about/ / posts/<slug>/index.md
static/CNAME          vasantlong.de5.net — must be present in the build output
themes/blowfish/      theme v3.9.0, vendored and trimmed (not a submodule) — see scripts/update-theme.sh
scripts/              dev.sh / new-post.sh / security-check.sh / update-theme.sh
.github/workflows/    pages.yml (build + deploy), security.yml (12 invariant checks)
docs/                 operational docs (Chinese) and ADRs
CONTEXT.md            domain glossary; AGENTS.md holds the rules for AI contributors
```

## License

Three scopes, deliberately different:

| Scope                                                                          | License                                                                                                |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| `content/` — the articles                                                      | [CC BY-NC-SA 4.0](LICENSE-CONTENT): reuse and adaptation with attribution, non-commercial, share-alike |
| everything else — scripts, config, docs, workflows, `hugo.toml`, `archetypes/` | [MIT](LICENSE)                                                                                         |
| `themes/blowfish/` — vendored upstream theme                                   | upstream MIT, © 2022 Nuno Coração; governed by its own license, see [NOTICE](NOTICE)                   |

Because the root license is MIT while the content is not, GitHub labels the repository "View license" instead of a single identifier. That is the expected result of a split code/content license, not a misconfiguration. Do not delete `themes/blowfish/LICENSE`: it is the theme's own MIT grant and must be preserved across upgrades.
