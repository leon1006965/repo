#!/bin/bash
set -e

cd "$(dirname "$0")"

REPO_NAME="galaxys21tech"
REPO_URL="https://leon1006965.github.io/repo"
DESCRIPTION="galaxys21tech's iOS tweak repository"
ORIGIN="galaxys21tech"
LABEL="galaxys21tech Repo"
SUITE="stable"
VERSION="1.0"
ARCHS="iphoneos-arm iphoneos-arm64"
COMPONENTS="main"

DEBS_DIR="debs"
PACKAGES="Packages"
RELEASE="Release"

echo "=== Building index with local depictions ==="
REPO_URL="$REPO_URL" python3 - <<'PYEOF'
import os, re, sys, subprocess, tempfile, json, hashlib

repo_url = os.environ["REPO_URL"]
debs_dir = "debs"
dep_dir = "sileo/depictions"
os.makedirs(dep_dir, exist_ok=True)

def extract_control(deb):
    tmp = tempfile.mkdtemp()
    try:
        for name, flags in (("control.tar.gz", "-xzf"), ("control.tar.xz", "-xJf"), ("control.tar.zst", "--zstd -xf")):
            with open(deb, "rb") as fh:
                p = subprocess.run(["ar", "p", deb, name], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            if p.returncode != 0:
                continue
            t = subprocess.run(["tar", *flags.split(), "-", "-C", tmp],
                               input=p.stdout, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if t.returncode == 0:
                break
        with open(os.path.join(tmp, "control"), "rb") as fh:
            return fh.read().decode("utf-8", "replace")
    finally:
        subprocess.run(["rm", "-rf", tmp])

def parse_control(text):
    fields, current, cur = {}, None, []
    for line in text.splitlines():
        if re.match(r"^\S", line):
            if current is not None:
                fields[current] = "\n".join(cur).strip()
            current, cur = line.split(":", 1)[0], [line.split(":", 1)[1].strip()]
        elif line.startswith(" ") and current:
            cur.append(line[1:])
    if current is not None:
        fields[current] = "\n".join(cur).strip()
    return fields

def json_str(s):
    return json.dumps(s, ensure_ascii=False)

entries = []
for deb in sorted(os.listdir(debs_dir)):
    if not deb.endswith(".deb"):
        continue
    path = os.path.join(debs_dir, deb)
    text = extract_control(path)
    if not text:
        print(f"WARN: no control in {deb}", file=sys.stderr)
        continue
    f = parse_control(text)
    pkg = f.get("Package", "")
    if not pkg:
        print(f"WARN: no Package field in {deb}", file=sys.stderr)
        continue

    f["Filename"] = path
    data = open(path, "rb").read()
    f["Size"] = str(len(data))
    f["MD5sum"] = hashlib.md5(data).hexdigest()
    f["SHA1"] = hashlib.sha1(data).hexdigest()
    f["SHA256"] = hashlib.sha256(data).hexdigest()

    icon = f.get("Icon", "")
    if icon.startswith("file://"):
        icon = f"{repo_url}/CydiaIcon.png"
        f["Icon"] = icon

    dep_url = f"{repo_url}/{dep_dir}/{pkg}.json"
    f["SileoDepiction"] = dep_url
    if "Depiction" in f and "SileoDepiction" in f:
        f.pop("Depiction", None)

    name = f.get("Name", pkg)
    author = f.get("Author", f.get("Maintainer", "Unknown"))
    desc = f.get("Description", "No description provided.")
    section = f.get("Section", "Tweaks")
    version = f.get("Version", "")

    depiction = {
        "minVersion": "0.1",
        "class": "DepictionTabView",
        "tintColor": "#e94560",
        "headerImage": icon,
        "tabs": [
            {
                "class": "DepictionStackView",
                "tabname": "Details",
                "views": [
                    {"class": "DepictionMarkdownView", "markdown": desc, "useSpacing": True},
                    {"class": "DepictionSeparatorView"},
                    {"class": "DepictionHeaderView", "title": "Information"},
                    {"class": "DepictionTableTextView", "title": "Author", "text": author},
                    {"class": "DepictionTableTextView", "title": "Version", "text": version},
                    {"class": "DepictionTableTextView", "title": "Package", "text": pkg},
                    {"class": "DepictionTableTextView", "title": "Section", "text": section},
                ],
            }
        ],
    }
    with open(os.path.join(dep_dir, f"{pkg}.json"), "w") as fh:
        json.dump(depiction, fh, indent=2, ensure_ascii=False)

    entry = "\n".join(f"{k}: {v}" for k, v in f.items())
    entries.append(entry)

with open("Packages", "w") as fh:
    fh.write("\n\n".join(entries) + "\n")

print(f"Packages: {len(entries)} entries, depictions in {dep_dir}/")
PYEOF

echo "=== Compressing ==="
gzip -9 -f -k "$PACKAGES"
bzip2 -9 -f -k "$PACKAGES"

echo "=== Generating $RELEASE ==="
{
    echo "Origin: $ORIGIN"
    echo "Label: $LABEL"
    echo "Suite: $SUITE"
    echo "Version: $VERSION"
    echo "Codename: $SUITE"
    echo "Architectures: $ARCHS"
    echo "Components: $COMPONENTS"
    echo "Description: $DESCRIPTION"

    sums=""
    for f in "$PACKAGES" "$PACKAGES.gz" "$PACKAGES.bz2"; do
        sums="$sums $f"
    done

    echo "MD5Sum:"
    for f in $sums; do echo " $(md5sum "$f" | awk '{print $1}') $(stat -c%s "$f") $f"; done
    echo "SHA1:"
    for f in $sums; do echo " $(sha1sum "$f" | awk '{print $1}') $(stat -c%s "$f") $f"; done
    echo "SHA256:"
    for f in $sums; do echo " $(sha256sum "$f" | awk '{print $1}') $(stat -c%s "$f") $f"; done
} > "$RELEASE"

echo "=== Done ==="
ls -la "$PACKAGES" "$PACKAGES.gz" "$PACKAGES.bz2" "$RELEASE"
