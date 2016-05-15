#!/usr/bin/env bash

# 1 register vagrant environment +
# check shell running - check for common shell conf files +

# 2 register vbox hdd folder
# 5 check non standard vbox hdd folders (?)

# 3 add machines to vbox
#    show list of machines available and machines that are not imported - show warning
# 4 check UID with machine UID if different adjust creator_uid
# 6 deregister vagrant environment
#

# Colours for messages
RED="\x1b[31m"
CYAN="\x1b[96m"
GREEN="\x1b[32m"
CLEARCOLOR="\x1b[0m"
YELLOW="\x1b[33m"

VERSION="0.1"

# External parameters
# NEW_VAGRANT_HOME_FOLDER="/Volumes/test/vagranthome";
# NEW_VB_MACHINE_FOLDER="/Volumes/test/VMbase";

NEW_VAGRANT_HOME_FOLDER="";
NEW_VB_MACHINE_FOLDER="";

DRYRUN_MODE=0;
CREATE_FLAG=1;
FORCE_FLAG=1;
RESTORE_FLAG=0;

# Internal parameters
VB_MACHINE_FOLDER_DEFAULT=0; #not used?

showVersion () {
    echo "Vagrant on External Drive v$VERSION";
    exit 0;
}


init ()
{
    prepare_arguments $# $@;
}

# require_parameter()
#
# Usage:
#   require_argument <option> <argument>
#
# If <argument> is blank or another option, print an error message and  exit
# with status 1.
require_parameter() {
  # Set local variables from arguments.
  local _OPTION="${1:-}"
  local _TEST_PARAM="${2:-}"

  echo $_OPTION;

  if [[ -z "${_TEST_PARAM}" ]] || [[ "${_TEST_PARAM}" =~ ^- ]]
  then
    printf "Option %s requires parameter.\n" "${_OPTION}"
    exit 1;
  fi
}


prepare_arguments ()
{
    # echo ${OPTIONS[0]};
    # echo $OPTIONS_LENGTH;
    # Print usage instructions
    if [[ ${#} -eq 0 ]]
    then
        echo "Missing options. Please read help." >&2
        showHelp;
        exit 0;
    fi

    # Get arguments and assign variables
    while [ ${#} -gt 0 ]
    do

        local _OPTION="${1:-}"
        local _PARAM="${2:-}"

        case "$_OPTION" in
            -b|--vbox-path)
                require_parameter $_OPTION $_PARAM;
                NEW_VB_MACHINE_FOLDER=$2
                shift 2
                ;;
            -g|--vagrant-env)
                require_parameter $_OPTION $_PARAM;
                NEW_VAGRANT_HOME_FOLDER=$2
                shift
                ;;
            -d|--dry-run)
                DRYRUN_MODE=1
                ;;
            -f|--force)
                FORCE_FLAG=1
                ;;
            -c|--create)
                CREATE_FLAG=1
                ;;
            -r|--restore)
                RESTORE_FLAG=1
                ;;
            -v|--version)
                showVersion
                ;;
            -h|--help)
                showHelp
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Use -h or --help to read full help."
                exit 1
                ;;
        esac
        echo $DRYRUN_MODE;
        shift
    done
}

init $# $@;
