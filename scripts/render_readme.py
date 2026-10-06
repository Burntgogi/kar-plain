"""Render both READMEs for local review and check their links and skill metadata."""
from pathlib import Path
from html import escape
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import json
import os
import re
import xml.etree.ElementTree as ET
from markdown_it import MarkdownIt

ROOT = Path(__file__).resolve().parents[1]
PARSER = MarkdownIt("commonmark", {"html": True}).enable("table")
PREVIEWS = {"README.md": "docs/README.preview.html", "README.en.md": "docs/README.en.preview.html"}
SKILL_DIR = ROOT / "plugins/kar-plain/skills/kar-plain"

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.targets = []
        self.anchors = set()
        self.images = 0

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        for key in ("id", "name"):
            if values.get(key):
                self.anchors.add(values[key])
        for key in ("href", "src"):
            if values.get(key):
                self.targets.append(values[key])
        if tag == "img":
            self.images += 1
            assert values.get("alt"), "Image missing alternative text"

def exact_case(path):
    """Windows and macOS ignore case, but GitHub and Linux do not."""
    current = ROOT
    for part in path.relative_to(ROOT).parts:
        if part not in {child.name for child in current.iterdir()}:
            return False
        current = current / part
    return True

def slug(text):
    text = re.sub(r"<[^>]+>", "", text).lower()
    return re.sub(r"[^\w\- ]", "", text).replace(" ", "-")

def with_anchors(html):
    used = {}
    def heading(match):
        tag, attrs, text = match.groups()
        name = slug(text)
        count = used.get(name, 0)
        used[name] = count + 1
        name += f"-{count}" if count else ""
        return f'<{tag}{attrs} id="{name}">{text}</{tag}>'
    return re.sub(r"<(h[1-6])([^>]*)>(.*?)</\1>", heading, html, flags=re.S)

STYLE = """
*{box-sizing:border-box}html{scroll-behavior:auto}body{margin:0;background:#fff;color:#1f2328;font:16px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI","Malgun Gothic",sans-serif;overflow-wrap:break-word}
.preview-note{max-width:980px;margin:24px auto 0;padding:10px 20px;background:#f6f8fa;border:1px solid #d1d9e0;border-radius:6px;color:#59636e;font-size:13px}
.markdown-body{max-width:980px;margin:12px auto 48px;padding:32px;border:1px solid #d1d9e0;border-radius:6px}
.markdown-body>:first-child{margin-top:0}a{color:#0969da;text-decoration:none}a:hover{text-decoration:underline}p,blockquote,ul,ol,table,pre{margin:0 0 16px}h1,h2,h3{line-height:1.25;margin:24px 0 16px;font-weight:600;scroll-margin-top:16px}h1,h2{padding-bottom:.3em;border-bottom:1px solid #d1d9e0}h1{font-size:2em}h2{font-size:1.5em}h3{font-size:1.25em}img{max-width:100%;height:auto;vertical-align:middle}p[align="center"]{text-align:center}h1[align="center"]{text-align:center}blockquote{padding:0 1em;border-left:.25em solid #d1d9e0;color:#59636e}blockquote>:last-child{margin-bottom:0}code{font:85%/1.5 ui-monospace,SFMono-Regular,Consolas,monospace;background:#eff1f3;border-radius:6px;padding:.2em .4em;white-space:break-spaces}pre{background:#f6f8fa;border-radius:6px;padding:16px;overflow:auto}pre code{background:none;padding:0;white-space:pre}table{border-collapse:collapse;display:block;width:max-content;max-width:100%;overflow:auto}th,td{padding:6px 13px;border:1px solid #d1d9e0}th{font-weight:600}tr:nth-child(2n){background:#f6f8fa}li+li{margin-top:.25em}
@media(max-width:600px){.preview-note{margin:12px 12px 0;padding:8px 12px}.markdown-body{margin:8px 12px 24px;padding:16px}h1{font-size:1.65em}h2{font-size:1.35em}}
"""

results = []
for name, preview in PREVIEWS.items():
    source = ROOT / name
    rendered = with_anchors(PARSER.render(source.read_text(encoding="utf-8")))
    links = Links()
    links.feed(rendered)
    local_count = 0
    for target in links.targets:
        parts = urlsplit(target)
        if parts.scheme or parts.netloc:
            continue
        if parts.path:
            path = (ROOT / unquote(parts.path)).resolve()
            assert path.is_relative_to(ROOT), f"Link outside repository: {target}"
            assert path.exists(), f"Missing repository link: {target}"
            assert exact_case(Path(os.path.normpath(ROOT / unquote(parts.path)))), f"Link case differs from file: {target}"
            local_count += 1
        elif parts.fragment:
            assert unquote(parts.fragment) in links.anchors, f"Missing anchor: {target}"
    for readme_name, preview_name in PREVIEWS.items():
        rendered = rendered.replace(f'href="{readme_name}"', f'href="{preview_name}"')
    rendered = re.sub(r'href="#([^\"]+)"', lambda match: f'href="{preview}#{match.group(1)}"', rendered)
    lang = "ko" if name == "README.md" else "en"
    note = "한국어 README · 로컬 렌더링 미리보기" if lang == "ko" else "English README · Local rendering preview"
    document = f'<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><base href="../"><title>{escape(note)}</title><style>{STYLE}</style></head><body><div class="preview-note">{escape(note)}</div><article class="markdown-body">{rendered}</article></body></html>'
    (ROOT / preview).write_text(document, encoding="utf-8", newline="\r\n")
    results.append({"source": name, "preview": preview, "local_links": local_count, "images": links.images, "bytes": source.stat().st_size})

for path in (ROOT / "assets").rglob("*.svg"):
    ET.parse(path)
skill = (SKILL_DIR / "SKILL.md").read_text(encoding="utf-8")
body = skill.split("---", 2)[2].strip()
body_words = len(body.split())
assert body_words < 350, 'Keep the shared skill concise'
assert len(list(SKILL_DIR.rglob("*.*"))) == 2
claude_explicit = "disable-model-invocation: true" in skill.split("---", 2)[1]
codex_explicit = "allow_implicit_invocation: false" in (SKILL_DIR / "agents/openai.yaml").read_text(encoding="utf-8")
assert claude_explicit == codex_explicit, "Claude and Codex invocation policies differ"
plugin = json.loads((ROOT / "plugins/kar-plain/.claude-plugin/plugin.json").read_text(encoding="utf-8"))
marketplace = json.loads((ROOT / ".claude-plugin/marketplace.json").read_text(encoding="utf-8"))
assert [(entry["name"], entry["source"]) for entry in marketplace["plugins"]] == [(plugin["name"], "./plugins/kar-plain")]
for name in PREVIEWS:
    assert str(body_words) in (ROOT / name).read_text(encoding="utf-8"), "README word count is stale"
print(json.dumps({"readmes": results, "links": "PASS", "SVG": "PASS", "skill_body_words": body_words}, ensure_ascii=False))
