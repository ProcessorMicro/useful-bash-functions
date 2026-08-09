#!/bin/bash
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	/etc/profile.d/FUNCTIONS-SH-EXTRA-FUNCTIONS.sh

SCRIPT_PURPOSE="This script contains a set of extra bash functions for use in the command line."
SCRIPT_VERSION="12.04.03 - Aug 07, 2026"

# Copyright (C) 2013-2025 by Mike Armstrong
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy (the file 'LICENSE') of the GNU General Public
# License along with this program; if not, see <https://www.gnu.org/licenses>.

##________________________________________________________________________________
## INSTALLATION - If this script is installed in the directory "/etc/profile.d",
##   the following functions will be available for all "bash" terminal sessions.

##________________________________________________________________________________
##
## FUNCTIONS - This function will load the functions.sh script into the current
##     environment, turn off bash debugging and set all EXITs to RETURNs.
##     Requires: functions.sh
##   Usage: FUNCTIONS [-N]
##   Where: -N will load functions.sh.NEW
function FUNCTIONS () {
  local new
  set +x
  [[ $1 == -N ]] && { new=".NEW" ; shift ; } || unset new
  (( $# )) && functions.sh${new} "$@" || source functions.sh${new}
  USAGE_RETURN
}

##________________________________________________________________________________
##
## HIGHLIGHT - A debugging function that highlights the usage
##   of GET_ARGS, IS_EXCLUSIVE, ${TEST...} etc. in script $1.
##   Requires functions.sh
function HIGHLIGHT() {
  FUNCTIONS
  GET_ARGS_HIGHLIGHT "$1"
}

##________________________________________________________________________________
##
## RUNME - Creates a sub-shell, loads functions.sh, executes
##         the arguments as a command and pretty-displays the results.
##   Usage:
##     RUNME [OPTIONS] FUNCTION_N_ARGS
##   Where OPTIONS are:
##     -c CMDS
##       Execute CMDS after executing the function. If CMDS
##       contains more than one command or any expansions use:
##          -C "eval CMD1 \$var ; CMD2 ..."
##     -e Force an exit on "quit" rather than a return.
##     -l LIBRARY
##       Load function LIBRARY as well as functions.sh.
##       This option may be repeated for additional libraries.
##     -n Load functions.sh.NEW rather than functions.sh
##     -o Load functions.sh.OLD rather than functions.sh
##     -x or -xNC
##       Execute FUNCTION with bash debugging (set -x). If NC is
##       not null, cleanup functions are bypassed.
##     FUNCTION_N_ARGS
##       The function (with arguments) to be executed.
##   RUNME is useful for testing/trying, any functions loaded into
##     the bash environment, in a safe (protected) subshell. However
##     is designed to interact with the functions contained in
##     functions.sh.
##   If a function returns a variable (uses -V) or if it is one of
##     the ASK... functions, the contents of that variable is also
##     displayed (columnized).
##   Note: Since it is executed as a function, the current bash
##         environment is available to FUNCTION and to CMDS.
##   Note: RUNME can execute any linux command, not just functions
##         available in the environment.
##   Example:  RUNME ASK -l -C "a f k z p" -M
##   Requires: functions.sh
function RUNME() {
  local _Cmds_ _Debug_ _Exit_ _FoundV_ _i_ _IsArray_ _Lib_ _New_ _Ret_ _Var_
  ( while true ; do					# Do everything in a sub-shell
      case "${1,,}" in
        -c) _Cmds_="$2"   ; shift 1 ;;			# Execute commands after
        -e) _Exit_="1  " ;;				# Force an exit
        -l) _Lib_+=($2)   ; shift 1 ;;			# Load another function library
        -n) _New_=".NEW" ;;				# Load the .NEW version of the libraries
        -o) _New_=".OLD" ;;				# Load the .OLD version of the libraries
       -x*) _Debug_="1"					# Turn on bash debugging
            (( ${#1} > 2 )) && _Debug_="2" ;;		#   And test mode
        -h) echo -e "RUNME [OPTIONS] <FUNCTION_N_ARGS>\n  -c CMD  Execute commands CMD after executing FUNCTION\n  -e      Force an exit\n  -l LIB  Load library LIB\n  -n      Load the .NEW version of the libraries\n  -o      Load the .OLD version of the libraries\n  -x[x]   Turn on bash debugging (-x) and script debugging (-xx)\n  -h      This info"
            return 0
            ;;
         *) break ;;					# The rest are commands to be executed
      esac
      shift 1
    done
    # Load the functions and the global defaults into this environment.
    if (( _functions_sh_loaded_ )) ; then           # Is functions.sh loaded?
      FUNCTIONS_SH_INIT                             # Initialize functions.sh
    else                                            # functions.sh not loaded
      COMMON_FUNCTIONS="$(type -p functions.sh)"    # Locate and load functions.sh
      [[ -x ${COMMON_FUNCTIONS} ]] && source "${COMMON_FUNCTIONS}" || { echo -e "Cannot locate "${COMMON_FUNCTIONS:-functions.sh}"." 1>&2 ; exit ; }
    fi
    [[ -f ~/bin/FUNCTIONS-SH-GLOBAL-DEFAULTS.sh ]] && EFdir=~/bin || EFdir=/etc/profile.d
    source "${EFdir}/FUNCTIONS-SH-GLOBAL-DEFAULTS.sh"

    for _i_ in ${_Lib_[*]} ; do echo source "${_i_}${_New_}" ; source "${_i_}${_New_}" ; done	# Load other libraries
    if (( _Debug_ > 1 )) ; then
      TEST_SET
      unset _CLEANUP_ALWAYS_
    fi
    _Cmd_="$1"
    unset _Var_
    if [[ $@ =~ \ -V\  ]] ; then			# Output to be placed into a variable?
      for _i_ in "$@" ; do				# Look at the args
        (( _FoundV_ )) && { _Var_="$_i_"; break; }	# Save the name and get out
        [[ ${_i_} == -V ]] && _FoundV_="1"		# Found -V so next one is the var name
      done
    elif [[ ${_Cmd_} =~ ^ASK_? ]] ; then		# ASK or ASK_WITH_MENU always returns a variable
      _Var_="ANSWER"					#   so "ANSWER" is the default variable name
    fi
    unset ${_Var_} ${_Var_}_IDX ${_Var_}_VAL		# Ensure the answer variables are unset
    [[ " $* " =~ \ ASK.*\ -M\  ]] && _IsArray_="1"	# Is array so expect 1 to 3 answer variables

    # Display, nicely formatted into columns, the results from executing the function
    function _Display_() {
      local _Count_ _Instruct_ _Sep_=$'\001' _Type_ _Val_
      COLORS_SET -T					# In case it was set for GUI mode
      (( _Debug_ )) && set -x
      echo -e "\n\t${UL}Results for function \"${_Cmd_}\"${DEF}."
      {
        if [[ -n ${_Var_} ]] ; then			# Variable requested
          eval _Type_="\${#${_Var_}[*]}"		# Get the number of elements in '_Var_'
          eval _Count_=\${\#${_Var_}_IDX[*]}
          (( _Type_ < 2 && ! _Count_ )) && _Type_="Scalar" || _Type_="Array"
          echo -n "${_Type_} ${_Var_}:${_Sep_}"
          eval echo -e \"\${${_Var_}[@]@Q}\"		# Display '${_Var_[*]}'
          if (( _Count_ )) ; then
            echo -n "${_Type_} ${_Var_}_IDX:${_Sep_}"
            eval echo -e \"\${${_Var_}_IDX[@]@Q}\"	# Display '${_Var__IDX[*]}'
          fi
          eval _Count_=\${\#${_Var_}_VAL[*]}
          if (( _Count_ )) ; then
            echo -n "${_Type_} ${_Var_}_VAL:${_Sep_}"
            eval echo -e \"\${${_Var_}_VAL[@]@Q}\"	# Display '${_Var__VAL[*]}'
          fi
        fi
        echo -e "Return code:${_Sep_} ${_Ret_}"
      } | column --table --table-right=1 --separator="${_Sep_}" --output-separator=" " | sed -e 's/^/  /'
      [[ ${1} == \<CTRL-C\> ]] && echo -e "Press <CTRL-C> again to exit."
      (( _Debug_ )) && set +x
      CLEANUP_SCRIPT					# Do cleanup (as we set the EXIT trap to _Display_)
      return ${_Ret_}
    }

  function _Set_Ret_() {				# Executed if <CTRL-C> keypress
    trap - EXIT						# Reset the trap's
    trap - SIGINT
    _Ret_="130"						# Set the "quit" error code
    eval $_Var_=\(\"\<CTRL-C\>\"\)			# Show the answer as '<CTRL-C>'
    echo						# An extra <NL>
    CLEANUP_SCRIPT					# Do cleanup (as we removed the EXIT trap)
    _Display_ '<CTRL-C>'
  }

    # All set. So do it.
    trap "_Display_ ${_Ret_}" EXIT			# Execute the function Display upon exit
    trap "_Set_Ret_" SIGINT				# Trap the <CTRL-C>
    (( _Debug_ )) && set -x				# bash debugging reqested
    (( ! _Exit_ )) && USAGE_RETURN			# Normally we return on all errors
    "$@"						# Execute the command
    export _Ret_=$?
    ${_Cmds_}						# Execute any additional commands
    set +x
    return ${_Ret_}
  )							# End of sub-shell
}

