#!/bin/bash

###################################################
#
# Small script to command line manage docker
#
###################################################
# (c) Matthias Nott, SAP. Licensed under WTFPL.
###################################################

###################################################
#
# Configuration
#

#
# Configure an Editor. You may want to use vi.
#

editor=e

_edit() {
  $editor $1
}


#
# Check if we have rlwrap
#
if command -v rlwrap &>/dev/null; then
  HISTORY=$HOME/.docker_history;
  RLWRAP=true;
else
  RLWRAP=false;
fi

#
# Configure for graphical programs
#
#
# If you want to run graphical programs from within
# Docker, you can first install socat on your host,
# like
#
# brew install socat
#
# Then run socat like so:
#
# socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\"
#
# Then, if on a Mac, run Xqartz and configure it under
# Security to allow connections from network clients;
# depending on your configuration, you may or may not
# Authenticat connections (same configuration page).
# Finally, you just pass in the IP as a configuration
# option like so:
#
# -e DISPLAY=$myip:0
#
myip=$(ifconfig | grep -v :: | grep inet | \
       awk '{print $2}' | cut -d':' -f2 | \
       grep -iv 127.0.0.1 | head -1)

#
###################################################


###################################################
#
# Some Variables for Colors
#

RED='\033[0;41;30m'
BLU='\033[0;34m'
GRE='\033[0;32m'
STD='\033[0;0;39m'

###################################################
#
# Shared Functions
#
###################################################


apause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

###################################################
#
# The Logging System. Copied shamelessly from
#
# http://github.com/fredpalmer/log4bash
#
# I've added error precedence so that we can
# have actual error loglevels.
#

# This should probably be the right way - didn't have time to experiment though
# declare -r INTERACTIVE_MODE="$([ tty --silent ] && echo on || echo off)"
declare -r INTERACTIVE_MODE=$([ "$(uname)" == "Darwin" ] && echo "on" || echo "off")

# Begin Logging Section
if [[ "${INTERACTIVE_MODE}" == "off" ]]
then
    # Then we don't care about log colors
    declare -r LOG_DEFAULT_COLOR=""
    declare -r LOG_ERROR_COLOR=""
    declare -r LOG_INFO_COLOR=""
    declare -r LOG_SUCCESS_COLOR=""
    declare -r LOG_WARN_COLOR=""
    declare -r LOG_DEBUG_COLOR=""
else
    declare -r LOG_DEFAULT_COLOR="\033[0m"
    declare -r LOG_ERROR_COLOR="\033[1;31m"
    declare -r LOG_INFO_COLOR="\033[1m"
    declare -r LOG_SUCCESS_COLOR="\033[1;32m"
    declare -r LOG_WARN_COLOR="\033[1;33m"
    declare -r LOG_DEBUG_COLOR="\033[1;34m"
fi


#
# Log level ranking
#
loglevels() {
    if [[ ${LOGLEVEL} == "SUCCESS" ]]; then lvl=1;
  elif [[ ${LOGLEVEL} == "ERROR"   ]]; then lvl=2;
  elif [[ ${LOGLEVEL} == "WARN"    ]]; then lvl=3;
  elif [[ ${LOGLEVEL} == "INFO"    ]]; then lvl=4;
  elif [[ ${LOGLEVEL} == "DEBUG"   ]]; then lvl=5;
  else lvl=4;
  fi;
}
loglevels;


#
# Default log function: add any of the keywords
# in front of the log message, or nothing for info
# level.
#
log() {
    if [[ $1 == "DEBUG"   && $lvl >  4 ]]; then shift; log_debug   "$@";
  elif [[ $1 == "INFO"    && $lvl >  3 ]]; then shift; log_info    "$@";
  elif [[ $1 == "WARN"    && $lvl >  2 ]]; then shift; log_warn    "$@";
  elif [[ $1 == "ERROR"   && $lvl >  1 ]]; then shift; log_error   "$@";
  elif [[ $1 == "SUCCESS" && $lvl > -1 ]]; then shift; log_success "$@";
  elif [[ $lvl > 3 && $1 != "DEBUG" && $1 != "INFO" && $0 != "WARN" && $0 != "ERROR" && $0 != "SUCCESS" ]]; then
    log_info "$@";
  fi
}
_log() { log "$@"; }


#
# Print the actual log message
#
log_msg() {
    local log_text="$1"
    local log_level="$2"
    local log_color="$3"

    [[ -z ${log_level} ]] && log_level="INFO";
    [[ -z ${log_color} ]] && log_color="${LOG_INFO_COLOR}";

    printf "${log_color}[$(date +"%Y-%m-%d %H:%M:%S %Z")] "
    printf "[%-8s] ${log_text} ${LOG_DEFAULT_COLOR}\n" ${log_level};
    return 0;
}


log_speak()     {
    if [[ ! ${LOGVOICE} == "true" ]]; then return; fi;
    if type -P say >/dev/null
    then
        local easier_to_say="$1";
        case "${easier_to_say}" in
            studionowdev*)
                easier_to_say="studio now dev ${easier_to_say#studionowdev}";
                ;;
            studionow*)
                easier_to_say="studio now ${easier_to_say#studionow}";
                ;;
        esac
        say "${easier_to_say}";
    fi
    return 0;
}

log_success()  { if [[ $lvl > -1 ]]; then log_msg "$1" "SUCCESS" "${LOG_SUCCESS_COLOR}"; fi; }
log_error()    { if [[ $lvl >  1 ]]; then log_msg "$1" "ERROR"   "${LOG_ERROR_COLOR}"; log_speak "$1"; fi; }
log_warn()     { if [[ $lvl >  2 ]]; then log_msg "$1" "WARNING" "${LOG_WARN_COLOR}"; fi; }
log_info()     { if [[ $lvl >  3 ]]; then log_msg "$1" "INFO"    "${LOG_INFO_COLOR}"; fi; }
log_debug()    { if [[ $lvl >  4 ]]; then log_msg "$1" "DEBUG"   "${LOG_DEBUG_COLOR}"; fi; }
log_captains() {
    if type -P figlet >/dev/null;
    then
        figlet -f computer -w 120 "$1";
    else
        log "$1";
    fi

    log_speak "$1";

    return 0;
}

#
# End Logging Section
###################################################

#
# read -i does not exist on Bash 3 on MacOS
#
function readinput() {
  printf "$3[$5] "
  read vmname && [ -n "$vmname" ] || vmname=$5
}


###################################################
#
# Docker Compose
#
###################################################

_up () {
  docker-compose up -d
}

_down () {
  # down would remove the container
  docker-compose stop
}


###################################################
#
# Containers
#
###################################################

_ls() {
  echo ""
  echo "Running Containers:"
  echo ""
  docker ps -f "status=running"
}

lss() {
  echo ""
  echo "Stopped Containers:"
  echo ""
  docker ps -f "status=exited"
}

_lsp() {
  echo ""
  echo "Paused Containers:"
  echo ""
  docker ps -f "status=paused"
}

_la() {
  echo ""
  echo "All Containers:"
  echo ""
  docker container ls -a
}

_stop() {
  if [[ "" == "$1" ]]; then
    _ls
    readinput -e -p "Enter Container name to stop: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
    docker stop "$i"
    echo ""
  done
}

_pause() {
  if [[ "" == "$1" ]]; then
    _ls
    readinput -e -p "Enter Container name to pause: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
    docker pause "$i"
    echo ""
  done
}

_kill() {
  if [[ "" == "$1" ]]; then
    _ls
    readinput -e -p "Enter Container name to kill: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
    docker kill "$i"
    echo ""
  done
}


_create() {
  if [[ "" == "$1" ]]; then
    _lsi
    readinput -e -p "Enter Image name to instantiate: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
      if [[ -f docker-compose.yaml || -f docher-compose.yml ]]; then
        docker-compose up -d
      else
        if docker ps -a --format '{{.Names}}' | grep -Eq "^$(echo $i|sed 's#/#_#g')\$"; then
          docker restart $(echo $i|sed 's#/#_#g')
        else
          docker run --name $(echo $i|sed 's#/#_#g') -d  $i
        fi
      fi
    echo ""
  done
}


_start() {
  if [[ "" == "$1" ]]; then
    lss
    readinput -e -p "Enter Container name to start: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
    docker start "$i"
    echo ""
  done
}

_unpause() {
  if [[ "" == "$1" ]]; then
    _lsp
    readinput -e -p "Enter Container name to unpause: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
    docker unpause "$i"
    echo ""
  done
}


_rm() {
  if [[ "" == "$1" ]]; then
    lss
    readinput -e -p "Enter Container name to remove: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi


  for i in $vmname; do
    echo ""
    docker rm "$i"
    echo ""
  done
}


_rms() {
  docker container prune
}


###################################################
#
# Images
#
###################################################

_lsi() {
  docker image ls
}

_lsd() {
  docker images -f "dangling=true"
}

_rmd() {
  docker rmi $(docker images -f "dangling=true" -q)
}


_rmi() {
  if [[ "" == "$1" ]]; then
    _lsi
    readinput -e -p "Enter Image name to remove: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  for i in $vmname; do
    echo ""
    docker rmi "$i"
    echo ""
  done
}

_build() {
  if [[ -f docker-compose.yaml || -f docher-compose.yml ]]; then
    docker-compose build
  else
    readinput -e -p "Enter tag: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
    docker build --squash -t "$vmname" .
  fi
}




###################################################
#
# con
#
###################################################

_con() {
  if [[ "" == "$1" ]]; then
    _ls
    readinput -e -p "Enter Container name to connect to: " -i "$vmname" vmname
    if [[ "" == "$vmname" ]]; then return; fi
  else
    vmname=$1
  fi

  echo ""
  if [[ $myip != "" ]]; then
    docker exec -e DISPLAY=$myip:0 --privileged -it "$vmname" /bin/bash
  else
    docker exec --privileged -it "$vmname" /bin/bash
  fi
  echo ""
}

###################################################
#
# Main Menu
#
###################################################

show_menus() {
    clear
    echo -e "-------------------------------------------"
    echo -e "       ${BLU}D O C K E R      C O N T R O L${STD}"
    echo -e "-------------------------------------------"
    echo ""

    if [[ -f docker-compose.yaml || -f docker-compose.yml ]]; then
      echo -e "${GRE}Compose${STD}"
      echo ""
      echo -e "${GRE}[up]${STD}     Up      $DM"
      echo -e "${GRE}[down]${STD}   Down    $DM"
      echo ""
    fi

    echo -e "${GRE}Containers${STD}"
    echo ""
    echo -e "${GRE}[la]${STD}       List    All       Containers"
    echo -e "${GRE}[ls]${STD}       List    Running   Containers"
    echo -e "${GRE}[lsp]${STD}      List    Paused    Containers"
    echo -e "${GRE}[lss]${STD}      List    Stopped   Containers"
    echo ""
    echo -e "${GRE}[create]${STD}   Create  Container"
    echo -e "${GRE}[start]${STD}    Start   Container"
    echo -e "${GRE}[pause]${STD}    Pause   Container"
    echo -e "${GRE}[unpause]${STD}  Unpause Container"
    echo -e "${GRE}[stop]${STD}     Stop    Container"
    echo -e "${GRE}[kill]${STD}     Kill    Container"
    echo -e "${GRE}[rm]${STD}       Remove  Container"
    echo -e "${GRE}[rms]${STD}      Remove  Stopped Containers"
    echo ""

    echo -e "${GRE}Images${STD}"
    echo ""
    echo -e "${GRE}[lsi]${STD}      List    All       Images"
    echo -e "${GRE}[lsd]${STD}      List    Dangling  Images"
    echo -e "${GRE}[rmd]${STD}      Remove  Dangling  Images"
    echo -e "${GRE}[rmi]${STD}      Remove  Image"
    echo ""
    echo -e "${GRE}[edit]${STD}     Edit    Dockerfile"
    echo -e "${GRE}[build]${STD}    Build   Image"
    echo ""

    echo -e "${GRE}Console${STD}"
    echo ""
    echo -e "${GRE}[con]${STD}      Connect to Container"

    echo ""
}

read_options(){
    sleeptime=0.5
    trap 'echo "";exit 0' SIGINT
    local choice
    pr="$(echo -e ${GRE}"Choose Option "$STD) to run, or q to exit: "
    if [[ "$RLWRAP" == true ]]; then
      echo -e $pr
      choice=$(rlwrap -D 2 -H $HISTORY sh -c 'read REPLY && echo $REPLY')
    else
      read -p "$pr" choice
    fi

    #
    # Get first word; special handling for commands that
    # can take arguments
    #
    first=$(echo $choice | awk '{print $1;}')
    if [[    "$first" == "push"
          || "$first" == "pull"
          || "$first" == "commit"
          || "$first" == "add"
       ]]; then
        rest=$(echo $choice | awk '{for (i=2; i<=NF; i++) print $i}')
        _$first $rest
        apause
        return
    fi

    #
    # Some commands take just exactly one parameter
    #
    if [[    "$first" == "swc"
       ]]; then
        parm=$(echo $choice | awk '{for (i=2; i<3; i++) print $i}')
        choice=$(echo $choice | awk '{for (i=3; i<=NF; i++) print $i}')
        _$first $parm
        if [[ "$choice" == "" ]]; then
          return
        fi
    fi


    for i in $choice; do
      case $i in
        up)      _up;apause;;
        down)    _down;apause;;
        ls)      _ls;apause;;
        lsp)     _lsp;apause;;
        lss)     _lss;apause;;
        la)      _la;apause;;
        stop)    _stop;apause;;
        kill)    _kill;apause;;
        create)  _create;apause;;
        pause)   _pause;apause;;
        unpause) _unpause;apause;;
        start)   _start;apause;;
        rm)      _rm;apause;;
        rms)     _rms;apause;;
        lsi)     _lsi;apause;;
        lsd)     _lsd;apause;;
        rmd)     _rmd;apause;;
        rmi)     _rmi;apause;;
        edit)    _edit Dockerfile;apause;;
        build)   _build;apause;;
        con)     _con;apause;;

        q|x) exit 0;;
        *) if [[ "$RLWRAP" == true && -f "${HISTORY}" ]]; then
                               cat "$HISTORY" | grep -v "$choice" > "${HISTORY}.sav"
                               mv "${HISTORY}.sav" "${HISTORY}"
                            fi
	   echo -e "${RED}Error...${STD}" && sleep 1
      esac;
    done
}


###################################################
# Trap CTRL+C, CTRL+Z and quit singles
###################################################

trap '' SIGINT SIGQUIT SIGTSTP


###################################################
# Main Loop
###################################################

if [[ "$#" -gt 0 ]]; then
    # Extract the command name and remove the underscore prefix
    command_name="_$1"
    shift  # Remove the command name from the arguments list

    # Check if the command is a known function
    if [[ $(type -t "$command_name") == function ]]; then
        # Check if there are additional arguments
        if [[ "$#" -gt 0 ]]; then
            # Loop through all remaining arguments
            for arg in "$@"; do
                # Call the function with each argument
                $command_name "$arg"
            done
        else
            # Call the function without arguments
            $command_name
        fi
    else
        log ERROR "! ${command_name:1} is not a known command."
    fi
else
    while true
    do
        show_menus
        read_options
    done
fi






