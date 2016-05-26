#!/usr/bin/env bash

# ##################################################
#
version="1.0.0"
#
# HISTORY:
#
# * DATE - v1.0.0  - Initial commit
#
# ##################################################


function mainScript() {
    installdir="/usr/local/bin/"
    toinstall=(
        up
        palias
        d2u
    )
    sourcedScripts=(
        up
    )

    for script in "${toinstall[@]}"
    do
        cp "src/$script" $installdir
        chmod 755 ${installdir}${script}
        success "$script copied"
    done
    
    if [ "$sourcing" = true ] ; then
        printf "\n# AL-BASHINO SCRIPTS\n" >> ~/.bashrc
        printf "# ------------------\n" >> ~/.bashrc
        for script in "${sourcedScripts[@]}"
        do
            echo ". ${installdir}${script}" >> ~/.bashrc
            success "$script sourced (see ~/.bashrc)"
        done
    fi

    echo -n
}

scriptName=$(basename "$0")

function safeExit() {
    # safeExit
    # -----------------------------------
    # Non destructive exit for when script exits naturally.
    # -----------------------------------

    trap - INT TERM EXIT
    exit
}

# Set Flags
# -----------------------------------
quiet=false
sourcing=true
args=()

# Options and Usage
# -----------------------------------
# Print usage
usage() {
  echo -n "${scriptName} [OPTION]... [FILE]...

This is the main installation script. It will install the scripts in src based on your options.

 ${bold}Options:${reset}
  -q, --quiet       Quiet (no output)
  -h, --help        Display this help and exit
      --version     Output version information and exit
"
}

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;

    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safeExit ;;
    --version) echo "$(basename $0) ${version}"; safeExit ;;
    -s|--no-sourcing) sourcing=false ;;
    -q|--quiet) quiet=true ;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

# Store the remaining part as arguments.
args+=("$@")


# Logging and Colors
# -----------------------------------------------------
# Here we set the colors for the script feedback.
# Example usage: success "sometext"
#------------------------------------------------------

# Set Colors
bold=$(tput bold)
reset=$(tput sgr0)
purple=$(tput setaf 171)
red=$(tput setaf 1)
green=$(tput setaf 76)
tan=$(tput setaf 3)
blue=$(tput setaf 38)
underline=$(tput sgr 0 1)

function _alert() {
  if [ "${1}" = "error" ]; then local color="${bold}${red}"; fi
  if [ "${1}" = "warning" ]; then local color="${red}"; fi
  if [ "${1}" = "success" ]; then local color="${green}"; fi
  if [ "${1}" = "debug" ]; then local color="${purple}"; fi
  if [ "${1}" = "header" ]; then local color="${bold}""${tan}"; fi
  if [ "${1}" = "input" ]; then local color="${bold}"; fi
  if [ "${1}" = "info" ] || [ "${1}" = "notice" ]; then local color=""; fi
  # Don't use colors on pipes or non-recognized terminals
  if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then color=""; reset=""; fi

  # Print to console when script is not 'quiet'
  if ${quiet}; then return; else
   echo -e "$(date +"%r") ${color}$(printf "[%7s]" "${1}") ${_message}${reset}";
  fi
}

function die ()       { local _message="${*} Exiting."; echo -e "$(_alert error)"; safeExit;}
function error ()     { local _message="${*}"; echo -e "$(_alert error)"; }
function warning ()   { local _message="${*}"; echo -e "$(_alert warning)"; }
function notice ()    { local _message="${*}"; echo -e "$(_alert notice)"; }
function info ()      { local _message="${*}"; echo -e "$(_alert info)"; }
function success ()   { local _message="${*}"; echo -e "$(_alert success)"; }
function input()      { local _message="${*}"; echo -n "$(_alert input)"; }
function header()     { local _message="== ${*} ==  "; echo -e "$(_alert header)"; }

# Set IFS to preferred implementation
IFS=$' \n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
set -o errexit

# Bash will remember & return the highest exitcode in a chain of pipes.
set -o pipefail

# Run script
mainScript

# Exit cleanly
safeExit
