"""Превращает ошибки xcodebuild в аннотации GitHub Actions (::error ...).

Аннотации видны на странице прогона без входа в GitHub и доступны через публичный API,
поэтому ошибки сборки можно разбирать без доступа к полным логам.
GitHub показывает не больше 10 error-аннотаций на шаг, поэтому ошибки группируются.
"""
import os
import re
import sys

log = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
workspace = os.environ.get("GITHUB_WORKSPACE", "")
pattern = re.compile(r"^(/[^:]+):(\d+):(?:(\d+):)? error: (.*)$")

errors: list[str] = []
seen = set()
for line in log:
    m = pattern.match(line)
    if m:
        path, row, _, message = m.groups()
        rel = path[len(workspace) + 1:] if workspace and path.startswith(workspace) else path
        text = f"{rel}:{row}: {message}"
    elif "error:" in line or ("Test Case" in line and "failed" in line):
        text = line.strip()
    else:
        continue
    text = text[:700]
    if text not in seen:
        seen.add(text)
        errors.append(text)

if not errors:
    errors = [" | ".join(l.strip() for l in log[-30:] if l.strip())]

# До 9 аннотаций по ~6000 символов.
chunks: list[list[str]] = [[]]
for err in errors:
    if sum(len(e) for e in chunks[-1]) + len(err) > 6000:
        if len(chunks) == 9:
            break
        chunks.append([])
    chunks[-1].append(err)

for i, chunk in enumerate(chunks, 1):
    body = "%0A".join(e.replace("%", "%25").replace("\r", "").replace("\n", " ") for e in chunk)
    print(f"::error title=xcodebuild errors {i}/{len(chunks)} ({len(errors)} total)::{body}")
