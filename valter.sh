#!/usr/bin/env bash

# TODO
# 3 add machines to vbox
#    show list of machines available and machines that are not imported - show warning
# 4 check UID with machine UID if different adjust creator_uid
# 6 deregister vagrant environment
#



VERSION="0.1"

# External parameters
NEW_VAGRANT_HOME_FOLDER="";
NEW_VB_MACHINE_FOLDER="";

DRYRUN_MODE=0;
CREATE_FLAG=0;
FORCE_FLAG=0;
RESTORE_FLAG=0;
##
# @param boolean NOCOLOR - 0 for colour (default), 1 for no colour.
##
NOCOLOR=0

# Internal parameters
VB_MACHINE_FOLDER_DEFAULT=0; #not used?


showVersion () {
    echo "Vagrant on External Drive v$VERSION";
    exit 0;
}

showHelp () {

    local _underline=`tput smul`
    local _nounderline=`tput rmul`
    local _bold=`tput bold`
    local _normal=`tput sgr0`

echo -e "

valter v$VERSION

${_bold}Usage:${_normal}
./valter.sh [--vagrant-env ${_underline}\"/path/to/folder/\"${_normal}] [--vbox-path ${_underline}\"/path/to/folder/\"${_normal}] {--dry-run|--force|--create|--restore|--version|--help}

${_bold}Arguments:${_normal}
${_bold}-b|--vbox-path${_normal} ${_underline}\"/path/to/folder/\"${_normal}
    Path to the directory where Virtual Box will keep Vagrant hdd images.
    By defult it is \"\$HOME/VirtualBox VMs/\". You can also give 'default'
    as a value to restore to default settings.

    ${_bold}Example:${_normal}
        ./valter.sh --vbox-path /Volumes/USBdisk/
        ./valter.sh --vbox-path \"/Volumes/external disk/\"
        [quotes are necessary if there are spaces in path]
        ./valter.sh --vbox-path default

${_bold}-g|--vagrant-env${_normal} ${_underline}"/path/to/folder/"${_normal}
    Provides path for 'VAGRANT_HOME' environment variable. By default it is
    your '\$HOME' directory.
    VAGRANT_HOME can be set to change the directory where Vagrant stores global
    state. By default, this is set to ~/.vagrant.d. The Vagrant home directory
    is where things such as boxes are stored, so it can actually become quite
    large on disk.

    ${_bold}Example:${_normal}
        ./valter.sh --vagrant-env /Volumes/USBdisk/
        ./valter.sh --vagrant-env \"/Volumes/external disk/\"
        [quotes are necessary if there are spaces in path]
        ./valter.sh --vagrant-env \$HOME/

${_bold}-d|--dry-run${_normal}    Run script in pretend mode. All possibly destructive actions
                will only show debug messages. No actual changes are made.

${_bold}-f|--force${_normal}      Force overwriting of VAGRANT_HOME environment variable. Without
                that flag if VAGRANT_HOME is present in your shell config file,
                script will abort.

${_bold}-c|--create${_normal}     Create shell configuration file. For ZSH '.zshrc' will be
                created, for Bash '.bash_profile' (for OSX) and '.bshrc' for
                Linux, '.kshrc' will be created for Korn shell.

${_bold}-r|--restore${_normal}    Shortcut to restore default settings, i.e. remove VAGRANT_HOME
                from your shell configuration, and set Virtual Box machine
                folder to 'defult'.

${_bold}-v|--version${_normal}    Show version of valter script.

${_bold}-h|--help${_normal}       Show this help.
";
    exit 0;
}



init ()
{
    prepare_arguments $# $@;
    set_colours;

    if [ $DRYRUN_MODE -eq 1 ];
    then
        echo -e "$YELLOW[DEBUG] NEW_VAGRANT_HOME_FOLDER=$NEW_VAGRANT_HOME_FOLDER $CLEARCOLOR";
        echo -e "$YELLOW[DEBUG] NEW_VB_MACHINE_FOLDER=$NEW_VB_MACHINE_FOLDER $CLEARCOLOR";
        echo -e "$YELLOW[DEBUG] DRYRUN_MODE=$DRYRUN_MODE $CLEARCOLOR";
        echo -e "$YELLOW[DEBUG] CREATE_FLAG=$CREATE_FLAG $CLEARCOLOR";
        echo -e "$YELLOW[DEBUG] FORCE_FLAG=$FORCE_FLAG $CLEARCOLOR";
        echo -e "$YELLOW[DEBUG] RESTORE_FLAG=$RESTORE_FLAG $CLEARCOLOR";
    fi

    if [[ -n $NEW_VAGRANT_HOME_FOLDER ]]
    then
        set_new_vagrant_environment;
    fi

    if [[ -n $NEW_VB_MACHINE_FOLDER ]]
    then
        change_current_vbox_machine_folder;
    fi

    if [[ $RESTORE_FLAG -eq 1 ]]
    then
        restore_to_defaults;
    fi

    exit 0;

    # set_new_vagrant_environment;
    # restore_to_defaults;
    # check_shell;
    # is_vagrant_env_in_profile;
    # remove_vagrant_env_from_profile;
    # add_vagrant_env_to_profile;
    #change_current_vbox_machine_folder;
}

check_shell ()
{
    # check $shell var and grab the last part of it, that should be the name of
    # default shell binary
    local _CURRENT_SHELL=$(echo $SHELL | awk -F "/" '{print $NF}');
    echo -e "$GREEN[INFO] Checking your shell. Detected: $YELLOW $_CURRENT_SHELL $CLEARCOLOR";

    set_shell_profile $_CURRENT_SHELL;

    echo -e "$GREEN[INFO] Your default shell configuration set to $YELLOW $SHELL_CONFIG $CLEARCOLOR";
    # echo $SHELL_CONFIG;
}

set_shell_profile ()
{
    case $1 in
        ksh)
            SHELL_CONFIG="$HOME/.zshrc";;
        bash)
        #this is apparently only for OSX - all other systtems use .bashrc
            SHELL_CONFIG="$HOME/.bash_profile";;
        zsh)
            SHELL_CONFIG="$HOME/.kshrc";;
        *)
            echo "Great Scott! I don't know this shell.";;
    esac
}


add_vagrant_env_to_profile ()
{
    if [ -n "$SHELL_CONFIG" ];
        then
            echo -e "$GREEN[INFO] Checking your shell configuration files.$CLEARCOLOR";

            if [[ $(check_if_profile_exist $SHELL_CONFIG) == "true" ]];
                then
                    echo -e "$GREEN[INFO] Adding 'VAGRANT_HOME' into your shell configuration.$CLEARCOLOR";

                    if [ $DRYRUN_MODE -eq 1 ];
                    then
                        echo -e "$YELLOW[DEBUG] Pretending to 'export VAGRANT_HOME=$NEW_VAGRANT_HOME_FOLDER' to your '$SHELL_CONFIG'.$CLEARCOLOR";
                    else
                        # WARNING! Next line is potentialy destructible!
                        if VGH_EXP_RESULT=$(echo "export VAGRANT_HOME=\"$NEW_VAGRANT_HOME_FOLDER\"" >> $SHELL_CONFIG);
                        then
                            echo -e "$GREEN[INFO] Added $YELLOW 'export VAGRANT_HOME=$NEW_VAGRANT_HOME_FOLDER'$GREEN to your$YELLOW '$SHELL_CONFIG'.$CLEARCOLOR";
                        else
                            echo -e "$RED[ERROR] Problem adding VAGRANT_HOME $VGH_EXP_RESULT.$CLEARCOLOR";
                        fi
                    fi

            elif [[ $(check_if_profile_exist $SHELL_CONFIG) == "false" ]] && [[ $CREATE_FLAG -eq 1 ]];
                then

                    echo -e "$GREEN[INFO] Shell configuration file not found.$CLEARCOLOR";
                    echo -e "$GREEN[INFO] Using 'CREATE' configuration mode.$CLEARCOLOR";

                    if [ $DRYRUN_MODE -eq 1 ];
                    then
                        echo -e "$YELLOW[DEBUG] Touching your config file: '$SHELL_CONFIG'.$CLEARCOLOR";
                    else
                        # create shell config file
                        touch $SHELL_CONFIG;
                    fi

                    if [[ $(check_if_profile_exist $SHELL_CONFIG) == "true" ]];
                    then
                        echo -e "$GREEN[INFO] Shell configuration file has been created.$CLEARCOLOR";
                    else
                        echo -e "$RED[ERROR] Cannot create shell profile. Please create it manually.$CLEARCOLOR";
                        exit 1;
                    fi
                    # invoke self to go through adding VAGRANT_HOME routine again.
                    add_vagrant_env_to_profile $SHELL_CONFIG;

                else
                    echo -e "$RED[ERROR] Your shell configuration file does not exists. Try running the script with -C flag, or create it manually.$CLEARCOLOR";
                    exit 1;
            fi

        else
            echo -e "$RED[ERROR] Your shell path is not set. Cannot proceed.$CLEARCOLOR";
            exit 1;
    fi
}

is_vagrant_env_in_profile ()
{
    if [ -n "$SHELL_CONFIG" ];
        then
            if local TEST_RESULT=$(grep 'VAGRANT_HOME' $SHELL_CONFIG);
            then
                echo "true";
            else
                echo "false";
            fi
        else
            echo -e "$RED[ERROR]Shell config not set.$CLEARCOLOR";
            exit 1;
    fi
}

remove_vagrant_env_from_profile ()
{
    if [ -n "$SHELL_CONFIG" ];
        then

            if [ $DRYRUN_MODE -eq 1 ];
            then
                echo -e "$YELLOW[DEBUG] Pretending to remove VAGRANT_HOME from $SHELL_CONFIG . $CLEARCOLOR";
            else
                if VGH_RESULT=$(sed -i '' '/VAGRANT_HOME/d' $SHELL_CONFIG);
                then
                    echo -e "$GREEN[INFO] Removed VAGRANT_HOME from your config file.$CLEARCOLOR";
                else
                    echo -e "$RED[ERROR] Problem removing VAGRANT_HOME $VGH_RESULT.$CLEARCOLOR";
                fi
            fi

        else
            echo "Shell config not set";
    fi
}

##
# Check if given shell profile (path to it) is a file
##
check_if_profile_exist ()
{
    if [ -f "$1" ];
    then
        echo "true";
    else
        echo "false";
    fi
}

change_current_vbox_machine_folder ()
{
    #
    case $(check_os) in
        Darwin)
            echo -e "$GREEN[INFO] OSX detected.$CLEARCOLOR";
            VM_CONF_PATH="$HOME/Li*/Virt*/VirtualBox.xml";
            CURRENT_VBOX_MACHINE_FOLDER=$(check_current_vbox_machine_folder $VM_CONF_PATH);;
        *)
            echo -e "$GREEN[INFO] Other system detected.$CLEARCOLOR";
            exit 1;;
    esac

    echo -e "$GREEN[INFO] Your current VirtualBox VM folder is: $YELLOW \"$CURRENT_VBOX_MACHINE_FOLDER\".$CLEARCOLOR";
    echo -e "$GREEN[INFO] Changing it to: $YELLOW $NEW_VB_MACHINE_FOLDER.$CLEARCOLOR";

    if [ $DRYRUN_MODE -eq 1 ];
    then
        echo -e "$YELLOW[DEBUG] Pretending to change your VBox machinefolder. $CLEARCOLOR";
        echo -e "$YELLOW[DEBUG] Your machine folder is: $(check_current_vbox_machine_folder $VM_CONF_PATH) $CLEARCOLOR";
    else
        # VBoxManage setproperty machinefolder $NEW_VB_MACHINE_FOLDER;
        if VBM_RESULT=$(VBoxManage setproperty machinefolder $NEW_VB_MACHINE_FOLDER);
        then
            echo -e "$GREEN[INFO] Default VirtualBox Machine folder has been changed.$CLEARCOLOR";
        else
            echo -e "$RED[ERROR] VBoxManage failed changing the folder with error: $VBM_RESULT.$CLEARCOLOR";
        fi
    fi
}

check_current_vbox_machine_folder ()
{
    echo $(grep -o -E 'defaultMachineFolder=\".*?\" ' $1 | awk -F= '{print $2}' | sed 's/"//g');
}


check_os ()
{
    #todo add checking uname &/or lsb_release -a
    echo $(uname -s);
}

restore_to_defaults ()
{
    #TODO: add dry run mode to it!!!
    NEW_VB_MACHINE_FOLDER="default";

    check_shell;
    remove_vagrant_env_from_profile;
    change_current_vbox_machine_folder;

}

set_new_vagrant_environment ()
{
    check_shell;

    if [[ $(is_vagrant_env_in_profile) == 'true' ]];
    then
        echo -e "$YELLOW[WARNING] There is already a VAGRANT_HOME in your profile.$CLEARCOLOR";
        if [ $FORCE_FLAG -eq 1 ];
        then
            echo -e "$YELLOW[WARNING] Force mode turned on.$CLEARCOLOR";
            remove_vagrant_env_from_profile;
        else
            echo -e "$YELLOW[WARNING] Please use -F flag to force overwriting.$CLEARCOLOR";
            exit 1;
        fi
    fi

    add_vagrant_env_to_profile;

    # [[ ! $(source $SHELL_CONFIG) ]] && { echo "Error sourcing"; exit 1; } || echo "Re-loaded shell profile";
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

##
# @function set_colours()
#   Prepare global colours variables by assigning CLI colour values to them
#   or empty for no colour (for file output).
#
#   Usage:
#       set_colours <option> | set_colours
#
# @global RED
# @global CYAN
# @global GREEN
# @global CLEARCOLOR
# @global YELLOW
# @global WHITE
#
# @param $1 optional boolean 1 for no colour, 0 for colour
#
# @return void
##
set_colours() {
    # Prepare vars for color/non-color output
    if [[ $NOCOLOR -eq 1 ]] || [[ $1 -eq 1 ]]
    then
        RED=""
        CYAN=""
        GREEN=""
        CLEARCOLOR=""
        YELLOW=""
        WHITE=""
    else
        # Colours for messages
        RED="\x1b[31m"
        CYAN="\x1b[96m"
        GREEN="\x1b[32m"
        CLEARCOLOR="\x1b[0m"
        YELLOW="\x1b[33m"
        WHITE="\x1b[37m"
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
            -n|--no-color)
                NOCOLOR=1
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
