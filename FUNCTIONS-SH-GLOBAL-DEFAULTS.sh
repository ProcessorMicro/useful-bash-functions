#!/bin/bash
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	/etc/profile.d/FUNCTIONS-SH-GLOBAL-DEFAULTS.sh

SCRIPT_PURPOSE="This script sets global defaults for the GET_ARGS and COLOR functions."
SCRIPT_VERSION="12.04.02 - Sep 10, 2025"

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

## Global Implementation
##________________________________________________________________________________
##
## 1) REQUIRED COMMAND - Load (and export) the common functions into the environment.
##    The following command creates a global implementation of functions.sh.
##      source /usr/local/bin/functions.sh

source /usr/local/bin/functions.sh${_NEW_}     # Load the functions into the environment

##________________________________________________________________________________
##
## 2) REQUIRED COMMAND - Ensure the defaults in this script are loaded as well
##    The following command ensures that the every invocation of bash is properly
##    configured.
##      declare -x BASH_ENV="${BASH_SOURCE[0]}"

declare -x BASH_ENV="${BASH_SOURCE[0]}"

##________________________________________________________________________________
##
## GLOBAL - Global variables that modify the GET_ARGS function defaults
##________________________________________________________________________________
##
## 1) _GET_ARGS_GLOBAL_HELP_DEFAULT_ - Set the default help mode <HM>
##    The variable _GET_ARGS_GLOBAL_HELP_DEFAULT_ sets the default <HM> mode
##      for all scripts that use GET_ARGS.
##    The syntax is:
##
##      declare -x _GET_ARGS_GLOBAL_HELP_DEFAULT_="<HM_DEFAULT>"
##
##    Where <HM_DEFAULT> is:
##      <GEBC> [[-L] GTAB]
##    And the acceptable values for <GBEC> are:
##        e [[-L] GTAB]   # For expanded help
##        b [[-L] GTAB]   # For brief help
##        c [[-L] GTAB]   # for compact help
##    Where:
##        -L Indicates only the leading <TABS> will be expanded to spaces.
##           The default is to expand all tabs.
##      GTAB Is the integer tabstop length: 0 < GTAB < 16
##           The default GTAB is 8.
##    The <HM> default can be overwritten by the GET_ARGS_DIRECTIVE
##    --Default or by using the HELP basic option with an <HM> code.

declare -x _GET_ARGS_GLOBAL_HELP_DEFAULT_="c"	# Default <HM> is compressed mode

##________________________________________________________________________________
##
## 2) _GET_ARGS_PARSED_HELP_DIR_ - Set the parsed files location.
##    When GET_ARGS parses the GET_ARGS_DIRECTIVES in a parent script, it creates a
##    number of files that:
##      a) Recreate the gawk parsed variables needed for the parent script
##         option scan.
##      b) Recreate the bash parsed variables created by the option scan.
##      c) Act as templates for displaying parent script help.
##    These files are stored in ${_GET_ARGS_PARSED_HELP_DIR_}/<PARENT_SCRIPT_NAME>
##    The base pathname, _GET_ARGS_PARSED_HELP_DIR_, defaults to:
##        ~/.config/${FUNCTIONS_SH_NAME}
##      Where FUNCTIONS_SH_NAME is the basename of functions.sh
##    Change this location with:
##
##      declare -x GET_ARGS_PARSED_HELP_DIR_="<NEW_PATH>"
##
##________________________________________________________________________________
##
## 3) _GET_ARGS_DONT_SAVE_ENVIRONMENT_ - Create temporary GET_ARGS parsed files.
##    To have the files, parsed by GET_ARGS for each parent script, always created
##    in a unique temporary directory (that will be deleted when the parent script
##    exits), declare the following:
##
##      declare -x _GET_ARGS_DONT_SAVE_ENVIRONMENT_="1"
##
##    Note: For any parent script, to reverse the option to use temporary files,
##    include the following in that script:
##
##      unset _GET_ARGS_DONT_SAVE_ENVIRONMENT_

##________________________________________________________________________________
##
## 4) _GET_ARGS_GLOBAL_DIRECTIVES_DEFAULTS_ - Set default GET_ARGS_DIRECTIVES
##    Global GET_ARGS_DIRECTIVES are defined with the variable:
##      _GET_ARGS_GLOBAL_DIRECTIVES_DEFAULTS_="GAD1 GAD2 ..."
##    Each GADi is written as "--KEYWORD [ARG]" in the same way as specifying
##      GET_ARGS directives. Except any ARGi that contains spaces must be
##      surrounded by single quotes.
##    The directives are inserted at the beginning of the list of directives
##      (GET_ARGS_DIRECTIVES) used in every GET_ARGS function call.
##    Directives that can only be specified once, if they are used here, cannot be
##      specified again in any parent script.
##    The following lines are examples:
##      export _GET_ARGS_GLOBAL_DIRECTIVES_DEFAULTS_="--Nocolor"     # No colored help
##      export _GET_ARGS_GLOBAL_DIRECTIVES_DEFAULTS_="--Pager more"  # more not less
##    An example of multiple global GET_ARGS_DIRECTIVES setting the help pager,
##      and creating a parent option that is always defined.
##
##  export _GET_ARGS_GLOBAL_DIRECTIVES_DEFAULTS_="--Pager more --Opt_D 'X XXXX' --Des_D 'Option -X is ubiquitous.'"
##
##   Note: Include the following in a parent script to nullify, for that script,
##         the global defaults. It must preceed the call to the GET_ARGS function.
##
##     unset _GET_ARGS_GLOBAL_DIRECTIVES_DEFAULTS_
##________________________________________________________________________________
##
##  5) HelpColors - Set the default help highlight colors
##    The global colors for GET_ARGS are set in the variables:
##      GAsh      # Default SECTION highlight
##      GAoh      # Default OPTION highlight
##      GAth      # Default TITLE highlight
##      GAah      # Default ACTION highlight
##    To change the colors, modify the following lines.
##      declare -x GAsh GAoh GAth GAah
##      COLOR_MAKE -F blue -E 1 GAsh      # Default SECTION highlight - BOLD Blue
##      COLOR_MAKE -F SkyBlue1 GAoh       # Default OPTION highlight
##      GAth="${GAsh}"                    # Default TITLE highlight
##      GAah="${GLD}"                     # Default ACTION highlight
##    To remove a single color set its value to the following ASCII sequence.
##      E.G.  GAsh=X$'\010'

declare -x GAsh GAoh GAth GAah
COLOR_MAKE -F blue -E 1 GAsh      # Default SECTION highlight - BOLD Blue
COLOR_MAKE -F SkyBlue1 GAoh       # Default OPTION highlight
GAth="${GAsh}"                    # Default TITLE highlight
GAah="${GLD}"                     # Default ACTION highlight

