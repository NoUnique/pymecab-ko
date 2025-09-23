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
    set +x
}

fn_main
