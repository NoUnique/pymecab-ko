#!/bin/bash
# Build and install libmecab (mecab-ko) into /usr/local inside the manylinux
# container. Invoked by cibuildwheel as `before-all` (see pyproject.toml), so
# it runs once per container before any wheel is built.
set -euo pipefail

WORK="$(mktemp -d)"
cd "$WORK"
git clone --depth=1 https://github.com/NoUnique/mecab-ko.git mecab
cd mecab/mecab

# mecab-ko ships config.guess/config.sub from 2011, which do not know aarch64.
# Replace them with the copies bundled with automake (always newer) when
# available, otherwise fetch the current ones from GNU config.
case "$(uname -m)" in
  aarch64|arm64)
    automake_dir="$(ls -d /usr/share/automake-* 2>/dev/null | sort -V | tail -1 || true)"
    if [[ -n "$automake_dir" && -f "$automake_dir/config.sub" ]] && grep -q aarch64 "$automake_dir/config.sub"; then
      cp "$automake_dir/config.guess" "$automake_dir/config.sub" .
    else
      curl -fsSL 'https://git.savannah.gnu.org/cgit/config.git/plain/config.guess' -o config.guess
      curl -fsSL 'https://git.savannah.gnu.org/cgit/config.git/plain/config.sub' -o config.sub
    fi
    grep -q aarch64 config.sub || { echo "config.sub does not support aarch64" >&2; exit 1; }
    chmod +x config.guess config.sub
    ;;
esac

./configure --enable-utf8-only
make -j"$(nproc)"
make install
