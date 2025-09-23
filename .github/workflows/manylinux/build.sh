#!/bin/bash
set -euo pipefail

MODE="${1:-all}"
ARCH=$(uname -m)
MANYLINUX_VERSION=2014
case "$ARCH" in
  x86_64)
    PLAT=x86_64
    ;;
  aarch64|arm64)
    PLAT=aarch64
    ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
 esac

MECAB_ROOT="/github/workspace/mecab_${PLAT}"
SRC_DIR="${MECAB_ROOT}/mecab"

build_mecab() {
  if [[ -d "$SRC_DIR" ]]; then
    echo "mecab directory already exists at $SRC_DIR; skipping build."
    return 0
  fi

  git clone --depth=1 https://github.com/NoUnique/mecab-ko.git mecab

  if [[ "$PLAT" == "aarch64" ]]; then
    yum -y update && yum install -y wget
    wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O mecab/mecab/config.guess
    wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD' -O mecab/mecab/config.sub
  fi

  mv mecab "$MECAB_ROOT"
  pushd "$SRC_DIR" >/dev/null
  ./configure --enable-utf8-only
  make
  popd >/dev/null
}

build_wheels() {
  build_mecab

  pushd "$SRC_DIR" >/dev/null
  make install
  popd >/dev/null

  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/

  WHEELHOUSE=/github/workspace/wheels
  OUTPUT_DIR=/github/workspace/manylinux-wheels
  rm -rf "$WHEELHOUSE" "$OUTPUT_DIR"
  mkdir -p "$WHEELHOUSE" "$OUTPUT_DIR"

  for PYVER in cp38-cp38 cp39-cp39 cp310-cp310 cp311-cp311 cp312-cp312 cp313-cp313; do
    /opt/python/$PYVER/bin/pip wheel /github/workspace -w "$WHEELHOUSE" || { echo "Failed while building $PYVER wheel" >&2; exit 1; }
  done

  for wheel in "$WHEELHOUSE"/mecab_ko-*.whl; do
    auditwheel repair "$wheel" --plat manylinux${MANYLINUX_VERSION}_${PLAT} -w "$OUTPUT_DIR"
  done

  echo "Built wheels:"
  ls "$OUTPUT_DIR"
}

case "$MODE" in
  build_mecab)
    build_mecab
    ;;
  build_wheels)
    build_wheels
    ;;
  all)
    build_wheels
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 1
    ;;
 esac
