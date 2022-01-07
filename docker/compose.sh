#!/bin/bash
# shell script to control container-based development environment.
# (Docker and Docker-compose)
#
# Author : Taehwan Yoo (kofmap@gmail.com)
# Copyright 2022 Taehwan Yoo. All Rights Reserved

COMPOSE_PROJECT_NAME=""
DEFAULT_SERVICE="dev"
COMPOSE_FNAME="docker-compose.yml"
COMPOSE_VERSION="1.25.4"

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_DIR="$(dirname -- "${SCRIPT_DIR}")"
DIRNAME="${PROJECT_DIR##*/}"

# by docker image & container naming rules
COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:="$(echo "${DIRNAME}" | sed 's/[^0-9a-zA-Z]*//g' | tr '[A-Z]' '[a-z]')"}
export COMPOSE_IMAGE_NAME=${COMPOSE_PROJECT_NAME}
COMPOSE_PROJECT_NAME="${USER}_${COMPOSE_PROJECT_NAME}"

function fn_configure() {
    NO_CACHE=${NO_CACHE:=""}
    IS_EXIST=${IS_EXIST:="FALSE"}
    IS_RUNNING=${IS_RUNNING:="FALSE"}
    RUN_TENSORBOARD=${RUN_TENSORBOARD:="FALSE"}
    RUN_JUPYTER=${RUN_JUPYTER:="FALSE"}
    DO_BUILD=${DO_BUILD:="FALSE"}
    DO_RUN=${DO_RUN:="FALSE"}
    DO_BASH=${DO_BASH:="FALSE"}
    DO_KILL=${DO_KILL:="FALSE"}
    DO_DOWN=${DO_DOWN:="FALSE"}
}

function fn_is_exist() {
    IS_EXIST=`docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} ps -q ${DEFAULT_SERVICE}`
    if [[ "${IS_EXIST}" != "FALSE" ]] && [[ -n "${IS_EXIST}" ]]; then
        IS_EXIST="TRUE"
    fi
}

function fn_is_running() {
    IS_RUNNING=`docker ps -q --no-trunc | grep $(docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} ps -q ${DEFAULT_SERVICE})`
    if [[ "${IS_RUNNING}" != "FALSE" ]] && [[ -n "${IS_RUNNING}" ]]; then
        IS_RUNNING="TRUE"
    fi
}

function fn_build() {
    echo "Build '${COMPOSE_PROJECT_NAME}' docker image"
    docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} build ${NO_CACHE} ${DEFAULT_SERVICE}
}

function fn_run() {
    echo "Run '${COMPOSE_PROJECT_NAME}_${DEFAULT_SERVICE}' docker container"
    fn_kill $1
    docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} up -d ${DEFAULT_SERVICE}
}

function fn_bash() {
    fn_is_running
    if [[ "${IS_RUNNING}" != "TRUE" ]]; then
        fn_run
    fi
    echo "Connect to shell of '${COMPOSE_PROJECT_NAME}_${DEFAULT_SERVICE}' docker container"
    fn_upgrade_compose
    docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} exec ${DEFAULT_SERVICE} /bin/bash
}

function fn_kill() {
    fn_is_running
    if [[ "${IS_RUNNING}" == "TRUE" ]]; then
        echo "Kill '${COMPOSE_PROJECT_NAME}_${DEFAULT_SERVICE}' docker container"
        docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} kill ${DEFAULT_SERVICE}
        if [[ "$1" == "rm" ]]; then
            echo "Remove state of ${DEFAULT_SERVICE} service container"
            docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} rm ${DEFAULT_SERVICE}
        fi
    else
        echo "There is no running '${COMPOSE_PROJECT_NAME}_${DEFAULT_SERVICE}' docker container"
    fi
}

function fn_down() {
    fn_is_exist
    if [[ "${IS_EXIST}" == "TRUE" ]]; then
        echo "Down '${COMPOSE_PROJECT_NAME}' docker container"
        docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} down -v
    fi
}

function fn_main() {
    fn_configure
    if [[ "${DO_DOWN}" == "TRUE" ]]; then
        fn_down
    elif [[ "${DO_KILL}" == "TRUE" ]]; then
        fn_kill
    elif [[ "${DO_BASH}" == "TRUE" ]]; then
        fn_bash
    elif [[ "${DO_RUN}" == "TRUE" ]]; then
        fn_run
    elif [[ "${DO_BUILD}" == "TRUE" ]]; then
        fn_build
    fi
}

function fn_upgrade_compose() {
    verlt() {
        [ "$1" = "$2" ] && return 1 || [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
    }
    CURRENT_COMPOSE_VERSION=$(docker-compose --version | sed 's/.*version\ //g' | sed 's/,.*//g')
    if verlt ${CURRENT_COMPOSE_VERSION} ${COMPOSE_VERSION}; then
        # compare current version to target version
        echo "Upgrade docker-compose version from '${CURRENT_COMPOSE_VERSION}' to '${COMPOSE_VERSION}'"
        echo "Installation needs 'sudo' permissions. Please enter your password."
        sudo -k # make sure to ask for password on next sudo
        if sudo true; then
            sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        else
            echo "docker-compose is not upgraded"
            exit 1
        fi
    fi
}

optspec=":bdrks-:"
while getopts "${optspec}" optchar; do
    case ${optchar} in
        -)
            case "${OPTARG}" in
                no-cache)
                    echo "Parsing option: '--${OPTARG}', build with no-cache";
                    NO_CACHE="--no-cache"
                    ;;
                project)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
                    COMPOSE_PROJECT_NAME=${val}
                    ;;
                project=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    echo "Parsing option: '--${opt}', value: '${val}'" >&2;
                    COMPOSE_PROJECT_NAME=${val}
                    ;;

                service)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
                    DEFAULT_SERVICE=${val}
                    ;;
                service=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    echo "Parsing option: '--${opt}', value: '${val}'" >&2;
                    DEFAULT_SERVICE=${val}
                    ;;

                release)
                    echo "Parsing option: '--${OPTARG}', release mode";
                    DEFAULT_SERVICE="release"
                    ;;

                *)
                    if [ "${OPTERR}" == 1 ] || [ "${optspec:0:1}" != ":" ]; then
                        echo "Unknown option --${OPTARG}"
                     fi
                    ;;
            esac
            ;;
        b)
            DO_BUILD="TRUE"
            ;;
        d)
            DO_DOWN="TRUE"
            ;;
        r)
            DO_RUN="TRUE"
            ;;
        s)
            DO_BASH="TRUE"
            ;;
        k)
            DO_KILL="TRUE"
            ;;
        *)
            if [ "${OPTERR}" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'"
            fi
            ;;
    esac
done

fn_main