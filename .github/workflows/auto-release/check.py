#!/usr/bin/env python3
"""Find CPython versions that the latest PyPI release has no wheel for.

Compares the CPython versions cibuildwheel would build for this project
(from pyproject.toml, via ``cibuildwheel --print-build-identifiers``) with
the wheels present on PyPI for the latest release of the package. When
some are missing, the release tag is verified to exist in this repository
and to carry the cibuildwheel configuration, so that the Release workflow
can rebuild it and add the missing wheels to the same version.

Outputs (written to ``$GITHUB_OUTPUT``):
  missing  - space separated python tags without a wheel, e.g. "cp315"
  version  - the latest version on PyPI
  tag      - the git tag of that version (empty when nothing is missing)

Only the standard library is used so the script can run anywhere.
"""

import json
import os
import subprocess
import sys
import urllib.request

PACKAGE = "mecab-ko"


def cibuildwheel_python_tags():
    out = subprocess.check_output(
        ["cibuildwheel", "--print-build-identifiers", "--platform", "linux",
         "--archs", "x86_64"],
        text=True,
    )
    return {ident.split("-", 1)[0]
            for ident in out.split() if ident.startswith("cp")}


def pypi_latest():
    url = f"https://pypi.org/pypi/{PACKAGE}/json"
    with urllib.request.urlopen(url, timeout=30) as resp:
        data = json.load(resp)
    version = data["info"]["version"]
    tags = set()
    for f in data["releases"].get(version, []):
        name = f["filename"]
        if name.endswith(".whl"):
            # {dist}-{version}(-{build})?-{python}-{abi}-{platform}.whl
            tags.add(name[:-4].split("-")[-3])
    return version, tags


def git_tag_for(version):
    tag = f"v{version}"
    ok = subprocess.run(["git", "rev-parse", "-q", "--verify",
                         f"refs/tags/{tag}^{{commit}}"],
                        capture_output=True).returncode == 0
    if not ok:
        raise SystemExit(f"error: tag {tag} for PyPI release {version} "
                         "does not exist in this repository")
    has_config = subprocess.run(["git", "cat-file", "-e",
                                 f"{tag}:pyproject.toml"],
                                capture_output=True).returncode == 0
    if not has_config:
        raise SystemExit(f"error: {tag} predates the cibuildwheel "
                         "configuration (pyproject.toml); cut a new release "
                         "instead of rebuilding this one")
    return tag


def main():
    def order(tag):
        return int(tag[2:]) if tag[2:].isdigit() else 0

    wanted = cibuildwheel_python_tags()
    version, have = pypi_latest()
    missing = sorted(wanted - have, key=order)

    print(f"cibuildwheel builds: {sorted(wanted, key=order)}")
    print(f"PyPI {PACKAGE} {version} has:  {sorted(have, key=order)}")
    print(f"missing: {missing or 'none'}")

    tag = git_tag_for(version) if missing else ""
    with open(os.environ.get("GITHUB_OUTPUT", os.devnull), "a") as fh:
        fh.write(f"missing={' '.join(missing)}\n")
        fh.write(f"version={version}\n")
        fh.write(f"tag={tag}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
