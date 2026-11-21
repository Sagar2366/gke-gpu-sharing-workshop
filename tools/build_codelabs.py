#!/usr/bin/env python3
"""build_codelabs.py: assemble Google-Codelabs-style pages from the lesson and lab sources.

    python3 tools/build_codelabs.py              # render labs + build docs/codelabs/*.md
    python3 tools/build_codelabs.py --fix-static # also rewrite old links in the other docs pages

Each codelab in tools/codelabs.yml becomes one page. Every step becomes an "## N. Title"
section; course.js shows one step at a time with a left step list, Back/Next buttons and
"N mins remaining".
"""
import os
import posixpath
import re
import subprocess
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DOCS = os.path.join(ROOT, "docs")


def read(p):
    with open(os.path.join(ROOT, p), encoding="utf-8") as f:
        return f.read()


def strip_chrome(text):
    """Drop the page H1, the lesson-head block and 'Next lesson' buttons."""
    text = re.sub(r'<div class="lesson-head" markdown>.*?</div>\n*', "", text, count=1, flags=re.S)
    lines = text.split("\n")
    out, dropped_h1 = [], False
    for ln in lines:
        if not dropped_h1 and ln.startswith("# "):
            dropped_h1 = True
            continue
        if re.match(r"^\[.*\]\(.*\)\{ \.md-button[^}]*\}\s*$", ln):
            continue
        out.append(ln)
    return "\n".join(out).strip("\n") + "\n"


def demote(text):
    """## -> ### etc., skipping column-0 fenced code blocks."""
    out, fence = [], False
    for ln in text.split("\n"):
        if re.match(r"^(```|~~~)", ln):
            fence = not fence
        elif not fence and re.match(r"^#{2,5} ", ln):
            ln = "#" + ln
        out.append(ln)
    return "\n".join(out)


def split_h2(text):
    """Return [(title, body)]; content before the first H2 becomes 'Introduction'."""
    parts, title, buf, fence = [], "Introduction", [], False
    for ln in text.split("\n"):
        if re.match(r"^(```|~~~)", ln):
            fence = not fence
        if not fence and ln.startswith("## "):
            if "".join(buf).strip():
                parts.append((title, "\n".join(buf)))
            title = re.sub(r"^(Step \d+|Part [A-Z])\s*[·:.-]\s*", "", ln[3:].strip())
            buf = []
        else:
            buf.append(ln)
    if "".join(buf).strip():
        parts.append((title, "\n".join(buf)))
    return parts


def apply_variant(text, variant):
    """Keep <!-- only:X --> blocks for this variant, convert or drop Plan B boxes."""
    def only(m):
        return m.group(2) if variant in (None, m.group(1)) else ""
    text = re.sub(r"<!-- only:(\w+) -->\n?(.*?)<!-- /only -->\n?", only, text, flags=re.S)
    if variant is None:
        return text
    out, lines, i = [], text.split("\n"), 0
    while i < len(lines):
        m = re.match(r'^(\s*)(\?\?\?\+?|!!!) planb "(.*)"\s*$', lines[i])
        if not m:
            out.append(lines[i]); i += 1; continue
        indent = m.group(1)
        body, j = [], i + 1
        while j < len(lines) and (not lines[j].strip() or lines[j].startswith(indent + "    ")):
            body.append(lines[j]); j += 1
        while body and not body[-1].strip():
            body.pop(); j -= 1
        if variant == "jarvislabs":
            out.append('%s!!! info "On this cluster (Jarvislabs)"' % indent)
            out.extend(body)
        i = j
    return "\n".join(out)


def make_lean(text):
    """Main points only: collapse explanatory 'why' boxes (keep gotchas open), drop per-step quizzes."""
    text = re.sub(r'^(\s*)!!! why "((?:(?!gotcha|Gotcha)[^"])*)"$', r'\1??? why "\2"', text, flags=re.M)
    text = re.sub(r"^## Test your knowledge\n.*?(?=^!!! takeaway|^!!! checkpoint|^## |\Z)", "", text, flags=re.S | re.M)
    return text


LINK_RE = re.compile(r'(\]\(|src="|href=")([^)"#\s]+\.(?:md|svg|png|jpg|html))(#[^)"\s]*)?')


def make_rewriter(link_map, page_maps=None):
    page_maps = page_maps or {}
    def rewrite(text, from_vpath, to_vpath):
        local = page_maps.get(to_vpath, {})
        def sub(m):
            prefix, target, anchor = m.group(1), m.group(2), m.group(3) or ""
            if re.match(r"^[a-z]+://", target) or target.startswith("/"):
                return m.group(0)
            resolved = posixpath.normpath(posixpath.join(posixpath.dirname(from_vpath), target))
            if resolved in local or resolved in link_map:
                page, idx = local.get(resolved) or link_map[resolved]
                anchor = anchor or "#%d" % idx
                resolved = page
            elif not resolved.endswith(".html") and not os.path.exists(os.path.join(DOCS, resolved)):
                print("  !! unresolved link %s -> %s (in %s)" % (target, resolved, from_vpath), file=sys.stderr)
            rel = posixpath.relpath(resolved, posixpath.dirname(to_vpath))
            return prefix + rel + anchor
        return LINK_RE.sub(sub, text)
    return rewrite


def main():
    subprocess.run([sys.executable, os.path.join(HERE, "render_labs.py")] +
                   sorted(os.path.join(HERE, "lab-src", f) for f in os.listdir(os.path.join(HERE, "lab-src"))),
                   check=True, stdout=subprocess.DEVNULL)
    manifest = yaml.safe_load(read("tools/codelabs.yml"))
    defaults = manifest.get("defaults", {})

    # 1. expand steps, build vpath -> (page, step index) map
    plans, link_map, page_maps = [], {}, {}
    for cl in manifest["codelabs"]:
        page = "codelabs/%s.md" % cl["id"]
        variant = cl.get("variant")
        local = page_maps.setdefault(page, {})
        lean = cl.get("lean", False)
        V = lambda t: make_lean(apply_variant(t, variant)) if lean else apply_variant(t, variant)
        steps = []
        for st in cl["steps"]:
            text = V(strip_chrome(read(st["file"]))) if "file" in st else ""
            if st.get("split"):
                mins = st.get("mins", [])
                for k, (title, body) in enumerate(split_h2(text)):
                    steps.append({"title": title, "body": body, "vpath": st["vpath"],
                                  "mins": mins[k] if k < len(mins) else 5})
                    if k == 0:
                        link_map.setdefault(st["vpath"], (page, len(steps) - 1))
                        local.setdefault(st["vpath"], (page, len(steps) - 1))
            elif st.get("parts"):
                # several sources in one step; links are rewritten per part
                bodies = []
                for part in st["parts"]:
                    bodies.append(("PART", part["vpath"], demote(V(strip_chrome(read(part["file"]))))))
                    if not part["vpath"].startswith("codelabs/_"):
                        link_map.setdefault(part["vpath"], (page, len(steps)))
                        local.setdefault(part["vpath"], (page, len(steps)))
                steps.append({"title": st["title"], "parts": bodies, "vpath": None, "mins": st.get("mins", 5)})
            else:
                steps.append({"title": st["title"], "body": demote(text), "vpath": st["vpath"], "mins": st.get("mins", 5)})
                if not st["vpath"].startswith("codelabs/_"):
                    link_map.setdefault(st["vpath"], (page, len(steps) - 1))
                    local.setdefault(st["vpath"], (page, len(steps) - 1))
        plans.append((cl, page, steps))
    rewrite = make_rewriter(link_map, page_maps)

    # 2. write pages
    os.makedirs(os.path.join(DOCS, "codelabs"), exist_ok=True)
    for cl, page, steps in plans:
        title = cl["title"]
        out = ["---", "hide:", "  - navigation", "  - toc", "title: \"%s\"" % title.replace('"', "'"), "---", "",
               "<!-- GENERATED by tools/build_codelabs.py from tools/codelabs.yml. Edit the sources, not this file. -->",
               "",
               '<div class="codelab-marker" data-catalog="../index.html"></div>', "",
               "# %s" % title, "",
               '<p class="codelab-bigtitle">%s</p>' % title, "",
               '<div class="codelab-about" markdown>', "",
               "### About this codelab", "",
               ":material-text-box-outline: Last updated %s" % cl.get("updated", defaults.get("updated", "")), "",
               ":material-account-circle: Written by %s" % cl.get("author", defaults.get("author", "")), "",
               ":material-timer-outline: %s" % cl.get("duration", ""), "",
               "</div>", ""]
        for i, st in enumerate(steps):
            if st.get("parts"):
                body = "\n\n".join(rewrite(b, vp, page).strip("\n") for _, vp, b in st["parts"])
            else:
                body = rewrite(st["body"], st["vpath"], page)
            out += ['## %d. %s { data-mins="%s" }' % (i + 1, st["title"], st["mins"]), "", body.strip("\n"), ""]
        with open(os.path.join(DOCS, page), "w", encoding="utf-8") as f:
            f.write("\n".join(out))
        print("built %-32s %2d steps" % (page, len(steps)))

    # 3. optionally fix links in hand-written pages
    if "--fix-static" in sys.argv:
        for dirpath, _, files in os.walk(DOCS):
            for fn in files:
                if not fn.endswith(".md"):
                    continue
                full = os.path.join(dirpath, fn)
                vpath = os.path.relpath(full, DOCS).replace(os.sep, "/")
                if vpath.startswith("codelabs/"):
                    continue
                with open(full, encoding="utf-8") as f:
                    s = f.read()
                new = rewrite(s, vpath, vpath)
                if new != s:
                    with open(full, "w", encoding="utf-8") as f:
                        f.write(new)
                    print("fixed links in", vpath)


if __name__ == "__main__":
    main()
