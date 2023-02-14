#!/bin/bash

DIR_SOURCE=mecab-python3
DIR_TARGET=../


escape() {
    local STRING=$1

    echo "$(printf '%s\n' "$STRING" | sed -e 's/[]\/$*.^[]/\\&/g')"
}

function fn_init() {
    # set working directory
    SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    cd ${SCRIPT_DIR}
}

function fn_copy() {
    local SOURCE=$1
    local TARGET=$2

    mkdir -p ${TARGET}
    cp -rf ${SOURCE} ${TARGET}
}

function fn_remove() {
    local TARGET=$1

    rm -rf ${TARGET}
}

function fn_move() {
    local SOURCE=$1
    local TARGET=$2

    mv ${SOURCE} ${TARGET}
}

function fn_replace() {
    local TARGET=$1
    local FROM=$(escape "$2")
    local TO=$(escape "$3")

    sed -i "s/${FROM}/${TO}/g" ${TARGET}
}

function fn_main() {
    set -x
    fn_init

    # patch src
    fn_remove ${DIR_TARGET}/src
    fn_copy ${DIR_SOURCE}/src/MeCab ${DIR_TARGET}/src
    fn_move ${DIR_TARGET}/src/MeCab ${DIR_TARGET}/src/mecab_ko
    fn_replace ${DIR_TARGET}/src/mecab_ko/__init__.py \
                'import unidic' \
                'import mecab_ko_dic as unidic'
    fn_replace ${DIR_TARGET}/src/mecab_ko/__init__.py \
                'import unidic_lite' \
                'import mecab_ko_dic as unidic_lite'
    fn_replace ${DIR_TARGET}/src/mecab_ko/__init__.py \
                'https://github.com/SamuraiT/mecab-python3' \
                'https://github.com/NoUnique/pymecab-ko'
    fn_replace ${DIR_TARGET}/src/mecab_ko/__init__.py \
                'issueを英語で書く必要はありません。' \
                'issue를 영어로 작성할 필요는 없습니다.'
    fn_replace ${DIR_TARGET}/src/mecab_ko/cli.py \
                'from MeCab import Tagger' \
                'from mecab_ko import Tagger'

    # patch github actions
    fn_copy ${DIR_SOURCE}/.github ${DIR_TARGET}
    fn_replace ${DIR_TARGET}/.github/workflows/build_mecab.sh \
                'https://github.com/polm/mecab.git' \
                'https://github.com/NoUnique/mecab-ko.git mecab'
    fn_replace ${DIR_TARGET}/.github/workflows/entrypoint.sh \
                '/github/workspace/wheels/*.whl' \
                '/github/workspace/wheels/mecab_ko-*.whl'
    fn_replace ${DIR_TARGET}/.github/workflows/manylinux.yml \
                'https://github.com/taku910/mecab.git' \
                'https://github.com/NoUnique/mecab-ko.git mecab'
    fn_replace ${DIR_TARGET}/.github/workflows/test_manylinux.yml \
                'unidic-lite' \
                'mecab-ko-dic'
    fn_replace ${DIR_TARGET}/.github/workflows/osx.yml \
                'https://github.com/taku910/mecab.git' \
                'https://github.com/NoUnique/mecab-ko.git mecab'
    fn_replace ${DIR_TARGET}/.github/workflows/osx.yml \
                'mecab_python3' \
                'mecab_ko'
    fn_replace ${DIR_TARGET}/.github/workflows/osx.yml \
                'mecab-python3' \
                'pymecab-ko'
    fn_replace ${DIR_TARGET}/.github/workflows/windows.yml \
                'curl -LO "https://github.com/chezou/mecab/releases/download/mecab-0.996-msvc-5/mecab-msvc-x64.zip"' \
                'curl -L "https://github.com/Pusnow/mecab-ko-msvc/releases/download/release-0.9.2-msvc-3/mecab-ko-msvc-x64.zip" -o mecab-msvc-x64.zip'
    fn_replace ${DIR_TARGET}/.github/workflows/windows.yml \
                'mecab_python3' \
                'mecab_ko'
    for file in ${DIR_TARGET}/.github/workflows/*.yml; do
        fn_replace "${file}" \
                    'twine upload' \
                    'twine upload ${{ vars.TWINE_ARGS }}'
    done
    set +x
}

fn_main
