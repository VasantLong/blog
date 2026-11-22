#!/usr/bin/env python3
"""从 Blowfish 自带 i18n 表生成界面双语字典 assets/data/ui-i18n.json。

为什么不能手写：主题有 111 行键、含 Go 模板插值与单复数，手写必漏；
主题升级后键会漂移，所以带 --check 模式给 CI 用。

用法:
  python3 scripts/gen-ui-dict.py           # 重新生成
  python3 scripts/gen-ui-dict.py --check   # 只校验是否漂移（CI 用）
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
I18N = ROOT / "themes" / "blowfish" / "i18n"
SOURCES = {"zh": I18N / "zh-CN.yaml", "en": I18N / "en.yaml"}
OVERLAY = ROOT / "data" / "ui-i18n-overlay.yaml"
OUT = ROOT / "assets" / "data" / "ui-i18n.json"

# admonition.* 属于文章正文语气，不是界面文案，不进字典
EXCLUDE_PREFIXES = ("admonition.",)

TPL = re.compile(r"\{\{\s*\.([A-Za-z0-9_]+)\s*\}\}")


def flatten(node, prefix=""):
    out = {}
    for key, value in node.items():
        path = prefix + key
        if isinstance(value, dict):
            out.update(flatten(value, path + "."))
        else:
            out[path] = value
    return out


def plural_key(path):
    for suffix in (".one", ".other"):
        if path.endswith(suffix):
            return path[: -len(suffix)], suffix[1:]
    return path, None


def build_pattern(zh, en):
    """把插值串翻成客户端正则 + 替换模板；模板形态不一致时返回 None。"""
    zh_tokens = []

    def mark_zh(match):
        zh_tokens.append(match.group(1))
        return "\x00"

    zh_body = TPL.sub(mark_zh, zh)
    if "\x00" not in zh_body:
        return None
    en_tokens = []

    def mark_en(match):
        en_tokens.append(match.group(1))
        return "\x00"

    en_body = TPL.sub(mark_en, en)
    if zh_tokens != en_tokens:
        return None

    zh_parts = zh_body.split("\x00")
    body = "^"
    for index, part in enumerate(zh_parts):
        body += re.escape(part)
        if index < len(zh_tokens):
            body += r"(\d+)" if zh_tokens[index] == "Count" else r"(.+?)"
    body += "$"

    en_parts = en_body.split("\x00")
    tpl = ""
    for index, part in enumerate(en_parts):
        tpl += part
        if index < len(en_parts) - 1:
            tpl += "$%d" % (index + 1)
    return body, tpl


def collect():
    zh = flatten(yaml.safe_load(SOURCES["zh"].read_text(encoding="utf-8")))
    en = flatten(yaml.safe_load(SOURCES["en"].read_text(encoding="utf-8")))
    strings = {}
    patterns = {}
    conflicts = []

    for path, zh_value in zh.items():
        if any(path.startswith(prefix) for prefix in EXCLUDE_PREFIXES):
            continue
        en_value = en.get(path)
        if en_value is None or en_value == zh_value:
            continue
        base, variant = plural_key(path)
        if "{{" in zh_value:
            built = build_pattern(zh_value, en_value)
            if built is None:
                conflicts.append((base, zh_value, "插值形态不一致", en_value))
                continue
            body, tpl = built
            slot = patterns.setdefault(body, {"re": body})
            if variant:
                slot[variant] = tpl
            else:
                slot["en"] = tpl
            continue
        previous = strings.get(zh_value)
        if previous is not None and previous != en_value:
            conflicts.append((base, zh_value, previous, en_value))
            continue
        strings[zh_value] = en_value

    overlay = yaml.safe_load(OVERLAY.read_text(encoding="utf-8")) or {}
    strings.update({str(k): str(v) for k, v in (overlay.get("strings") or {}).items()})
    patterns.update(overlay.get("patterns") or {})

    data = {
        "note": "由 scripts/gen-ui-dict.py 生成，勿手改",
        "strings": dict(sorted(strings.items())),
        "patterns": [patterns[key] for key in sorted(patterns)],
    }
    return data, conflicts


def main():
    data, conflicts = collect()
    text = json.dumps(data, ensure_ascii=False, indent=1, sort_keys=True) + "\n"
    for conflict in conflicts:
        print("conflict %s: %r -> %r / %r" % conflict, file=sys.stderr)

    if "--check" in sys.argv[1:]:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != text:
            print("FAIL  界面字典漂移：请跑 python3 scripts/gen-ui-dict.py", file=sys.stderr)
            return 1
        print("OK    界面字典与主题 i18n 表一致（%d 串 + %d 模式）" % (len(data["strings"]), len(data["patterns"])))
        return 0

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8")
    print("写出 %s（%d 串 + %d 模式）" % (OUT.relative_to(ROOT), len(data["strings"]), len(data["patterns"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
