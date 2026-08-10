#!/bin/bash
set -e

cd "$(dirname "$0")"

REPO_NAME="galaxys21tech"
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

extract_control() {
    local deb="$1" tmp
    tmp="$(mktemp -d)"
    if ar p "$deb" control.tar.gz 2>/dev/null | tar -xzf - -C "$tmp" 2>/dev/null; then
        :
    elif ar p "$deb" control.tar.xz 2>/dev/null | tar -xJf - -C "$tmp" 2>/dev/null; then
        :
    elif ar p "$deb" control.tar.zst 2>/dev/null | tar --zstd -xf - -C "$tmp" 2>/dev/null; then
        :
    fi
    cat "$tmp/control" 2>/dev/null
    rm -rf "$tmp"
}

echo "=== Generating $PACKAGES ==="
for deb in "$DEBS_DIR"/*.deb; do
    [ -e "$deb" ] || continue

    ctrl="$(extract_control "$deb")"
    [ -n "$ctrl" ] || { echo "WARN: no control in $deb" >&2; continue; }

    md5="$(md5sum "$deb" | awk '{print $1}')"
    sha1="$(sha1sum "$deb" | awk '{print $1}')"
    sha256="$(sha256sum "$deb" | awk '{print $1}')"
    size="$(stat -c%s "$deb")"

    {
        echo "$ctrl"
        echo "Filename: $deb"
        echo "Size: $size"
        echo "MD5sum: $md5"
        echo "SHA1: $sha1"
        echo "SHA256: $sha256"
    }
    echo
done > "$PACKAGES"

sed -i '/^$/d' "$PACKAGES"

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
