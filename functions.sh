#!/usr/bin/bash
# vim: set nomodified number nowrap foldmethod=indent foldnestmax=2 nofoldenable:

SCRIPT_PURPOSE_FUNCTIONS_SH="This script contains a set of common bash functions for use in other bash scripts."
COMMON_FUNCTIONS_VERSION="14.01.08 - Aug 06, 2026"

# Copyright (C) 2013-2026 by Mike Armstrong
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

## INTRODUCTION - functions.sh
##
## The following are common functions and variables that can be
## invoked/used within user bash scripts.
##________________________________________________________________________________
##
## GLOBAL IMPLEMENTATION
##   It is enabled globally as follows.
##
##   "source" it when a bash terminal emulator is opened.
##   To do this create a file in /etc/profile.d/ with the contents:
##
##     #!/bin/bash
##     source /usr/local/bin/functions.sh
##     declare -x BASH_ENV="${BASH_SOURCE[0]}"
##
##   This will load the functions and export them into the bash environment.
##
## FUNCTIONS-SH-GLOBAL-DEFAULTS.sh
##   This script, installed in the directory /etc/profile.d, implements this.
##   It also defines some global defaults used by the GET_ARGS function.
##
##   For more information on these variables execute:
##
##     FIND-FUNCTIONS -c -l -s /etc/profile.d/FUNCTIONS-SH-GLOBAL-DEFAULTS.sh
##
## PARENT SCRIPT IMPLEMENTATION
##   In each parent script that will use the GET_ARGS function, the
##     parent script must contain two variables:
##        SCRIPT_PURPOSE   and   SCRIPT_VERSION
##     They should be defined BEFORE the GET_ARGS function is called as their
##     values are included in the generated HELP.
##
##   Also, each parent script must either initialize functions.sh or source it.
##
##   The following is a sample of the code required in every parent script.
##   Note: The command MKSCRIPT will create lines somewhat like the following:
##________________________________________________________________________________
##
##        #!/bin/bash
##        #
##        SCRIPT_PURPOSE="Text describing the basic purpose of this script..."
##        SCRIPT_VERSION="03.01.14 - Jan 01, 2025"    # It is displayed as-is
##        #
##        # The following is a failsafe way to implement functions.sh.
##        #
##        if [[ -n ${_functions_sh_loaded_} ]] ; then
##          FUNCTIONS_SH_INIT             # Initialize the preloaded functions
##        else                            # Otherwise locate and load functions.sh
##          COMMON_FUNCTIONS="$(type -p functions.sh)"
##          if [[ -x ${COMMON_FUNCTIONS} ]] ; then
##            source "${COMMON_FUNCTIONS}"
##          else
##            echo -e "Cannot locate \"${COMMON_FUNCTIONS:-functions.sh}\"." 1>&2
##            exit
##          fi
##        fi
##________________________________________________________________________________
##
##   The functions.sh script is self documenting.
##     If you execute it as a command. Vis:
##       functions.sh                # Displays the complete documentation.
##       functions.sh -v             # Displays the purpose and version.
##       functions.sh INTRODUCTION   # Displays this introduction.
##       functions.sh FUNCTIONS      # Displays the functions implemented.
##       functions.sh VARIABLES      # Displays the global variables available.
##       functions.sh <FUNCTIONNAME> # Displays documentation for <FUNCTIONNAME>.
##                                   # Note: This uses the script FIND-FUNCTIONS.
##
##   If you make changes to functions.sh or to the accompaning gawk scripts, read
##     the heading "MODIFICATIONS AND TESTING" below in the GET_ARGS documentation
##     on how to ensure your modifications are re-loaded.

FUNCTIONS_SH_PATH="${BASH_SOURCE[0]}"			# The pathname of this common functions script
FUNCTIONS_SH_NAME="${FUNCTIONS_SH_PATH##*/}"		# The name of this common functions script
FUNCTIONS_SH_DIR="${FUNCTIONS_SH_PATH%/*}"		# The directory containing this common functions script
FUNCTIONS_SH_SHARED_DIR="${FUNCTIONS_SH_DIR}"		# Shared data for the user defined scripts "data"
FUNCTIONS_SH_BASENAME="${FUNCTIONS_SH_NAME%%.NEW}"
FUNCTIONS_SH_SUFFIX="${FUNCTIONS_SH_NAME##${FUNCTIONS_SH_BASENAME}}"

function DO_HELP() {
  local _FUNCTIONS_SH_="${FUNCTIONS_SH_DIR}/${FUNCTIONS_SH_NAME}"
  if [[ $1 == -v ]] ; then
    echo -e "Purpose: ${SCRIPT_PURPOSE_FUNCTIONS_SH}\nVersion: ${COMMON_FUNCTIONS_VERSION}"
  elif (( $# )) ; then
    FIND-FUNCTIONS -l -c -s "${_FUNCTIONS_SH_}" "$@"
  else
    grep --line-number '^##' "${_FUNCTIONS_SH_}" \
      |  sed -e 's/##[ _]\?//' \
      |  column --separator ":" --output-separator " " --table --table-right 1 --table-columns-limit 2 \
      |& less -R -S
  fi
}
# Check to see if it has been executed as a command
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && { DO_HELP $1 ; exit ; }

##________________________________________________________________________________
## FUNCTIONS -
##   The primary functions included are:
##      GET_ARGS:
##        Option/argument parsing with automatically generated help,
##        version display, parent testing options.
##      IS_EXCLUSIVE:
##        Validates option combinations.
##      ASK:
##        Ask a question (with headers and prompts) and verify the response
##        (automatic parent script exit with "q") and optional GUI dialog.
##        Variations: ASK_WITH_MENU (generated from an array of choices).
##      ERROR:
##        Parent script error display and control.
##
##   EXAMPLE
##     The following is a simple example of GET_ARGS usage in a parent script.
##       It requires (and enforces) one non-option argument (FILENAME).
##       And one option (-p or --pattern) can be used to define/use a PATTERN.
##
##     GET_ARGS --Args_Req 1@FILENAME \
##       --Opt_D "p: pattern:@PATTERN" --Des_D "PATTERN is ..." \
##       -- "$@"
##________________________________________________________________________________
##
## LIST OF FUNCTIONS.  A full description precedes each function definition.
##     Note: For any function that is invoked in the parent script, any options
##           (e.g. -V, -N, ...) defined by the function must precede all function
##           arguments.
##     Also: If a function option requires a value (e.g. -V VARNAME) the value
##           must be separated from the option by whitespace.
##   ASK                Ask a question or, for ASK_WITH_MENU, present a menu of
##                      choices. Verifies the response is one of the choices.
##   ASK_GUI            Similar to ASK but using a GUI interface for the
##                      response. All the options to ASK can be specified.
##   ASK_WITH_MENU      Creates a menu { 1).., 2)... } from an array, displays
##                      it and asks for a choice from the menu.
##   ASK_WITH_MENU_GUI  Similar to ASK_WITH_MENU but using a GUI interface
##                      for the response.
##   CLEANUP_ALWAYS     Force CLEANUP even if testing.
##   CLEANUP_SCRIPT     Standard cleanup function.
##   COLOR_MAKE         Create or modify a color variable
##   COLORS_DISPLAY     Display the default color variables available.
##   COLORS_SET         Set the color variables $GRN (green), $RED (red),
##                      $PUR (purple) etc. Used with 'echo -e "${RED}...${DEF}...'.
##   ENVIRONMENT_DISPLAY Displays NAMES of functions or values of variables
##                      defined in the script environment.
##   ERROR              Simple error reporting with a forced "exit"
##   ERROR_GUI          Similar to ERROR but using a GUI interface for the
##                      response. All the options to ERROR can be specified.
##   ERROR_PREFIX       Alias for ERROR_SET_PREFIX.
##   ERROR_SCRIPT       This script will execute if an ERR signal is raised
##                      and trapped via ERROR_TRAP_SET.
##   ERROR_SET_PREFIX   Sets the args as a prefix (in red characters) to
##                      precede any USAGE or ERROR message.
##   ERROR_TRAP_RESET   Reset the ERR trap.
##   ERROR_TRAP_SET     Trap and execute ERROR_SCRIPT on any script error.
##   EXPORT_CLEANUP     Set/Reset everything needed for any child scripts to
##                      execute CLEANUP_SCRIPT in the parent.
##   FIND_NFS_PATH_FROM_FSTAB
##                      Display all the NFS entries or match one NFS entry
##                      in /etc/fstab.
##   FUNCTIONS_SH_INIT Initialise global variables needed by functions.sh
##   GET_ALL_PC_NAMES   Displays a space-separated lowercase list of valid
##                      PC names Requires variable LOCAL_PCS to be set.
##   GET_ARGS           A function that defines acceptable parent script
##                      arguments and parses them when the parent is invoked.
##   GET_ARGS_DEFAULT   Call this to use the GET_ARGS function in this script.
##   GET_ARGS_HIGHLIGHT A debugging function that highlights the parent script.
##   GET_ARGS_LIST_OPTIONS
##                      Displays parent script options and alternative spellings.
##   GET_IP_FROM_DOMAIN Convert a domain name into an IP address.
##   GET_LOCAL_DOMAIN_NAME
##                      Displays the (hard coded) name of this PC's DOMAIN.
##   GET_LOCAL_PC_NAME  Displays (displays) the name of THIS PC. Requires
##                      variable LOCAL_PCS to be set.
##   GET_MATCHING_NFS_DOMAIN_IN_FSTAB
##                      Display the DNS domain of an NFS entry in /etc/fstab
##                      that matches $1.
##   GET_OTHER_PC_NAME  Displays (displays) a PC name from the list of PC names
##                      in this domain excluding the name of this PC.
##   GET_ALL_UNIQUE_NFS_DOMAINS_IN_FSTAB
##                      Display all the NFS domain names found in /etc/fstab.
##   IS_EXCLUSIVE       Returns successfully to the calling script when a valid
##                      combination of options is detected.
##   IS_HEX             Returns TRUE if Arg #1 is formatted as HEXADECIMAL.
##   IS_IP              Returns TRUE if $1 is a valid IPV4 or IPV6 address.
##   IS_IP_ALIVE        Analyzes all IP_ARG... (domain names or IP addresses)
##                      to determine if any is active.
##   IS_LOGICAL_VOLUME  Returns TRUE if $1 is a logical volume, otherwise FALSE.
##   IS_MAC             Returns TRUE if $1 is a MAC address.
##   IS_NUMERIC         Returns TRUE (0) if $1 is numeric; otherwise FALSE.
##   IS_ROOT            Returns TRUE (0) if the UID is "root"; otherwise FALSE.
##   IS_TESTING         Returns TRUE if TESTing is enabled.
##   IS_UUID            Returns TRUE is Arg #1 is formatted as a UUID.
##   MOUNT_IT           Mount the filesystem $1 onto directory $2 and remember
##                      where it was mounted.
##   OBSOLETE           Alternate name for USAGE_OBSOLETE.
##   PAD_IT             Displays a string padded to a specific length with PAD.
##   PAUSE              Waits for a carriage return (<ENTER>) or 'q' to quit.
##   PROGRESS           Displays a "." every $1 times it is called.
##   REVERSE_ARGS       Display the arguments in reverse order.
##   ROOT_ONLY          Ensures only 'root' can run this script.
##   SORT_ARGS          Sort the arguments and display the results. No argument
##                      can have whitespace.
##   SORT_ARGS_WS       Sort the arguments and display the results. Arguments
##                      can have whitespace.
##   TEST_DISPLAY       Display the TESTing variable values.
##   TEST_RESET         Reset the TESTing variables to default and stop TESTing.
##   TEST_SET           Turn on TESTing.
##   TMP_DIR_CREATE     Like TMP_FILE_CREATE but creates a temporary directory
##                      rather than a file.
##   TMP_DIR_DELETE     Like TMP_FILE_DELETE but deletes temporary directories
##                      instead of files.
##   TMP_DIR_PERMANENT  Prevent CLEANUP from deleting a TMP directory.
##   TMP_FILE_CREATE    Create a temporary work file/directory that can be
##                      referenced by TMP_NAME_VAR.
##   TMP_FILE_DELETE    Delete TEMP files or dirs created by TMP_FILE_CREATE.
##   TMP_FILE_PERMANENT Prevent CLEANUP from deleting a TMP file.
##   TRIM               Displays ${1} with surrounding whitespace removed.
##                      Whitespace within ARG1 will not be changed.
##   UMOUNT_IT          Un-mount the filesystems/devices ($*) mounted by
##                      MOUNT_IT.
##   USAGE              External stub for normal error processing. Calls
##                      internal function _USAGE_DEFAULT_ passing all arguments.
##   USAGE_EXIT         Alias for USAGE_SET_EXIT.
##   USAGE_FORCE_OBSOLETE
##                      Call USAGE_OBSOLETE with the prepended text
##                      "Exit forced. "
##   USAGE_FORCE_RETURN Issue a USAGE message and return even if "exit" is set.
##   USAGE_OBSOLETE     Issue an "obsolete" message and "exit".
##   USAGE_RETURN       Alias for USAGE_SET_RETURN.
##   USAGE_SET          Function to invoke, with an option, the functions
##                      USAGE_FORCE_RETURN, USAGE_SET_EXIT, ERROR_SET_PREFIX
##                      and USAGE_SET_RETURN.
##   USAGE_SET_EXIT     In the script from this point forward, makes the USAGE
##                      and ERROR functions exit with an error code of 1 rather
##                      than return to the script.
##   USAGE_SET_RETURN   In the script from this point forward, makes the USAGE
##                      and ERROR functions return with an error code of 2
##                      rather than exit the script.
##   WARNING            Simple error reporting with no "Usage" message.
##   WARNING_SET_PREFIX Sets the args as a prefix (in purple characters) to
##                      precede any WARNING or ERROR message.
##   ZERO_FILL          Display a zero-filled NUMBER of size NUM_DIGITS.

##________________________________________________________________________________
##
## VARIABLES - A list of global veriables defined/set:
##   ANSWER             Variable is set to the answer from ASK and
##                      ASK_WITH_MENU. Is a number, character, word, 'y' or 'n'.
##   ANSWER_IDX         Array of numbers set to the index into the menu item
##                      array passed to ASK_WITH_MENU matching the choices made.
##   ANSWER_VAL         Array of values set to the value passed to ASK_WITH_MENU
##                      that matches the menu choice made.
##   Args[*]            Array containing the non-option arguments in a parent
##                      script. Set by GET_ARGS when parsing script options.
##   ASK_ANSWER_IS_ALL  Variable is set by the function ASK if the response is
##                      for all items.
##   ASK_WITH_MENU_NUMBER
##                      For multiple menus, the sub-menu number currently
##                      displayed.
##   BLK WHI RED ...    GLD BLU GRN YEL ORG PNK LIM UL BOLD DEF
##                      Default color variables used in the echo and yad commands
##                          echo -e "${PUR}purple chars${DEF}black chars."
##   CMD                The basename of the parent script.
##   CMD_DIR            The containing directory of the parent script.
##   CMD_LINE           The command line (as typed and re-quoted) that invoked
##                      the script.
##   ERROR_PREFIX_SPACES
##                      A number of spaces equal to the ERROR prefix length.
##                      Use it to pretty up multi-line error messages.
##   _ERROR_MESSAGE_    If an error occurs, contains the error message even
##                      if it is displayed.
##   _functions_sh_loaded_
##                      Set to "1" if functions.sh has been loaded into the
##                      bash environment.
##   FUNCTIONS_SH_PATH  The pathname of functions.sh
##   FUNCTIONS_SH_NAME  The name of this script
##   FUNCTIONS_SH_BASENAME
##                      The name of this script without any .NEW suffix
##   FUNCTIONS_SH_DIR   The directory containing functions.sh
##   FUNCTIONS_SH_SHARED_DIR
##                      The shared data used by functions.sh
##   FUNCTIONS_SH_SUFFIX
##                      The suffix ".NEW" if functions.sh renamed
##   _GET_ARGS_GLOBAL_HELP_DEFAULT_
##                      Contains global defaults for GET_ARGS help.
##                      See "IMPLEMENTATION of functions.sh" above.
##   _GET_ARGS_DONT_SAVE_ENVIRONMENT_
##                      If not null, GET_ARGS will always perform a full scan
##   _GET_ARGS_PARSED_HELP_DIR_
##                      The base directory where parsed help files are stored
##   _LOCAL_DOMAIN_ _LOCAL_PC_ _ALL_PCS_ _OTHER_PCS_
##                      Global, exported variables set by the functions
##                      GET_LOCAL_DOMAIN_NAME, GET_LOCAL_PC_NAME,
##                      GET_OTHER_PC_NAME and GET_ALL_PC_NAMES.
##   LOCAL_PCS          A space-separated list of PCs available to the local
##                      network. Used by GET_ALL_PC_NAMES and GET_OTHER_PC_NAME.
##                      This variable must be set (and exported) in the parent
##                      script environment. Vis: export LOCAL_PCS="pc1 pc2"
##   _MOUNTED_FS_ARRAY_ An array set internally containing the filesystems
##                      mounted by MOUNT_IT. It is unset by default.
##   Opt_x Opt_x_Val    Where 'x' is the 1st option name in OPTLIST. Set by
##                      GET_ARGS when parsing script options.
##   Alt_Opts[-X]       Contains a list of the other options in OPTLIST for
##                      option -X (OPT1 = the first one).
##   Opts_Alt[-X]       Contains a cross reference to the first option in
##                      OPTLIST for option -X.
##   Opts_All           A space separated list of every option (i.e. -x)
##                      detected when invoking the parent script.
##   _PROGRESS_COUNTER_ _PROGRESS_INTERVAL_ _PROGRESS_MAX_
##                      Can be set by the calling script. See the PROGRESS
##                      function below.
##   SCRIPT_PURPOSE     This variable should be set by the script BEFORE
##                      functions.sh is 'sourced'. It is included in the USAGE
##                      display.
##   SCRIPT_VERSION     This variable should be set by the script BEFORE
##                      functions.sh is 'sourced'. It is included in the USAGE
##                      display.
##   TEST_xxx           A set of variables used to invoke script testing. See
##                      the function 'TEST_DISPLAY'.
##   _TESTING_          Indicates if TESTing is set or not.
##   _TMP_NAMES_ARRAY   _ Variable set internally. An associative array of
##                      the TMP files created by TMP_FILE_CREATE.
##________________________________________________________________________________
##
## The function FUNCTIONS_SH_INIT (at the end) executes commands and functions
##   needed by this script to set defaults needed by functions.sh
##
##  #############################################################################
##  # Note: For the GET..._PC_NAME functions to work, you must define all your  #
##  #       local PC names, In your terminal command line environment execute:  #
##  #            export LOCAL_PCS="pc1 pc2 ..."                                 #
##  #############################################################################
##
declare -gx LOCAL_PCS=${LOCAL_PCS:=LOCAL_PC_NAMES_UNDEFINED} # List of local PCs to be accessed

[[ -n $BASH_VERSION ]] && shopt -s extglob		# Turn on extended pattern expansion
_ERROR_MESSAGE_="" _LOCAL_USAGE_="" _USAGE_OPTIONS_=""

##________________________________________________________________________________
##
## ASK - Used to display instructions or, for ASK_WITH_MENU, present a menu of
##     choices and wait for a response. ASK will verify that the response is one
##     of the acceptable choices/answers (or QUITCODE) and assign it to the
##     variable VARIABLE.
##   Usage: ASK [ASKCODE] [ASKOPTIONS] [INSTRUCTIONS]
##   Where:
##     ASKCODE
##       Is a code that indicates what type of response is expected. It also
##       determines the allowed characters in CHIOCES. Valid ASKCODE values are:
##         -yn | --yn | --yesno
##            The response must be 'y' 'n' or 'q'. This is the   default if
##              ASKCODE is missing.
##            Note: -C CHOICES and -M are ignored.
##         -n[=DIGITS] | --number[=DIGITS] | -d[=DIGITS] | --digit[=DIGITS]
##            The numeric response(s) must be positive integers greater than -1
##              and either within a default CHOICE RANGE or, with -C, from one
##              of the numeric CHOICES.
##            DIGITS specifies the number of digits in then default CHOICE RANGE.
##              The default CHOICE RANGE is changed by DIGITS as follows:
##                For -n=1 the RANGE is 0-9, for -n=2 the RANGE is 0-99 etc.
##              DIGITS defaults to 2.
##         -an | --an | --alphanumeric
##            The alphanumeric response(s) must be an alphabetic character or a
##              digit and either within a default CHOICE RANGE or, with -C,
##              from one of the numeric CHOICES.
##            The default CHOICE RANGE is: 0-9, A-Z and a-z.
##         -a | --alpha
##            The alphabetic response(s) must be an alphabetic character and
##              and either within a default CHOICE RANGE or, with -C, from one
##              of the numeric CHOICES. The default CHOICE RANGE is A-Z and a-z.
##         -l | --lower
##            The alphabetic response(s) must be a lowercase character and
##              either within a default CHOICE RANGE or, with -C, from one
##              of the numeric CHOICES. The default CHOICE RANGE is a-z.
##         -u | --upper
##            The alphabetic response(s) must be a uppercase character and
##              either within a default CHOICE RANGE or, with -C, from one
##              of the numeric CHOICES. The default CHOICE RANGE is A-Z.
##         -ca | --characterarray
##         -c | --character
##            The response can be any single character. If -C CHOICES is used
##              there is no separator between each character.
##            In either CHOICES or the response, the first 32 characters of the
##              ASCII character set may produce indeterminant results.
##            CHOICES can contain single quotes and/or double quotes if properly
##              escaped. CHOICES can contain any character except <NL>. if any
##              special (bash) characters are is CHOICES surround the choices
##              with single quotes.
##            Backslashes within CHOICES must be doubled ('abc\\' not 'abc\')..
##            Any character can occur more than once in CHOICES. It indicates
##              that, if option -M is used, that character may appear in the
##              response as many times as it appears in CHOICES.
##            The response is stored in the scalar "VARIABLE" even with -M.
##              You can use -ca to force each response character to be stored
##              in the "VARIABLE" as an array.
##            There is no default set of CHOICES.
##         -w | --word
##            The response(s) is/are any multi-character word from the set
##              A-Z, a-z, _ and 0-9. No word can begin with a digit. This is
##              the definition of a bash "name".
##            Validation is done if -C CHOICES is used in which case the
##              response must match one of the CHOICES.
##            There is no default set of CHOICES.
##         -e | --everything
##            All printable characters are acceptable in the response.
##            Validation is done only if -C CHOICES is used in which case
##              no CHOICE can contain whitespace.
##            There is no default set of CHOICES.
##            If CHOICES does not contain a QUITCODE then QUITCODE is used
##              to quit. Otherwise <CTRL-C> is required.
##            Note: If CHOICES contains backslash it must be escaped (\\).
##            Note: The following characters in the RESPONSE must be escaped:
##                      Backslash (\\) and Backquote (\`)
##     ASKOPTIONS
##       Note: For UNIX compatability, all multi-character options can be
##             preceeded by either one or two dashes (e.g. -CC or --CC).
##       -C CHOICESLIST
##          A space separated list of the choices that can be made
##          (e.g. "a e x") when QUESTION is displayed. The CHOICESLIST must
##          follow the acceptable set of responses by each ASKCODE below.
##          If ASKCODE is:
##            -a, -l, -u,  each CHOICE is an alphabetic RANGE.
##            -an          each CHOICE is an alphanumeric RANGE.
##            -n or -d     each CHOICE is an positive integer RANGE.
##            -c           each CHOICE is any character except <NL>.
##            -w           each CHOICE is a word.
##            -e           Each CHOICE is any characters except whitespace.
##          CHOICES within CHOICESLIST can be in any order and must be unique
##            except for ASKCODES -c, -w and -e. For these three ASKCODES a
##            CHOICELIST can contain multiple matching CHOICES. The RESPONSE
##            may then contain up to the same number of a matching CHOICE.
##          RANGES within CHOICESLIST can be in any order.
##          If -C CHOICESLIST is not specified, an acceptable response is any
##            character(s) or word(s) acceptable to the ASKCODE.
##          For a CHOICESLIST consisting of RANGES, the separator can be a space
##            or comma.
##          For an ASKCODE of -c, CHOICESLIST is a set of acceptable characters
##            without any separator. Thus a space can be an acceptable choice.
##          Option -C cannot be used with ASKCODE -yn.
##       -CA
##          Display CHOICES as-is. For ASKCODES that accept ranges, the display
##          of CHOICES is not normalized into ranges.
##       -CC[=NUMBER]
##          CHOICES compressed. Wrap a longlist of CHOICES but don't line up the
##          choices into columns. See -CW below.
##          Note: Compressed CHOICES wrapping may be somewhat imperfect as the
##            length of each CHOICE may vary.
##       -CD DISPLAY
##          In the PROMPT, replace the generated CHOICESDISPLAY with DISPLAY.
##          To not display CHOICESDISPLAY, set DISPLAY to the null string ("").
##       -CW[=NUMBER]
##          Wrap the CHOICESDISPLAY to a length that is a fraction of the
##            terminal line width ($COLUMNS). The CHOICES are displayed in
##            columns.
##          NUMBER is an integer (1 >= NUMBER <= 99) that is a percentage of the
##            terminal COLUMNS value. The default NUMBER is 50 (50%).
##          Wrapping occurs at the first space after WRAPLEN characters where:
##            WRAPLEN=$(( (COLUMNS * NUMBER + 50) / 100)))
##          CHOICESiDISPLAY is not wrapped for ASKCODES of -y or -c.
##       -D DEFAULTANSWER:
##          DEFAULTANSWER is used as the answer if a null response is returned.
##            DEFAULTANSWER must match one of the acceptable CHOICES (if CHOICES
##            is defined) or the generated QUITCODE.
##          If the generated QUITCODE is the keystroke <CTRL-C>, DEFAULTANSWER
##            can be set to the characters "<CTRL-C>".
##       -ER An empty response is allowed. Oherwise an empty response causes
##          an error message to be displayed and the QUESTION is redisplayed.
##       -F FONT
##          Only if -G is used. Display the dialog box using font FONT. Valid
##          FONTS can be listed by the command: yad --font
##          If the font displayed contains a numeric size (i.e." 10") then -FS
##          (below) is not needed. The default FONT is "Noto Sans Mono Regular".
##       -FS FONTSIZE
##          Only if -G is used. The FONTSIZE value is relative to the font size
##          specified in FONT (above). FONTSIZE can be one of:
##            xx-small, x-small, small, medium, large, x-large, xx-large,
##            smaller, larger
##          Or FONTSIZE can be a positive number that specifies the absolute
##            size in points. This overrides the size specified in FONT.
##          The default is "medium".
##       -FW WEIGHT
##          Only if -G is used. Specify the weight of the FONT. WEIGHT is
##          relative to the weight specified in FONT. WEIGHT can be one of:
##            ultralight, light, normal, bold, ultrabold, heavy
##          Or an absolute numeric weight. This overrides the weight specified
##          in FONT. The default is "normal".
##       -FY FONTSTYLE
##          Only if -G is used, FONTSTYLE can be one of: normal, italic, oblique
##          The default is "normal".
##       -G Display the question and answer with a GUI dialog box (using yad).
##          The font in the box is changed to fixed length (mono) to preserve
##          formatting of the header and question. ASK_GUI is equivalent to -G.
##       -H HEADER
##          Display HEADER prior to the INSTRUCTIONS section in the PROMPT.
##            HEADER can have 'echo -e ...' escape sequences. A newline (\n)
##            is automatically added to the end of HEADER.
##          For a GUI dialog, HEADER is split into two parts TITLE and SUBTITLE.
##            Everything before the first newline is the TITLE and is displayed
##            in the title bar of the dialog box. The remaining lines (if any)
##            are displayed as a SUBHEADER in the text portion of the dialog box.
##          Note: A GUI dialog TITLE cannot contain any escape sequences.
##       -H1 HELP1
##          Replace the HELP1 section in the PROMPT with HELP1.
##       -H2 HELP2
##          Replace the HELP2 section in the PROMPT with HELP2. If HELP2 is
##          null (-H2 "") only ": " is displayed.
##       -L LEGEND
##          Add "Legend: LEGEND\n" to the PROMPT after the INSTRUCTIONS section.
##            LEGEND should explain the purpose of the CHOICES.
##          A newline (\n) is automatically added to the end as shown.
##       -M[=MULT] -C CHOICES
##          Accept multiple answers from the list of CHOICES. Option -C CHOICES
##            is required. A response of MULT can be entered to select all the
##            choices. MULT defaults to "*". If MULT is empty ("") then there
##            is no shortcut that selects all the choices.
##          The responses are stored in an array "VARIABLE" unless the ASKCODE
##            is -c in which case the responses are stored as a scalar.
##          The variable ASK_ANSWER_IS_ALL is set to "1" if MULT is entered as
##            the response or to 2 if MULTMULT is entered. Otherwise it is unset.
##          Option -M cannot be used with ASKCODE -yn.
##       -MD[=NOHELP1]
##          Minimal display. Display only the INSTRUCTIONS and HELP1 sections
##            in the PROMPT omitting the HEADER, LEGEND, and CHOICES sections.
##            This is a shortcut to omit -H and -L prompts and to specify:
##              -CD "", -H1 "" and -H2 ""
##          This allows you to use -H1 and INSTRUCTIONS to design your own
##            PROMPT.
##          If NOHELP1 is any non-empty value (e.g. -MD=x) then only the
##            INSTRUCTIONS (if any) and the default prompt (": ") is displayed.
##          If -H1 is not used, the HELP1 section in the PROMPT is changed to
##            the following minimal prompt:
##                 For ASK:           "Enter your response: "
##              or For ASK_WITH_MENU: "Select menu item: "
##          See PROMPT below to for an explanation of the PROMPT sections.
##       -P The response is a passphrase. Hide (don't echo) what is typed.
##       -Q QUITCODECHARS Change the QUITCODE to QUITCODECHARS. QUITCODECHARS
##            is any number of characters but cannot contain whitespace unless
##            the ASKCODE is -e wthout -C CHOICES. The default QUITCODECHAR is
##            "q". Setting QUITCODECHARS to "" forces the use of <CTRL-C> to
##            exit the script.
##       -R Return rather than exit from a QUITCODE response.
##       -U FILEDESC
##          Use file descriptor FILEDESC to read the response to the question.
##          FILEDESC is a single digit from 3 to 9. The default FILEDESC is 9.
##       -V VARIABLE
##          Is the name of a variable that contains the result. The default
##            VARIABLE name is 'ANSWER'.
##          VARIABLE may be referenced as ${VARIABLE} or ${VARIABLE[x]} where
##            x = 0 to the number of VARIABLE elements minus one.
##          For option -M, VARIABLE_IDX[x] and VARIABLE_VAL[x] is also created.
##          If the expected result is numeric a numeric comparison with CHOICES
##            is made. However leading zeros are NOT removed in the result.
##          Note: The suffix "_VAL" is created by the ASK functions while the
##            GET_ARGS functions use a suffix of _Val. This somewhat confusing
##            and seemingly inappropriate difference was purposely done to make
##            it extremly unlikely both functions would generate the same
##            variable name.
##       -- Indicates the end of options. The remaining arguments comprise
##          the QUESTION. This is needed only if QUESTION begins with a "-".
##     RANGELISTS
##       For the ASKCODES below, both CHOICESLIST and, if -M is used, the RESPONSE
##         may be a RANGELIST containing one or more RANGES. A RANGE is either a
##         single character 'm' or a range with the format 'm-n', 'm to n' or
##         'm thru n' (m <= n).
##           ASKCODE       VALID RANGE
##             -n or -d  m and n must be positive integers.
##             -a        m and n must be an alphabetic character.
##             -l        m and n must be a lowercase character.
##             -u        m and n must be an uppercase character.
##       For any other ASKCODE a RANGE cannot be used.
##       RANGES, for the above ASKCODES, within a set of CHOICES or RESPONSES
##         can be in any order but each RANGE must be unique and not over-lapping.
##       RANGES in a RANGELIST may be separated by a space " " or a comma ",".
##       Examples:  ASK -n -C '3-5 8 to 14 1' ...
##                  ASK -u -C "G A-E K T thru X" ...
##     INSTRUCTIONS
##       After parsing the OPTIONS, the remaining arguments, if any, comprise
##         the INSTRUCTIONS and are displayed in the PROMPT. It may specify a
##         question and/or gives directions; It can contain escape sequences
##         recognized by 'echo -e ...' or pango markup.
##       If pango markup is present in INSTRUCTIONS, the option -G is assumed.
##       For ASK_WITH_MENU (see below), the menu is the INSTRUCTIONS. A newline
##         is automatically added to the end of INSTRUCTIONS.
##     PROMPT
##       The ASK "PROMPT", based upon OPTIONS used, is constructed as follows:
##           HEADER
##           INSTRUCTIONS
##           LEGEND
##           HELP1
##           CHOICESDISPLAY
##           HELP2: <RESPONSE>
##       It is displayed on FILEDESC or, for GUI, in a dialog window.
##       The following options create or modify the PROMPT:
##         -C -CA -CC -CD -CW -F -FS -FW -FY -G -H -H1 -H2 -L -M -MD -P -Q -S
##       Use spaces, tabs (\t) and newlines (\n) to control the output of:
##         HEADER, INSTRUCTIONS, LEGEND, HELP1, CHOICESDISPLAY and HELP2.
##       Note: For ASKCODES that use RANGES, the CHOICESDISPLAY is sorted
##             and normalized into RANGES (unless option -CA is used).
##       HELP1 and HELP2
##         The HELP1 section preceeds the CHOICES section and has text
##         appropriate to the AKCODE (e.g. "Select one..."). The HELP2 section
##         follows CHOICES and contains text explaining additional responses
##         other than a CHOICE. This includes:
##           Switching multiple menus.
##           The response to select all CHOICES.
##           How to quit.
##         You can design your own PROMPT by including the ASK arguments:
##           -MD -H1 "..." INSTRUCTIONS
##         Or, for ASK_WITH_MENU:
##           -MD -H1 "..." -MI MENUINSTRUCTIONS
##         The HELP2 section is always followed by ": ".
##     RESPONSE
##       The (non GUI) RESPONSE is read from file descriptor 9 or, if -U is
##         used, from FILEDESC.
##       For all ASKCODES except -c and -e, Nultiple responses can be separated
##         with a space " " or a comma ",".
##       If option -M is used with ASKCODES -a, -u, -l -an or -n, the response
##         is a RANGELIST and is treated differently. If any RANGE format is "m"
##         it is processed as one of the CHOICES. If any RANGE format is "m-n"
##         then any value within the RANGE that matches one of the acceptable
##         CHOICES is included in the response. All others are ignored.
##         An empty resultant response is not accepted unless -ER is used.
##       For example:
##                     Command: ASK -n -C '11-16 2-6' -M
##          Normalized CHOICES: 2 3 4 5 6 11 12 13 14 15 16
##              Typed response: 3 1 14-20 5-7
##                      Result: ERROR: "1" is not a valid choice.
##              Typed response: 3 14-20 5-7
##                      Result: echo ${ANSWER[*]} --> 3 5 6 14 15 16
##     QUITCODE
##       Responding with QUITCODE causes an immediate exit from the calling
##         script unless USAGE_RETURN (-R) has been invoked.
##       The QUITCODE is generated by ASK. It is the first unique pattern of one
##         to three repetitions of the QUITCODECHARS not found in CHOICES.
##       If no unique QUITCODE can be generated then QUITCODE is set to the
##         keystroke <CTRL-C>.
##       The option -Q changes the default QUITCODECHARs.
##     SPECIAL CHARACTERS
##       Special characters may not produce expected results as follows:
##         Whitespace:
##           For ASKTYPE -c, whitespace in both CHOICES and the RESPONSE (other
##             than spaces or tabs), must be entered with a verbatim insert.
##             E.G. Ctrl-V Ctrl-M inserts a carriage return.
##             ALso whitespace RESPONSES may be stored as dollar quoted. E.G.
##             A vertical tab is stored as the characters $'\v'
##         Bash expansion characters " ` $ and \
##           Combinations of these characters may not produce expected results.
##     RETURN CODE
##       The return code is as follows:
##         0 (TRUE)  for all valid responses and for 'y' to a -yn choice.
##         1 (FALSE) for a 'n' response to a -yn choice.
##         2 (FALSE) For all ASK or ASK_WITH_MENU errors.
##         3 (FALSE) for a QUITCODE response.
##       130 (FALSE) for a <CTRL-C> response.
function ASK() {
  _FUNCTION_="ASK"
  _FUNCTION_SPACES_="     "
  _ASK_WITH_GUI_="0"
  _ASK_WITH_MENU_="0"
  _ASK_DOIT_ "$@"
}
_ASK_WITH_GUI_="0"					# Default

##________________________________________________________________________________
##
## ASK_GUI - Equivalent to 'ASK ... -G'. Uses a GUI interface for the response.
##   All the options of ASK can be specified. The <OK> button simulates a
##   default response that returns a null answer unless the -D option is used.
##   The <Cancel> button is equivalent to QUITCODE (q, qq, ...).
function ASK_GUI() {
  local _ASK_WITH_GUI_
  _FUNCTION_="ASK_WITH_GUI"
  _FUNCTION_SPACES_="              "
  _ASK_WITH_GUI_="1"
  _ASK_WITH_MENU_="0"
  _ASK_DOIT_ "$@"
}


function _ASK_DOIT_() {
  local _PROMPT_HEADER_ _PROMPT_INSTRUCTIONS_ _PROMPT_LEGEND_ _PROMPT_MORE_ _PROMPT_TYPE_ _PROMPT_PLURAL_
  local _PROMPT_MM_ _BUTTONS_ _THE_RESULT_ _NL_ _PROMPT_INDENT_="\n    " _PROMPT_COMPRESSED_
  local _PROMPT_SHORTCUT_="*" _PROMPT_SHORTCUT_MM_ _PROMPT_ALL_=${_PROMPT_INDENT_} _PROMPT_QUIT_ _PROMPT_MINIMAL_
  local _CHOICES_ORIG_ _CHOICES_COMPARE_ _CHOICES_DISPLAY_ _DISPLAY_CHOICES_
  local _IS_DISPLAY_CHOICES_ _IS_CHOICES_ _IS_MULTI_CHOICES_ _NINES_
  local _ANSWER_ORIG_ _DEFAULT_ANSWER_ _DEFAULT_ANSWER_DISPLAY_ _IS_DEFAULT_ANSWER_
  local _HELP1_ _IS_HELP1_ _HELP2_ _IS_HELP2_ _PROMPT_SUPPRESS_HELP1_
  local _AS_IS_ _IS_ERROR_ _IS_ARRAY_ _IS_NUMBER_="1" _WRAP_CHOICES_ _WRAP_LENGTH_="50"
  local _CHOICES_DISPLAY_MAX_=$(( COLUMNS * _WRAP_LENGTH_ / 100 ))
  local _ACCEPTABLE_1_ _DIGITS_ _EMPTY_RESPONSE_="0" _PASSWORD_=""
  local _ASK_CODE_ _ASK_ERROR_ _ASK_RETURN_ _ASK_TYPE_
  local _FONT_SIZES_=" xx-small x-small small medium large x-large xx-large smaller larger "
  local _FONT_STYLES_=" normal italic oblique "
  local _FONT_WEIGHTS_=" ultralight light normal bold ultrabold heavy "
  local _FONT_="Noto Sans Mono Regular" _FONT_SIZE_="14pt" _FONT_STYLE_="normal" _FONT_WEIGHT_="normal"
  local _MAX_SINGLE_COLUMN_="20" _SINGLE_COLUMN_="0" _MENU_COLUMNS_="0"
  local _QUIT_CODE_="q" _PTS_ _FILE_DESC_="9" _OLD_ASK_WITH_GUI_
  local _DLR1_ _ANSWER_VARIABLE_="ANSWER"
  _LOCAL_USAGE_="1"					# Ensure that the USAGE function in functions.sh is used
  while true ; do					# Parse the OPTIONS
    [[ $1 =~ ^--. ]] && _DLR1_="${1:1}" || _DLR1_="$1"	# Convert "--OP" into "-OP" but leave "--" as is
    case "${_DLR1_}" in
      "") (( $# > 0 )) && { shift 1 ; continue ; } || break ;;
      -C)	#|--choices
          (( ${#2} == 0 )) && ERROR "${_FUNCTION_}: For option \"-C CHOICES\", invalid CHOICES \"${2}\"."
          _CHOICES_ORIG_="$2"				# Remember the original CHOICES
          _IS_CHOICES_="1"
          if [[ ${1} =~ = ]] ; then
            [[ ${1} =~ =w ]] && _PROMPT_REPORT_WHITESPACE_="1"
            _PROMPT_SUPPRESS_HELP_="1"
          fi
          shift 1 ;;
      -CA)	#|--as-is				# Choices as-is (without normalization)
          _AS_IS_="1" ;;
      -CD)	#|--choices-display
          _DISPLAY_CHOICES_="$2"
          _IS_DISPLAY_CHOICES_="1"
          shift 1 ;;
      -CC*)	#|--choices-compressed
          _PROMPT_COMPRESSED_="1"
          ;&						# Carry on to the next "case"
      -CW*)	#|--choices-wrapped
          _WRAP_CHOICES_="1"
          [[ ${1} =~ = ]] && _WRAP_LENGTH_="${1#*=}"
          ;;
      -D)	#|--default)
          (( ${#2} == 0 )) && ERROR "${_FUNCTION_}: For option \"-D DEFAULT\", empty or missing DEFAULT \"${2}\"."
          _DEFAULT_ANSWER_="$2"				# The default answer if "OK" or "<Enter>"
          _IS_DEFAULT_ANSWER_="1"
          shift 1 ;;
      -ER)	#|--empty-allowed
          _EMPTY_RESPONSE_="1"				# An empty response is allowed
          ;;
      -F)	#|--font
          _FONT_="$2"
          shift 1 ;;
      -FS)	#|--font-size
          if IS_NUMERIC "$2" ; then
            _FONT_SIZE_="${2}pt"
          else
            [[ ${_FONT_SIZES_} =~ \ $2\  ]] || ERROR "${_FUNCTION_}: For option -FS, invalid or missing font size \"${2}\"."
            _FONT_SIZE_="$2"
          fi
          shift 1 ;;
      -FW)	#|--font-weight
          [[ ${_FONT_WEIGHTS_} =~ \ $2\  ]] || ERROR "${_FUNCTION_}: For option -FW, invalid font weight \"${2}\"."
          _FONT_WEIGHT_="$2"
          shift 1 ;;
      -FY)	#|--font-style
          [[ ${_FONT_STYLES_} =~ \ $2\  ]] || ERROR "${_FUNCTION_}: For option -FY, invalid or missing font style \"${2}\"."
          _FONT_STYLE_="$2"
          shift 1 ;;
      -G)	#|--gui					# The GUI version
          if [[ ! ${_FUNCTION_} =~ _GUI ]] ; then
            _FUNCTION_="${_FUNCTION_}_GUI"
            _FUNCTION_SPACES_="${_FUNCTION_SPACES_}    "
          fi
          _ASK_WITH_GUI_="1" ;;
      -H)	#|--header
          _PROMPT_HEADER_="$2\n"			# The header to display
          shift 1 ;;
      -H1)	#|--help1
          _HELP1_="$2"					# Replace the HELP1 section of PROMPT
          _IS_HELP1_="1"
          shift 1 ;;
      -H2)	#|--help2
          _HELP2_="$2"					# Replace the HELP2 section of PROMPT
          _IS_HELP2_="1"
          shift 1 ;;
      -L)	#|--legend
          _PROMPT_LEGEND_="Legend: $2\n"		# Explains the meaning of the choices
          shift 1 ;;
      -MD*)	#|--minimal-display
          _PROMPT_MINIMAL_="1"
          [[ ${1} =~ = ]] && _PROMPT_SUPPRESS_HELP1_="1"
          ;;
      -M=)
          _PROMPT_SHORTCUT_="${1#*=}"
          ;&
      -M)	#|--multiple-choices
          _IS_MULTI_CHOICES_="1"
          _PROMPT_MORE_=" or more"
          _PROMPT_PLURAL_="s" ;;
      -P) 	#|--password mode
          _PASSWORD_="-s" ;;
      -Q)	#|--quitcode
          _QUIT_CODE_="$2"
          shift 1 ;;
      -R)	#|--return
          _ASK_RETURN_="1" ;;
      -U) [[ $2 =~ ^[3-9]$ ]] || ERROR "${_FUNCTION_}: For option -U, invalid or missing file descriptor \"$2\"."
          _FILE_DESC_="$2"
          shift 1 ;;
      -V)	#|--variable
          _ANSWER_VARIABLE_="$2"			# The variable that will contain the response
          [[ ${_ANSWER_VARIABLE_} == ANSWER ]] && unset ANSWER || local ANSWER=""
          shift 1 ;;
      --) shift 1 ; break ;;				# '--' indicates the end of options
      -*) if [[ -z ${_ASK_CODE_} ]] ; then		# Any other arg starting with '-' or '--' must be an ask code
            _ASK_CODE_="${1}"
          else
            ERROR "${_FUNCTION_}: Invalid option \"$1\"."
          fi ;;
       *) break ;;					# No more options
    esac
    shift 1
  done
  [[ ${_ASK_CODE_} =~ ^--. ]] && _ASK_CODE_="${_ASK_CODE_#-}"
  case "${_ASK_CODE_}" in			# _ASK_CODE_ is the type of question.
    -y*|-yesno)		# |-yn
      _ASK_YN_ || return ${_IS_ERROR_}
      ;;
    -n*|-d*)		# |-numeric|-digit
      _ASK_TYPE_="N"
      if [[ ${_ASK_CODE_} =~ = ]] ; then
        _DIGITS_="${_ASK_CODE_#*=}"
        [[ ${_DIGITS_} =~ ^[0-9]+$ ]] || ERROR "${_FUNCTION_}: The precision for \"${_ASK_CODE_}\" is not numeric."
        _NINES_="$( printf "%*s" ${_DIGITS_} "" | tr ' ' 9 )"
      else
        _DIGITS_="2"					# The default is up to 2 digits
        _NINES_="99"
      fi
      _ACCEPTABLE_1_='^[0-9]{1,'${_DIGITS_}'}$'
      _PROMPT_TYPE_="number"
      _ASK_NORMALIZE_CHOICES_RANGE_ "0-${_NINES_}" "${_ACCEPTABLE_1_}" ${_IS_NUMBER_} || return $?
      ;;
    -an|-alphan*)	# |-alphanumeric
      _ASK_TYPE_="AN"
      _ACCEPTABLE_1_='^[[:alnum:]]*$'
      _PROMPT_TYPE_="alphanumeric character"
      _ASK_NORMALIZE_CHOICES_RANGE_ "0-9 A-Z a-z" "${_ACCEPTABLE_1_}" || return 2
      ;;
    -a*)		# |-alphabetic
      _ASK_TYPE_="A"
      _ACCEPTABLE_1_='^[A-Za-z]$'
      _PROMPT_TYPE_="alphabetic character"
      _ASK_NORMALIZE_CHOICES_RANGE_ "A-Z a-z" "${_ACCEPTABLE_1_}" || return 2
      ;;
    -l*)		# |-lowercase
      _ASK_TYPE_="A"
      _ACCEPTABLE_1_='^[a-z]$'
      _PROMPT_TYPE_="lowercase character"
      _ASK_NORMALIZE_CHOICES_RANGE_ "a-z" "${_ACCEPTABLE_1_}" || return 2
      ;;
    -u*)		# |-uppercase
      _ASK_TYPE_="A"
      _ACCEPTABLE_1_='^[A-Z]$'
      _PROMPT_TYPE_="uppercase character"
      _ASK_NORMALIZE_CHOICES_RANGE_ "A-Z" "${_ACCEPTABLE_1_}" || return 2
      ;;
    -w|-word)
      _ASK_TYPE_="W"
      _ACCEPTABLE_1_='^[[:alpha:]_][[:alnum:]_]*$'
      _PROMPT_TYPE_="word"
      if (( _IS_CHOICES_ )) ; then
        local _COMMA_="" _WORD_
        _CHOICES_COMPARE_=" ${_CHOICES_ORIG_//,/ } "	# Convert "," to " "
        if (( _WRAP_CHOICES_ )) ; then
          _ASK_WRAP_CHOICES_ "${_CHOICES_COMPARE_}"
        else
          for _WORD_ in ${_CHOICES_COMPARE_} ; do
            [[ ${_WORD_} =~ ${_ACCEPTABLE_1_} ]] || { ERROR "${_FUNCTION_}: Invalid word \"${_WORD_}\" in CHOICES." ; return 2 ; }
            _CHOICES_DISPLAY_+="${_COMMA_}${_WORD_}"
            _COMMA_=", "
          done
        fi
      fi
      _ASK_PROMPT_QUIT_ 3
      ;;
    -ca|-ch*ar*)	# |-character-array
      _IS_ARRAY_="1"					# Return the answer as an array
      ;&
    -c*)		# |-character
      _ASK_TYPE_="C"
      _CHOICES_DISPLAY_="${_CHOICES_ORIG_}"
      _ASK_VERIFY_CHARACTERS_ 1				# Augment _CHOICES_DISPLAY_ WRT whitespace
      _CHOICES_COMPARE_="${_CHOICES_ORIG_}"
      _PROMPT_TYPE_="character"
       _ASK_PROMPT_QUIT_ 1
      ;;
    -e*)		# |-everything			# The last one as it is least likely used
      _ASK_TYPE_="E"
      _CHOICES_COMPARE_=" ${_CHOICES_ORIG_//\"/\\\"} "	# Escape double quotes
      if (( _IS_MULTI_CHOICES_ )) ; then
        _PROMPT_TYPE_="choice"
        _CHOICES_DISPLAY_="$( sed -e 's/[[:space:]]+/ /g'<<<"${_CHOICES_COMPARE_}" )"
      else
        _PROMPT_TYPE_="response containing any characters"
        _CHOICES_DISPLAY_="${_CHOICES_COMPARE_# }"
      fi
      if (( _IS_CHOICES_ )) ; then
        _ACCEPTABLE_1_='^[^[:space:]]*$'
        (( _WRAP_CHOICES_ )) && _ASK_WRAP_CHOICES_ "${_CHOICES_DISPLAY_}"
        _ASK_PROMPT_QUIT_ 3
      else
        _ACCEPTABLE_1_='^.*$'
        _ASK_PROMPT_QUIT_ 0
      fi
      ;;
    -*)
      ERROR "${_FUNCTION_}: The ASKCODE \"${_ASK_CODE_}\" is not valid."
      ;;
    *)
      _ASK_YN_ || return ${_IS_ERROR_}		# Assume --yesno
      ;;
    esac
    # ===== Get ready to ask the question. =====
    unset _IS_ERROR_
    (( ${#} )) &&_PROMPT_INSTRUCTIONS_="$*\n"				# The remaining arguments will be displayed
    [[ ${_PROMPT_INSTRUCTIONS_} =~ "<span " ]] && _ASK_WITH_GUI_="1"	# Force GUI if "<span " detected in message
    if (( _ASK_WITH_GUI_ )) ;then
      local _PROMPT_TITLE_
      _PROMPT_TITLE_="${_PROMPT_HEADER_#\\n*}"		# Remove possible leading <NL>
      _PROMPT_HEADER_="${_PROMPT_TITLE_#*\\n}"		# Everything after 1st <NL> is a sub-header
      [[ ${_PROMPT_TITLE_} == ${_PROMPT_HEADER_} ]] && unset _PROMPT_HEADER_
      _PROMPT_TITLE_="${_PROMPT_TITLE_%%\\n*}"		# Everything before 1st <NL> is the title
    fi
    if (( _IS_DEFAULT_ANSWER_ )) ; then
      if (( _IS_CHOICES_ )) ; then			# Does the default match the generated quit or a CHOICE
        if [[ ${_DEFAULT_ANSWER_} == ${_PROMPT_QUIT_} ]] ;  then
          :						# Do nothing == accept it
        elif [[ ${_ASK_TYPE_} == C ]] ; then		# _ASK_TYPE_ "test" is character by character
          [[ ${_CHOICES_COMPARE_} =~ ${_DEFAULT_ANSWER_} ]] || _IS_ERROR_="2"
        else						# All others need surrounding spaces
          [[ ${_CHOICES_COMPARE_} =~ \ ${_DEFAULT_ANSWER_}\  ]] || _IS_ERROR_="2"
        fi
      fi
      (( _IS_ERROR_ )) && ERROR "${_FUNCTION_}: The default answer \"${_DEFAULT_ANSWER_}\" does not match any of the CHOICES."
      _DEFAULT_ANSWER_DISPLAY_=" (default: ${_DEFAULT_ANSWER_})"
    fi
    if (( _IS_MULTI_CHOICES_ )) ; then
      (( _IS_CHOICES_ )) || { ERROR "${_FUNCTION_}: Option \"-M\" requires option \"-C CHOICES\"." ; _IS_ERROR_=2 ; }
      if (( _MULTI_MENUS_ )) ; then
        (( _ONLY_MM_CHOICES_ )) || _PROMPT_SHORTCUT_MM_="(${_PROMPT_SHORTCUT_}${_PROMPT_SHORTCUT_}) "
        _PROMPT_ALL_+="or ${_PROMPT_SHORTCUT_} ${_PROMPT_SHORTCUT_MM_}for all choices "
      else
        _PROMPT_ALL_+="or ${_PROMPT_SHORTCUT_} for all choices "
      fi
    fi
    if (( _MULTI_MENUS_ )) ; then				# Additional text-based prompt for multi-menus
      if (( _ASK_WITH_GUI_ )) ; then
        _PROMPT_MM_="${_PROMPT_INDENT_}MENU #;; of ${_MULTI_MENUS_} "
      else
        _PROMPT_MM_="${_PROMPT_INDENT_}${LIM}\u25B2 \u25C0${DEF}  Previous (MENU #;; of ${_MULTI_MENUS_}) Next ${LIM}\u25B6  \u25BC${DEF} "
      fi
    else
      unset _PROMPT_MM_
    fi
    if (( _IS_ERROR_ )) ; then
      (( _ASK_RETURN_ )) && return ${_IS_ERROR_}
      (( _IS_USAGE_EXIT_ )) && exit ${_IS_ERROR_} || return ${_IS_ERROR_}
    fi
    _IS_ERROR_="0"

    # ===== Loop until we get a valid answer or "quit". =====
    while true ; do					# Now display the question/menu
      eval unset _ANSWER_ORIG_ ${_ANSWER_VARIABLE_} ASK_ANSWER_IS_ALL
      if [[ $(declare -p ${_ANSWER_VARIABLE_} 2>/dev/null) =~ 'declare -A ' ]] ; then
        declare -A ${_ANSWER_VARIABLE_}			# Ensure answer variable is an associative array
      fi
      if (( _ASK_WITH_GUI_ )) ; then			# A GUI display
        if [[ ${_ASK_TYPE_} == YN ]] ; then
          # The first button defined is the default one
          if [[ ${_DEFAULT_ANSWER_} == n ]] ; then
            _BUTTONS_="--button=yad-no:1 --button=yad-yes:0"
          else
            _BUTTONS_="--button=yad-yes:0 --button=yad-no:1"
          fi
          set -o pipefail
          _ANSWER_ORIG_="$(yad --fixed --center --nowrap ${_BUTTONS_} \
             --button=yad-quit:3 --buttons-layout=center --title "${_PROMPT_TITLE_}" \
            --text '<span font="'"${_FONT_}"'" style="'${_FONT_STYLE_}'" size="'${_FONT_SIZE_}'" weight="'${_FONT_WEIGHT_}'">'"$( _ASK_PROMPT_TEXT_ )"'</span>' \
            | sed -e 's/[$"`\\]/\\&/g'))"
          _THE_RESULT_="$?"
          set +o pipefail
          case ${_THE_RESULT_} in
            0) _ANSWER_ORIG_="y" ;;
            1) _ANSWER_ORIG_="n" ;;
            3) _ANSWER_ORIG_="${_PROMPT_QUIT_}" ;;
          esac
        else
          if (( _MULTI_MENUS_ )) ; then			# The leftmost button is the default
            _BUTTONS_="--button=Previous:${_PREVIOUS_} --button=Next:${_NEXT_} --button=yad-quit:3 --button=yad-ok:0"
          else
            _BUTTONS_="--button=yad-quit:3 --button=yad-ok:0"
          fi
          [[ -n ${_PASSWORD_} ]] && _PASSWORD_="--hide-text"
          set -o pipefail
          _ANSWER_ORIG_="$( yad --fixed --center --nowrap --entry ${_PASSWORD_} --entry-text="${_DEFAULT_ANSWER_}" \
            ${_BUTTONS_} --buttons-layout=center --title "${_PROMPT_TITLE_}" \
            --text '<span font="'"${_FONT_}"'" style="'${_FONT_STYLE_}'" size="'${_FONT_SIZE_}'" weight="'${_FONT_WEIGHT_}'">'"$( _ASK_PROMPT_TEXT_ )"'</span>' \
            | sed -e 's/[$"`\\]/\\&/g')"
          _IS_ERROR_="$?"
          set +o pipefail
          case ${_IS_ERROR_} in
            0) : ;;
            3) _ANSWER_ORIG_="${_PROMPT_QUIT_}"
               _IS_ERROR_="0" ;;
            *) return ${_IS_ERROR_} ;;
          esac
        fi
        _OLD_ASK_WITH_GUI_="${_ASK_WITH_GUI_}"
        unset _ASK_WITH_GUI_
      else						# A text display
        unset _IS_ERROR_ _OLD_ASK_WITH_GUI_ _PRE_READ_
        _ASK_PROMPT_TEXT_					# Display the "menu"
        _PTS_=( $( ps -p $$ -h ) )			# Find the character special path for my input device
        [[ ${_PTS_[1]} =~ ^pts/[0-9]+$ ]] || ERROR "${_FUNCTION_}: No input device (keyboard) available."
        eval exec ${_FILE_DESC_}\</dev/${_PTS_[1]}	# Open a temporary input file descriptor so no conflict with I/O redirection
        if (( _MULTI_MENUS_ )) ; then			# Have to process each keystroke separately
          local _COUNT_="0"
          while read -N 1 -s -r -u ${_FILE_DESC_} || _IS_ERROR_="$?" ; do	# Get a keystroke (silently)
            case $REPLY in
              $'\e')					# <ESC>
                read -N2 -s -r -u ${_FILE_DESC_}		# Get the next two keystrokes
                [[ ${REPLY} =~ \[[BC] ]] && { echo -e "\n" ; return ${_NEXT_} ; }
                [[ ${REPLY} =~ \[[AD] ]] && { echo -e "\n" ; return ${_PREVIOUS_} ; }
                continue					# All other <ESC>xx are ignored
                ;;
              $'\n')					# <NL>
                echo					# So display it
                break ;;				# Finished
              $'\177')					# <BACKSPACE>
                if (( _COUNT_ > 0 )) ; then		# Remove the last character typed
                  _ANSWER_ORIG_="${_ANSWER_ORIG_:0:_COUNT_-1}"
                  echo -n $'\b'' '$'\b'			# And erase it on the screen
                  ((--_COUNT_))				# And adjust the count
                fi
                continue ;;
#              [\"$\`\\])					# Special characters
#                : ;;
              *)					# Any other keystroke
                _ANSWER_ORIG_+="${REPLY}"		# Remember it
                ((++_COUNT_))				# Count it
                [[ -z ${_PASSWORD_} ]] && echo -n "${REPLY}"	# And display it
                ;;
            esac
          done
        else
          if [[ ${_ASK_TYPE_} =~ [CE] ]] ; then
            # Accept all characters - even '\' and trailing spaces
            IFS="" read ${_PASSWORD_} -u ${_FILE_DESC_} -r _ANSWER_ORIG_ || _IS_ERROR_="$?"
          else
            # Record the original response
            read ${_PASSWORD_} -u ${_FILE_DESC_} _ANSWER_ORIG_ || _IS_ERROR_="$?"
          fi
        fi
        eval exec ${_FILE_DESC_}\<\&-			# Close the temporary input file descriptor
      fi
      (( _IS_ERROR_ )) && ERROR "${_FUNCTION_}: Error code \"${_IS_ERROR_}\" occurred while reading the response."

      # ===== Process the obvious answers. =====
      if [[ ! ${_ASK_TYPE_} =~ [CE] ]] ; then		# -c and -e can have any characters
        _ANSWER_ORIG_="${_ANSWER_ORIG_//,/ }"		# Convert separator "," to a space
        [[ ${_ANSWER_ORIG_} =~ ^[[:space:]]*$ ]] && unset _ANSWER_ORIG_	# An empty response
      fi
      while true  ; do
        unset _IS_ERROR_ _RESPONSE_ERROR_		# _IS_ERROR_ may be set by the awk scripts
        if [[ -z ${_ANSWER_ORIG_} ]] ; then		# An empty response
          if [[ -n  ${_DEFAULT_ANSWER_} ]] ; then	# Is AOK if there is a default answer
            eval ${_ANSWER_VARIABLE_}=\"\${_DEFAULT_ANSWER_}\"
            [[ ${_DEFAULT_ANSWER_} == ${_PROMPT_QUIT_} ]] && return 3 || return 0
          elif (( _EMPTY_RESPONSE_ )) ; then		# Or if an empty answer is allowed
            eval ${_ANSWER_VARIABLE_}=\"\"
            return 0
          fi
          _RESPONSE_ERROR_="An empty response is not allowed."
          break						# Incorrect response
        fi
        if [[ ${_ANSWER_ORIG_} == ${_PROMPT_QUIT_} ]] ; then	# Get out if requested
          eval ${_ANSWER_VARIABLE_}=\"\${_ANSWER_ORIG_}\"	# Answer as a scalar
          (( _ASK_WITH_MENU_ )) && return 3 || _IS_ERROR_="3"
        fi
        if (( _IS_ERROR_ )) ; then
          (( _ASK_RETURN_ )) && return ${_IS_ERROR_}
          (( _IS_USAGE_EXIT_ )) && exit ${_IS_ERROR_} || return ${_IS_ERROR_}
        fi
        if (( _IS_MULTI_CHOICES_ )) ; then		# Want all the choices
          if (( _MULTI_MENUS_ > 1 )) ; then
            if [[ -n ${_PROMPT_SHORTCUT_} ]] ; then
              if [[ ${_ANSWER_ORIG_} == "${_PROMPT_SHORTCUT_}${_PROMPT_SHORTCUT_}" ]] ; then
                if (( ! _ONLY_MM_CHOICES_ )) ; then	# OK only if -MMC NOT used
                  ASK_ANSWER_IS_ALL="2"			# Indicate the double-shortcut was used
                  return 0				# No need for further processing
                fi
              elif [[ ${_ANSWER_ORIG_} == "${_PROMPT_SHORTCUT_}" ]] ; then
                ASK_ANSWER_IS_ALL="1"			# Indicate the shortcut was used
                return 0
              fi
            fi
          elif [[ -n ${_PROMPT_SHORTCUT_} && ${_ANSWER_ORIG_} == "${_PROMPT_SHORTCUT_}" ]] ; then
            _ANSWER_ORIG_="${_CHOICES_COMPARE_}"	# Create the answer
            ASK_ANSWER_IS_ALL="1"			# Indicate the shortcut was used
          fi
        fi
        case "${_ASK_TYPE_}" in
          YN)						# Yes or no
            eval ${_ANSWER_VARIABLE_}=\"\${_ANSWER_ORIG_:0:1}\"
            case "${_ANSWER_ORIG_}" in
              y*) return 0 ;;				# Return 'true'
              n*) return 1 ;;				# Return 'false'
            esac
            break					# Incorrect response
            ;;
          N)						# Single integer
            _ASK_VERIFY_ANSWER_RANGE_ "${_IS_NUMBER_}" && return 0
            break					# Incorrect response
            ;;
          A|AN)						# Single alphabetic or alphanumeric characters
            _ASK_VERIFY_ANSWER_RANGE_ && return 0
            break					# Incorrect response
            ;;
          C)						# Single (any) characters
            _ASK_VERIFY_CHARACTERS_ && return 0
            break					# Incorrect response
            ;;
          W)						# Words
            _ASK_VERIFY_WORDS_ && return 0
            break					# Incorrect response
            ;;
          E)						# Everything
            if [[ -z ${_CHOICES_ORIG_} ]] ; then		# Everything accepted
              eval ${_ANSWER_VARIABLE_}=\"\${_ANSWER_ORIG_}\"	# So create a scalar
              return 0
            fi
            _ASK_VERIFY_WORDS_ && return 0
            break						# Incorrect response
            ;;
        esac
      done
      _ASK_ERROR_="${_FUNCTION_}: Response \"${_ANSWER_ORIG_}\" is invalid.${_RESPONSE_ERROR_:+\n${_FUNCTION_SPACES_}}${_RESPONSE_ERROR_}"
      _ASK_WITH_GUI_="${_OLD_ASK_WITH_GUI_}"
    done
  }

_GAWK_NORMALIZE_="${FUNCTIONS_SH_DIR}/.${FUNCTIONS_SH_BASENAME}.ASK_Normalize_Ranges.gawk${FUNCTIONS_SH_SUFFIX}"

  # Normalize a set of single-character OPTION RANGES. $1=default choices $2=valid regex
  function _ASK_NORMALIZE_CHOICES_RANGE_() {
    local _GAWK_VARIABLES_
    if [[ -z ${_CHOICES_ORIG_} ]] ; then
      _CHOICES_ORIG_="$1"				# Use the default set of 1-char choices
      _IS_CHOICES_="1"
    else
      _CHOICES_ORIG_="${_CHOICES_ORIG_//,/ }"		# Convert "," separator to <SPACE>
    fi
    [[ -f ${_ASK_SCRIPT_FILE_} ]] || TMP_FILE_CREATE _ASK_SCRIPT_FILE_ _ASK_ARGS_FILE_	# If it doesn't exist, create it
    # Assumptions: -v VariablePrefix=_CHOICES_ -v VariableSuffix=COMPARE_ -v DisplaySuffix=DISPLAY_
    _GAWK_VARIABLES_=" -v ScriptFile=${_ASK_SCRIPT_FILE_} -v IsUsageExit=${_IS_USAGE_EXIT_} -v Function=${_FUNCTION_} "
    _GAWK_VARIABLES_+="-v AskCode=${_ASK_CODE_} -v Plural=${_PLURAL_} -v IsAnswer=0 -v IsNumber=${3:-0} "
    echo "${_CHOICES_ORIG_}" > "${_ASK_ARGS_FILE_}"
    gawk ${DebugN:+-D} ${_GAWK_VARIABLES_} -v PromptType="${_PROMPT_TYPE_}" -v Valid="${2}" \
      -f "${_GAWK_NORMALIZE_}" "${_ASK_ARGS_FILE_}"
    source "${_ASK_SCRIPT_FILE_}"			# Evaluate the variables/errors
    (( _IS_ERROR_ )) && return ${_IS_ERROR_}
    if (( _AS_IS_ )) ; then
      _CHOICES_DISPLAY_="${_CHOICES_ORIG_}"		# No normalization
    else
      (( _WRAP_CHOICES_ )) && _ASK_WRAP_CHOICES_ "${_CHOICES_DISPLAY_}"
    fi
    _ASK_PROMPT_QUIT_ 3					# Set up the character(s) to quit
    return 0
  }

  function _ASK_PROMPT_QUIT_() {			# $1 = max number of q's
    if [[ $1 == 0 ]] ; then				# Special case
        if [[ -z ${_CHOICES_ORIG_} ]] ; then		# No choices
          if [[ -n ${_QUIT_CODE_} ]] ; then		# But there is a QUITCODE
            _PROMPT_QUIT_="${_QUIT_CODE_}"		# So use it
          else
            _PROMPT_QUIT_="<CTRL-C>"			# Else use <CTRL-C> to get out of Dodge
          fi
        return
      fi
    fi
    local _COMPARE_="${1:-3}" _COUNT_=1 _SPACE_=" "
    [[ ${_ASK_TYPE_} == C ]] && _SPACE_=""		# No extra spaces for type -c or -ca
    _PROMPT_QUIT_="${_QUIT_CODE_}"
    # Look for _PROMPT_QUIT_ in _CHOICES_COMPARE_
    while [[ ${_SPACE_}${_CHOICES_COMPARE_}${_SPACE_} =~ ${_SPACE_}${_PROMPT_QUIT_}${_SPACE_} ]] ; do
      (( ++_COUNT_ > _COMPARE_ )) && { _PROMPT_QUIT_="<CTRL-C>" ; return ; }	# q's > max so must use <CTRL-C>
      _PROMPT_QUIT_+="${_QUIT_CODE_}"			# Ensure there is a code to exit ASK (q or qq or qqq or ...)
    done
  }

  function _ASK_PROMPT_TEXT_() {
    local _PROMPT_FROM_ _PROMPT_HELP1_ _PROMPT_HELP2_
    if [[ ${_ASK_TYPE_} == YN ]] ; then			# yes/no is a special case
      local _YN_
      if [[ ${_DEFAULT_ANSWER_} == "n" ]] ; then
        _YN_="n, y"
        _DEFAULT_ANSWER_DISPLAY_=" (default is 'n' == No)"
      elif [[ ${_DEFAULT_ANSWER_} == "y" ]] ; then
        _YN_="y, n"
        _DEFAULT_ANSWER_DISPLAY_=" (default is 'y' == Yes)"
      else
        _YN_="y, n"
      fi
      _PROMPT_HELP2_="Enter ${_YN_} or ${_PROMPT_QUIT_} to quit${_DEFAULT_ANSWER_DISPLAY_}"
    else
      _PROMPT_MM_="${_PROMPT_MM_/;;/${_MM_IDX_}}"
      _PROMPT_HELP2_="${_PROMPT_MM_}${_PROMPT_ALL_}or ${_PROMPT_QUIT_} to quit${_DEFAULT_ANSWER_DISPLAY_}"
      (( ${#_CHOICES_DISPLAY_} > _CHOICES_DISPLAY_MAX_ )) && _ASK_WRAP_CHOICES_ "${_CHOICES_DISPLAY_}"
      if (( _IS_CHOICES_ && ! _ASK_WITH_MENU_ )) ; then
        (( _IS_DISPLAY_CHOICES_ )) || _PROMPT_FROM_+=" from: "
      fi
      ###if (( _ASK_WITH_MENU_ && ( ${#_MM_ARRAY_[*]} > 1 && _ONLY_MM_CHOICES_ ) )) ; then
      if (( _ASK_WITH_MENU_ )) ; then
        _PROMPT_HELP1_="Select one${_PROMPT_MORE_} menu item${_PROMPT_PLURAL_}. "
        unset _CHOICES_DISPLAY_
      else
        if (( _ASK_WITH_MENU_ )) ; then
          _PROMPT_HELP1_="\nSelect one${_PROMPT_MORE_} item${_PROMPT_PLURAL_} from: "
        else
          if [[ _ASK_TYPE_ == E && ! _IS_CHOICES_ ]] ; then
            _PROMPT_HELP1_="Type a response: "
          else
            _PROMPT_HELP1_="Enter one${_PROMPT_MORE_} ${_PROMPT_TYPE_}${_PROMPT_PLURAL_}${_PROMPT_FROM_}"
          fi
        fi
      fi
    fi
    (( _IS_HELP1_ )) && _PROMPT_HELP1_="${_HELP1_}"	# Override generated HELP1
    if (( _PROMPT_MINIMAL_ )) ; then			# -MD used
      unset _PROMPT_HEADER_ _PROMPT_LEGEND_ _CHOICES_DISPLAY_ _PROMPT_HELP2_
      if (( _PROMPT_SUPPRESS_HELP1_ )) ; then
        unset _PROMPT_HELP1_
      else
        if (( ! _IS_HELP1_ )) ; then
          if (( _ASK_WITH_MENU_ )) ; then
            _PROMPT_HELP1_="Select one${_PROMPT_MORE_} menu item${_PROMPT_PLURAL_}${_PROMPT_FROM_}"
          else
            _PROMPT_HELP1_="Enter your response${_PROMPT_PLURAL_}"
          fi
        fi
      fi
    else
      (( _IS_HELP2_ )) && _PROMPT_HELP2_="${_HELP2_}"	# Override generated HELP2
      (( _IS_DISPLAY_CHOICES_ )) && _CHOICES_DISPLAY_="${_DISPLAY_CHOICES_}"
    fi
    if (( _ASK_WITH_GUI_ )) ; then
      ( (( ${#_ASK_ERROR_} )) && echo -e "${_ASK_ERROR_}"
        echo -e -n "${_PROMPT_HEADER_}${_PROMPT_INSTRUCTIONS_}${_PROMPT_LEGEND_}${_PROMPT_HELP1_}${_CHOICES_DISPLAY_}${_PROMPT_HELP2_}"
      ) | sed -e 's/[$"`\\]/\\&/g' -e s'/<CTRL-C>/click on "Quit"/g'
    else
      (( ${#_ASK_ERROR_} )) && echo -e "\n${_ASK_ERROR_}"
      echo -e -n "${_PROMPT_HEADER_}${_PROMPT_INSTRUCTIONS_}${_PROMPT_LEGEND_}${_PROMPT_HELP1_}${_CHOICES_DISPLAY_}${_PROMPT_HELP2_}: "
    fi
  }

  # Verify a set of character CHOICES or answers
  function _ASK_VERIFY_CHARACTERS_() {
    local _GAWK_VARIABLES_
    local _GAWK_VERIFY_CHARS_="${FUNCTIONS_SH_DIR}/.${FUNCTIONS_SH_BASENAME}.ASK_Verify_Characters.gawk${FUNCTIONS_SH_SUFFIX}"
    [[ -f ${_ASK_SCRIPT_FILE_} ]] || TMP_FILE_CREATE _ASK_SCRIPT_FILE_ _ASK_ARGS_FILE_	# If it doesn't exist, create it
    _GAWK_VARIABLES_="  -v ScriptFile=${_ASK_SCRIPT_FILE_} -v IsUsageExit=${_IS_USAGE_EXIT_} -v Function=${_FUNCTION_} -v AskReturn=${_ASK_RETURN_} "
    _GAWK_VARIABLES_+=" -v AnswerVariable=${_ANSWER_VARIABLE_} -v EmptyAllowed=${_EMPTY_RESPONSE_} -v IsArray=${_IS_ARRAY_} -v MultiChoices=${_IS_MULTI_CHOICES_} "
    _GAWK_VARIABLES_+=" -v IsChoices=${1:-0}"
    if (( $# )) ; then
      echo "${_CHOICES_ORIG_}" > ${_ASK_ARGS_FILE_}
    else
      echo "${_ANSWER_ORIG_}" > ${_ASK_ARGS_FILE_}
    fi
    gawk ${DebugC:+-D} ${_GAWK_VARIABLES_} -v Indent="${_PROMPT_INDENT_}" -v Choices="${_CHOICES_ORIG_//\\/\\\\}" \
          -f ${_GAWK_VERIFY_CHARS_} "${_ASK_ARGS_FILE_}"
    source "${_ASK_SCRIPT_FILE_}"				# Evaluate the variables/errors
    return ${_IS_ERROR_}
  }

  # Verify a set of alphanumeric single-character ANSWER RANGES.
  function _ASK_VERIFY_ANSWER_RANGE_() {
    [[ -f ${_ASK_SCRIPT_FILE_} ]] || TMP_FILE_CREATE _ASK_SCRIPT_FILE_ _ASK_ARGS_FILE_	# If it doesn't exist, create it
    local _GAWK_VARIABLES_
    # Assumptions: -v Type=answer -v VariableSuffix=COMPARE_
    _GAWK_VARIABLES_=" -v ScriptFile=${_ASK_SCRIPT_FILE_} -v IsUsageExit=0 -v Function=${_FUNCTION_} "
    _GAWK_VARIABLES_+="-v AskCode=${_ASK_CODE_} -v AnswerVariable=${_ANSWER_VARIABLE_} "
    _GAWK_VARIABLES_+="-v IsAnswer=1 -v EmptyAllowed=${_EMPTY_RESPONSE_} -v IsNumber=${1:-0} "
    _GAWK_VARIABLES_+="-v Plural=${_PLURAL_} -v MultiChoices=${_IS_MULTI_CHOICES_} "
    echo "${_ANSWER_ORIG_//,/ }" > "${_ASK_ARGS_FILE_}"
    gawk ${DebugA:+-D} ${_GAWK_VARIABLES_} -v Valid="${_CHOICES_COMPARE_}" -v PromptType="${_PROMPT_TYPE_}" \
          -f ${_GAWK_NORMALIZE_} "${_ASK_ARGS_FILE_}"
    source "${_ASK_SCRIPT_FILE_}"				# Evaluate the variables/errors
    return ${_IS_ERROR_}
  }

  # Verify words or anything entered.
  function _ASK_VERIFY_WORDS_() {
    if [[ ${_ASK_TYPE_} == E && ! ${_IS_CHOICES_} ]] ; then	# "-e" without choices can have anything
      eval ${_ANSWER_VARIABLE_}=\"\${_ANSWER_ORIG_}\"
      return 0
    fi
    if (( ! _IS_MULTI_CHOICES_ )) ; then
      if [[ ${_ANSWER_ORIG_} =~ " " ]] ; then
        _RESPONSE_ERROR_="Multiple responses are not allowed."
        return 2
      fi
    fi
    local _ANSWER_ARRAY_=( ${_ANSWER_ORIG_} ) _GOOD_="1" _IDX_ _INDENT_
    for _IDX_ in ${!_ANSWER_ARRAY_[*]} ; do		# Verify each response
      [[ ${_ANSWER_ARRAY_[_IDX_]} =~ ${_ACCEPTABLE_1_} ]] \
        || { unset _GOOD_ ; _RESPONSE_ERROR_="The response \"${_ANSWER_ARRAY_[_IDX_]}\" is not a bash \"name\"." ; }
      if [[ -n ${_CHOICES_ORIG_} ]] ; then
        [[ ${_CHOICES_COMPARE_} =~ " ${_ANSWER_ARRAY_[_IDX_]} " ]] \
          || { unset _GOOD_ ; _RESPONSE_ERROR_="The response \"${_ANSWER_ARRAY_[_IDX_]}\" does not match any choice\n${_FUNCTION_SPACES_}or occurs more than the maximum allowed."; }
      fi
      (( ! _GOOD_ )) && return 2
      eval ${_ANSWER_VARIABLE_}+=\(\${_ANSWER_ARRAY_[${_IDX_}]}\)	# Create an array
      _CHOICES_COMPARE_=" ${_CHOICES_COMPARE_/ ${_ANSWER_ARRAY_[_IDX_]} /} "	# Remove that choice
    done
    return 0
  }

  function _ASK_WRAP_CHOICES_() {				# $1=CHOICES $2=prefix $3=suffix
    local _GAWK_VARIABLES_
    local _GAWK_WRAP_="${FUNCTIONS_SH_DIR}/.${FUNCTIONS_SH_BASENAME}.ASK_Wrap_Choices.gawk${FUNCTIONS_SH_SUFFIX}"
    [[ -f ${_ASK_SCRIPT_FILE_} ]] || TMP_FILE_CREATE _ASK_SCRIPT_FILE_ _ASK_ARGS_FILE_	# If it doesn't exist, create it
    echo "$*" > "${_ASK_ARGS_FILE_}"
    _GAWK_VARIABLES_=" -v ScriptFile=${_ASK_SCRIPT_FILE_} -v IsUsageExit=${_IS_USAGE_EXIT_} -v Function=${_FUNCTION_} "
    _GAWK_VARIABLES_+="-v Compressed=${_PROMPT_COMPRESSED_} -v WrapLen=$(( (COLUMNS*_WRAP_LENGTH_+50)/100 )) "
    _GAWK_VARIABLES_+="-v AskType=${_ASK_TYPE_} -v Multi=${_IS_MULTI_CHOICES_}"
    gawk ${DebugW:+-D} ${_GAWK_VARIABLES_} -v Indent="${_PROMPT_INDENT_}" -f "${_GAWK_WRAP_}" "${_ASK_ARGS_FILE_}"
    source "${_ASK_SCRIPT_FILE_}"				# Evaluate the variables/errors
  }

  function _ASK_YN_() {
    _ASK_TYPE_="YN"
    if (( _IS_CHOICES_ + _IS_MULTI_CHOICES_ )) ; then
      ERROR "${_FUNCTION_}: You cannot use OPTIONS -C or -M with ASKTYPE \"-yn\"."
      _IS_ERROR_="2"
      return 2
    fi
    _CHOICES_ORIG_=" y n "
    _CHOICES_COMPARE_=" y n "
    _IS_CHOICES_="1"
    _ASK_PROMPT_QUIT_ 1
    _PROMPT_TYPE_="character"
  }

##________________________________________________________________________________
##
## ASK_WITH_MENU - Creates a MENU of sequenced ITEMS, displays it and asks for a
##     response from the menu. Each MENU line consists of a SELECTOR followed by
##     the ITEM info.
##   ASK_WITH_MENU uses the function ASK to display the menu and to read and
##     verify the response. The ASK section INSTRUCTIONS contains the generated
##     menu. Responses are placed in the variable/array ANSWER. For more info
##     see -V below and ASK above.
##   Usage: ASK_WITH_MENU [ASKOPTIONS] { ARRAYNAME | ARGS }
##   Where:
##     ASKOPTIONS:
##       Note: For UNIX compatability, all multi-character options can be
##             preceeded by either one or two dashes (e.g. -CC or --CC).
##       Note: If an option requires a value, the value is a separate argument.
##               E.G.  -D DEFAULTANSWER
##             If an option has an optional value, the option is followed by an
##             equal sign followed by the optional value. If two optional values
##             are possible the second value is preceeded by ":".
##               E.G.  -I  or  -I=8  or  -MM  or  -MM=4  or  -MM=4:2  or -MM=:2
##       -CA
##          Display CHOICES as-is. For ASKCODES that accept ranges, the display
##          of the generated CHOICES is not normalized into ranges.
##       -D DEFAULTANSWER
##          DEFAULTANSWER is used as the answer if a null response is given.
##            It must be one of the menu selectors (CHOICES).
##       -EE PRE   or   -EE [PRE]:POST
##          Enhance each menu element by surrounding it with PRE and or POST.
##       -ER An empty response is allowed. By default an empty response generates
##          an error message and the QUESTION is redisplayed.
##       -ES PRE   or   -ES [PRE]:POST
##          Enhance each menu selector by surrounding it with PRE and or POST.
##          For example the following will display the menu selectors in bold
##            gold followed by ")":   -ES "${BOLD}${GLD}:${DEF}${DEF})"
##       -EV In creating the menu, include empty values in array elements or
##            arguments.  By default empty element/argument values are ignored
##            and don't appear in the menu and cannot be included in the answer.
##          Empty is defined as a value that is present that equates to "".
##            A missing element in a sparse array (i.e. element x[2] in the
##            array x[1], x[3], x[4]...) is not "empty".
##       -F FONT
##          Only with -G. Change the font to FONT. See ASK for details.
##       -FS FONTSIZE
##          Only with -G. Change the font size to FONTSIZE. See ASK for details.
##       -FW WEIGHT
##          Only with -G. Change the font weight to WEIGHT. See ASK for details.
##       -FY FONTSTYLE
##          Only with -G. Change the font style to FONTSTYLE. See ASK for details.
##       -G Display the menu with a GUI interface. See ASK for details.
##       -H HEADER
##          "HEADER\n" is displayed prior to the menu items. See ASK for details.
##       -H1 HELP1
##          Replace the HELP1 section in the PROMPT with HELP1.
##       -H2 HELP2
##          Replace the HELP2 section in the PROMPT with HELP2. If HELP2 is
##          null (-H2 "") only ": " is displayed.
##       -I[=LENGTH]
##          Use the index of ARRAYNAME as the SELECTOR for menu items. For
##            an associative ARRAY, this enables complete control of the SELECTOR
##            values by assigning the ARRAYNAME indices.
##          No index in ARRAYNAME can contain whitespace. Indices containing
##            special characters may cause problems due to expansions and quotes.
##            It is best to use just alphanumeric characters and "_".
##          Use of -I for ARGS does not make sense as they always have numeric
##            indices ($1, $2, ...). However it can be used to adjust the size of
##            the menu SELECTOR field.
##          LENGTH is the size of the menu SELECTOR field. The default for LENGTH
##            is 6. Specifyng LENGTH to accommodate every index ensures the menu
##            SELECTORS and items are aligned.
##       -L LEGEND
##          Add "\nLegend: LEGEND\n" to the prompt. See ASK for details.
##       -M[=MULT]
##          Multiple choices in the response are allowed. Same as for ASK but
##            option -C CHOICES is not required as CHOICES is generated
##            automatically from the sequenced menu items.
##          A response of MULT can be entered to select all the choices. MULT
##            defaults to "*". If MULT is empty ("") then there is no shortcut
##            to select all the choices.
##          See RESPONSES below.
##       -MD[=NOHELP1]
##          Minimal display. Display only the INSTRUCTIONS and HELP1 sections.
##          See ASK for details.
##       -MI MENUINSTRUCTIONS
##          Since in ASK_WITH_MENU the generated menu is the "INSTRUCTIONS" in
##            the ASK PROMPT, specifying INSTRUCTIONS is not available.
##          The option -MD places MENUINSTRUCTIONS at the beginning of the
##            generated menu augmenting the PROMPT.
##       -MM[=SMCOUNT]   or   -MM[=SMCOUNT]:SMNUM
##          Multiple menus. Split ARRAYNAME/ARGS into SMCOUNT sub-menus and
##          display sub-menu SMNUM. If SMCOUNT is missing ASK_WITH_MENU will
##          split the menu into DIVISOR sub-menus (see -MML below). SMNUM
##          defaults to sub-menu 1. See MULTIPLE MENUS below.
##       -MMC
##          If the number of sub-menus is greater than one, limit the valid
##          choices to the sub-menu SELECTIONS displayed.
##       -MML LINES   or   -MML [LINES]:PERCENT
##          Adjust the value of DIVISOR used to split a menu into multiple menus
##          DIVISOR is calculated as follows (using integer arithmetic):
##             DIVISOR=$((LINES * PERCENT / 100))
##          LINES is an integer (0 < LINES). The default is the bash variable
##            $LINES.
##          PERCENT is an integer ( 0 < PERCENT <= 100).
##          If LINES is present and PERCENT is not, PERCENT defaults to "100".
##            Otherwise it defaults to "75".
##          No verification is done to ensure reasonable values for LINES,
##             PERCENT  or DIVISOR.
##       -P The response is a password. Hide (don't echo) what is typed.
##       -Q QUITCODE
##          Change the quit code to QUITCODE.  The default QUITCODE is "q".
##          See ASK for details.
##       -R Return rather than exit from a QUITCODE response.
##       -S[=SORTOPTION]
##          Sort the menu SELECTORS in ascending order. Useful to sequence
##            associative arrays.  SORTOPTION modifies the default sort order.
##          The sorting is done by the SORT_ARGS function which uses the linux
##            "sort" command. See SORTOPTION below.
##       -U FILEDESC
##          Use file descriptor FILEDESC to read the response to the question.
##          FILEDESC is a single digit from 3 to 9. The default FILEDESC is 9.
##       -V VARIABLE
##          Sets the name prefix to VARIABLE for the arrays that contain the
##          results. The default name prefix is 'ANSWER'.
##       -- Indicates the end of options. The remaining arguments comprise
##          ARRAYNAME or ARGS. This is needed only if ARGS begins with a "-".
##     ARRAYNAME or ARGS
##       ARRAYNAME
##         If there is a single argument, it is assumed to be ARRAYNAME which is
##         the name of an array containing the menu items. It can be a sparse (non
##         contiguous) indexed or an associative array. For the latter, the order
##         of the displayed menu items is indeterminant. If ARRAYNAME is an
##         associative array and if option -I is used, no index can contain spaces.
##       ARGS
##         If there is more than one argument then ARGS are the menu items from
##         which a choice is made. ARGS is converted into an array (origin 1).
##       A menu is created either with sequential numeric SELECTORS or with the
##         array indices asSELECTORS.
##   INSTRUCTIONS
##     The generated menu is the prompt INSTRUCTIONS. Additional instructions may
##       be added with the -MI option.
##   CHOICES
##     For single menus, the generated menu SELECTORS are the acceptable CHOICES
##     for the response. For multiple menus (-MM) the acceptable CHOICES are the
##     the total SELECTORS of all the generated menus.
##   SORTOPTION
##     SORTOPTION modifies the sort order of the menu SELECTORS. It contains
##       the options acceptable to the SORT_ARGS function and can have two
##       formats: SORTOPTION or SHORTCUTS.
##     SORTOPTION
##       Consists of an optional "-N ", an "-S " followed by one option of the
##       sort command. E.G. -S="-S -n".
##     Note: Due to implementation restrictions, the SORT_ARGS option -S can be
##       followed by only one "sort" option. However the option "-S=" can
##       be repeated for each sort option wanted.
##     SHORTCUTS
##       SHORTCUT codes can be used instead of the SORTOPTION format. The codes
##         can be combined in any order to produce a variety of sorted menus.
##       Any SORTOPTION that doesn't start with "-N" or "-S" is assumed to be
##         a SHORTCUT. Each SHORTCUT generates an appropriate SORTOPTION.
##       Valid SHORTCUT codes are:
##         CODE  SHORTOPTION     SELECTOR SORT
##           d   -S="-S -d"   Dictionary (case independent alpha then numbers)
##           n   -S="-S -n"   Numeric (all numbers in numeric value order)
##           a   -S="-N"      ASCII (numbers, uppercase, lowercase)
##           r   -S="-S -r"   Reverse
##           v   -S="-S -V"   Version (properly sequences file.01.5...)
##         Note: SHORTCUT code "n" cannot be used with "d" or "v".
##       For example the option -S=rn will sort the menu SELECTORS in reverse
##         numerical order.
##   MULTIPLE MENUS
##     Multiple menus (-MM) splits a long menu into sub-menus to ensure every
##       sub-menu will fit in terminal screen. The number of sub-menus and the
##       nnumber of items in each sub-menu is calculated as described in -MML
##       above. If the celculation determines that there is only one sub-menu
##       then multiple menus is automatically turned off.
##     The splitting of a menu into sub-menus is based on the number of menu
##       array elements and does not take into account the additional menu lines
##       in the ASK sections: HEADER LEGEND HELP1 CHOICESDISPLAY HELP2. To
##       account for these extra lines use option -MML to modify the calculation.
##     If SMCOUNT is missing, SMCOUNT is derived from the number of elements
##       in ARRAYNAME or ARGS divided by DIVISOR (see -MML above).
##       ASK_WITH_MENU will manage displaying the sub-menus.
##     Switching sub-menus is done with the arrow keys or, in GUI mode, by
##       clicking on the "Next" and "Previous" buttons.
##     The variable ASK_WITH_MENU_NUMBER is set to the last sub-menu displayed.
##       Specifyiug the option "-MM:${ASK_WITH_MENU_NUMBER}" allows you to issue
##       commamds after a menu response and then redisplay the same sub-menu.
##     Within the parent script, prior to the first time ASK_WITH_MENU with the
##       option "-MM:${ASK_WITH_MENU_NUMBER}" is called, ASK_WITH_MENU_NUMBER
##       should be set either to the number of the first sub-menu to be
##       displayed or unset. For example:
##         unset ASK_WITH_MENU_NUMBER
##         while ...			# Loop ...
##           # Split a_menu_array into 3 sub-menus and begin with sub-menu #2.
##           ASK_WITH_MENU -MM=3:${ASK_WITH_MENU_NUMBER} a_menu_array
##             Sub-menu #1 is displayed
##             Go to (isplay) sub-menu #2
##             Select an item from sub-menu #2
##             <do-something-or-quit>
##           ASK_WITH_MENU -MM=3:${ASK_WITH_MENU_NUMBER} a_menu_array
##             Sub-menu #2 is displayed again.
##         done
##       If ASK_WITH_MENU_NUMBER is set to a non-existant sub-menu number it
##       is reset to 1.
##   RESPONSES
##     A valid response is one menu SELECTOR. If more than one sub-menu is
##        present, you can respond with a menu SELECTOR from any menu/sub-menu
##        even if it is not displayed.
##     If multiple answers (-M) is specified, more than one menu SELECTOR can be
##        specified and a menu item for each selector is returned into the ANSWER
##        array. If the option -I is not used then numeric RANGES (see ASK above)
##        can be used to specify SELECTORS.
##     In addition, a shortcut (MULT) can be used to select all of the menu
##        items. The behaviour of MULT depends upon the number of sub-menus and
##        upon the use of the multi-menu choices option (-MMC).
##     Typing MULT once ("*") will select all the item values in the displayed
##        menu/sub-menu. If there is more than one sub-menu, typing MULT twice
##        ("**") selects all the ARRAYNAME elements or ARGUMENTS even if not
##        displayed in a sub-menu.
##     The option -MMC negates the use of MULTMULT, and restricts both the response
##        and MULT to only the SELECTORS in the displayed sub-menu.
##   RETURN VALUES
##     ASK_WITH_MENU returns, as an answer, three indexed arrays (origin 0).
##     For index  "i"
##         VARIABLE[i]:     The menu/sub-menu SELECTORS of the response(s).
##         VARIABLE_IDX[i]: The index into ARRAYNAME or the ARGS 'position'.
##         VARIABLE_VAL[i]: The actual menu item text. I.E. The value of
##                          ${ARRAYNAME[${VARIABLE_IDX[i]}]} or
##                          ${ARGS[${VARIABLE_IDX[i]}]}
function ASK_WITH_MENU() {
  _FUNCTION_="ASK_WITH_MENU"
  _FUNCTION_SPACES_="               "
  _ASK_WITH_MENU_DOIT_ "$@"
}

##________________________________________________________________________________
##
## ASK_WITH_MENU_GUI - Equivalent to 'ASK_WITH_MENU -G'.
##   All the options of ASK can be specified. The <OK> button simulates a
##   default response that returns a null answer unless the -D option is used.
##   The <Cancel> button is equivalent to the QUITCODE (q, qq...).
function ASK_WITH_MENU_GUI() {
  _ASK_WITH_GUI_="1"
  _FUNCTION_="ASK_WITH_MENU_GUI"
  _FUNCTION_SPACES_="                   "
  _ASK_WITH_MENU_DOIT_ "$@"
}

function _ASK_WITH_MENU_DOIT_() {
  local _NEXT_=67 _PREVIOUS_=68				# Codes for "▶ " ("<ESC>[C") and "◀ " ("<ESC>[D")
  local _INDEX_ITEM_MAP_ _IS_SORT_ _SELECTOR_SORT_ _SELECTOR_SORT_OPT_ _SELECTOR_INDEX_MAP_
  local _IS_ARGS_ _IDX_ _IDX1_ _MENU_IDX_ _INDICES_ _ELEMENT_PRE_ _ELEMENT_POST_ _SELECTOR_PRE_ _SELECTOR_POST_
  local _MENU_CHOICES_ _MENU_SELECTOR_ _MENU_POSITION_ _MENU_TYPE_="-n" _MENU_IDX_
  local _MM_ARRAY_ _ELEMENTS_ _HAS_EMPTY_VALUES_ _ONLY_MM_CHOICES_ _MC_IDX_ _MM_IDX_ _MULTI_MENUS_ _THE_MENU_
  local _dlr1_ _LINES_="${LINES}" _PERCENT_="75" _SPLIT_
  local _SELECTOR_LEN_=6 _USE_INDEX_ _IGNORE_EMPTY_VALUES_="1" _EMPTY_QUOTES_ _MENU_EMPTY_RESPONSE_
  local _MENU_ANSWER_ _MENU_ANSWER_VARIABLE_="ANSWER" _VALUE_
  local _ASK_OPTIONS_ __ASK_RETURN__ _DEFAULT_ _HEADER_ _LEGEND_ _ReturnCode_
  local _FONT_="Sans" _FONT_SIZE_="medium" _FONT_STYLE_="normal" _FONT_WEIGHT_="normal"
  local _AIDX_ _SIDX_ _VIDX_
  _ASK_WITH_MENU_="1"
  while true ; do
    [[ $1 =~ ^--. ]] && _dlr1_="${1:1}" || _dlr1_="$1"
    case "${_dlr1_}" in
      -CA)	#|--as-is				# Choices as-is (without normalization)
          _ASK_OPTIONS_+=( $1 ) ;;
      -D)	#|--default)
          _DEFAULT_="$2"				# The default answer if "OK" or "<ENTER>"
          shift 1 ;;
      -EE)	#|--enhance-selectors
          _ELEMENT_PRE_="${2%:*}"
          [[ ${2} =~ : ]] &&_ELEMENT_POST_="${2#*:}"
          shift 1 ;;
      -ER)	#|--empty-response
          _ASK_OPTIONS_+=( $1 )				# An empty response is allowed
          ;;
      -ES)	#|--enhance-selectors
          _SELECTOR_PRE_="${2%:*}"
          [[ ${2} =~ : ]] &&_SELECTOR_POST_="${2#*:}"
          shift 1 ;;
      -EV)	#|--empty-array
          unset _IGNORE_EMPTY_VALUES_			# Empty menu items are alloewd
          ;;
      -F) 	#|--font
          _ASK_OPTIONS_+=( $1 "$2" )
          shift 1 ;;
      -FS) 	#|--font-size
          _ASK_OPTIONS_+=( $1 "$2" )
          shift 1 ;;
      -FW) 	#|--font-weight
          _ASK_OPTIONS_+=( $1 "$2" )
          shift 1 ;;
      -FY) 	#|--font-style
          _ASK_OPTIONS_+=( $1 "$2" )
          shift 1 ;;
      -G)	#|--gui)				# The GUI version
          if [[ ! ${_FUNCTION_} =~ _GUI ]] ; then
            _FUNCTION_="${_FUNCTION_}_GUI"
            _FUNCTION_SPACES_="${_FUNCTION_SPACES_}    "
          fi
          _ASK_OPTIONS_+=( $1 ) ;;
      -H1)	#|--help1
          _ASK_OPTIONS_+=( $1 "$2" )			# Replace the HELP1 section of PROMPT
          shift 1 ;;
      -H2)	#|--help2
          _ASK_OPTIONS_+=( $1 "$2" )			# Replace the HELP2 section of PROMPT
          shift 1 ;;
      -H)	#|--header)				# A menu header is requested.
          _HEADER_="${2}"
          shift 1 ;;
      -I*)	#|--use-index
          _USE_INDEX_="1"
          [[ ${1} =~ = ]] && _SELECTOR_LEN_="${1/-I=/}"
          _MENU_TYPE_="-e" ;;
      -L)	#|--legend
          _LEGEND_="${2}"
          shift 1 ;;
      -MD*)	#|--minimal-display
          _ASK_OPTIONS_+=( $1 ) ;;
      -MI)	#|--menu-instructions
          _THE_MENU_[0]="$2"
          shift 1 ;;
      -MMC)	#| --multiple-menu-choices
          _ONLY_MM_CHOICES_="1" ;;
      -MML)	#| --multi-menu-lines
          _SPLIT_="${2%:*}"
          if [[ -n ${_SPLIT_} ]] ; then
            _LINES_="${_SPLIT_}"
            _PERCENT_="100"				# If LINES specified then PERCENT defaults to 100
          fi
          if [[ $2 =~ : ]] ; then
            _SPLIT_="${2#*:}"
            [[ -n ${_SPLIT_} ]] && _PERCENT_="${_SPLIT_}"
          fi
          shift 1 ;;
      -MM*)	#| --multiple-menus
          local _mm_="$1"
          if [[ ${_mm_} =~ : ]] ; then			# If there is a ":"
            ASK_WITH_MENU_NUMBER="${_mm_#*:}"		# Set the starting sub-menu number
            _mm_="${_mm_%:*}"
          fi
          if [[ ${_mm_} =~ = ]] ; then			# Optional values are present
            _MULTI_MENUS_="${_mm_/-MM=/}"			# Remove the -MM=
          fi
          [[ -z ${_MULTI_MENUS_} ]] && _MULTI_MENUS_="-1"
          ;;
      -M*)	#|--multiple-choices)
          _ASK_OPTIONS_+=( $1 ) ;;
      -P) 	#|--password mode
          _ASK_OPTIONS_+=( $1 ) ;;
      -Q)	#|--quitcode
          _ASK_OPTIONS_+=( $1 "$2" )
          shift 1 ;;
      -R)	#|--return
          __ASK_RETURN__="1"
          _ASK_OPTIONS_+=( $1 ) ;;
      -S*)	#|--selectorsort)
          _IS_SORT_="1"
          [[ $1 =~ = ]] && _SELECTOR_SORT_OPT_+=( "${1/-S=/}" ) ;;
      -U) [[ $2 =~ ^[3-9]$ ]] || ERROR "${_FUNCTION_}: Invalid file descriptor \"-U $2\"."
          _ASK_OPTIONS_+="-U $2 "
          shift 1 ;;
      -V)	#|--variable)				# The variable that will contain the response
          _MENU_ANSWER_VARIABLE_="$2"
          shift 1 ;;
      --) shift 1 ; break ;;				# '--' indicates the end of options
      -*) ERROR "${_FUNCTION_}: Invalid option \"$1\"." ;;
       *) break ;;					# No more options
    esac
    shift 1
  done
  (( $# )) || ERROR "No array or arguments found."	# Nothing to do
  unset _INDICES_ _SELECTOR_INDEX_MAP_
  (( _USE_INDEX_ )) && declare -A _SELECTOR_INDEX_MAP_
  unset _MENU_ANSWER_ ${_MENU_ANSWER_VARIABLE_} ${_MENU_ANSWER_VARIABLE_}_IDX ${_MENU_ANSWER_VARIABLE_}_VAL
  if (( $# == 1 )) ; then				# Only ARG1 == the array name containing the menu items
    eval '_ELEMENTS_="${#'$1'[@]}"'
    (( ${_ELEMENTS_} )) || ERROR "The array \"$1\" is empty."	# Nothing to do
    eval '_INDICES_=" ${!'$1'[@]} "'
  else							# ARGS present
    _IS_ARGS_="1"
    _ELEMENTS_="$#"
    _INDICES_=" $(eval echo \{1..$#}) "
    unset _USE_INDEX_					# Option -I doesn't make sense for arguments
    _MENU_TYPE_="-n"
  fi
  [[ ${_INDICES_} =~ [$~\\\"\'{}[]\#] ]] && ERROR "Invalid character(s) in the indices for array \"$1\".\nIndices must only use alphanumeric characters and \"_\". \n"
  (( _IS_SORT_ )) && _ASK_WITH_MENU_SORT_INDICES_ ${_INDICES_}
  _INDICES_=" ${_INDICES_} "
  for _IDX_ in ${_INDICES_} ; do			# Find any empty values
    if (( _IS_ARGS_ )) ; then
      eval '_VALUE_="${'${_IDX_}'}"'
    else
      eval '_VALUE_="${'$1'['${_IDX_}']}"'
    fi
    if [[ ${_VALUE_} =~ ^[[:space:]]*$ ]] ; then
      if (( _IGNORE_EMPTY_VALUES_ )) ; then		# Empty values are not allowed
        eval '_INDICES_="${_INDICES_/ '${_IDX_}' / }"'	# Remove the empty index
        (( _ELEMENTS_-- ))				# Reduce the element count
      fi
      _HAS_EMPTY_VALUES_="1"				# Remember we have some
    fi
  done
  _ASK_WITH_MENU_MK_MM_					# Split the menu into parts
  if (( _MULTI_MENUS_ )) ; then
    # If there is only 1 menu then turn off multi-menus
    (( ${#_MM_ARRAY_[*]} == 1 )) && unset _MULTI_MENUS_ _ONLY_MM_CHOICES_
  else
    _MM_ARRAY_[1]="${#_THE_ARRAY_[*]}"			# Single menu - one part
    unset _ONLY_MM_CHOICES_
  fi
  # Create the menu(s)
  if (( ! ${#_THE_MENU_} )) ; then			# Only create the menus once
    _MM_IDX_="1"
    for _IDX_ in ${_INDICES_} ; do			# Process all the menu items
      (( ++_MENU_POSITION_ ))				# Each line in the menu
      if (( _USE_INDEX_ )) ; then
        _MENU_SELECTOR_="${_IDX_}"			# Use the original index as the menu "selector"
      else
        (( ++_MENU_SELECTOR_ ))				# What is displayed on the menu
      fi
      if (( _MENU_POSITION_ > ${_MM_ARRAY_[_MM_IDX_]:-0} )) ; then	# Create the next menu
        (( _MM_IDX_++ ))
      fi
      _SELECTOR_INDEX_MAP_[${_MENU_SELECTOR_}]="${_IDX_}"	# To locate the index from the selector
      # We must be able to locate the menu position from the menu selector.
      _MENU_CHOICES_[0]+="${_MENU_SELECTOR_} "		# All the choices
      _MENU_CHOICES_[_MM_IDX_]+="${_MENU_SELECTOR_} "	# Each menu's set of choices
      printf -v _MENU_SELECTOR_ "%*s" ${_SELECTOR_LEN_} "${_MENU_SELECTOR_}"	# Align the selectors
      if (( _IS_ARGS_ )) ; then
        if (( _HAS_EMPTY_VALUES_ )) ; then
          eval '[[ ${'${_IDX_}'} =~ ^[[:space:]]*$ ]]'
          (( $? )) && unset _EMPTY_QUOTES_ ||  _EMPTY_QUOTES_='"'
        fi
        eval '_THE_MENU_[_MM_IDX_]+="${_SELECTOR_PRE_}${_MENU_SELECTOR_}${_SELECTOR_POST_}  ${_ELEMENT_PRE_}${_EMPTY_QUOTES_}${'${_IDX_}'}${_EMPTY_QUOTES_}${_ELEMENT_POST_}\n"'
      else
        if (( _HAS_EMPTY_VALUES_ )) ; then
          eval '[[ ${'$1'['${_IDX_}']} =~ ^[[:space:]]*$ ]]'
          (( $? )) && unset _EMPTY_QUOTES_ ||  _EMPTY_QUOTES_='"'
        fi
        eval '_THE_MENU_[_MM_IDX_]+="${_SELECTOR_PRE_}${_MENU_SELECTOR_}${_SELECTOR_POST_}  ${_ELEMENT_PRE_}${_EMPTY_QUOTES_}${'$1'['${_IDX_}']}${_EMPTY_QUOTES_}${_ELEMENT_POST_}\n"'
      fi
    done
  fi
  _MM_IDX_="${ASK_WITH_MENU_NUMBER:=1}"			# Process the menu(s)
  (( _MM_IDX_ < 1 || _MM_IDX_ > ${#_MM_ARRAY_[*]} )) && _MM_IDX_="1"	# Failsafe
  if [[ ${_USE_INDEX_} == 1 ]] ; then
    if [[ ${_INDICES_[0]} =~ ^[0-9\ ]*$ ]] ; then
      _MENU_TYPE_="-n"					# Can use ranges if the indices are digits
      unset _MENU_ANSWER_
    else
      declare -A _MENU_ANSWER_				# Need an associative array
    fi
  fi
  while true ; do
    (( _ONLY_MM_CHOICES_ )) && _MC_IDX_="${_MM_IDX_}" || _MC_IDX_="0"
    # In the following line, the construct: ${_HEADER_:+-H} "${_HEADER_}" is done to preserve quoting.
    _ASK_DOIT_ ${_MENU_TYPE_} -R -V _MENU_ANSWER_ -C "${_MENU_CHOICES_[_MC_IDX_]}" \
        "${_ASK_OPTIONS_[@]}" ${_DEFAULT_:+-D} "${_DEFAULT_}" \
        ${_HEADER_:+-H} "${_HEADER_}" ${_LEGEND_:+-L} "${_LEGEND_}" -- "${_THE_MENU_[_MM_IDX_]%\\n}"
    _ReturnCode_="$?"
    if (( _MULTI_MENUS_ )) ; then
      if (( _ReturnCode_ == _NEXT_ )) ; then		# Display the next menu
        (( _MM_IDX_++ ))
        (( _MM_IDX_ > ${#_MM_ARRAY_[*]} )) && _MM_IDX_="1"
        ASK_WITH_MENU_NUMBER="${_MM_IDX_}"		# Remember the sub-menu displayed
        continue
      elif (( _ReturnCode_ == _PREVIOUS_ )) ; then	# Display the previous menu
        (( _MM_IDX_-- ))
        (( _MM_IDX_ < 1 )) && _MM_IDX_=${#_MM_ARRAY_[*]}
        ASK_WITH_MENU_NUMBER="${_MM_IDX_}"		# Remember the sub-menu displayed
        continue
      fi
    fi
    if (( $_ReturnCode_ > 0 )) ; then			# ==> quit
      eval ${_MENU_ANSWER_VARIABLE_}=\"${_MENU_ANSWER_}\"	# Answer as a scalar
      (( __ASK_RETURN__ )) && return ${_ReturnCode_}
      (( _IS_USAGE_EXIT_ )) && exit ${_ReturnCode_} || return ${_ReturnCode_}
    fi
    break
  done
  if (( ASK_ANSWER_IS_ALL )) ; then			# For multi menu (-MM) "*" or "**" was entered
    if (( ASK_ANSWER_IS_ALL == 2 )) ; then		# Need the index into all menu items
      _MENU_ANSWER_=( ${_MENU_CHOICES_[0]} )
    else
      _MENU_ANSWER_=( ${_MENU_CHOICES_[_MM_IDX_]} )
    fi
  fi
  _VIDX_="-1"						# The index into the answer values
  for _SIDX_ in "${_MENU_ANSWER_[@]}" ; do		# The answer values are the selectors
    (( _VIDX_++ ))
    eval _AIDX_="\${_SELECTOR_INDEX_MAP_[${_SIDX_}]}"	# Get the original array index
    eval ${_MENU_ANSWER_VARIABLE_}[_VIDX_]=\"${_SIDX_}\"
    eval ${_MENU_ANSWER_VARIABLE_}'_IDX[_VIDX_]="'${_AIDX_}'"'
    if (( _IS_ARGS_ )) ; then
      eval ${_MENU_ANSWER_VARIABLE_}'_VAL[_VIDX_]="${'${_AIDX_}'}"'
    else
      eval ${_MENU_ANSWER_VARIABLE_}'_VAL[_VIDX_]="${'$1'['${_AIDX_}']}"'
    fi
  done
  unset _MENU_ANSWER_					# Don't remember this
}

function _ASK_WITH_MENU_MK_MM_() {
  local _EXTRA_ _FROM_ Idx _REMAINDER_ _TO_
  if (( _MULTI_MENUS_ == -1 )) ; then			# We have to calculate the number of menus
    _LINES_=$(( (_LINES_ * _PERCENT_) / 100 ))		# PERCENT of display LINES
    _MULTI_MENUS_="$(( _ELEMENTS_ / _LINES_ ))"		# How many menus
    (( _ELEMENTS_ % _LINES_ )) && ((_MULTI_MENUS_++))	# Any remainder needs 1 more menu
  fi
  _MM_ARRAY_=( "" )					# Dummy 0th element to make array origin 1
  _FROM_="1"						# Start at the beginning
  (( _MULTI_MENUS_ < 1 )) && _MULTI_MENUS_="1"
  _LINES_="$(( _ELEMENTS_ / _MULTI_MENUS_ ))"		# The size of each menu
  _REMAINDER_="$(( _ELEMENTS_ % _MULTI_MENUS_ ))"	# Used to redistrubute extra menu lines
  for (( Idx=1 ; Idx<=_MULTI_MENUS_ ; Idx++ )) ; do
    (( _REMAINDER_-- > 0 )) && _EXTRA_="1" || unset _EXTRA_
    _TO_=$(( _FROM_ + _LINES_  - 1 + _EXTRA_ ))
    _MM_ARRAY_+=( ${_TO_} )
    _FROM_="$((++_TO_))"
  done
  unset _MM_ARRAY_[0]				# Remove dummy 0th element
}

function _ASK_WITH_MENU_SORT_INDICES_() {
  local _OPT_ _EIDX_
  for _EIDX_ in ${!_SELECTOR_SORT_OPT_[*]} ; do		# For each time -S is used
    _OPT_="${_SELECTOR_SORT_OPT_[_EIDX_]}"
    if [[ ${_OPT_} =~ ^- ]] ; then			# I.E. is not a shortcut
      _SELECTOR_SORT_+="${_OPT_} "			# Collect the specific "sort" option
      continue
    fi
    case "${_OPT_,,}" in				# Otherwise parse the shortcuts
      *a*) _SELECTOR_SORT_+="-N "    ;;&		# Normal ASCII sort
      *d*) _SELECTOR_SORT_+="-S -d " ;;&		# Dictionary order sort
      *n*) _SELECTOR_SORT_+="-S -n " ;;&		# Numeric sort
      *r*) _SELECTOR_SORT_+="-S -r " ;;&		# Reverse sort
      *v*) _SELECTOR_SORT_+="-S -V " ;;			# Version sort
*[^adnrv]*) ERROR "for option -SA, SORTOPTION \"${_OPT_}\" contains an invalid shortcut.\nValid shortcuts are: a, d, n, r and v."
           ;;
    esac
  done
  SORT_ARGS -V _INDICES_ ${_SELECTOR_SORT_} "${@}"
}

##________________________________________________________________________________
##
## CLEANUP_SCRIPT - Standard cleanup function.
##   The command 'trap CLEANUP_SCRIPT EXIT' is executed by this function.
##    CLEANUP_SCRIPT un-mounts any filesystems (remembered in
##      ${_MOUNTED_FS_ARRAY_}) mounted by MOUNT_IT.
##    CLEANUP_SCRIPT then removes any names (files and directories) created
##      by TMP_FILE_CREATE in TMP_DIR_CREATE.
##    Before cleaning up, CLEANUP_SCRIPT calls the function
##      CLEANUP_EXTRA_BEFORE, if it is defined, so additional clean-up actions
##      can be before CLEANUP_SCRIPT is executed.
##    After cleaning up, CLEANUP_SCRIPT calls the function
##      CLEANUP_EXTRA_AFTER, if it is defined,
##      so additional clean-up actions can be after CLEANUP_SCRIPT is executed.
##   Set the variable _CLEANUP_ALWAYS_ or call the function CLEANUP_ALWAYS to
##      ensure CLEANUP is run even if testing.
##   If "TESTing", the default is to display the cleanup commands rather
##     than execute them.
function CLEANUP_SCRIPT() {
  if (( _CLEANUP_ALWAYS_ )) ; then
    unset TEST_CMD
    (( _TESTING_ )) && echo -e "CLEANUP commands will execute."
  else
    if (( _TESTING_ )) ; then
      echo -e "CLEANUP commands will not execute"
      TEST_CMD="$( sed 's/:/ CLEANUP_SCRIPT:/'<<<"${TEST_CMD}" )"
    fi
  fi
  type -t CLEANUP_EXTRA_BEFORE >&/dev/null && ${TEST_CMD} CLEANUP_EXTRA_BEFORE	# Execute function CLEANUP_EXTRA_BEFORE if it is defined
  ${TEST_CMD} UMOUNT_IT -A -P "${1:-.*}"		# Un mount everything that wa mounted
  ${TEST_CMD} TMP_FILE_DELETE -A -P "${1:-.*}"		# Delete any temporary files created by TMP_FILE_CREATE
  ${TEST_CMD} TMP_DIR_DELETE -A -P "${1:-.*}"		# Delete any temporary dirs created by TMP_DIR_CREATE
  type -t CLEANUP_EXTRA_AFTER >&/dev/null && ${TEST_CMD} CLEANUP_EXTRA_AFTER	# Execute function CLEANUP_EXTRA_AFTER if it is defined
   _CLEANUP_ALWAYS_="0"
}

function _CLEANUP_INIT_() {
  trap "CLEANUP_SCRIPT $$" EXIT				# run the cleanup function on any exit
  _CLEANUP_ALWAYS_="0"
}
_CLEANUP_INIT_

##________________________________________________________________________________
##
## CLEANUP_ALWAYS - Force CLEANUP even if testing.
##   Sets the variable _CLEANUP_ALWAYS_ to ensure CLEANUP is run even if testing.
function CLEANUP_ALWAYS() {
  _CLEANUP_ALWAYS_="1"
}

##________________________________________________________________________________
##
## COLOR_MAKE - Make (or modify) a variable contaning display colors/styles.
##   Any colors/style value consists of three elements: PRE, STYLE and POST.
##   This function sets the correct values for "echo" or "yad" dialog use.
##   Both require a "RESET" to return all colors/styles back to the defaults.
##     The default variable DEF contains the "RESET" for color/style sequences.
##       E.G.  ${COLORVAR}colored text${DEF}
##   Terminal color/styles are set with ANSI <ESC> sequences. See:
##     https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
##   Color/Styles for a yad dialog box are set with pango markup. See:
##     https://docs.gtk.org/Pango/pango_markup.html
##
##   Usage: COLOR_MAKE [-T] [-F COLOR] [-B COLOR] [-E ESTYLES]... -W COLORVAR
##          COLOR_MAKE -G [-F COLOR] [-B COLOR] [-P PMARKUP]... -W COLORVAR
##          COLOR_MAKE [-G|-T] -R COLORVAR
##   Where:
##     -B COLOR
##        Set the background COLOR.
##     -D Display the contents of the color table used by COLOR_MAKE and return
##     -E ESTYLES
##        Add/set ANSI <ESC> styles ESTYLES. ESTYLES is a space-separated
##          list of ANSI x-term ESC codes. Do not include the "<ESC>[" PRE code
##          or the "m" POST code. Also, don't include foreground or background
##          colors. Use -F and -B instead.
##        This option may be included more than once.
##        Some useful ESTYLE values are:
##          1	set bold mode.
##          2	set dim/faint mode.
##          3	set italic mode.
##          4	set underline mode.
##          5	set blinking mode
##          7	set inverse/reverse mode
##          8	set hidden/invisible mode
##          9	set strikethrough mode.
##        Example:
##          COLOR_MAKE -E "3 4" ItUl
##          echo -e "Text ${ItUl}italic and underlined text${DEF} text."
##     -F COLOR
##        Set the foreground COLOR.
##     -G Make COLORVAR contain PANGO_MARKUP suitable for a "yad" dialog box.
##          yad --text "${COLORVAR}colored text${DEF}"
##     -P PMARKUP
##        Add/set pango markup styles PMARKUP separated by a space. The
##          format for each PMARKUP style is: MARKUP_NAME="MARKUP_VALUE"
##          Don't include foreground or background colors. Use -F and -B instead.
##        This option may be included more than once.
##        Example:
##           COLOR_MAKE -G -P 'style="italic" underline="single"' ItUl
##           yad "Text ${ItUl}italic and underlined text${DEF} text."
##     -R COLORVAR
##        Make COLORVAR a RESET variable to reset the display styles to
##        the default. ${DEF} is the default RESET color variable.
##     -T Make COLORVAR contain ANSI <ESC> sequences suitable for:
##          echo -e "${ESC_ATTRIBS}colored text${DEF}
##        Option -T is the default if neither -G nor -T is specified.
##     -W Issue a warning if duplicate names are encountered when converting a
##        color name to another format. Otherwise the first match will be
##        selected silently, Use this to debug "color" issues.
##     COLORVAR
##        The name of the color variable to be created/modified. The default
##        color variables (see COLOR_SET below) can also be modified.
##     COLOR
##        The possible color values can be expressed as:
##          An X-term index NUM (E.G. 3 for olive):    0 <= NUM <= 255
##          A case independent X-term color name:      olive
##          A 24-bit HEX code in the format:           #808000 or 0x808000
##          3 RGB numbers separated with ";" or ",":   RED;BLUE;GREEN
##          HSL codes are not supported.
##        COLOR is converted to the correct format expected by -T or -G.
##   NOTES:
##     Some error checks are done but error checking is not ubiquitous.
##     The pre-defined color variables are formatted with <ESC> sequences.
##       To change them to pango markup, execute: COLORS_SET -G
##     The following is the default location of the color table used to convert
##       a color code or name to another format. the pathname for COLORFILE is:
##         /usr/local/share/functions.sh/.functions.sh.COLOR_MAKE.ColorTable.txt
##       The file contains a header and 256 lines consisting of five columns:
##          1) The X-term index (code)
##          2) The X-term color name
##          3) The HEX color code
##          4) The RGB color code
##          5) The HSL color code (HSL is not supported by this function)
##     There are several ways to see the color values for any color:
##       1) In konsole (other terminal emulators may not work) type:
##            less $COLORFILE
##          Then hover the mouse over a color name or HEX code (#ff00ff).
##       2) View: https://www.ditig.com/publications/256-colors-cheat-sheet
##            Or: https://ss64.com/bash/syntax-colors.html
##       3) The command "yad --color" displays the HEX value for the color
##          selected.
##     The x-term color index has some duplicate names and HEX codes.
##       To see all the duplicate names execute:
##         sort -k 2,2 "$COLORFILE" | column -td -O 1,3,4,5,2 | uniq -D -f4
##       To see the duplicate HEX codes execute:
##         sort -k 3,3 "$COLORFILE" | column -td -O 1,2,4,5,3 | uniq -D -f4
##     The command "yad --font" displays the selected font name and size
##          description DES to be used in the pango markup: font="DES".
function COLOR_MAKE() {
  local Cdx="3" _COLOR_="X" Gui Idx Result Warning
  if [[ -z ${_COLOR_FILE_} ]] ; then			# Do once
    _COLOR_FILE_="${FUNCTIONS_SH_SHARED_DIR}/.${FUNCTIONS_SH_NAME}.COLOR_MAKE.ColorTable.txt"
    _PRE_G_="<span" _PRE_GF_="fgcolor=\\\"" _PRE_GB_="bgcolor=\\\"" _CLOSE_G_="\\\"" _POST_G_=">" _DEF_G_="</span>"
    _PRE_T_="["   _PRE_TF_="38;5;"        _PRE_TB_="48;5;"        _CLOSE_T_=""     _POST_T_="m" _DEF_T_="[0m"
                _PRE_TF_RGB_="38;2;"    _PRE_TB_RGB_="48;2;"
  fi
  [[ " $* " =~ " -D " ]] && { less -R "${_COLOR_FILE_}" ; return ; }
  [[ " $* " =~ " -W " ]] && Warning="1"			# Pre-scan
  if [[ " $* " =~ " -G " ]] then			# Pre-scan
    Gui=1
    _PRE_="${_PRE_G_}" _PRE_F_="${_PRE_GF_}" _PRE_B_="${_PRE_GB_}" _CLOSE_="${_CLOSE_G_}" _POST_="${_POST_G_}"
    DEF="${_DEF_G_}"
  else
    Gui=0						# Equivalent to -T
    _PRE_="${_PRE_T_}" _PRE_F_="${_PRE_TF_}" _PRE_B_="${_PRE_TB_}" _CLOSE_="${_CLOSE_T_}" _POST_="${_POST_T_}"
    _PRE_F_RGB_="${_PRE_TF_RGB_}"
    _PRE_B_RGB_="${_PRE_TB_RGB_}"
    DEF="${_DEF_T_}"
  fi
  while true ; do
    case "$1" in
      -B) _COLOR_MAKE_VERIFY_COLOR_ "${1}" "${2}"	# Background color
          _COLOR_+=( "${_PRE_B_}${_COLOR_}${_CLOSE_}" )
          shift 2
          ;;
      -E) (( Gui )) && ERROR "COLOR_MAKE: Cannot use x-term <ESC> squences for pango markup."
          _COLOR_+=( ${2} )
          shift 2
          ;;
      -F) _COLOR_MAKE_VERIFY_COLOR_ "${1}" "${2}"	# Foreground color
          _COLOR_[1]="${_PRE_F_}${_COLOR_}${_CLOSE_}"
          shift 2
          ;;
      -G|-T|-W) shift 1					# Skip - already processed
          ;;
      -P) (( ! Gui )) && ERROR "COLOR_MAKE: Cannot use pango markup for x-term <ESC> squences."
          _COLOR_+=( ${2//\"/\\\"} )
          shift 2
          ;;
      -R) eval \${2}=\"\${_DEF_}\"			# Make COLORVAR the "RESET" sequence
          return					# All done
          ;;
      -*) ERROR "COLOR_MAKE: Invalid option \"${1}\"."
          ;;
       *) break						# End of options
         ;;
    esac
  done
  (( Gui )) && Result="${_PRE_} " || Result=""
  unset _COLOR_[0]					# This element used for temporary storage
  for Idx in ${!_COLOR_[*]} ; do
    if (( Gui )) ; then
      Result+="${_COLOR_[Idx]} "
    else
      [[ -n ${_COLOR_[Idx]} ]] && Result+="${_PRE_}${_COLOR_[Idx]}${_POST_}"
    fi
  done
  (( Gui )) && eval ${1}="\"${Result}${_POST_}\"" || eval ${1}="\"${Result}\""
}

function _COLOR_MAKE_VERIFY_COLOR_() {
  local _Color_ Idx="0"
  _COLOR_="${2}"					# Store color in work area (_COLOR_ === _COLOR_[0])
  case "${_COLOR_}" in					# Analyze the color code
    *[,\;]*)						# Might be RGB
      if [[ ${COLOR_} =~ [0-9]{1,3}[,\;][0-9]{1,3}[,\;][0-9]{1,3} ]] ; then
        if (( Gui )) ; then				# GUI - convert RGB to HEX
          local Red Green Blue
          IFS=",;" read Red Green Blue <<<"${_COLOR_}"
          _COLOR_="$( printf "#%.2x%.2x%.2x" ${Red} ${Green} ${Blue} )"
        else						# Use the correct RGB prefix for x-term
          _COLOR_="${_COLOR_//,/;}"			# Use ; as separator
          [[ ${1} == -F ]] && _PRE_F_="${_PRE_F_RGB_}" || _PRE_B_="${_PRE_B_RGB_}"
        fi
        return
      else
        ERROR "COLOR_MAKE: Invalid RGB color specification: \"${_COLOR_}\"."
      fi
      ;;
    [0-9]*)						# Might be an x-term color code
      _Color_=( $(grep "^${_COLOR_} " "${_COLOR_FILE_}" 2>/dev/null) )
      (( $? )) && ERROR "COLOR_MAKE: Invalid color numeric code: \"${2}\"."
      (( Gui )) && _COLOR_="${_Color_[2]}"
      return
      ;;
    0[xX]*)						# HEX as 0x00ff00 or 0X00ff00
      Idx="1"
      ;&
    \#*)						# HEX as #00ff00
      (( Idx++ ))
      [[ ${_COLOR_:Idx} =~ ^[0-9a-f]{6}$ ]] || ERROR "COLOR_MAKE: Invalid color HEX code: \"${_COLOR_}\"."
      if (( Gui )) ; then
        _COLOR_="#${_COLOR_}"				# HEX (only 6 chars) OK for pango markup
      else						# HEX no good for x-term - convert to RGB
        eval _COLOR_="\"\$((16#${_COLOR_:Idx:2}));\$((16#${_COLOR_:Idx+2:2}));\$((16#${_COLOR_:Idx+4:2}))\""
        [[ ${1} == -F ]] && _PRE_F_="${_PRE_F_RGB_}" || _PRE_B_="${_PRE_B_RGB_}"
      fi
      return
      ;;
    [A-Za-z0-9]*)					# Might be a color name
      _Color_=( $(grep -i --color=none " ${_COLOR_} " "${_COLOR_FILE_}" 2>/dev/null) )
      (( $? )) && ERROR "COLOR_MAKE: Invalid x-term color name: \"${_COLOR_}\"."
      if (( ${#_Color_[*]} > 5 && Warning )) ; then
        WARNING "COLOR_MAKE: Found duplicate x-term color name \"${_COLOR_}\":"
        local Len
        Len="${#_Color_[Idx+1]}"
        for (( Idx=0 ; Idx < ${#_Color_[*]} ; Idx=Idx+5 )) ; do
           printf "    %3d  %-*s  %6s  %-14s  %s\n" ${_Color_[Idx+0]} ${Len} ${_Color_[Idx+1]} ${_Color_[Idx+2]} ${_Color_[Idx+3]} ${_Color_[Idx+4]}
        done
        echo -e "Using the first one."
      fi
      (( ! Gui )) && _COLOR_="${_Color_[0]}"
      return
      ;;
    *) ERROR "COLOR_MAKE: Color \"$2\" is not an X-term code/name or HEX/RGB value."
  esac
}

##________________________________________________________________________________
##
## COLORS_DISPLAY - Display default color variables $GRN (green), $RED (red) ...
function COLORS_DISPLAY() {
  if [[ $1 == "-G" ]] ; then
    COLORS_SET -G
    _FONT_="Source Code Pro 14"
    yad --title "Default Color Variables" --width=900 --text "<span font=\"${_FONT_}\" style=\"${_FONT_STYLE_}\" size=\"${_FONT_SIZE_}\" weight=\"${_FONT_WEIGHT_}\">
    BLK=${BLK}BLK${DEF}      WHI=<span bgcolor=\"black\">${WHI}WHI${DEF}</span>
    RED=${RED}RED${DEF}      PUR=${PUR}PUR${DEF}     GLD=${GLD}GLD${DEF}   BLU=${BLU}BLU${DEF}  GRN=${GRN}GRN${DEF}
    YEL=${YEL}YEL${DEF}      ORG=${ORG}ORG${DEF}     PNK=${PNK}PNK${DEF}   LIM=${LIM}LIM${DEF}   UL=${UL}UL${DEF}
    BOLD=${BOLD}BOLD${DEF}    GREP=${GREP}GREP${DEF} \n
  The variable \\\$DEF  resets colors and/or styles to the default.\n\n  ${UL}Example:${DEF}    echo -e \\\"Some text \\\${BLU}colored text\\\${DEF} some more text.\\\" \n  Result:i    Some text ${BLU}colored text${DEF} some more text.</span> "
  else
    COLORS_SET -T
    echo -e "\t    ${UL}Default Color Variables${DEF}"
    echo -e "BLK=[48;5;255m${BLK}BLK${DEF}   RED=${RED}RED${DEF}      PUR=${PUR}PUR${DEF}    GLD=${GLD}GLD${DEF}   BLU=${BLU}BLU${DEF}"
    echo -e "GRN=${GRN}GRN${DEF}   YEL=${YEL}YEL${DEF}      ORG=${ORG}ORG${DEF}    PNK=${PNK}PNK${DEF}   LIM=${LIM}LIM${DEF}"
    echo -e "WHI=${WHI}WHI${DEF}    UL=${UL}UL${DEF}      BOLD=${BOLD}BOLD${DEF}  GREP=${GREP}GREP${DEF}"
    echo -e "\nThe variable \$DEF resets colors and/or styles to the default."
    echo -e "\n\t\t    ${UL}Example${DEF}"
    echo -e "Command: echo -e \"Text \${LIM}colored \${UL}and underlined text\${DEF} some more text."
    echo -e "Result:  Text ${LIM}colored ${UL}and underlined text${DEF} some more text."
  fi
}

##________________________________________________________________________________
##
## COLORS_SET - Set/create the default color variables $GRN (green), $RED (red),
##     $GLD (gold)... E.G. echo -e "${RED}some text displayed in red${DEF}"
##   Usage: COLORS_SET [{ -G[R] | -T[R] }]
##   Where:
##     -G Use pango markup for the default color variables. Suitable for "yad".
##    -GR Force reset of the pango markup color variables
##     -T Use <ESC> sequences for the default color variables. Suitable for
##    -TR Force reset of the <ESC> sequences color variables
##        "echo -e ...". This is the default.
##   The default color variables are:
##     BLK WHI RED PUR GLD BLU GRN YEL ORG PNK LIM WHI UL BOLD GREP
##   Also $DEF resets colors and/or styles to the default.
function COLORS_SET() {
  if [[ ${1:0:2} == -G ]] ; then			# Colors for "yad ..."
    if [[ -z ${_RED_G_} || ${1} == -GR ]] ; then # Only do it once or if forced
      _RED_G_=Red     _PUR_G_=Purple       _GLD_G_=Gold1         _BLU_G_=DodgerBlue1 _GRN_G_=DarkCyan
      _YEL_G_=Yellow1 _ORG_G_=DarkOrange   _PNK_G_=MediumOrchid1 _LIM_G_=Chartreuse1 _GREP_G_=Magenta1
      _BLK_G_=black			   _WHI_G_="White"
      _UL_G_=" underline=\"single\""      _BOLD_G_="weight=\"bold\""
    fi
    export RED="<span fgcolor=\"${_RED_G_}\">"  PUR="<span fgcolor=\"${_PUR_G_}\">"
    export GLD="<span fgcolor=\"${_GLD_G_}\">"  BLU="<span fgcolor=\"${_BLU_G_}\">"
    export GRN="<span fgcolor=\"${_GRN_G_}\">"  YEL="<span fgcolor=\"${_YEL_G_}\">"
    export ORG="<span fgcolor=\"${_ORG_G_}\">"  PNK="<span fgcolor=\"${_PNK_G_}\">"
    export LIM="<span fgcolor=\"${_LIM_G_}\">" GREP="<span fgcolor=\"${_GREP_G_}\">"
    export BLK="<span fgcolor=\"${_BLK_G_}\">"  WHI="<span fgcolor=\"${_WHI_G_}\">"
    export  UL="<span ${_UL_G_}>"              BOLD="<span ${_BOLD_G_}>"
    export DEF="</span>"
  else							# Colors for "echo -e ..."
    if [[ -z ${_RED_T_} || ${1} == -TR ]] ; then # Only do it once or if forced
      _RED_T_=198  _PUR_T_=129 _GLD_T_=220 _BLU_T_=33   _GRN_T_=36
      _YEL_T_=226  _ORG_T_=208 _PNK_T_=207 _LIM_T_=118 _GREP_T_=201
       _UL_T_=4   _BOLD_T_=1   _BLK_T_=0   _WHI_T_=255
    fi
    export RED="[38;5;${_RED_T_}m"  PUR="[38;5;${_PUR_T_}m"
    export GLD="[38;5;${_GLD_T_}m"  BLU="[38;5;${_BLU_T_}m"
    export GRN="[38;5;${_GRN_T_}m"  YEL="[38;5;${_YEL_T_}m"
    export ORG="[38;5;${_ORG_T_}m"  PNK="[38;5;${_PNK_T_}m"
    export LIM="[38;5;${_LIM_T_}m" GREP="[38;5;${_GREP_T_}m"
    export BLK="[38;5;${_BLK_T_}m"  WHI="[38;5;${_WHI_T_}m"
    export  UL="[${_UL_T_}m"       BOLD="[${_BOLD_T_}m"
    export DEF="[0m"
  fi
}

COLORS_SET -GR						# Set the color variables for GUI dialogs
COLORS_SET -TR						# Set the color variables for text dialogs (default).

##________________________________________________________________________________
##
## ENVIRONMENT_DISPLAY - Displays function NAMES or content, or values of variables
##     defined in the current environment.
##   Usage: ENVIRONMENT_DISPLAY { -F | -S | -V } [ NAMES ]
##   Where: -F  Display only the name of functions named by NAMES.
##          -S  Display the source code of functions named by NAMES.
##          -V  Display the values of variables named by NAMES as
##              an assignment NAME="VALUE".
##   Option -V is the default.
##   Each NAME is a grep expression used to display one or more NAMES.
function ENVIRONMENT_DISPLAY() {
  local EC ENVIRON IDX OPTION PATTERN
  if [[ \ ${1}\  =~ \ -[FSV]\  ]] ; then
    if [[ $1 != -V ]] ; then
      [[ $1 == -S ]] && OPTION="-f" || OPTION="-F"
    fi
    shift 1
  fi
  for (( IDX=1 ; IDX <= $# ; IDX++ )) ; do
    eval PATTERN+=\"\$$IDX\|\"
  done
  set -o pipefail
  if [[ ${OPTION} == -f ]] ; then
    while read -u 3 ENVIRON ; do
      declare -p ${OPTION} "${ENVIRON}"
      EC="$((EC+$?))"
    done 3< <( declare -p ${OPTION^^} | cut -f 3 -d " " | grep -v "PATTERN=" | grep -E "${PATTERN%*\|}" )
  else
    declare -p ${OPTION} | cut -f 3 -d " " | grep -v "PATTERN=" | grep -E "${PATTERN%*\|}"
    EC="$?"
  fi
  set +o pipefail
  return "${EC}"
}

##________________________________________________________________________________
##
## ERROR - Simple error reporting with no USAGE message.
##   The message is displayed on stderr.
##   Usage: ERROR [-G] ERRORMESSAGE
##   Where:
##     -G Display ERRORMESSAGE with a GUI dialog box (using yad). The style
##        and font in the dialog box is the same as specified with the last
##        (previous) call to ASK_WITH_GUI otherwise is the default settings.
##        ERROR -G ... is equivalent to ERROR_GUI ....
##   If pango markup is present in ERRORMESSAGE, the option -G is assumed.
function ERROR() {
  set +x						# Turn off bash debugging
  if [[ $1 == "-G" || "$@" =~ "<span " ]] ; then
    _ERROR_WITH_GUI_="1"
    shift 1
  else
    unset _ERROR_WITH_GUI_
  fi
  _ERROR_DOIT_ "$@"
}

function _ERROR_DOIT_() {
  set +x						# Turn off bash debugging
  _ERROR_MESSAGE_="$@"
  if (( _ERROR_WITH_GUI_ || _ASK_WITH_GUI_ )) ; then
    COLORS_SET -G
    ERROR_SET_PREFIX "${_USAGE_ERROR_PREFIX_TEXT_}" "${_USAGE_TRY_PREFIX_TEXT_}"
    yad --fixed --center --nowrap --button=yad-quit:3 --title "ERROR" \
      --text '<span font="'"${_FONT_}"'" style="'${_FONT_STYLE_}'" size="'${_FONT_SIZE_}'" weight="'${_FONT_WEIGHT_}'">'"${_USAGE_ERROR_PREFIX_}""$@"'</span>' # 2>/dev/null
  else
    echo -e "${_USAGE_ERROR_PREFIX_}""$@" 1>&2
  fi
  (( _IS_USAGE_EXIT_ )) && exit 2 || return 2
}

##________________________________________________________________________________
##
## ERROR_GUI - Similar to ERROR but using a GUI interface for the response. All
##   the options to ERROR can be specified. This is equivalent to ERROR -G ...
##   Usage: ERROR_GUI ERRORMESSAGE
function ERROR_GUI() {
  _ERROR_WITH_GUI_="1"
  _ERROR_DOIT_ "$@"
}

##________________________________________________________________________________
##
## ERROR_SCRIPT - This default script executes if an ERR signal is raised and
##   trapped via ERROR_TRAP_SET. Create a function ERROR_SCRIPT to do different
##   things (other than the default of exit or return) on a script error.
function ERROR_SCRIPT() {
  (( _IS_USAGE_EXIT_ )) && exit 2 || return 2
}

##________________________________________________________________________________
##
## ERROR_TRAP_RESET - Reset the ERR trap.
function ERROR_TRAP_RESET() {
  set -o errtrace					# Child commands will inherit the ERR trap
  trap ERR
}

##________________________________________________________________________________
##
## ERROR_TRAP_SET - Trap and execute ERROR_SCRIPT on any script error
##   Redefine the function ERROR_SCRIPT to do different things on a script error
function ERROR_TRAP_SET() {
  set -o errtrace					# Child commands will inherit the ERR trap
  trap ERROR_SCRIPT ERR
}

##________________________________________________________________________________
##
## EXPORT_CLEANUP - Set/Reset everything needed for any child scripts to
##     execute CLEANUP_SCRIPT in the parent.
##   Usage: EXPORT_CLEANUP [ set | unset ]
##   Where: set ==   Export the function and variable names to enable
##                   CLEANUP_SCRIPT in a child process. This is the default.
##          unset == Reset the exported names.
function EXPORT_CLEANUP () {
  if [[ ${1:-set} == set ]]
    then
      declare -g -x -f CLEANUP_SCRIPT CLEANUP_SCRIPT_BEFORE CLEANUP_SCRIPT_AFTER
      declare -g -x -f UMOUNT_IT      REVERSE_ARGS          IS_NUMERIC            _USAGE_CHOICE_  TMP_FILE_DELETE
      declare -g -x    REVERSE_ARGS   _TMP_NAMES_ARRAY_     _MOUNTED_FS_ARRAY_
    else
      declare -g +x -f CLEANUP_SCRIPT CLEANUP_SCRIPT_BEFORE CLEANUP_SCRIPT_AFTER
      declare -g +x -f UMOUNT_IT      REVERSE_ARGS          IS_NUMERIC            _USAGE_CHOICE_  TMP_FILE_DELETE
      declare -g +x    REVERSE_ARGS  _TMP_NAMES_ARRAY_       _MOUNTED_FS_ARRAY_
  fi
 }

##________________________________________________________________________________
##
## FIND_NFS_PATH_FROM_FSTAB - Display all the NFS entries or match one NFS
##     entry in /etc/fstab.
##   Usage:    DISPLAY_NFS_FROM_FSTAB FIELDS [ -V VAR ] [ NFSPATH ]
##   Displays: The first and/or second /etc/fstab fields depending upon FIELDS.
##   Returns:  If a match is made, returns 0, otherwise returns 1.
##             If NFSPATH does not contain a valid (partial) nfs path then
##               the return code is 2 and _ERROR_MESSAGE_ has the error message
##             If more than one match is found the return code is 3.
##   Where:
##     FIELDS This option is required.
##       It can have the format { -1 | -11 | -12 | -2 | -22 }
##       The number(s) after the '-' indicate what field is to be displayed
##         from each matching fstab line. 1 displays the first (device) field
##         and 2 displays the second (mount point) field.
##       The two-numbered options (-11 -12 -22) display two fields.
##     -V VAR
##       Store the fields in array VAR rather than displaying it.
##     NFSPATH makes an attempt to match NFSPATH (or a parent dir of NFSPATH).
##       Otherwise all NFS filesystem entries found in /etc/fstab are displayed.
function FIND_NFS_PATH_FROM_FSTAB () {
  local FSTAB_F1 FSTAB_F2
  local Cmd QueriedDomain Matches Options Rest Sep Var
  _ERROR_MESSAGE_=""
  while true ; do
    case "$1" in
      -1|-11|-12|-2|-22)
          Options=( ${1:1:1} ${1:2:1} )
          shift 1 ;;
      -V) Var="$2" ; unset ${Var} ; shift 2 ;;
       *) break ;;
    esac
  done
  (( $# > 0 )) && Cmd="grep --color=none ^${Domain}:" || Cmd="cat"
  Matches="0"
  if (( $# > 0 )) ; then
    while (( $# > 0 )) ; do
      [[ $1 =~ : ]] || { _ERROR_MESSAGE_="FIND_NFS_PATH_FROM_FSTAB: The path \"$1\" is not a valid (partial) nfs pathname." ; return 2 ; }
      QueriedDomain="$( GET_MATCHING_NFS_DOMAIN_IN_FSTAB -Q ${1%:*} )"
      [[ $? -gt 0 || -z ${QueriedDomain} ]] && { _ERROR_MESSAGE_="FIND_NFS_PATH_FROM_FSTAB: The domain name in \"$1\" is not in \"/etc/fstab\"." ; return 2 ; }
      while read -u 3 FSTAB_F1 FSTAB_F2 Rest ; do
        if [[ ${1} =~ ${FSTAB_F1} || ${1} =~ ${FSTAB_F2} ]] ; then
          _FIND_NFS_PATH_FROM_FSTAB_
          (( Matches++ ))
          shift 1
          continue 2
        fi
      done 3< <( grep --color=none "${QueriedDomain}:.*\snfs[0-9]*\s" /etc/fstab | ${Cmd} )
    done
  else
    _FIND_NFS_PATH_FROM_FSTAB_
  fi
  (( ${Matches} == 0 )) && return 1
  (( ${Matches} == 1 )) && return 0 || return 3
}

# Internal function
function _FIND_NFS_PATH_FROM_FSTAB_ () {
  local Idx
  for Idx in "${Options[@]}" ; do
    [[ -n ${Var} ]] && { eval ${Var}+=\( \"\${FSTAB_F${Idx}}\" \) ; } || eval echo -n \"${Sep}\${FSTAB_F${Idx}}\"
    Sep=" "
  done
}

##________________________________________________________________________________
##
## GET_ARGS - This function, when called in a parent script, does the following:
##     1) It defines acceptable parent script options and arguments.
##     2) When the parent script is invoked, it parses the command line options.
##     3) It generates a manpage-like help (USAGE) message.
##     4) It implements default options (BASEOPT) for help, version and testing.
##
##   Usage: GET_ARGS [ GET_ARGS_DIRECTIVES ] -- "$@"
##
##   Where: GET_ARGS_DIRECTIVES is a list of directives that have two purposes:
##     1) Define acceptable parent script options.
##     2) Define information to be included in the HELP message.
##   Note 1: The string "--" signals the end of the GET_ARGS_DIRECTIVES and is
##    required.
##   Note 2: The string "$@" passes the options/nonoptions, specified when
##    the parent script is executed, to GET_ARGS for parsing. Ir is required.
##
##   When invoked, GET_ARGS uses the GET_ARGS_DIRECTIVES to generate a call to
##     the Linux getopt command. getopt parses the parent shell command-line
##     options ("$@" following the "--"). It then creates variables, related
##     to the command-line options used, that can subsequently be tested by
##     the parent script. When the parent script is invoked, any long option
##     (one with more than one character: i.e. --file) may be abbreviated (per
##     getopt) as long as the abbreviation is unique.
##   The options/nonoptions within "$@" can contain the argument "--". This
##     informs GET_ARGS that the remaining arguments are nonoptions even if
##     they begin with a "-". The remaining arguments are parsed as arguments.
##   In conjunction with GET_ARGS, the function IS_EXCLUSIVE can be used to
##     define and verify valid combinations of the parent script options.
##
##   Because the list of GET_ARGS_DIRECTIVES is usually long, it is suggested the
##     bash line continuation character "\" be used as follows:
##
##       GET_ARGS \
##         GET_ARGS_DIRECTIVE_1 \
##         GET_ARGS_DIRECTIVE_2 \
##         ... \
##         -- "$@"
##
##   SUMMARY OF GET_ARGS_DIRECTIVES THAT DEFINE VALID PARENT SCRIPT OPTIONS
##     --Opt[ion]_D[efinition] [FCLIST] OPTLIST
##         --Des[cription]_D[efinition] OPTION_DESCRIPTION
##     --Hid[den]_D[efinition] [FCLIST] OPTLIST
##         --Des[cription]_D[efinition] OPTION_DESCRIPTION
##     --Act[ion]_D[efinition] [FCLIST] OPTLIST [-K ACTKEY] [-O] [-A] [-I ACTINFO]
##         --Des[cription]_D[efinition] OPTION_DESCRIPTION
##     --Act[ion]_D[efinition] [FCLIST] "" [-k ACTKEY] [-O] [-A] [-I ACTINFO]
##     --Args_No[ne] [FCLIST]
##     --Args_Re[quired] [FCLIST] N[@KEYWORD]
##     --Args_Mi[nimum] [FCLIST] N[@KEYWORD]
##     --Args_Ma[ximum] [FCLIST] N[@KEYWORD]
##     --Args_Op[tional] [FCLIST] N[@KEYWORD]
##     --Args_Ar[ray] [FCLIST] [@KEYWORD]
##     --Args_Li[st] [FCLIST] [NUM]@"ARGLIST"
##     --Opts_Re[quired] [FCLIST] N[@KEYWORD]
##     --Opts_Mi[nimum] [FCLIST] N[@KEYWORD]
##     --Opts_No[ne] [FCLIST]
##
##     GET_ARGS_DIRECTIVES --Opt_D, --Hid_D and the first --Act_D must always
##       be followed by --Des_D DESCRIPTION
##
##   SUMMARY OF GET_ARGS_DIRECTIVES THAT AUGMENT THE HELP DISPLAY
##     These GET_ARGS_DIRECTIVES are parsed on a pre-scan.
##       --Filter FC FILTERDESCRIPTION  | --Act[ion] ACTION
##       --Bas[ic]_O[ption] MODINFO     | --Hea[ding] [N@]HEADING
##       --Deb[ug] [SIMULATEHELP]       | --Var[iables] VARLIST
##       --Sec[tionTitle] SECTION "NEWTITLE"
##       --Noc[olors]
##     These are parsed for content and errors.
##       --Cmd_D[escription] [FCLIST] CMD_DESCRIPTION
##       --Tit[le] [FCLIST] [-N] SECTION TITLE
##       --Par[agraph] [FCLIST] [-N] SECTION PARAGRAPH
##       --Cop[yright] [FCLIST] [COPYRIGHT]
##       --Whe[re] [FCLIST] WHERE          | --Inf[o] [FCLIST] INFORMATION
##       --Exa[mple] [FCLIST] EXAMPLE      | --Fil[es] [FCLIST] FILES
##       --Aut[hors] [FCLIST] AUTHORS      | --Bug[s] [FCLIST] BUGS
##       --See[Also] [FCLIST] SEEALSOINFO  | --Not[e] [FCLIST] NOTE
##       --Exp[andTabstops] [-L] ETAB      | --Bri[efTabstops] [-L] BTAB
##       --Com[pactTabstops] [-L] CTAB     | --Tab[stops] [-L] TTAB
##       --Pag[er] PAGER                   | --Def[ault] EBC [[-L] DTAB]
##
##     All GET_ARGS_DIRECTIVES can be abbreviated to "--" followed by three
##       characters except:
##         "--Filter" must be spelled exactly.
##       The following must begin with the first 5 characters and then contain
##         an "_" followed by the uppercase letter "D" (or "O" for --Bas_O):
##           --Opt_D --Act_D --Hid_D --Des_D --Cmd_D --Bas_O
##       The following two directives must start with the first 7 characters
##         followed by at least two more characters:
##           --Args_.. --Opts_..
##
##   ##############################################################################
##   # IMPLEMENTATION RESTRICTIONS                                                #
##   # Be aware the 3-character sequence single-quote space single-quote (' ')    #
##   #   within any GET_ARGS_DIRECTIVE argument may give indeterminant results.   #
##   # Do not begin any GET_ARGS_DIRECTIVE argument with 2 dashes followed by an  #
##   #   uppercase character (--[A-Z]]. It will be parsed as a GET_ARGS_DIRECTIVE.#
##   # Use of the 4-characters sequence space dash dash space ( -- ) within any   #
##   #   GET_ARGS_DIRECTIVE argument may prematurely terminate parsing of the     #
##   #   remaining GET_ARGS_DIRECTIVES.                                           #
##   ##############################################################################
##
##   HELP DISPLAY
##     GET_ARGS also uses GET_ARGS_DIRECTIVES to create/display HELP (a help page).
##       This is displayed by invoking the parent script with the basic options:
##           -h[<MOD>], -H[<MOD>], --help=[<MOD>] or --HELP=[<MOD>]
##       The optional <MOD> has two formats: <HM> or <FC>[<HM>].
##         <HM> modifies the help display: b=brief, c=compact or e=expanded.
##         <FC> is only used if the GET_ARGS_DIRECTIVE --Filter is used.
##       The uppercase basic options -H and --HELP display help using "less -RS".
##       The help message is divided into multiple sections each with a header.
##         The sections (optional ones are [...]), in order by row, are:
##           HEADER            [mypurpose]        PURPOSE          SYNOPSIS
##           [mysynopsis]      [CMD DESCRIPTION]  [ACTION SYNTAX]  [OPTIONS]
##           [mybasicoptions]  BASIC OPTIONS      [WHERE]          [INFORMATION]
##           [EXAMPLES]        [FILES]            [AUTHORS]        [BUGS]
##           [COPYRIGHT]       [SEE ALSO]         [mynote]         [NOTE]
##       Each section with an UPPERCASE name has that name as a header/title.
##         The my... sections allow text insertion before/after automatically
##         generated text.
##       The optional sections are created when the appropriate GET_ARGS_DIRECTIVE
##         is used. E.G. The WHERE section is created if --Where is used.
##       GET_ARGS_DIRECTIVES --Title and --Para can be used to define extra text
##         in any of the sections. Some sections are generated automatically
##         so using --Title and --Para for the my... sections provides a method
##         to add text at the beginning (or end for mypurpose) of those sections.
##     The lines displayed by HELP are automatically folded to fit into the
##       terminal width. The folding attempts to maintain the indentation of the
##       preceding line. GET_ARGS_DIRECTIVES --Compact and --TabStops can be used
##       to modify the default indentation. Also a help modifier <HM> of b (brief),
##       c (compact) or e (expand) can be used to temporarily modify the format.
##     NOTE: For any GET_ARGS_DIRECTIVE that adds text to HELP, the text can
##       contain "\t" to insert a tab, "\n" to insert a newline and ANSI escape
##       sequences for colored and highlighted text.
##     NOTE: Two variables SCRIPT_PURPOSE and VERSION should be defined by the
##       parent script before the GET_ARGS function is called as they are
##       displayed in the appropriate HELP section.
##       The value of SCRIPT_PURPOSE is inserted into the section PURPOSE.
##       The value of VERSION is displayed by the basic options -v or --version.
##     The help display also has highlighting Capability. See HIGHLIGHTING below.
##
##   PARENT SCRIPT OPTION DIRECTIVES
##     --Opt[ion]_D[efinition] [FCLIST] OPTLIST
##         --Des[cription]_D[efinition] OPTION_DESCRIPTION
##       Each --Opt_D defines a parent script option that can be used when the
##         script is executed. Every "--Opt_D [FCLIST] OPTLIST" must immediately be
##         followed by "--Des_D OPTION_DESCRIPTION". OPTION_DESCRIPTION is used
##         in the help message to describe the options defined by --Opt_D.
##       OPTION_DESCRIPTION normally should not contain newlines as it is folded
##         and indented to fit within the terminal width. Spaces, newlines, \t
##         and \n can be used to force formatting.
##       Each Opt_D and Des_D pair defines an acceptable invoking script option
##         and a description of the option for the help message.
##       Any number of --Opt_D --Des_D pairs may be defined.
##
##       FCLIST is a set of single character filter <codes> FCi that apply to
##           --Opt_D, --Hid_D or --Act_D and to some GET_ARGS_DIRECTIVES below.
##         Each FCi used must be defined by a corresponding "--Filter FC" option
##           (see below).
##         FCLIST can contain any number of valid FCi (no spaces). When help is
##           invoked with an <FC> of FCi all the paragraphs are displayed that
##           have the corresponding FCi in FCLIST. Sections HEADIING, PURPOSE,
##           mypurpose, mysynopsis and SYNOPSIS are always displayed.
##         For all the GET_ARGS_DIRECTIVES employing the optional [FCLIST], it is
##           required if the GET_ARGS_DIRECTIVE --Filter is used. Otherwise the
##           optional [FCLIST] must NOT be used.
##         A special FCi of "a" can be used display the complete help text.
##           An empty FCLIST ("") implies an FCLIST of "a". "a" can be redefined
##           by --Bas_O (see below)
##
##       OPTLIST Is a space separated list of one or more related script options
##         OPT1 OPT2... Each OPTi in the list must NOT begin with "-" but may
##           contain dashes. Each OPTi can contain any visible character except
##           whitespace. No single character OPTi can be defined as ":" or "?".
##           Special characters must be escaped or quoted.
##         If any OPTi is a single character it is a short option ("p" == "-p").
##           Otherwise it is a long option ("list" == "--list").
##         If any OPTi is followed by a ":", the option requires a VALUE. If used,
##           ":" must follow every OPTi in the OPTLIST.
##         If any OPTi is followed by "::", the option has an optional VALUE. If
##           used, "::" must follow every OPTi in the OPTLIST.
##             E.G. --Opt_D "l:: list-format::" enables the shell options "-l" or
##                  "-lVALUE" or "--list-format" or "--list-format=VALUE".
##         If OPTLIST begins with a "*" the OPTi may appear more than once at
##           parent script invocation. Otherwise multiple occurences of the
##           options OPTi at parent script invocation is an error.
##         If OPTLIST ends with "@KEYWORD" then, in the HELP message, the
##           characters of KEYWORD replace the placeholder "VALUE" for options
##           that have an (optional) argument (OPTi: or OPTi::).
##         The first OPTi in OPTLIST (OPT1) is converted into a bash variable
##           with a prefix of "Opt_" and all non alphanumeric characters are
##           converted to underscores. This can cause a conflict. For example:
##           --Opt_D "?" and --Opt_D "+" both create the variable Opt__. GET_ARGS
##           does not check for this. To avoid this, and to still be able to use
##           -? and -+ in your parent script, use the definitions:
##              --Opt_D "question ? and" --Opt_D "plus +"
##           The variables Opt_plus and Opt_question are created and you can use
##           the options -? and -+ when invoking the parent script.
##         The variables Opt_OPT1 and Opt_OPT1_Val (where "OPT1" is replaced by
##           the first option in OPTLIST) are unset by GET_ARGS when parsing
##           GET_ARGS_DIRECTIVES. When parsing the parent script options, the
##           value of the option variable Opt_OPT1 is set to the number of times
##           that option is used. If : or :: follows OPTi, the array Opt_OPT1_Val
##           is set to the values of the option.
##         If OPT1 contains any character other than alphanumeric or underscore,
##           the characters are converted to "_" when creating the corresponding
##           bash variable. E.G. For an OPTLIST
##           of "long-opt:", using --long-opt at script invocation creates the
##           variable names "Opt_long_opt" and "Opt_long_opt_Val"..
##         If an option has or requires a VALUE, the Opt_OPT1_Val variable is a
##           zero-based array containing one element for each similar OPT1 option
##           encountered. E.G. ${Opt_OPTi_Val[0], ${Opt_OPTi_Val[1]} ...
##           and Opt_OPT1 contains the number of elements in the array.
##         After invoking GET_ARGS, the parent script can test if any single
##           OPTi has been specified on the command line with:
##             if (( Opt_OPT1 )) ; then ...
##
##       GET_ARGS creates a variable "Opts_All" which contains a space separated
##         list of all options used (in that order but no values) at parent script
##         invocation. Only the OPT1 option is used in the list. The remaining
##         OPTi can be accessed with ${Alt_Opts["${OPT1}"]}
##         If OPTLIST begins with a "*" then Opts_All will contain each occurence
##         of OPTi as it is encountered in the calling script.
##           EXAMPLE: CMD is invoked as:  CMD -x -YYY -z aaa -z bbb -z ccc
##           To parse the options used in the order they were specified, use:
##             for OPT in ${Opts_All} ; do
##               case "${OPT}" in
##                 -x) $Opt_x_Val ... ;;
##               -YYY) $Opt_YYY_Val ... ;;
##                 -z) ${Opt_z_Val[i]} ... ;;
##              esac ; done
##           To test a single option use:
##             (( Opt_YYY )) && ...
##             (( ! Opt_x )) && ...
##             for (( Idx=0 ; Idx<Opt_z ; Idx++ )) ; do
##               MYVAL=${Opt_x_Val{Idx]}
##             done
##
##       GET_ARGS creates an associative array Alt_Opts that, for each OPTLIST,
##         contains a list of each OPTi in that OPTLIST (with "-" or "--" as
##         appropriate). The array reference: ${Alt_Opts["${OPT1_VARNAME}"]} or
##         ${Alt_Opts["-OPT1"]} (one or two "-") expands to the list. This array
##         can be used by any shell that calls GET_ARGS to programatically
##         determine the set of shell options defined by each "--Opt_D ...".
##       GET_ARGS also creates an associative array Opts_Alt that, for each OPTi,
##         contains OPT1. It provides a cross reference to locate OPT1 from
##         any OPTi. For example:
##             The GET_ARGS argument:         --Opt_D "x extra X"
##             Creates the array element:     Alt_Opts["Opt_x"}=" -x --extra -X "
##             And the array element:         Alt_Opts["-x"}=" -x --extra -X "
##             And the array elements         Opts_Alt["-<X>"]=" -x "
##             So:
##               ${Alt_Opts["Opt_x"]} expands to : " -x --extra -X "
##               ${Alt_Opts["-x"]} expands to: " -x --extra -X "
##               ${Opts_Alt["-x"]} expands to: " -x "
##               ${Opts_Alt["--extra"]} expands to: " -x "
##               ${Opts_Alt["-X"]} expands to: " -x "
##
##
##     --Des[cription]_D[efinition] OPTION_DESCRIPTION
##         This GET_ARGS_DIRECTIVE must immediately follow --Opt_D, --Hid_D or
##         (optionally) --Act_D. OPTION_DESCRIPTION explains the meaning of the
##         previous GET_ARGS_DIRECTIVE. It is displayed in the HELP message.
##         Use \n and \t within the OPTION_DESCRIPTION to create additional
##         paragraphs. Or immediately follow the --Des_D with one or more --Para
##         GET_ARGS_DIRECTIVE.
##       OPTION_DESCRIPTION in any of the GET_ARGS_DIRECTIVES can contain the
##         escape sequences available in the "echo" command or any ANSI character
##         color or or highlighting sequences.
##
##       EXAMPLES
##         For the following examples --Des_D "OPTION_DESCRIPTION" has been left
##         out for clarity.
##
##         EXAMPLE: If CMD.sh contains the line:
##             GET_ARGS --Opt_D "a all" --Opt_D "file: f:" --Opt_D "*n: N: new:"
##           The command line:
##             CMD.sh --all -n ABC -f FILE1 --new=def -Nabc
##           GET_ARGS generates:
##             Opts_All="-a -n --file -n -n"
##             Opt_a="1" Opt_file="1" Opt_file_Val="FILE1"
##             Opt_n="3" and an array Opt_n_Val=( ABC def abc )
##             The associative array Alt_Opts with values:
##                     Alt_Opts["-a"]=" -a --all "
##                  Alt_Opts["Opt_a"]=" -a --all "
##                 Alt_Opts["--file"]=" --file -f "
##               Alt_Opts["Opt_file"]=" --file -f "
##                     Alt_Opts["-n"]=" -n -N --new "
##                  Alt_Opts["Opt_n"]=" -n -N --new "
##             And the associative array Opts_Alt indexed by all the OPTi.
##                     Opts_Alt["-a"]=" -a "
##                   Opts_Alt["-all"]=" -a "
##                 Opts_Alt["--file"]=" --file "
##                     Opts_Alt["-f"]=" --file "
##                     Opts_Alt["-n"]=" -n "
##                     Opts_Alt["-N"]=" -n "
##                   Opts_Alt["-new"]=" -n "
##
##         EXAMPLE: If CMD.sh contains the line:
##             GET_ARGS --Opt_D "*d: directory:"
##           Then the following command is valid:
##             CMD.sh -d Adir --directory Bdir -d Cdir
##
##     --Act[ion]_D[efinition] [FCLIST] OPTLIST [-K ACTKEY] [-O] [-A] [-I ACTINFO ]
##          --Des[cription]_D[efinition] OPTION_DESCRIPTION
##     --Act[ion]_D[efinition] [FCLIST] "" [-K ACTKEY] [-O] [-A] [ -I ACTINFO ]
##       Each --Act_D describes alternate variations of command syntax.
##         It creates a section 'ACTION SYNTAX' with the following format:
##           CMD [ACTKEY] [{-Opt_1|--Opt_2...}] [OPTIONS] [ARGs] [ACTINFO]
##         A following --Des_D is required unless OPTLIST is empty.
##           However OPTLIST is required, even if empty.
##       -K ACTKEY
##         Create a list of action keys. Then, when the parent script is invoked,
##         the first non-option argument (ARG1) must match a key in the list.
##         A variable Act_Key is created with the key as the value. ARG1 is
##         removed and the argument count is decremented. No match generates an
##         error. ACTKEY is included in the generated ACTION description
##         immediately following the parent script name and it is highlighted.
##       ACTKEY acts the same as seen in 'btrfs' syntax: "btrfs filesystem ..."
##         If -K ACTKEY is used, it must be used in every --Act_D. An empty
##         ACTKEY ("") is valid.
##       If OPTLIST is not empty, OPTLIST (see above) is converted from a
##         space/comma separated list to a "choose-from" option list.
##         like '{-Opt_1|--Opt_2...}' in the ACTION description.
##         Also a GET_ARGS_DIRECTIVE '--Opt_D [FCLIST] OPTLIST' is automatically
##         generated as in --Opt_D above. In this case --Act_D MUST be followed
##         by a '--Des_D OPTION_DESCRIPTION'.
##       -O Include the string '[ OPTIONS ]' in the action description.
##       -A If any ARGs have been defined (see '--Args_...' below), the string
##          '[ ARGs ]' is included in the ACTION description.
##       -I ACTINFO
##          Include 'ACTINFO' following the ACTION description. ACTINFO is
##          free-form input displayed at the end of the ACTION description line.
##          If ACTINFO contains spaces it must be enclosed in quotes.
##          It is suggested that ACTINFO starts with "# " to simulate a comment.
##          The ACTINFO display may be continued on the next line using '\n' and
##          may contain tab (\t) characters as well.
##       -C ACTCOMMENT
##          Like -I but ACTCOMMENT is preceded by "# ".
##       Any number of '--Act_D ... [--Des_D]' may be defined. If --Act_D is
##         used it is suggested that --Action (see below) be used as well.
##       Neither ACTKEY nor ACTINFO can start with a "-".
##     --Hid[den]_D[efinition] [FCLIST] OPTLIST --Des_D OPTION_DESCRIPTION
##       This is a special case of -Opt_D that defines a script option which,
##       along with OPTION_DESCRIPTION, is not displayed in the help message.
##       A script can call another script using its --Hid_D option to do a
##       script-related action not normally done by a user.
##       Note: The --Des_D OPTION_DESCRIPTION is still required.
##     GET_ARGS_DIRECTIVES --Opt_D, --Hid_D and --Act_D may be intermixed.
##
##     EXAMPLE: The GET_ARGS_DIRECTIVE:
##       --Act_D "a all" -A copy -O -I "# Will copy..."
##          --Des_D "-a|--all will cause the copy action to..."
##       Displays the ACTION:
##          CMD copy {-a|--all} [OPTIONS]       # Will copy...
##       And also generates:
##          --Opt_D "a all" --Des_D "-a|--all will cause the copy action to..."
##
##   BASIC OPTIONS
##     GET_ARGS implements the following parent script basic options by default.
##       -h[<FC>][<HM>] | --help[=[<FC>][<HM>]]
##         Display the generated help message (posibly filtered by <FC>).
##       -H[<FC>][<HM>] | --HELP[=[<FC>][<HM>]]
##         Display the generated help message (posibly filtered by <FC>) with
##         "less -S" as a screen pager.
##       -t[NOCLEANUP] | --test[=NOCLEANUP]
##         Implement script testing. Script commands using "${TEST_CMD} ..." are
##         not executed but are displayed. Any clean-up scripts are executed
##         unless the value of NOCLEANUP is not empty.
##         See TEST_RESET and TEST_SET below.
##       -v | --version
##         The contents of the variable SCRIPT_VERSION are displayed and the
##         script exits. SCRIPT_VERSION must be defined in the calling script
##         before GET_ARGS is called.
##       The mnemonic for any basic option can be changed with --Bas_O.
##         See below.
##     FILTERED HELP: <FC>
##       If the GET_ARGS_DIRECTIVE "--Filter" is used, only the paragraphs defined
##       with a filter code matching <FC> are displayed. If the GET_ARGS_DIRECTIVE
##       "--Filter" is not used, <FC> must not be used.
##     BRIEF, COMPACT or EXPAND HELP: <HM>
##       A <HM> of "b" can be used to display brief help where only the
##         sections HEADING, PURPOSE, mypurpose, mysynopsis , SYNOPSIS, OPTIONS,
##         BASIC OPTIONS and mybasicoptions are displayed. All text is displayed
##         as one line with "less" iven if HELP is requested without "less"..
##       A <HM> of "c" compresses or "e" expands the display.
##       The three mnemonics for <HM> (b, c and e) can be changed with --Base_O.
##
##   MODIFYING A BASIC OPTION
##       --Bas[ic]_O[ption] BASEOPT=NEWOPT
##       --Bas[ic]_O[ption] -D BASEOPT
##       --Bas[ic]_O[ption] ALLOPT=NEWALLOPT[@ALLMSG]
##       --Bas[ic]_O[ption] MODOPT=NEWMODOPT[@MODMSG]
##     This GET_ARGS_DIRECTIVE is used to redefine a default basic option so
##       the default basic option can be used as a regular option and NEWOPT
##       is used for the basic option.
##     BASEOPT, ALLOPT or MODOPT is the basic option to be modified.
##       They collectively known as OLDOPT.
##     Valid BASEOPT are:
##         h help H HELP t test v version
##     NEWOPT Is the redefined option for BASEOPT. It can consist of any
##       alphanumeric characters, '-' and '_' but cannot start with "-".
##     Use of "-D BASEOPT" nullifies the use of that BASEOPT (as opposed to
##       redefining it) so it can used as a regular option. Note: If both the
##       short and the long BASEOPT are redefined (e.g. "v" and "version")
##       then that default basic option is not available to the parent script.
##     ALLOPT Can be "a" or "all" which redefines the default <FilterFC>
##       of "a" used to display all (filtered and un-filtered) HELP lines.
##     ALLMSG If used, replaces the default filter "all" message of:
##              All - display all help information.
##     MODOPT Can be 'b', 'brief', 'c', 'compact', 'e' or 'expand'. This
##       redefines the default help modifier <HM>.
##     MODMSG If used, replaces the default filter message of:
##              BRIEF   = Brief - display summarized help.
##              COMPACT = Compact - remove blank lines.
##              EXPAND  = Expand - include blank lines.
##     Do not include any newlines (\n or <NL>) in ALLMSG or MODMSG.
##     If OLDOPT is one character only the first character of NEWOPT is used.
##       However NEWALLOPT and NEWMODOPT must be a single alphanumeric character.
##     EXAMPLE:
##       A PARENT_SCRIPT has GET_ARGS that contains: '--Bas_O "h=m"'
##         EXECUTING: PARENT_SCRIPT -m
##         RESULT:    GET_ARGS will display HELP information.
##       A PARENT_SCRIPT has GET_ARGS that contains: '--Bas_O -D h'
##         EXECUTING: PARENT_SCRIPT -h
##         RESULT:    GET_ARGS will display an "invalid option" error.
##
##   HELP FILTER DIRECTIVE
##     --Filter FC FILTERDESCRIPTION
##       You can filter the output of the HELP message with the "--Filter"
##         GET_ARGS_DIRECTIVE. A filtered help message is then created.
##       FC is a single alphanumeric character.
##       FILTERDESCRIPTION is the text that describes the filter to be applied.
##         E.G. --Filter m "Display the management options"
##       A default (reserved) FC of "a" is predefined to display all the HELP
##         information. This FC can be modified by --Bas_O.
##       FC "a" is reserved and cannot be used unless modified by --Bas_O.
##       The --Filter GET_ARGS_DIRECTIVE may be used multiple times to define
##         different filters. Most GET_ARGS_DIRECTIVES have an optional FCLIST.
##       If the --Filter GET_ARGS_DIRECTIVE is used, then FCLIST is required.
##       If the --Filter GET_ARGS_DIRECTIVE is not used, Then FCLIST cannot
##         be specified.
##       Use of --Filter causes the invoking script options -h, -H, --help and
##         --HELP to require an affitional argument <FC>. The <FC> is then used
##         to display the paragraphs of the help message that correspond to <FC>.
##       If, in the invoking script, help is requested without <code>, a legend,
##         created from the --Filter GET_ARGS_DIRECTIVE arguments, is displayed.
##
##   ARGUMENT DIRECTIVES
##     These set requirements or restrictions on argument counts. In the following
##       the value N must be a positive integer greater than zero.
##     If no --Args_... GET_ARGS_DIRECTIVE is used then no arguments can be
##       specified when the parent script in invoked.
##     --Args_No[ne] [FCLIST]
##       No arguments. Generates an error if any non-option arguments are
##       specified. This is the default if no --Arg_... GET_ARGS_DIRECTIVE is
##       defined.
##     --Args_Re[quired] [FCLIST] N[@KEYWORD]
##       Required arguments = N. Generates an error if the number of ARGS at
##       invocation of the script is not N.
##     --Args_Mi[nimum] [FCLIST] N[@KEYWORD]
##       Minimum arguments = N. Generates an error if the number of ARGS at
##       invocation of the script is less than N.
##     --Args_Ma[ximum] [FCLIST] N[@KEYWORD]
##       Maximum arguments = N. Generates an error if the number of ARGS at
##       invocation of the script is greater than N.
##     --Args_Op[tional] [FCLIST] N[@KEYWORD]
##       Optional arguments = N. Generates an error if the number of ARGS at
##         invocation of the script is not N or zero.
##       If N is zero then all ARGS are optional (zero or any number of args
##         are accepted). This is equivalent to --Args_Array.
##     --Args_Ar[ray] [FCLIST] [@KEYWORD]
##       Zero or more arguments are processed. This is NOT equivalent to not
##       using any --Arg_... GET_ARGS_DIRECTIVES.
##     --Args_Li[st] [FCLIST] [NUM]@"ARGLIST"
##       This GET_ARGS_DIRECTIVE can be used if the arguments to the parent script
##         are not all the same type. Parent script arguments are expected as
##         specified by ARGLIST but most argument verification must be done by
##         the parent script.
##       ARGLIST is displayed in the help syntax section as-is with no formating.
##         I.E. GET_ARGS doesn't add the syntax characters: { | } [ ] ...
##         No argument count checking is done by GET_ARGS unless NUM is specified.
##       If NUM is present, GET_ARGS will verify the argument count and a message
##         will be displayed in the NOTE section of the HELP display.
##       The format of NUM is [N1][{+|=}][N2] and is interpreted as follows:
##         N1 and N2 are integers > 0.
##           NUM         MESSAGE
##           N1       Exactly N1 arguments are required.
##           N1=      Synonym for "N1".
##           N1+      At least N1 arguments are required.
##           N1=N2    N1 args are required and zero or N2 are optional.
##           N1+N2    N1 args are required and up to N2 more are optional.
##           =        No arguments may be specified.
##           +        No arguments are required, all arguments are optional
##           =N2      No arguments are required, zero or N2 args are optional.
##           +N2      No arguments are required, up to N2 args are optional.
##       EXAMPLE:   --Args_List 2+2@"DIRECTORY INFILE [OUTFILE1 [OUTFILE2]]"
##         GET_ARGS will verify if either 2, 3 or 4 arguments are present.
##       EXAMPLE:   --Args_List 2=2@"DIRECTORY INFILE [OUTFILE1 OUTFILE2]"
##         GET_ARGS will verify if either 2 or 4 arguments are present.
##
##     All arguments are placed in the array Args[*] (origin 1) in the order
##       encountered at parent script invocation.
##     Note: --Args_None, --Args_Req, --Args_Min, --Args_Max, --Args_Opt,
##           --Args_Array and --Args_List are mutually exclusive.
##     If @KEYWORD is included then, in the SYNTAX section of the HELP message,
##       the characters of KEYWORD replace the placeholder "ARG". Except for
##       --Args_List, KEYWORD must not contain any whitespace characters.
##
##     EXAMPLE: CMD.sh contains the line (--Des_D "..." is missing for clarity):
##         GET_ARGS --Args_None --Opt_D "print-it p" --Opt_D "f: format:" -- "$@"
##       This command line parses error free:            CMD.sh -p --format=long
##       And the following variable assignments are made:
##           Opt_print_it="1"; Opt_f"1" ; Opt_f_Val="long"
##       But this command line creates an error message: CMD.sh file1
##
##     EXAMPLE: If CMD.sh contains the line:
##         GET_ARGS --Args_Array -- "$@ "
##       Executing the following:          CMD.sh file1 file2
##       Creates the array assignments:    Args[1]="file1" ; Args[2]="file2"
##
##   OPTION DIRECTIVES
##     These set requirements or restrictions on option counts. In the following
##       the value N must be a positive integer grreater than zero.
##     --Opts_Mi[nimum] [FCLIST] N[@KEYWORD]
##       Minimum options is N. Generates an error if the number of options at
##       invocation of the parent script is less than N.
##     --Opts_Re[quired] [FCLIST] N[@KEYWORD]
##       Required options is N. Generates an error if the number of options at
##         invocation of the script is not N.
##     --Opts_No[ne] [FCLIST]
##       Signals GET_ARGS to treat all parent script "words" on the command line
##         as arguments even if they start with a "-". However, if the first
##         parent script word is a valid basic option, then that option is
##         processed normally and the remaining parent script words are treated
##         as arguments.
##       The number of parent script arguments expected should be defined with
##         the GET_ARGS_DIRECTIVE: --Args_...
##       With this directive, no --Opt_D, --Hid_D, --Act_D or --Des_D is allowed.
##     If @KEYWORD is included then, in the SYNTAX section of the HELP message,
##       the characters of KEYWORD replace the placeholder "OPTION". KEYWORD
##       must not contain any whitespace characters.
##     GET_ARGS_DIRECTIVES --Opts_Min and --Opts_Req are mutually exclusive.
##
##   SECTIONS AND FREE-FORM INFORMATION
##     The HELP display sections are created automatically by GET_ARGS_DIRECTIVES
##       and text is placed in the section to which they are related. I.E. --Des_D
##       DESCRIPTIONS are automatically placed in the OPTIONS section. Every
##       --Where text is placed in the WHERE section etc. The first time text is
##       placed in a section it is preceded by the header for that section
##       except for sections 'mysynopsis', mybasicoptions and mynote which have no
##       automatically generated header.
##     The GET_ARGS_DIRECTIVES --Title and --Para are the only options that can
##       place text in any section. They require a SECTION code to identify
##       which section they belong to.
##     The following describes the SECTION code, the name of the section
##       and what information goes into which section. The SECTION code can be
##       either the single character code or the first word of the section name.
##       The first word of the section name can be abbreviated to 3 characters.
##       CODE   NAME             WHAT GOES IN THE SECTION
##          H HEA[DER]         The first line which is created automatically.
##          p myp[urpose]      The title "PURPOSE", --Title p and --Para p
##          P PUR[POSE]        The value of the variable SCRIPT_PURPOSE.
##          s mys[ynopsis]     The title "SYNOPSIS:, --Title s, and --Para s
##          S SYN[OPSIS]       Command outline plus --Action descriptions.
##          D DES[CRIPTION]    The title "DESCRIPTION" and --Cmd_D descriptions.
##          A ACT[ION]         The title "ACTION" and --Act_D information
##          O OPT[IONS]        The title "OPTIONS", --Opt_D, --Act_D and --Des_D
##          b myb[asicoptions] The title "BASIC OPTIONS",--Title b and --Para b
##          B BAS[ICOPTIONS]   Descriptions of the auto-generated options:
##                                -h -H --help --HELP -t --test -v --version
##          W WHE[RE]          The title "WHERE" and --Where descriptions.
##          I INF[ORMATION]    The title "INFO" and --Info descriptions.
##          E EXA[MPLES]       The title "EXAMPLES" and --Exam descriptions.
##          F FILES            The title "FILES" and --Files descriptions.
##          U AUT[HORS]        The title "AUTHORS" and --Authors descriptions.
##          G BUG[S]           The title "BUGS" and --Bugs descriptions.
##          C COP[YRIGHT]      The title "COPYRIGHT" and --Copy descriptions.
##          M SEE[ALSO]        The title "SEE ALSO" and --See descriptions.
##          n myn[ote]         The title "NOTE", --Title n and --Para n
##          N NOT[E]           --Note, --Args_... and --Opts_... restrictions.
##       Note: The --Hid_D and corresponding --Des_D information is not displayed
##         in any section.
##     The purpose of sections mypurpose, mysynopsis, mybasicoptions and mynote
##       is to contain the title of the following section and to allow text to be
##       placed before the automatically generated text in the PURPOSE, SYNOPSIS,
##       sections. No text is automatically placed in any of these sections.
##     The following directives --Title and --Para place text in a SECTION (any
##       one of the sections above).
##     --Tit[le] [FCLIST] [-N] SECTION TITLE
##       Inserts left-justified text TITLE where it occurs within the current
##         position of section SECTION. TITLE will be preceded with a blank line
##         unless -N is specified or if --Brief or --Compact is used.
##       If SECTION doesn't exist it is created.
##       TITLE must not contain any newlines (\n or <NL>). Multiple --Title
##         GET_ARGS_DIRECTIVES can be defined.
##     --Par[agraph] [FCLIST] [-N] SECTION PARAGRAPH
##       Inserts an indented PARAGRAPH where it occurs within the current
##         position of section SECTION. PARAGRAPH will be preceded with a
##         blank line unless -N is specified or if --Brief or --Compact is used.
##       If SECTION doesn't exist it is created.
##       Multiple --Para GET_ARGS_DIRECTIVES can be defined.
##     The TITLEs and PARAGRAPHs occur in the order they are defined in the
##       list of GET_ARGS_DIRECTIVES (the next line available in that section).
##       For example, for the GET_ARGS_DIRECTIVES lines::
##           --Para O "My paragraph before..."  \
##           --Opt_D "a all" --Des_D "Will ..." \
##           --Para O "My paragraph after..."   \
##           --Opt_D "c cut" --Des_D "Will ..." \
##       "Ny paragraph before..." will be displayed before the description
##         for -a --all and "My paragraph after..." is displayed after -a --all.
##       Exceptions to the order occur for sections that contain automatically
##         generated text. The my... sections resolve that restriction.
##       For "brief" help all TITLE and PARAGRAPH text is suppressed. Also all
##         highlighting/colors is removed in sections OPTIONS and BASIC OPTIONS
##     --Sec[tionTitle] SECTION "NEWTITLE"
##       Modify the header for section SECTION to be NEWTITLE.
##       If NEWTITLE is empty (""), the section header is removed.
##
##   INFORMATION DIRECTIVES
##     --Act[ion] ACTION
##       Inserts the string ACTION after the parent script name in the command
##         synopsis. ACTION usually is a single word indicating the command has
##         a keyword that identifies separate set of options vis: 'btrfs keyword'.
##       Also adds ACTION (highlighted in gold) as a prefix to every --Des_D
##         OPTION_DESCRIPTION that is preceeded by --Act_D.
##       If this option is used, some Opt_D definitions should be changed to
##         --Act_D to create an 'ACTION SYNTAX' section.
##     --Cmd_D[escription] [FCLIST] CMD_DESCRIPTION
##       Create a 'COMMAND' section immediately following the SYNOPSIS
##         section with a paragraph CMD_DESCRIPTION. Use --Cmd_D to create a
##         detailed description of the purpose of the parent script.
##       Additional paragraphs can be added with the --Para GET_ARGS_DIRECTIVE.
##     --Hea[ding] [N@]HEADING
##       Use HEADING within the first line of the HELP display. The default
##       value for HEADING is "User Script". The syntax of the first line is
##       three fields:
##             ${CMD}(1)    ${HEADING}    ${CMD}(1)
##       spread evenly to fill the first line. If the length of the three fields
##       is greater than ${COLUMNS}, then only HEADING by itself is used.
##       If <ESC> sequences are used in HEADING, folding of the first may occur.
##       If so, add "N@" where N is number that overrides the calculated length
##       of HEADING.
##     --Whe[re] [FCLIST] WHERE
##       Inserts SYNTAX into the WHERE section (following BASIC OPTIONS).
##         Multiple --Where GET_ARGS_DIRECTIVES can be defined.
##     --Inf[o] [FCLIST] INFO
##       Inserts INFO into the INFORMATION section (following section WHERE).
##         Multiple --Info GET_ARGS_DIRECTIVES can be defined.
##     --Exa[mple] [FCLIST] EXAMPLE
##       Inserts EXAMPLE into the EXAMPLE section (following section
##         INFORMATION). Multiple --Example GET_ARGS_DIRECTIVES can be defined.
##     --Fil[es] [FCLIST] FILEINFO
##       Inserts FILEINFO into the FILES section (following section
##         EXAMPLE). Multiple --Files GET_ARGS_DIRECTIVES can be defined.
##     --Aut[hors] [FCLIST] AUTHORS
##       Inserts AUTHORS into the AUTHORS section (following section
##         FILES). Multiple --Authors GET_ARGS_DIRECTIVES can be defined.
##     --Bug[s] [FCLIST] BUG
##       Inserts BUG into the BUGS section (following section
##         AUTHORS). Multiple --Bugs GET_ARGS_DIRECTIVES can be defined.
##     --See[Also] [FCLIST] SEEALSOINFO
##       Inserts SEEALSOINFO into the SEE ALSO section (following section
##         BUGS). Multiple --SeeAlso GET_ARGS_DIRECTIVES can be defined.
##     --Cop[yright] [FCLIST] [COPYRIGHT]
##       In the COPYRIGHT section, display the COPYRIGHT text if present,
##         otherwise display a default (basic) Linux copyright paragraph.
##     --Not[e] [FCLIST] NOTE
##       Inserts NOTE into the NOTE section (the last section).
##         Multiple --Note GET_ARGS_DIRECTIVES can be defined.
##
##  MANAGE HELP DISPLAY
##     --Pag[er] PAGER
##       Change the default "display pager" command to PAGER. The default PAGER
##       command is "less -R -S".
##     --Exp[andTabstops] [-L] ETAB
##       Help expanded mode tabstops are set to ETAB. The default for ETAB is
##       normally set from the terminal <TAB> setting. Expanded help display
##       is the default.
##     --Bri[efTabstops] [-L] BTAB
##       Help brief mode tabstops are set to BTAB, blank lines are removed and
##       only the PURPOSE, SYNTAX, OPTIONS and BASIC OPTIONS sections are
##       displayed. The --Des_D descriptions are truncated for -h and --help or
##       displayed as one long line for -H and --HELP. The default BTAB is set
##       to ETAB/2.
##     --Com[pactTabstops] [-L] CTAB
##       Help compact mode tabstops are set to CTAB and blank lines are removed.
##       The default CTAB is set to ETAB/2.
##     --Tab[stops] [-L] TTAB
##       Set ETAB to TTAB and set BTAB and CTAB to TTAB/2. --Tab cannot be used
##       if any of the first three GET_ARGS_DIRECTIVES above have been used.
##     --Def[ault] EBC [[-L] DTAB]
##       Set the default display mode. This overrides the global default setting.
##       EBC can be "e", "b" or "c". The default is "e".
##     ETAB, BTAB, CTAB, CTAB and TTAB are positive integers less than 16.
##     The option -L causes only leading tabstops to be changed. Using -L with
##       --Brief has no meaning but is included for consistancy.
##     Changing tabstops may cause realignment of your HELP display.
##     The bash variable _GET_ARGS_GLOBAL_HELP_DEFAULT_ can be defined to set a
##       global default HELP to expanded, compacted or brief for all scripts. Use
##       of the --Default GET_ARGS_DIRECTIVE in any script overrides the global
##       default. To set the global default, see "IMPLEMENTATION OF functions.sh"
##       above.
##     HELP DEFAULTS: If an <HM> code is not used in a help request, the
##       following default settings will occur. Since -L and TAB are optional,
##       The first occurance of a non-null setting will be used.
##         1) --Default directive used: <HM>=EBC, -L and/or DTAB if set.
##         2) The global default used: <HM>=GEBC, -L and/or GTAB if set.
##         3) The ultimate default: <HM>=e (expanded), -L and/or ETAB if set.
##         4) If -L or TAB are still undefined, The -L and or TAB is set
##            depending upon the setting for <HM>.
##         5) The default TAB setting is the terminal tab setting for ETAB,
##            and ETAB/2 for BTAB and CTAB.
##         6) All tabstops are converted by default.
##
##   ADDITIONAL GET_ARGS FUNCTIONALITY AND DIRECTIVES
##     Save/Restore Functionality
##       The save/restore functionality causes one of the following actions to
##       be implemented. This functionality is now the default for all parent
##       scripts that use GET_ARGS.
##         a) If a "save" has occurred previously and if the parent script nor
##            this script (functions.sh) has not been modified since the save
##            occurred, then GET_ARGS will skip the pre-scan and scan steps of
##            the GET_ARGS_DIRECTIVES and proceed to the parent script options
##            and arguments scan.
##         b) Otherwise a full analysis of the GET_ARGS_DIRECTIVES is done and
##            the necessary GET_ARGS environment is saved.
##       This will improve performance especially if the parent script has many
##         GET_ARGS_DIRECTIVES defined.
##     --Debug [SIMULATEBO]
##       Displays the bash variables/commands that are created for the parent
##         script and the results of parsing the parent script options.
##         This option should be removed once testing is complete. Use of the
##         --Debug GET_OPTIONS_DIRECTIVE forces a prescan and full scan every
##         parent script invocation.
##       SIMULATEDBO simulates the action of a parent script basic option. It is
##         really only useful if all pre-defined GET_ARGS_DIRECTIVES of one type
##         (help, test, version) have been removed and you want to force the use
##         of that basic option. For example:
##                 --Bas_O -D t  --Bas_O -D test  --Debug -t
##         forces testing even though -t and --test have been deleted.
##       The first two characters of SIMULATEBO must be one of:
##             -h, -H, -t or -v.
##         -h or -H can be followed by <FC> and/or <HM> with the two following
##         formats depending on whether help is filtered or unfilted.
##         -t can be followed by the keyword NOCLEANUP.
##       SIMULATEBO for unfiltered help:
##         -[h|H][<HM>]       <HM> is one of the three defined help modifiers.
##       SIMULATEBO for filtered help:
##         -[h|H]<FC>[<HM>]   <FC> is one of the defined help filter codes.
##
##   ORDER OF GET_ARGS DIRECTIVES
##     The order of any GET_ARGS_DIRECTIVES is as follows:
##       1) For readability, the following GET_ARGS_DIRECTIVES should (but need
##          not) be the  beginning arguments to GET_ARGS.
##             --Filter    --Header     --Section  --Action
##             --Bas_O     --Variables  --Nocolor  --Debug
##             --Args_...  --Opts_...   --Expand   --Brief
##             --Compact   --Default    --Tabstops --Pager
##          The first 8 of these are pre-scanned before the full scan is done.
##       2) Any GET_ARGS_DIRECTIVE information for a section occurs in the order
##          the GET_ARGS_DIRECTIVE for that section is encountered.
##       3) Any --Des_D OPTION_DESCRIPTION is associated with and describes the
##          options defined in the last preceeding --Opt_D, --Act_D or --Hid_D.
##          It is recommended (but not mandatory) a --Des_D immediately follow
##          each option definition.
##       4) If any conflicting GET_ARGS_DIRECTIVES are used, the last one is the
##          one that takes effect.one
##       5) The following GET_ARGS_DIRECTIVES can only be specified once:
##            --Args_...  --Opts_...  --Heading   --Expand  --Brief
##            --Compact   --Default   --Tabs      --Action  --Copyright
##            --Cmd       --Var       --Pager     --Debug
##
##   HIGHLIGHTING
##     Select parts of the help display are (can be) highlighted. Several bash
##       variables contain ANSI ESC sequences that define the colors as follows:
##         GAsh   The color of all section headings. The default is BOLD blue.
##         GAoh   The color of all option lines. The default is SkyBlue1.
##         GAth   The color of all --Title text. The default is ${GAsh}.
##         GAah   The color of all --Action related keywords, Default is ${GLD}.
##       These variables must be set BEFORE invoking GET_ARGS. The function
##         COLOR_MAKE can be used to create the color variables.
##       For example the default color for GAsh is created with:
##         COLOR_MAKE -F blue -E 1 GAsh
##       To not use a color highlight, set it to ${DEF}. E.G. export GAsh="${DEF}"
##       Use --Nocolors to eliminate color highlighting.
##     --Noc[olors]
##       Eliminate all color highlighting.
##
##   BASH VARIABLES
##     --Var[iables] VARLIST
##       Modify the six bash variable names created by GET_ARGS. VARLIST is a
##         comma separated, positional list that reassigns those variable names.
##       When the parent script is invoked, GET_ARGS parses the options and
##         arguments on the command line and creates variables that represent
##         what was specified by --Var.
##       The VARLIST positional syntax is: "OPT,VAL,OPTSALL,ALTOPT,OPTALT,ARGS"
##       Where:
##         KEY  POSITION TYPE  DEFAULT        Description
##         OPT     1    Prefix Opt_      Options detected. E.G. -f myfile
##                                       creates:  Opt_f=1
##         VAL     2    Suffix _Val      Option values detected. E.G. -f myfile
##                                       creates array: Opt_f_Val[0]="myfile"
##         OPTSALL 3    List   Opts_All  A space separated list of all options
##                                       detected on the command line (in order).
##         ALTOPT  4    Array  Alt_Opts  Each element has the alternate spellings
##                                       E.G.: Alt_Opts[-f]=" -f --fi --file "
##         OPTALT  5    Array  Opts_Alt  Each element has the alternate spellings
##                                       E.G.: Opts_Alt["-f"]=" -f "
##                                             Opts_Alt["--fi"]=" -f "
##                                             Opts_Alt["--file"]=" -f "
##         ARGS    6    Array  Args      The arguments detected (index origin=1).
##       The default VARLIST name assignments are:
##         --Var "Opt_,_Val,Opts_All,Alt_Opts,Opts_Alt,Args"
##       VARLIST can have empty names and may have fewer than 6 entries.
##         E.G.   --Var ",,,Alternates"
##       Resssigns the array name "All_Opts" to be "Alternates".
##         The other names are unchanged.
##        Note: The suffix "_VAL" is created by the ASK functions while the
##          GET_ARGS functions use a suffix of _Val. This somewhat confusing
##          and seemingly inappropriate difference was purposely done to make
##          it extremly unlikely both functions would generate the same
##          variable name.
##
##   IMPLEMENTATION
##     GET_ARGS executes the following process steps:
##       (1) A prescan that processes --Bas_O, --filter, --Header, --Action,
##           --Debug --Variables and --SectionHeader.
##       (2) A scan of the GET_ARGS_DIRECTIVES to establish allowed/expected
##           parent script options and arguments. The results are saved in
##           the files "script.gawk" and "script1.sh".
##       (3) Creates files "help*" containing an expanded help and a brief
##           help display.
##       (4) A scan of the parent script options and arguments entered at
##           exeution time to check against what is allowed/expected. This
##           creates a deterministic set of variable assignments in
##           "script2.sh" that can be tested by the parent script.
##       (5) Returns the results to the parent script by sourcing "script1.sh"
##           and "script2.sh" or displays help and exits.
##     Provided the modification date of script.gawk is newer than the
##       modification date of either <PS.SH> or functions.sh, subsequent
##       invocations of <PS.SH> only invoke process steps (4) and (5).
##     The contents of "script.gawd" is a gawk BEGIN block.
##       "scripts[12].sh contain bash veriable assignments and commands.
##     The files are created in the directory:
##       ~/.config/functions.sh/<PS.SH>/
##
##   RETURN CODES
##     0 Successful execution or help or version information is requested.
##     1 Parent script option/argument parsing error occurred.
##       Or help or version display was requested.
##     2 A getarg options parsing error occurred.
##     3 A GET_ARGS_DIRECTIVE parsing error occurred.
##   An exit from the parent script is forced if help or version information
##   is requested.
##
##   ENVIRONMENT VARIABLES
##     Setting these variables will modify or set default values used by the
##       function GET_ARGS.
##     _GET_ARGS_GLOBAL_HELP_DEFAULT_
##       Contains global defaults for GET_ARGS help.
##     _GET_ARGS_PARSED_HELP_DIR_
##       Contains the pathname for the files created by GET_ARGS. These files are
##       stored as ${_GET_ARGS_PARSED_HELP_DIR_}/<PARENT_SCRIPT_NAME>/<FILES>
##     _GET_ARGS_DONT_SAVE_ENVIRONMENT_
##       If not null, GET_ARGS will always perform a full scan, no files are
##       stored in _GET_ARGS_PARSED_HELP_DIR_ and all files used for help are
##       temporary and are deleted.
##     _GET_ARGS_GLOBAL_DIRECTIVES_DEFAULT_
##       An array of GET_ARGS_DIRECTIVES. They are added to the end of the list
##       of GET_ARGS_DIRECTIVES used in every GET_ARGS function call.
##     HelpColors - Set the default help highlight colors
##       The global colors for GET_ARGS are set in the variables:
##         GAsh      # Default SECTION highlight
##         GAoh      # Default OPTION highlight
##         GAth      # Default TITLE highlight
##         GAah      # Default ACTION highlight
##
##     For more information on these variables execute:
##       FIND-FUNCTIONS -c -l -s /etc/profile.d/FUNCTIONS-SH-GLOBAL-DEFAULTS.sh
##
##   MODIFICATIONS AND TESTING
##     After making modifications to functions.sh and before testing them, type
##       the command: "source functions.sh". Alternatively, close the terminal
##       session and/or open a new one.
##     If you have made changes to the GET_ARGS function or to the gawk scripts
##       (.functions.sh.GET_ARGS.*.gawk) then, to test them with a parent script,
##       use the following command sequence:
##            touch PS.sh ; PS.sh
##       Alternatively, remove all the saved files with:
##            rm -rf ~/.config/functions.sh/*
##         This will ensure regeneration of the saved scripts and help files.
##       A second alternative would be to force the use of temporary files
##         by executing:
##           declare -x _GET_ARGS_DONT_SAVE_ENVIRONMENT_="1"
##     To test the GET_ARGS gawk scripts use the following syntax:
##            touch PS.sh ; DEBUG=a PS.sh
##       DEBUG can have any non-empty value.
##     Finally if you have a script (PS.sh) that uses awk or gawk, use the
##       following to invoke the awk script:
##            awk ${Debug:+-D} ...
##       Then, to test the imbedded awk script use:
##            Debug=a PS.sh

##________________________________________________________________________________
##
## GET_ARGS - Stub to implement the GET_ARGS_DEFAULT function.
##   Thus the parent script can use these functions, but also define a GET_ARGS
##   function and still have the GET_ARGS_DEFAULT function available.
function GET_ARGS() {
  GET_ARGS_DEFAULT "$@"
}

##________________________________________________________________________________
##
## GET_ARGS_DEFAULT - Call this to use the GET_ARGS function defined above.
##   It will bypass another implementation of GET_ARGS within the calling script.
function GET_ARGS_DEFAULT() {
  local _GAWK_VARIABLES_
  local _SAVE_OR_RESTORE_ _SAVEME_=1 _RESTOREME_=0 _SAVE_VARIABLES_
  local _TAB_STOPS_="$( tabs -d | sed 's/^.*tabs //;2,$d' )"
  _ERROR_MESSAGE_=""					# Initialize

  # Create the colors if they haven't beet set.
  [[ -z ${GAsh} ]] && COLOR_MAKE -F blue -E 1 GAsh	# Default SECTION highlight - BOLD Blue
  [[ -z ${GAoh} ]] && COLOR_MAKE -F SkyBlue1 GAoh	# Default OPTION highlight
  [[ -z ${GAth} ]] && GAth="${GAsh}"			# Default TITLE highlight
  [[ -z ${GAah} ]] && GAah="${GLD}"			# Default ACTION highlight

  # Analyze the arguments to GET_ARGS and the parent script args.
  local _GAWK_MAIN_="-f .functions.sh.GET_ARGS.1.main.gawk${FUNCTIONS_SH_SUFFIX}"
  local _GAWK_STUB_="-i .functions.sh.GET_ARGS.0.stub.gawk${FUNCTIONS_SH_SUFFIX}"

  if (( _GET_ARGS_DONT_SAVE_ENVIRONMENT_ )) ; then
    TMP_DIR_CREATE GET_ARGS_DIR
    local _SAVE_DIR_="${GET_ARGS_DIR}"			# An empty dir for files that will disappear on exit
  else
    local _CMD_
    # If multiple names exist, ensure we only use the first name.
    _CMD_="$( cd "${CMD_DIR}" ; find -samefile "${CMD}" | head -n 1 )"
    local _SAVE_DIR_="${_GET_ARGS_PARSED_HELP_DIR_}${_CMD_:1}"	# Where the saved files exist
    [[ -d ${_SAVE_DIR_} ]] || mkdir -p "${_SAVE_DIR_}"	# Create the save directory
  fi

  local _SAVED_GAWK_="${_SAVE_DIR_}/script.gawk"	# Contains a gawk BEGIN block
  local _SAVED_BASH1_="${_SAVE_DIR_}/script1.sh"	# Contains the GET_ARGS bash variables
  local _SAVED_BASH2_="${_SAVE_DIR_}/script2.sh"	# Contains the parsed parent script option variables
  local _ARGS_FILE_="${_SAVE_DIR_}/args.txt"		# Contains the arguments to GET_ARGS
  echo "' ${@@Q} '" >"${_ARGS_FILE_}"
  grep -q -- "' '--Debug' '" "${_ARGS_FILE_}" && touch "${CMD_PATH}"	# Force a "save" operation

  # See if a save or restore is needed.
  if [[ ! -f ${_SAVED_GAWK_} || ${CMD_PATH} -nt ${_SAVED_GAWK_} || ${FUNCTIONS_SH_PATH} -nt ${_SAVED_GAWK_} ]] ; then
    _SAVE_OR_RESTORE_="${_SAVEME_}"			# Initiate the save functionality
  else
    _GAWK_STUB_="-i ${_SAVED_GAWK_}"			# Use parent script analysis and saved vars as the stub
    _SAVE_OR_RESTORE_="${_RESTOREME_}"			# Initiate the restore functionality
  fi

  _SAVE_VARIABLES_="  -v SAVEorRESTORE=${_SAVE_OR_RESTORE_} -v SAVEme=${_SAVEME_} -v RESTOREme=${_RESTOREME_} "
  _SAVE_VARIABLES_+=" -v SAVEdir=${_SAVE_DIR_} "
  _SAVE_VARIABLES_+=" -v SAVEgawkScript=${_SAVED_GAWK_} -v SAVEbashScript1=${_SAVED_BASH1_} -v SAVEbashScript2=${_SAVED_BASH2_} "

  _GAWK_VARIABLES_="  -v BashCmd=${CMD} -v BashTabStop=${_TAB_STOPS_} -v BashColumns=${COLUMNS} -v BashIsUsageExit=${_IS_USAGE_EXIT_} "
  _GAWK_VARIABLES_+=" -v GAah=${GAah} -v GArs=${DEF} -v GAoh=${GAoh} -v GAsh=${GAsh} -v GAth=${GAth} "

  # The output of the gawk script (${_SAVED_GAWK_=}) is sourced to set the parsed, parent script option/arguments variables.
  ( cd "${FUNCTIONS_SH_DIR}"
    gawk ${DEBUG:+-D} ${_GAWK_MAIN_} ${_GAWK_STUB_} \
      ${_GAWK_VARIABLES_} ${_SAVE_VARIABLES_} \
      -v BashHelpGlobalDefault="${_GET_ARGS_GLOBAL_HELP_DEFAULT_}" \
      -v BashGlobalDirectives="${_GET_ARGS_GLOBAL_DIRECTIVES_DEFAULTS_}" \
      -v BashErrorPfx="${_USAGE_ERROR_PREFIX_}" -v BashErrorPfxLen="${_USAGE_ERROR_PREFIX_LEN_}" \
      -v BashErrorTry="${_USAGE_TRY_PREFIX_}"   -v BashErrorTryLen="${_USAGE_TRY_PREFIX_LEN_}" \
      -v BashScriptPurpose="${SCRIPT_PURPOSE:-Variable \"SCRIPT_PURPOSE\" undefined}" \
      -v BashScriptVersion="${SCRIPT_VERSION:-Variable \"SCRIPT_VERSION\" undefined}" \
      ${_ARGS_FILE_}
  )
  [[ -s ${_SAVED_BASH1_} ]] && source "${_SAVED_BASH1_}"
  [[ -s ${_SAVED_BASH2_} ]] && source "${_SAVED_BASH2_}"
}

##________________________________________________________________________________
##
## GET_ARGS_HIGHLIGHT - A debugging function that displays the calling script
##   definitions of GET_ARGS, IS_EXCLUSIVE, ${TEST...} and other salient functions.
##   USAGE: GET_ARGS_HIGHLIGHT [{-D|-L}] SCRIPT
##   Where:
##         -D The terminal background is dark. This is the default
##         -L The terminal background is light.
##     SCRIPT is the pathname of a script using GET_ARGS and IS_EXCLUSIVE.
##            The default script directory is /usr/local/bin.
##   GET_ARGS_HIGHLIGHT looks for and displays keywords in a script related to
##     the functions GET_ARGS, IS_EXCLUSIVE and TEST. It also displays any lines
##     containing a comment that ends  with " \".
##   The command "FUND_FUNCTIONS -- highlight" uses this function.
function GET_ARGS_HIGHLIGHT() {
  local dark="1"
  [[ $1 == -D ]] && shift 1
  [[ $1 == -L ]] && { dark="0" ; shift 1 ; }
  local Script="$1"
  [[ -f ${Script} ]] || Script="${FUNCTIONS_SH_DIR}/${Script}"
  [[ -f ${Script} ]] || ERROR "Script \"${1}\" not found and is not in \"${FUNCTIONS_SH_DIR}\".\nUSAGE: GET_ARGS_HIGHLIGHT ScriptPathname"
  (( $? )) && return 2					# Guarantee the following is not executed if an ERROR occurs
  # Change the grep default highlight color.
  (( dark )) && export GREP_COLORS="ms=38;5;10:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36"
  { echo -e "# GET_ARGS highlights for script \"${UL}$( realpath ${Script})${DEF}\".\n#"
    grep -E 'SCRIPT_[PV].*=|COMMON_FUNCTIONS|_functions_sh_loaded_|FUNCTIONS_SH_INIT|GET_ARGS[A-Z_]*|--[A-Z][A-Za-z_]+|\\$| -- "\$@"|Opt_[[:alpha:]_]+|\$\{#?Args[[].{1,20}]\}|IS_EXCLUSIVE|\$\{TEST_.{2,3}\}|\$\{CMD.{0,4}\}|IS_TESTING|WARNING |ERROR ' "${Script}" --color=always
  } | less -N -R -S
}

##________________________________________________________________________________
##
## GET_ARGS_LIST_OPTIONS - A debugging function that displays parent script options
##     and alternative spellings as defined by GET_ARGS in the parent script.
##   Usage: GET_ARGS_LIST_DIRECTIVES [ -V VAR ] [ OPTS ]...
##   Where:
##     -V VAR
##       Place the results as a single string in variable VAR.
##     OPTS
##       if present, display the option list for each OPT.
##       The default is: display all option lists.
##   Note: This function must be called after GET_ARGS has been called.
function GET_ARGS_LIST_OPTIONS() {
  local AllOptions Message MessageSuffix OptFile Opt Option Var
  MessageSuffix="\nThe first option defined with --Opt_D determines the variable name."
  Message="List of option equivalences for "
  if [[ $1 == -V ]] ; then
    Var="$2"
    unset $Var
    shift 2
  else
    TMP_FILE_CREATE OptFile
  fi
  if [[ -z ${1} ]] ; then
    AllOptions="${!Alt_Opts[*]}"
    Message+="all options defined in ${CMD}."
  else
    for Opt in $* ; do
      Opt="${Opts_Alt[${Opt}]}"
      Opt="${Opt//-/_}"
      [[ ${Opt:0:2} == __ ]] && Opt="${Opt:1}"
      for Option in ${!Alt_Opts[*]} ; do
        if [[ ${Option} =~ ${Opt}$ ]] ; then		# This test is "almost" perfect
          AllOptions+="${Option} "
          break
        fi
      done
    done
    Message+="the option(s) $*."
  fi
  [[ -z ${Var} ]] && echo -e "\n${Message}${MessageSuffix}\n"
  for Option in ${AllOptions} ; do
    [[ ${Option} =~ ^- ]] && continue			# Ignore these
    if [[ -n ${Var} ]] ; then
      eval $Var+=\"${Option}${Alt_Opts[${Option}]}\"
    else
      echo -e "${Option} ${Alt_Opts[${Option}]}" >> ${OptFile}
    fi
  done
  [[ -n ${Var} ]] && return
  ( echo -e "Variable Options" ; sort ${OptFile} ) | column --table | sed -e 's/^/     /'
}

##________________________________________________________________________________
##
## GET_ALL_PC_NAMES - Displays a space-separated lowercase list of valid PC names.
##   Usage: GET_ALL_PC_NAMES [ -V VAR ]
##   Where: -V VAR is the name of the variable containing the result.
##          Global variable "_ALL_PCS_" will always contain the list of all PCs.
##   Note:  Requires variable LOCAL_PCS to be set and exported in the parent
##          environment.
function GET_ALL_PC_NAMES() {
  declare -gx _ALL_PCS_="${LOCAL_PCS,,}"
  [[ $1 == -V ]] && eval ${2}=\"${_ALL_PCS_}\" || echo -n "${_ALL_PCS_}"
}

##________________________________________________________________________________
##
## GET_IP_FROM_DOMAIN - Convert a domain name into an IP address.
##     Accepts DNS 'A', "AAAA" and 'CNAME' names and displays the IP(s)
##     that match.
##   Usage: GET_IP_FROM_DOMAIN [-6] [-A] [-V VAR] DOMAIN
##   Where: DOMAIN is a valid DNS domain name (A, AAAA, or CNAME)
##     -6 Get the IPv6 address. The default is to get IPv4 addresses
##     -A Display all IPs found rather than just the first one.
##     -V VAR Store the result in the array VAR rather than displaying it.
##   Returns 1 if no IP found
function GET_IP_FROM_DOMAIN() {
  local ALL_IPS Found DOMAIN_NAME IP IPVER="-4" Var
  while (( $# > 0 )) ; do
    case "$1" in
      -6) IPVER="-6"   ; shift 1 ;;
      -A) ALL_IPS="1"  ; shift 1 ;;
      -V) Var="$2" ; unset ${Var} ; shift 2 ;;
       *) break ;;
    esac
  done
  [[ $1 =~ \. ]] && DOMAIN_NAME="$1" || DOMAIN_NAME="${1}.${_LOCAL_DOMAIN_}."
  while read -u 4 IP REST ; do
    Found="1"
    [[ ${IP} =~ \.$ ]] && continue
    [[ -n ${Var} ]] && eval ${Var}+=\( \"${IP}\" \) || echo "${IP}"
    (( ALL_IPS )) || return 0
  done 4< <( dig ${IPVER} +short "${DOMAIN_NAME}" 2>/dev/null )
  (( Found )) || return 1
}

##________________________________________________________________________________
##
## GET_LOCAL_DOMAIN_NAME - Displays the lowercase name of this PC's DOMAIN.
##   Usage: GET_LOCAL_DOMAIN_NAME [ -V VAR ]
##   Where: -V VAR is the name of a variable containing the result.
##   Note:  A global variable "_LOCAL_DOMAIN_" will always contain the result.
function GET_LOCAL_DOMAIN_NAME() {
  [[ $1 == -V ]] && eval ${2}=\"${_LOCAL_DOMAIN_}\" || echo -n "${_LOCAL_DOMAIN_}"
}

##________________________________________________________________________________
##
## GET_LOCAL_PC_NAME - Displays the lowercase name of this PC.
##   Usage: GET_LOCAL_PC_NAME [ -V VAR ]
##   Where: -V VAR is the name of the variable containing the result.
##   Note:  A global variable "_LOCAL_PC_" will always contain the result.
function GET_LOCAL_PC_NAME() {
  [[ $1 == -V ]] && eval ${2}=\"${_LOCAL_PC_}\" || echo "${_LOCAL_PC_}"
}

##________________________________________________________________________________
##
## GET_MATCHING_NFS_DOMAIN_IN_FSTAB - Display the DNS domain of an NFS entry in
##     /etc/fstab that matches the domain of $1. Since DNS domain names may have
##     any number of aliases the IP addresses of the domains are used to make a
##     match.
##   Usage:   GET_MATCHING_NFS_DOMAIN_IN_FSTAB [ -I ] [ -Q ] [ -V VAR ] NFSPATHS
##   Where:   -I Displays the IP address rather than the matching domain name.
##            -Q Don't display error messages. Return 1
##            -V VAR Store the result in variable VAR rather than displaying it.
##            -A Create VAR as an array.
##            NFSPATH has the format domain[:path[ or IP[:path[
##   Returns: If successful, displays matching fstab domain name (or IP address
##            if '-I') and returns 0. Otherwise returns 1.
function GET_MATCHING_NFS_DOMAIN_IN_FSTAB() {
  local ArgIP fstabDomain fstabDomainIP Quiet Result Sep1 Sep2 Var WantIP="0"
  while (( $# > 0 )) ; do
    case $1 in
      -I) WantIP="1" ; shift 1 ;;
      -Q) Quiet="$1" ; shift 1 ;;
      -V) Var="$2" ; unset ${Var} ; shift 2 ;;
      -A) Sep1="(" ; Sep2=")" ; shift 1 ;;
       *) break ;;
    esac
  done
  (( Array && ${#Var} == 0 )) && ERROR "GET_MATCHING_NFS_DOMAIN_IN_FSTAB: Option \"-A\" specified but no variable name defined."
  [[ -z ${Sep1} ]] && { Sep1="\"" ; Sep2="\"" ; }
  while (( $# > 0 )) ; do
    GET_IP_FROM_DOMAIN ${Quiet} -V ArgIP "${1%%:*}"
    for fstabDomain in $( GET_ALL_UNIQUE_NFS_DOMAINS_IN_FSTAB ) ; do # Collect all the possible (unique) nfs domains
      GET_IP_FROM_DOMAIN ${Quiet} -V fstabDomainIP "${fstabDomain}"
      if [[ ${fstabDomainIP} == ${ArgIP} ]] ; then
        (( WantIP )) && Result="${fstabDomainIP}" || Result="${fstabDomain}"
        [[ -n ${Var} ]] && eval ${Var}+=${Sep1}\${Result} ${Sep2} || echo -n "${Result} "
        #return 0
      fi
    done
    shift 1
  done
  [[ -z ${Result} ]] && return 1 || return 0
}

##________________________________________________________________________________
##
## GET_OTHER_PC_NAME - Displays/Validates a lowercase PC name from the list of
##     PC names in this domain excluding the name of this PC.
##   Usage: GET_OTHER_PC_NAME [-V VAR ] [ -S | PC ]
##   Where: -S Sets the global variable _OTHER_PCS_, unsets _OTHER_PC_
##          -V Sets VAR to _OTHER_PCS_ and exits.
##          PC Is prompted for if missing. Otherwise it is compared against
##             the list of other PCs. A match returns 0 otherwise 1.
##   The global variable _OTHER_PCS_ will always contain the PC name list
##     minus this PC's name.
##   The global variable _OTHER_PC_ is unset if -S is used. Otherwise it will
##     contain the result.
##   Note: Requires variable LOCAL_PCS to be set.
function GET_OTHER_PC_NAME() {
  local ARG OTHER_PCS _PC_ SET Var
  _ERROR_MESSAGE_=""
  [[ -z ${_LOCAL_PC_} ]] && GET_LOCAL_PC_NAME -V _LOCAL_PC_
  [[ -z ${_ALL_PCS_} ]]  && GET_ALL_PC_NAMES -V _ALL_PCS_
  declare -gx _OTHER_PC_ _OTHER_PCS_
  OTHER_PCS=" ${_ALL_PCS_} "
  OTHER_PCS=( ${OTHER_PCS/ ${_LOCAL_PC_} / } )
  _OTHER_PCS_="${OTHER_PCS[@]}"
  while (( $# > 0 )) ; do
    case ${1} in
      -S) SET="1"   ; shift 1 ;;
      -V) Var="$2"  ; unset ${Var} ; shift 2 ;;
       *) _PC_="$1" ; shift 1 ;;
    esac
  done
  if (( SET )) ; then
    [[ -n ${Var} ]] && eval ${Var}=\"${_OTHER_PCS_}\"
    unset _OTHER_PC_
    return
  fi
  if [[ -z ${_PC_} ]] ; then
    unset _OTHER_PC_ ${Var}
    ASK_WITH_MENU -M -H "\nSelect the other PC" OTHER_PCS
    (( $? > 0 )) && return
    _OTHER_PC_="${ANSWER_VAL}"
  else
    _OTHER_PC_="${_PC_,,}"
    if [[ ! " ${OTHER_PCS[*]} " =~ " ${_OTHER_PC_} " ]] ; then
      unset _OTHER_PC_
      ERROR "PC \"${_PC_}\" is invalid. Valid values are ${GLD}${_OTHER_PCS_}${DEF}."
    fi
  fi
  [[ -n ${Var} ]] && eval ${Var}=\"${_OTHER_PC_}\"
}

##________________________________________________________________________________
##
## GET_ALL_UNIQUE_NFS_DOMAINS_IN_FSTAB - Display all the NFS domain names
##     found in /etc/fstab
##   Usage: GET_ALL_UNIQUE_NFS_DOMAINS_IN_FSTAB [ -I ] [ -Q ] [ -V VAR ]
##   Where: -I Display the domain IP(s) rather than the names.
##          -Q Don't display error messages. Return 1
##          -V VAR Store the result in variable VAR rather than displaying it.
##          -A Create VAR as an array.
function GET_ALL_UNIQUE_NFS_DOMAINS_IN_FSTAB() {
  local IPs Result Var Sep1 Sep2
  while (( $# > 0 )) ; do
    case $1 in
      -I) IPs="1"    ; shift 1 ;;
      -Q) Quiet="$1" ; shift 1 ;;
      -V) Var="$2" ; unset ${Var} ; shift 2 ;;
      -A) Sep1="(" ; Sep2=")" ; shift 1 ;;
       *) break ;;
     esac
  done
  (( Array && ${#Var} == 0 )) && ERROR "GET_ALL_UNIQUE_NFS_DOMAINS_IN_FSTAB: Option \"-A\" specified but no variable name defined."
  [[ -z ${Sep1} ]] && { Sep1="\"" ; Sep2="\"" ; }
  Result=( $( gawk '/^[^#].*:.*\snfs[0-9]*\s+/ { Domain=gensub(/:.*/,"","1",$1)} ; !Seen[Domain]++ { printf("%s ", Domain) }' /etc/fstab ) )
  if (( IPs )) ; then
    for IPs in ${#Result[*]} ; do
      GET_IP_FROM_DOMAIN ${Quiet} -V Result[${IPs}] "${Result[IPs]}"
    done
  fi
  [[ -n ${Var} ]] && eval ${Var}=${Sep1}\${Result[*]}${Sep2} || echo "${Result[*]}"
  [[ -z ${Result} ]] && return 1 || return 0
}

##________________________________________________________________________________
##
## IS_EXCLUSIVE - Returns successfully to the parent script when a valid
##     combination of parent options (as parsed be GET_ARGS) is detected.
##     Otherwise it issues an error message and exits the calling script.
##   Usage: IS_EXCLUSIVE [--Strict] [EXCLOPT] OPTIONS
##   Where:
##     OPTIONS is a space separated list (Opt_i) of the first OPTi in any
##       GET_ARGS OPTLIST (without the preceding "-" or "--").
##     EXCLOPT is one of the following options:
##          <empty>  If EXCLOPT is not present then the options in OPTIONS
##                   are mutually exclusive (only one can be specified).
##       --Only_One  If specified, will check if only one (or none) of the
##                   Opt_i has been specified.
##       --Just_One  If specified, will check if just one (or none) of the
##                   Opt_i has been specified. No other options are allowed.
##                   Note: all "IS_EXCLUSIVE --Just_One ..." function calls
##                     must precede any "IS_EXCLUSIVE --Default ...".
##       --Default   If specified, will set OPTLIST Opt_1 as the default if
##                   none of Opt_1, Opt_2, Opt_3 ... has been specified.
##       --Assume    If specified will also set Opt_2, Opt_3, ... if Opt_1
##                   is used.
##       --One_Of    If specified, will check if exactly one of the Opt_i
##                   has been specified.
##       --All_Of    If specified, will check if all (or none) of the Opt_i
##                   have been specified.
##       --At_Least  If specified, will check if at least one of the Opt_i
##                   has been specified.
##       --Only_With If specified, will verify the option specified in Opt_1 can
##                   only be used with the options specified in Opt_2, Opt_3 ...
##       --Not_With  If specified, will check that the option specified in Opt_1
##                   must not be paired with any of the options specified in
##                   Opt_2, Opt_3 ...
##       --Paired_With[=N]
##                   If specified, will check that any N options specified in
##                   Opt_2, Opt_3 ... must be used with Opt_1. N defaults to 1
##       --Strict    If specified, modifies the test by counting every occurrence
##                   of Opt_i. By default IS_EXCLUSIVE tests if any single Opt_i
##                   has been specified at least once. --Strict ensures only one
##                   occurrence of any Opt_i was specified.
##   NOTE: This function assumes the script arguments have been parsed by the
##      function GET_ARGS above.
##   EXAMPLES:
##    IS_EXCLUSIVE q V
##      Assuming -q can be used more than once,
##      returns TRUE only if either -q, -qq, -qqq... or -V (or none) is used.
##    IS_EXCLUSIVE --Only_One q V
##      Assuming -q can be used more than once,
##      returns TRUE only if just -q, -qq, -qqq... or -V (or none) is used.
##    IS_EXCLUSIVE --Default a b c
##      If none of -a, -b or -c has been specified, sets Opt_a=1 and includes -a
##      in the variable "Opts_All".
##    IS_EXCLUSIVE --Assume a b c d
##      If a is used, automatically set any of Opt_b=1, Opt_c=1 or Opt_d=1 that
##      is not set and updates variable "Opts_All".
##    IS_EXCLUSIVE --Just_One q V
##      Returns TRUE if -q or -V is used with no other options, or if neither -q
##      or -V is used.
##    IS_EXCLUSIVE --One_Of q V
##      Returns TRUE only if one of -q, -qq, -qqq... or -V is used. One of them
##      must be used.
##    IS_EXCLUSIVE --Strict --One_Of q V
##      Returns TRUE only if exactly one of -q or -V is used. One of them must
##      be used.
##    IS_EXCLUSIVE --All_Of q V
##      Returns TRUE only if all of -q, -qq, -qqq... or -V is used.
##      In this case --Strict has no effect.
##    IS_EXCLUSIVE --At_Least q V
##      Returns TRUE if at least one of -q or -V is used.
##      In this case --Strict has no effect.
##    IS_EXCLUSIVE --Only_With V a b cc
##      Returns TRUE only if -V is not used or, if used once, can only be used
##      with -a -b or --cc.
##    IS_EXCLUSIVE --Not_With V a b cc
##      Returns TRUE only if -V is not used or, if used once, has not been used
##      with -a -b or --cc.
##    IS_EXCLUSIVE --Paired_With V a b cc
##      Returns TRUE only if -V is used and one of -a -b or --cc is also used.
##    IS_EXCLUSIVE --Paired_With=2 V a b cc
##      Returns TRUE only if -V is used and any two of -a -b or --cc is also used.
function IS_EXCLUSIVE() {
  local ALL_OF ARG1 ARGS ASSUME AT_LEAST CHECK_IT_OUT DASH DEFAULT NOT_WITH ONE_OF ONLY_ONE OPTS OPTS_ALL
  local PAIRED_COUNT PAIRED_WITH
  local EXCLUSIVE_ARRAY EXCLUSIVE_ARRAY_COUNT EXCLUSIVE_COUNT EXCLUSIVE_COUNTS EXCLUSIVE_OPTIONS EXECUTE_ME
  [[ ${1^^} == --STRICT ]] && { STRICT="1" ; shift 1 ; }
  [[ ${*^^} =~ --STRICT ]] && _USAGE_CHOICE_ "IS_EXCLUSIVE: If used, option --Strict must be the first argument."
  [[ ${*} =~ --.*-- ]] && _USAGE_CHOICE_ "IS_EXCLUSIVE: Only one (or none) of the following can be used:\n    --Default  --Only_One  --Just_One  --One_Of  --All_Of  --At_Least  --Only_With  --Not_With  --Paired_With"
  ARGS="$@"
  while (( $# > 0 )) ; do
    ARG1="$1"
    case "${1^^}" in
      --ONLY_ONE) ONLY_ONE="1" ; shift 1 ;;
        --ONE_OF)   ONE_OF="1" ; shift 1 ;;
        --ALL_OF)   ALL_OF="1" ; shift 1 ;;
      --AT_LEAST) AT_LEAST="1" ; shift 1 ;;
      --JUST_ONE) shift 1
                  OPTS_ALL=( ${Opts_All} )		# make an array so easy to count
                  (( ${#OPTS_ALL[*]} < 2 )) && return	# Zero or one option used so don't have to check
                  for OPTS in $* ; do
                    (( ${#OPTS} > 1 )) && DASH="--" || DASH="-"
                    if [[ " ${Opts_All} " =~ " ${DASH}${OPTS} " ]] ; then
                      _USAGE_CHOICE_ "IS_EXCLUSIVE: No other option can be used with option ${DASH}${OPTS}."
                    fi
                  done
                  return
                  ;;
      --NOT_WITH|--PAIRED_WITH*|--ASSUME|--DEFAULT)
                  case "${1^^}" in
                    --DEFAULT|--ASSUME)
                        (( ${#2} == 1 )) && Dash="-" || Dash="--"
                        [[ ${_ALL_OPTIONS_} =~ \ $2\  ]] || _USAGE_CHOICE_ "For the command 'IS_EXCLUSIVE ${ARGS}' the option '${Dash}$2' has not been defined."
                        [[ ${1^^} == "--ASSUME" ]] && ASSUME="1" || DEFAULT="$2"
                        ;;
                    --NOT_WITH)
                        NOT_WITH="1" ;;
                    --PAIRED_WITH*)
                        [[ $1 =~ = ]] && PAIRED_COUNT="${1#*=}" || PAIRED_COUNT="1"
                        PAIRED_WITH="1" ;;
                  esac
                  ;&							# Continue with the next 'list' with no test
      --ONLY_WITH) shift 1
                  eval ONE_OF=\"\${Opt_${1//-/_}}\"			# Turn option into a variable and et it's value
                  (( ${#1} == 1 )) && ONLY_ONE="-$1" || ONLY_ONE="--$1"	# For reporting
                  (( ! ONE_OF && ${#DEFAULT} == 0 )) && return 0	# Option not used so return
                  shift 1
                  local Comma=" " Dash
                  while (( $# != 0 )) ; do				# Now look at the remaining OPTs
                    (( ${#1} == 1 )) && Dash="-" || Dash="--"
                    OPTS+="${Comma}${Dash}${1}"				# For reporting
                    [[ ${_ALL_OPTIONS_} =~ \ $1\  ]] || _USAGE_CHOICE_ "For the command 'IS_EXCLUSIVE ${ARGS}' the option '${Dash}$1' has not been defined."
                    if (( ASSUME )) ; then				# The remaining options must be set
                      ONE_OF="Opt_${1//-/_}"				# Make this option a variable
                      if (( ONE_OF < 1 )) ; then			# If is hasn't been assigned
                        eval $ONE_OF="1"				#   Then assign it
                        Opts_All+=" ${Dash}${1} "			# And record it a being "used"
                      fi
                    fi
                    Comma=", "
                    eval ONE_OF=\$\(\( ONE_OF + Opt_${1//-/_} \)\)	# Add any occurrence of the remaining options (with '-' converted to '_')
                    shift 1
                  done
                  (( ASSUME )) && return
                  if [[ -n ${DEFAULT} ]] ; then
                    if (( ! ONE_OF )) ; then
                      eval Opt_${DEFAULT//-/_}=1
                      Opts_All+=" ${ONLY_ONE} "
                    fi
                    return 0
                  elif (( JUST_ONE )) ; then
                    [[ ${ONE_OF} ]] && _USAGE_CHOICE_ "IS_EXCLUSIVE: No other options can be used with option ${ONLY_ONE}."
                  elif (( PAIRED_WITH )) ; then
                    (( ONE_OF != ( 1 + PAIRED_COUNT ) )) && _USAGE_CHOICE_ "IS_EXCLUSIVE: Option ${ONLY_ONE} must be paired with exactly ${PAIRED_COUNT} of option(s) ${OPTS}."
                  elif (( NOT_WITH )) ; then
                    (( ONE_OF > 1 )) && _USAGE_CHOICE_ "IS_EXCLUSIVE: Option ${ONLY_ONE} cannot be used with option(s)${OPTS}."
                  else					# Must be --Only_With
                    (( ONE_OF == 1 )) && _USAGE_CHOICE_ "IS_EXCLUSIVE: Option ${ONLY_ONE} can only be used with option(s)${OPTS}."
                  fi
                  return 1
                  ;;
               *) OPTS+="${ARG1} " ; shift 1 ;;
    esac
  done
  CHECK_IT_OUT="$(( ONLY_ONE + JUST_ONE + ONE_OF + ALL_OF + AT_LEAST + MUST_WITH + NOT_WITH + ONLY_WITH + DEFAULT ))"
  (( ! CHECK_IT_OUT )) && ONLY_ONE="1"			# The default
  OPTS=" ${OPTS// --/ }"
  EXECUTE_ME=$( gawk --assign Var="${OPTS// -/ }" '
    BEGIN {
      ArrayNum=split(Var, Array, " ")
      FormatCounts = "0${Opt_%s} + "
      FormatArray = "${Opt_%s} "
      ExclusiveCounts = "EXCLUSIVE_COUNTS=\" "
      ExclusiveArray = "EXCLUSIVE_ARRAY=\" "
      ExclusiveOptions = "EXCLUSIVE_OPTIONS=\"( "
      for(Idx=1 ; Idx<=ArrayNum ; Idx++) {
        VariableName = gensub(/-/,"_","g",Array[Idx])
        ExclusiveCounts = ExclusiveCounts sprintf(FormatCounts, VariableName)
        ExclusiveArray = ExclusiveArray sprintf(FormatArray, VariableName)
        (length(Array[Idx]) == 1) ? FormatOptions = "-%s " : FormatOptions = "--%s "
        ExclusiveOptions = ExclusiveOptions sprintf(FormatOptions, Array[Idx])
      }
      printf "%s0 \" ; %s \" ; %s)\" ; EXCLUSIVE_IDX=%d", ExclusiveCounts, ExclusiveArray, ExclusiveOptions, Idx -1
    }	# End of BEGIN
'
              )
  eval ${EXECUTE_ME}
  if (( STRICT )) ; then
    eval EXCLUSIVE_COUNT="\$(( EXCLUSIVE_COUNTS ))"
  else
    EXCLUSIVE_COUNT=( ${EXCLUSIVE_ARRAY} )
    EXCLUSIVE_COUNT="${#EXCLUSIVE_COUNT[*]}"
  fi
  eval EXCLUSIVE_ARRAY=\(${EXCLUSIVE_ARRAY}\)
  (( ONLY_ONE && EXCLUSIVE_COUNT > 1 && ! AT_LEAST )) && _USAGE_CHOICE_ "Invalid combination of options.\nOptions ${EXCLUSIVE_OPTIONS} are mutually exclusive or used more than once."
  [[ -n ${ONE_OF} && EXCLUSIVE_COUNT -ne 1 ]] && _USAGE_CHOICE_ "Required option error.\nOne of ${EXCLUSIVE_OPTIONS} must be specified."
  (( AT_LEAST && EXCLUSIVE_COUNT < 1 )) && _USAGE_CHOICE_ "Required option missing.\nAt least one of ${EXCLUSIVE_OPTIONS} must be specified."
  if (( ALL_OF )) ; then
    (( ${#EXCLUSIVE_ARRAY[*]} != EXCLUSIVE_IDX && ${#EXCLUSIVE_ARRAY[*]} != 0 )) && \
       _USAGE_CHOICE_ "Required options missing.\nAll (or none) of ${EXCLUSIVE_OPTIONS} must be specified."
  fi
  (( EXCLUSIVE_COUNT != 0 && EXCLUSIVE_COUNT > 1 && ! AT_LEAST )) && _USAGE_CHOICE_ "Invalid combination of options.\nOptions ${EXCLUSIVE_OPTIONS} are mutually exclusive."
}

##________________________________________________________________________________
##
## IS_HEX - Returns TRUE if HEXNUM is valid; otherwise FALSE.
##   Usage: IS_HEX HEXNUM
##     A valid HEXNUM can be in many of the acceptable HEX representations.
##        1111, 0x1111, #1111, %1111, \\x1111, $#x1111
function IS_HEX() {
  [[ ${1,,} =~ ^(0x|#|%|\\x|&#x)*[a-f0-9]+$ ]]
  return $?
}

##________________________________________________________________________________
##
## IS_IP - Returns TRUE if $1 is a valid IPV4 or IPV6 address, otherwise FALSE.
##   Usage: IP_IP ADDRESS
##          ADDRESS is the IPV4 or IPV6 address to be verified.
function IS_IP() {
  [[ $1 =~ ^([0-7]{1,3}\.){3}[0-7]{1,3}$ ]] && return 0
  [[ $1 =~ :: ]] && return 0
  [[ $1 =~ (::).*(::) ]] && return 1
  local IPlc="${1,,}"
  if [[ $1 =~ :: ]] ; then
    if [[ $1 =~ ^:: ]] ; then
      [[ ${IPlc} =~ ^::([0-9a-f]{1,4}:){0,6}[0-9a-f]{1,4}$ ]] && return 0
    elif [[ $1 =~ ::$ ]] ; then
      [[ ${OPlc} =~ ([0-9a-f]{1,4}:){0,7}:$ ]] && return 0
    fi
  else
    [[ ${IPlc} =~ ^([0-9a-f]{0,4}:){7}[0-9a-f]{1,4}$ ]] && return 0
  fi
  return 1
}

##________________________________________________________________________________
##
## IS_IP_ALIVE - Analyzes IPv4/DOMAIN addresses to determine if any is active.
##   Usage: IS_IP_ALIVE [ -Q | -V VAR ] IPS ...
##   Where:
##     IPS     IPv4 addresses or domain names that resolve into IPv4 address.
##      -Q     Don't store/display the IP. Return a code of success or failure.
##      -V VAR Store the result in variable VAR rather than displaying it.
##   Note:
##     The first active IP/domain address found is displayed as an IPv4 address
##       or in VAR if -V is used, and IS_IP_ALIVE returns TRUE.
##     Otherwise: If -V is used, VAR is set to "". Then a message is stored in
##       the variable _ERROR_MESSAGE_ and IS_IP_ALIVE returns FALSE.
##   Note: This function uses the command "nmap".
function IS_IP_ALIVE() {
  local IP LINE IP_MSG IP_MSG_SEP PLURAL QUIET Var WORD1 WORD2
  _ERROR_MESSAGE_=""
  if [[ $1 == -V ]] ; then
    Var="$2"
    eval unset ${Var}			# Default value if no IP was found to be alive.
    shift 2
  elif [[ $1 == -Q ]] ; then
    QUIET="1"
    shift 1
  fi
  if (( $# == 0 )) ; then
    _ERROR_MESSAGE_="No IP addresses or domain names specified.\nUSAGE: IS_IP_ALIVE [ -V VAR ] IPS ..."
    return 1
  fi
  while read -u 3 WORD1 WORD2 WORD3 REST ; do
    case "${WORD1}${WORD2}${WORD3}" in
      Nmapscanreport)
        if [[ ${REST} =~ \( ]]
          then IP="${REST#*\(}"
               IP="${IP%)*}"
          else IP="${REST##for }"
        fi
        ;;
      Hostisup*)
        if [[ -n ${IP} ]] ; then
          (( QUIET )) && return 0
          [[ -n ${Var} ]] && eval ${Var}=\( \"${IP}\" \) || echo -e "${IP}"
          return 0					# Return the first IP found to be alive.
        fi
        ;;
      Failedto) : ;;
    esac
  done 3< <( nmap --max-retries 2 -T4 -sn "$@" 2>/dev/null )
  # All IPs dead so generate a message.
  (( $# > 1 )) && PLURAL="s"
  for PC in "$@" ; do
    if IS_NUMERIC "${PC:0:1}" ; then
      IP_MSG="${IP_MSG}${IP_MSG_SEP}${PC}"
    else
      GET_IP_FROM_DOMAIN -V PC_IP "${PC}"
      IP_MSG="${IP_MSG}${IP_MSG_SEP}${PC} (${PC_IP})"
    fi
    IP_MSG_SEP=", "
  done
  _ERROR_MESSAGE_="Cannot contact PC IP${PLURAL}: ${IP_MSG}"
  return 1
}

##________________________________________________________________________________
##
## IS_LOGICAL_VOLUME - Returns TRUE if $1 is a logical volume, otherwise
##   returns FALSE.
function IS_LOGICAL_VOLUME() {
  local STATUS DEVICE REST LVM WHAT
  WHAT="$( realpath --canonicalize-missing ${1} )"	# convert to an absolute pathname by following links
  while read -u 3 STATUS DEVICE REST ; do
    LVM="$( eval realpath --canonicalize-missing ${DEVICE} )"
    [[ ${WHAT} == ${LVM} ]] && return 0
  done
  return 1
} 3< <( lvscan 2>/dev/null )

##________________________________________________________________________________
##
## IS_MAC - Returns TRUE if MACADDR is valid; otherwise FALSE.
##   Usage: IS_MAC MACADDR
##     MACADDR is the MAC address to be tested.
function IS_MAC() {
  [[ ${1,,} =~ ^([a-f0-9]{2}:){5}[a-f0-9]{2}$ ]]
  return $?
}

##________________________________________________________________________________
##
## IS_NUMERIC - Returns TRUE if $1 is numeric; otherwise returns FALSE.
##   Integers, positive and negative numbers, floating point numbers, and
##     exponents (12.3e45) are detected.
##   If $1 is -A (absolute) then $2 cannot have either a '+' or a '-' sign.
function IS_NUMERIC() {
  [[ -z $1 ]] && return 1
  if [[ $1 == -A ]] ; then
    [[ $2 =~ ^[0-9]*\.?[0-9]*([eE]?[0-9]+)?$ ]]
  else
    [[ $1 =~ ^[+-]?[0-9]*\.?[0-9]*([eE]?[0-9]+)?$ ]]
  fi
  return $?
}

##________________________________________________________________________________
##
## IS-ROOT - Returns TRUE if the EUID is "root"; otherwise FALSE.
function IS_ROOT() {
  (( EUID )) && return 1 || return 0
}

##________________________________________________________________________________
##
## IS_TESTING - Returns TRUE if TESTing is enabled; otherwise FALSE.
function IS_TESTING() {
  (( _TESTING_ ))
  return $?
}

##________________________________________________________________________________
##
## IS_UUID - Returns TRUE if UUID is valid; otherwise returns FALSE.
##   Usage: IS_UUID UUID
##   A valid UUID has the accepted format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
function IS_UUID() {
  [[ ${1,,} =~ ^[a-f0-9-]+$ ]] \
    && [[ ${2} =~ ^........-....-....-....-............$ ]]
  return $?
}

##________________________________________________________________________________
##
## MOUNT_IT - Mount the filesystem $1 onto directory $2 and remember where it
##     was mounted.
##   Usage: MOUNT_IT FILESYSTEM [ WHERE ] [ MOUNT_OPTIONS]
##   Where:
##     FILESYSTEM can be a device special file (/dev/...), an NFS mount
##       (aa.bb.cc:/PATH) or a UUID ( UUID=...)
##     WHERE is the pathname of mount point. It must be a directory that exists.
##       If both FILESYSTEM and WHERE are present they are used as is.
##       If WHERE is not present or if $2 begins with a '-', then FILESYSTEM
##         is assumed to be a device or directory in /etc/fstab. So a search
##         is made in /etc/fstab for mounting information.
##       If directory $1 is not found then a recursive search of the parent
##         directory is made until a matching directory is found or the root
##         directory is reached.
##     MOUNT_OPTIONS are any options acceptable to the mount command.

unset _MOUNTED_FS_ARRAY_ ; declare -a _MOUNTED_FS_ARRAY_
_MOUNTED_FS_ARRAY_IDX_="0"

function MOUNT_IT() {
  local IS_LV SUDO NFS_SERVER NFS_WHAT_CANON TEST_WHAT_CANON WHAT_CANON WHAT_FS WHAT_ORIG WHERE_CANON WHERE_FS WHERE_ORIG
  IS_ROOT || SUDO="sudo"
  if [[ $# == 1 || ${2:0:1} == - ]]			# $1 alone or with MOUNT_OPTIONS
    then _MOUNT_IT_FIND_IN_FSTAB_ "$1"			# Set the values for WHAT and WHERE: XXX_ORIG, XXX_CANON, XXX_FS
         shift 1					# Remaining args are MOUNT_OPTIONS
    else WHAT_ORIG="$1"
         WHAT_CANON="$1"
         WHAT_FS="$1"
         WHERE_ORIG="$2"
         WHERE_CANON="$2"
         WHERE_FS="$2"
         shift 2					# Remaining args are MOUNT_OPTIONS
  fi
  [[ -d ${WHERE_CANON} ]] || _USAGE_CHOICE_ "MOUNT_IT: Mount point '${WHERE_CANON}' does not exist."
  if (( ! NFS )) && [[ ! ${WHAT_CANON} =~ : ]] ; then
    [[ -b ${WHAT_CANON} ]] || _USAGE_CHOICE_ "MOUNT_IT: Filesystem \"${WHAT_CANON}\" doesn't exist or is not a block device."
    TEST_WHAT_CANON="${WHAT_CANON}"
  else
    TEST_WHAT_CANON=":${NFS_WHAT_CANON}"
  fi
  if mount | grep -q "${TEST_WHAT_CANON}.*${WHERE_CANON}" ; then
    echo -e "Note: '${WHAT_CANON}' is already mounted onto '$WHERE_CANON'. It will be used as-is."
  else
    if IS_LOGICAL_VOLUME "${WHAT_CANON}"
      then IS_LV="YES"
           ${SUDO} lvchange -ay "${WHAT_CANON}"
      else IS_LV="NO"
    fi
    ${SUDO} mount "$@" "${WHAT_CANON}" "${WHERE_CANON}" || _USAGE_CHOICE_ "MOUNT_IT: Error mounting '$1' onto '$2'."
  fi
  # Remember where it was mounted and whether it is a logical volume
  _MOUNTED_FS_ARRAY_[_MOUNTED_FS_ARRAY_IDX_++]="${WHAT_CANON} ${WHERE_CANON} ${WHAT_FS} ${WHERE_FS} ${WHAT_ORIG} ${WHERE_ORIG} ${IS_LV}"
}

# INTERNAL FUNCTION - Called by MOUNT_IT
# In column 2 of /etc/fstab, look for the directory '$1' or (recursively) for the parent.
function _MOUNT_IT_FIND_IN_FSTAB_() {
  local ERROR_CODE=0 ERROR_TRESHOLD=0 FSTAB_LINE NFS=0 NUM_PATTERN="[0-9]*"
  local NFS_SERVER NFS_WHAT_CANON WHAT_CANON WHAT_ORIG WHERE_FS WHERE_ORIG WHERE_CANON
  set -o pipefail
  case "$1" in
    UUID=*)						# Identify device by UUID ==> UUID="..."
      WHAT_CANON="$( lsblk --noheadings --output UUID ${1} )" ; ERROR_CODE="$?"
      ;&						# Continue to next pattern
    *:/*)						# Identify device by NFS address ==> system:/path
      if [[ -z ${WHAT_CANON} ]] ; then
        WHAT_CANON="$1"
        NFS_WHAT_CANON="${1##*:}"
        NFS_SERVER="${1%%:*}"
        What_CANON="$( GET_MATCHING_NFS_DOMAIN_IN_FSTAB ${NFS_SERVER} ):${NFS_WHAT_CANON}"
        (( ERROR_CODE <= ERROR_TRESHOLD )) && { FSTAB_LINE=( $( grep -E --max-count 1 "^${WHAT_CANON}\s" /etc/fstab ) ) ; ERROR_CODE="$?" ; }
        if (( ERROR_CODE <= ERROR_TRESHOLD )) ; then
          NFS="1"
          WHERE_FS="${WHERE_FS[1]}"			# Get the 2nd column
          WHERE_ORIG="${WHERE_FS}"
          WHERE_CANON="${WHERE_FS}"
        fi
      fi
      ;&						# Continue to next pattern
    /dev/*)						# Identify device by special device name ==> /dev/...
      WHAT_ORIG="$1"
      [[ -z ${WHAT_CANON} ]] && WHAT_CANON="$1"
      (( ERROR_CODE <= ERROR_TRESHOLD && ! NFS )) && { WHAT_CANON="$( realpath --canonicalize-missing "${WHAT_CANON}" )" ; ERROR_CODE="$?" ; }
      (( ERROR_CODE <= ERROR_TRESHOLD )) && { FSTAB_LINE=( $( grep -E --max-count 1 "^${1}\s" /etc/fstab ) ) ; ERROR_CODE="$?" ; }
      if (( ERROR_CODE <= ERROR_TRESHOLD )) ; then
        WHAT_FS="${FSTAB_LINE[0]}"			# Get the 1st column
        WHERE_FS="${WHERE_FS[1]}"			# Get the 2nd column
        WHERE_ORIG="${WHERE_FS}"
        WHERE_CANON="${WHERE_FS}"
      fi
      ;;
    *)							# Must be a mount-point pathname
      WHERE_ORIG="$1"
      WHERE_CANON="$( realpath --canonicalize-missing "$1" )" ; ERROR_CODE="$?"
      if (( ERROR_CODE <= ERROR_TRESHOLD )) ; then
        while : ; do
          if (( ERROR_CODE <= ERROR_TRESHOLD )) ; then
            FSTAB_LINE=( $( grep -E --max-count 1 "\s${WHERE_CANON}${NUM_PATTERN}\s" /etc/fstab ) )
            ERROR_CODE="$?"
          fi
          if (( ERROR_CODE <= ERROR_TRESHOLD )) ; then
            WHERE_FS="${FSTAB_LINE[1]}"			# Prepare to get the 2nd column
            WHAT_FS="${FSTAB_LINE[0]}"			# Get the 1st column
            WHAT_ORIG="${WHAT_FS}"
            WHAT_CANON="${WHAT_FS}"
            break
          else
            WHERE_CANON="$(dirname "${WHERE_CANON}")"
            [[ $WHERE_CANON == / ]] && break
          fi
          ERROR_CODE=0
        done
      fi
      ;;
  esac
  set +o pipefail
  (( ERROR_CODE <= ERROR_TRESHOLD )) && return 0
  _USAGE_CHOICE_ "_MOUNT_IT_FIND_IN_FSTAB: Cannot find filesystem in column two of /etc/fstab for filesystem \"$1\"."
}

##________________________________________________________________________________
##
## UMOUNT_IT - Un-mount the filesystems/devices ($*) mounted by MOUNT_IT.
##   Usage: UMOUNT_IT [ -A | FS_OR_DEVICE... ]
##     If $1 == -A then umount all remembered mounts in reverse order
##       of mounting.
##     If $1 is missing the last entry in _MOUNTED_FS_ARRAY_ is un-mounted.
##       Otherwise search the "mounted" array for FS_OR_DEVICE.
function UMOUNT_IT() {
  local FS_ARRAY FS_ARRAY_IDX FS_ARRAY_IDX_LAST FS IDX _MOUNTED_FS_ARRAY_IDX_ IS_LVM SUDO
  IS_ROOT || SUDO="sudo"
  if [[ $1 == -A ]] ; then
    shift 1
    (( $# > 0 )) && set -- $( REVERSE_ARGS "${!_MOUNTED_FS_ARRAY_[@]}" )
  fi
  if (( $# == 0 )) & then
    set -- ${!_MOUNTED_FS_ARRAY_[@]}
    (( $# > 0 )) && shift $((${#_MOUNTED_FS_ARRAY_[@]} - 1))
  fi
  while (( $# > 0 )) ; do				# Each entry in "_MOUNTED_FS_ARRAY_" contains WHAT, WHERE and LVM information (space separated)
    for _MOUNTED_FS_ARRAY_IDX_ in ${!_MOUNTED_FS_ARRAY_[*]} ; do
      [[ -z ${_MOUNTED_FS_ARRAY_[${_MOUNTED_FS_ARRAY_IDX_}]} ]] && break 2	# Empty entry ==> END
      FS_ARRAY=( ${_MOUNTED_FS_ARRAY_[${_MOUNTED_FS_ARRAY_IDX_}]} )		# Get the info as an array
      FS_ARRAY_IDX_LAST="$(( ${#FS_ARRAY[*]} - 1 ))"	# Calculate the index of the last entry
      IS_LVM=${FS_ARRAY[${FS_ARRAY_IDX_LAST}]}		# Remember the last entry
      unset FS_ARRAY[${FS_ARRAY_IDX_LAST}]		# Do not want the last entry any more
      if IS_NUMERIC "$1" ; then
        FS=${FS_ARRAY[0]}				# Assume the first one is the best to use
        break
      else
        for FS_ARRAY_IDX in $( echo -n ${!FS_ARRAY[*]} ) ; do	# Have to look for the right saved entry
          [[ $1 == ${FS_ARRAY[${FS_ARRAY_IDX}]} ]] && { FS="${1}" ; break 2 ; }
        done
        continue					# Not found. Look for the next one
      fi
    done
    [[ -z $FS ]] && _USAGE_CHOICE_ "UMOUNT_IT: Cannot find the device/filesystem entry \"$1\" in _MOUNTED_FS_ARRAY_."
    ${SUDO} umount ${FS} || _USAGE_CHOICE_ "UMOUNT_IT: Error while un-mounting \"$1\"."
    [[ ${IS_LVM} == YES ]] && ${SUDO} lvchange -an ${FS_ARRAY[${IDX}]}	# if an LV then de-activate it
     unset _MOUNTED_FS_ARRAY_[${_MOUNTED_FS_ARRAY_IDX_}]	# Remove this element from the list
    shift 1
  done
}

##________________________________________________________________________________
##
## PAD_IT - Displays a string padded to a specific LENGTH with PAD.
##   Usage: PAD_IT [-L LENGTH ] [-P PAD ] [-R] [-T] [-V VAR] STRING
##   Where:
##     STRING Is the string to be padded.
##  -L LENGTH Is the length of the output string. The default LENGTH is 8.
##     -P PAD Is a string of 1 or more characters used to pad STRING to
##            length LENGTH. The default PAD is a single space " ".
##         -R Right justified. Place the padding before STRING. The default
##            is to pad on the left (after STRING).
##         -T Truncate overlength STRING on the left if -R otherwise truncate
##            on the right.
##         -V VAR Store the result in variable VAR rather than displaying it.
function PAD_IT() {
  local RightJust Truncate Var
  local Count LenResult="8" LenStr Padding PadStr=" "
  while (( $# > 0 )) ; do
    case "$1" in
      -L) LenResult="${2}" ; shift 2 ;;
      -P) PadStr="${2}"    ; shift 2 ;;
      -R) RightJust="1"    ; shift 1 ;;
      -T) Truncate="1"     ; shift 1 ;;
      -V) Var="$2" ; unset ${Var} ; shift 2 ;;
       *) break ;;
    esac
  done
  LenStr="${#1}"
  if (( LenStr > LenResult )) ; then			# Too long already
    if (( Truncate )) ; then
      (( RightJust )) && Result="${1:LenStr-LenResult}" || Result="${1:0:LenResult}"
    else
      Result="${1}"
    fi
  else
    Count=$(( ( ( LenResult - LenStr ) / ${#PadStr} ) + 2 ))
    Padding="$( eval "printf '${PadStr}%.0s' {1..${Count}}" )"
    if (( RightJust )) ; then
      Result="${Padding}${1}"
      Result="${Result:${#Result}-LenResult}"
    else
      Result="${1}${Padding}"
      Result="${Result:0:${LenResult}}"
    fi
  fi
  [[ -n ${Var} ]] && eval ${Var}=\"\${Result}\" || echo -n "${Result}"
}

##________________________________________________________________________________
##
## PAUSE - A simple function that waits for a carriage return or 'q' to quit.
##   Usage: PAUSE [ARGS}
##   Where: ARGS If present, will be displayed before the prompt.
##               They may contain "echo" escape characters.
function PAUSE() {
  local ANSWER
  # Display the ARGS this way as the prompt for 'read' does not recognize escape sequences.
  echo -en "${@}Press ENTER to continue (or q to quit): "
  read ANSWER
  [[ ${ANSWER} == "q" ]] && exit
}

##________________________________________________________________________________
##
## PROGRESS - Displays a "." every INTERVAL times it is called.
##   Usage: To set the INTERVAL (no "." limit). Call outside the loop:
##     PROGRESS [{-R | INTERVAL}]
##   Usage: To estimate the INTERVAL. Call outside the loop:
##     PROGRESS -E [ESTIMATED [ MAXDOTS ]]
##   Usage: For subsequent calls within a loop:
##     PROGRESS
##   Where:   -R Reset INTERVAL, ESTIMATED and MAXDOTS to their defaults.
##            -E Generate an INTERVAL based upon ESTIMATED and MAXDOTS.
##      INTERVAL Set the progress interval. The default is 1. A "." will be
##               displayed every INTERVAL times PROGRESS is subsequently called.
##     ESTIMATED Number of times PROGRESS is expected to be called by the
##               script. Used to calculate the INTERVAL. The default is 100.
##       MAXDOTS The maximum number of "." to be displayed. The default is 100.
##
##   To initialize, call PROGRESS (with arguments) once outside the loop.
##
##   Within a loop PROGRESS (without arguments) displays "." (on standard error)
##     every INTERVAL time.
##
##   The arguments ESTIMATED and MAXDOTS can be used to set a reasonable
##     INTERVAL to limit the total number of "." displayed. This is useful if the
##     number of iterations within the loop is unknown.
##     If used, the calculations are:
##       1)   Set: INTERVAL=abs(ESTIMATED-INTERVAL)
##       2) While: INTERVAL>MAXDOTS ; Set: INTERVAL=INTERVAL/2
##       3)   Set: INTERVAL to upper half of MAXDOTS
##          Where: MAXDOTS/2 <= INTERVAL <= MAXDOTS
function PROGRESS() {
  local IS_ESTIMATE _PROGRESS_ESTIMATE_ _RESULT_
  _ERROR_MESSAGE_=""
  if (( $# > 0 )) ; then				# Recalculate INTERVAL if arguments are present
    if [[ $1 =~ -[ER] ]] ; then
      _PROGRESS_INTERVAL_="0" _PROGRESS_ESTIMATE_="0" _PROGRESS_MAX_="0"
      [[ $1 == -E ]] && IS_ESTIMATE="1"
      shift 1
    fi
    [[ 0$1$2 =~ - ]] && ((_RESULT_++))			# No negative numbers
    IS_NUMERIC 0$1$2 || ((_RESULT_++))			# All args must be numeric
    (( _RESULT_ )) && ERROR "PROGRESS: All arguments ($1${2:+ }$2) must be positive integers."
    _PROGRESS_COUNTER_="-1"				# Set to -1 so PROGRESS with args won't display a "."
    _PROGRESS_INTERVAL_="${1:-1}"			# Get the interval (or set to the default)
    if (( IS_ESTIMATE )) ; then				# Recalculate the interval based upon ESTIMATED
      _PROGRESS_MAX_="${2:-100}"			# Get the maximum number of dots (or set to the default)
      _PROGRESS_ESTIMATE_="${1:-${_PROGRESS_MAX_}}"	# Get the expected number of calls (or set to the default)
      _PROGRESS_INTERVAL_="$(( _PROGRESS_ESTIMATE_ / _PROGRESS_MAX_ ))"
      # Round up.
      (( _PROGRESS_ESTIMATE_ - (_PROGRESS_INTERVAL_ * _PROGRESS_MAX_) > (_PROGRESS_INTERVAL_ / 2) )) && ((_PROGRESS_INTERVAL_++))
    fi
  fi
  (( ++_PROGRESS_COUNTER_ < _PROGRESS_INTERVAL_ )) && return
  echo -n "." > /dev/stderr
  _PROGRESS_COUNTER_="0"
}

##________________________________________________________________________________
##
## REVERSE_ARGS - Display the arguments in reverse order.
function REVERSE_ARGS() {
  local ARG REV_ARG
  for ARG in "${@}" ; do
    REV_ARG=("${ARG}" "${REV_ARG[@]}")
  done
  echo "${REV_ARG[@]}"
}

##________________________________________________________________________________
##
## SORT_ARGS - Sort the arguments to this function and display the sorted result.
##             No argument can contain whitespace.
##   Usage: SORT_ARGS [-N] [-S SORTOPTION]... { -L | [-V VAR [-A]] } ARGS...
##   Where:
##     -A Store the result in an array rather than a scalar variable.
##     -L Display each sorted ARG on a separate line.
##     -N Sort in a natural (ASCII code) order (with LC_COLLATE=C).
##     -S SORTOPTION is any option allowed by the sort command.
##        This option can be repeated for each sort option required.
##     -V VAR
##        Store the result in scalar variable VAR rather than displaying it.
##     ARGS are the values to be sorted.
##   EXAMPLE of common option combinations:
##       "-S -d"          A dictionary sort.
##       "-S -V"          A version sort.
##       "-S -n"          A sort with numbers in ascending numerical order.
##       "-N"             An ASCII sort (uses LC_COLLATE=C {ASCII code order}).
##       "-N -S -n"       An ASCII sort, numbers in ascending numerical order.
##       "-S -r"          Sort in reverse order
##       "-N -S -r"       An ASCII sort in reverse order
##       "-N -S -r -S -n" An ASCII sort in reverse numerical order
##     Sort AN_ARRAY on the numeric digits following the '-'.
##   EXAMPLE:
##       ARRAY=(file-1 file-10 file-11 file-2 file-20 file-3 file-30)
##       SORT_ARGS -S "-n -t- -k 2,2" -A -V SORTED ${ARRAY[*]}
##       echo "${SORTED[@]}"
##         file-1 file-2 file-3 file-10 file-11 file-20 file-30
function SORT_ARGS() {
  local Arg Ans Array Lines Nat SortOptions Var
  while (( $# > 0 )) ; do
    case "$1" in
      -A) Array="1"        ; shift 1 ;;
      -L) Lines="1"        ; shift 1 ;;
      -N) Nat="export LC_COLLATE=C"   ; shift 1 ;;
      -S) SortOptions+="$2 " ; shift 2 ;;
      -V) Var="$2" ; unset ${Var} ; shift 2 ;;
       *) break ;;
    esac
  done
  (( Array && ${#Var} == 0 )) && ERROR "SORT_ARGS: Option \"-A\" specified but no variable name defined."
  (( Lines && ${#Var}  > 0 )) && ERROR "SORT_ARGS: Cannot use -L with -A and/or -V."
  # Note: "${*}" expands with each argument on a new line
  Ans="$( set -f ; IFS=$'\n ' ; ${Nat} ; sort ${SortOptions} <<<"${*}" | gawk '{ printf "%s ", $0 }' ; )"
  if [[ -n ${Var} ]] ; then
    (( Array )) && eval ${Var}=\( \${Ans} \) || eval ${Var}=\"\${Ans}\"
  else
    if (( Lines )) ; then
      for Arg in ${Ans} ; do
        echo ${Arg}
      done
    else
      echo -n "${Ans}"
    fi
  fi
}

##________________________________________________________________________________
##
## SORT_ARGS_WS - Sort the arguments and display the results.
##                Arguments can have whitespace.
##   Usage: SORT_ARGS_WS [-S "SORTOPTIONS"] { -L | [-V VAR [-A]] } ARGS...
##   Where: SORTOPTIONS Are any options allowed by the sort command.
##                   -L Display each sorted ARG on a separate line.
##               -V VAR Store the result in variable VAR rather than displaying it.
##                   -A Store the result in an array rather than a variable.
##                 ARGS are the values to be sorted.
##   Notes: This function is the same as SORT_ARGS but is slower in execution.
##          Option -L is mutually exclusive with -V and -A.
##          Each ARGi must be quoted. The output is re-quoted.
##   EXAMPLE:
##     Sort AN_ARRAY of file names on the numeric digits following a '-'
##   ARRAY=("my file-11" "our file-10" "a file-1" file-2 file-20 file-3 file-30)
##   SORT_ARGS_WS -A -V SORTED_ARRAY -S "-n -t- -k 2,2" "${ARRAY[@]}"
##   echo ${SORTED_ARRAY[*]@Q}
##     'a file-1' 'file-2' 'file-3' 'our file-10' 'my file-11' 'file-20' 'file-30'
function SORT_ARGS_WS() {
  local Ans Array=0 Idx Lines=0 SortOptions SortedOutput Var
  local GawkScript="${FUNCTIONS_SH_DIR}/.${FUNCTIONS_SH_BASENAME}.SORT_ARGS_WS_DisplayResult.gawk"
  while (( $# > 0 )) ; do
    case "$1" in
      -A) Array="1"        ; shift 1 ;;
      -L) Lines="1"        ; shift 1 ;;
      -S) SortOptions="$2" ; shift 2 ;;
      -V) Var="$2" ; unset ${Var} ; shift 2 ;;
       *) break ;;
    esac
  done
  (( Array && ${#Var} == 0 )) && ERROR "SORT_ARGS_WS: Option \"-A\" specified but no variable name defined."
  (( Lines && ${#Var}  > 0 )) && ERROR "SORT_ARGS_WS: Cannot use -L with -A and/or -V."
  TMP_FILE_CREATE SortedOutput
  while (( $# > 0 )) ; do
     echo -e "${1}"
     shift 1
  done | ( set -f ; LC_COLLATE=C sort ${SortOptions} ) > "${SortedOutput}"
  eval $( gawk -v "Array=${Array}" -v "Lines=${Lines}" -v "Var=${Var}" -f "${GawkScript}" "${SortedOutput}" )
  TMP_FILE_DELETE SortedOutput
}

##________________________________________________________________________________
##
## ROOT_ONLY - Ensures only 'root' can run this script.
function ROOT_ONLY() {
  if ! IS_ROOT ; then
    _USAGE_CHOICE_ "You must be root to run this script."
    (( _IS_USAGE_EXIT_ )) && exit 2 || return 2
  fi
}

##________________________________________________________________________________
##
## TEST_DISPLAY - Display the TESTing variable values.
##   Useful for determining what variables (and their values) are available.
function TEST_DISPLAY() {
  set | grep "^TEST_.*="
}
##________________________________________________________________________________
##
## TEST_RESET - Reset the TESTing variables to the defaults and stop TESTing.
##
## The TEST_RESET function defines the TESTing variables shown by the
## TEST_DISPLAY command. To see all the TESTing variable assignments
##   execute the following:
##       source <PATH>/functions.sh ; TEST_DISPLAY
##   Use them to correctly display commands in a script whose TEST_SET is
##     on. Note: If any of the defined TESTing variables are used in a command
##     line, that command line must start with: '${TEST_CMD} eval '.
##   NOTE: Any bash metacharacters must be escaped.
##   The following are examples using the TESTing variables.
##     EXAMPLE:
##       Using the TESTing variables. Notice the required "eval" if any bash
##         operators are replaced in the command line.
##
##        ${TEST_CMD} eval CMD1 ${TEST_IN} FILE1 ${TEST_PIPE} CMD2 \
##          ${TEST_OUT}FILE2 ${TEST_ERR_OUT} ${TEST_TRUE} CMD_TRUE \
##          ${TEST_FALSE} CMD_FALSE ${TEST_BG}
##
##        If TESTing is off, will execute:
##    eval CMD1 < FILE1 | CMD2 >FILE2 2>&1 && CMD_TRUE || CMD_FALSE &
##       If TESTing is on, will display:
##   Testing: eval CMD1 < FILE1 | CMD2 >FILE2 2>&1 && CMD_TRUE || CMD_FALSE &
##
##     EXAMPLE: Using the TESTing metacharacters.
##        ${TEST_CMD} eval ${TEST_OPEN} CMD1 ${TEST_NL} CMD2 ${TEST_CLOSE}
##         If TESTing is off, will execute:          ( CMD1 ; CMD2 )
##         If TESTing is on,  will display: Testing: ( CMD1 ; CMD2 )
##     EXAMPLE: Using TESTing with no extra TESTing variables in a command
##              (no "eval" is needed).
##      ${TEST_CMD} rm -rf $1
##         If TESTing is off, will execute:          rm -rf $1
##         If TESTing is on,  will display: Testing: rm -rf $1
function TEST_RESET() {
  _TESTING_=""
  declare -gx  TEST_CMD=''
  declare -gx  TEST_TRUE='&&'   TEST_FALSE='||'  TEST_PIPE='|'          TEST_ERR_PIPE='|&'
  declare -gx  TEST_IN='<'      TEST_HERE='<<'   TEST_HERE_EOF='<<-EOF' TEST_HERE_STRING='<<<'
  declare -gx  TEST_OUT='>'     TEST_APPEND='>>' TEST_ERR='2>'          TEST_OUT_ERR='2>&1'    TEST_ERR_OUT='${TEST_OUT_ERR}' TEST_BOTH='>&'
  declare -gx  TEST_BG=' &'     TEST_NL=';'      TEST_OPEN='('          TEST_CLOSE=')'         TEST_LIST1=' {'                TEST_LIST2=' ; }'
  declare -gx  TEST_EXPR1='(('  TEST_EXPR2='))'  TEST_EVAL1='[[ '       TEST_EVAL2=' ]]'
  declare -gx  TEST_CMD1='$('   TEST_CMD2=')'    TEST_CMD3='<('
  declare -gx  TEST_OUT_NULL='>/dev/null'        TEST_ERR_NULL='2>/dev/null'                   TEST_BOTH_NULL='>&/dev/null'
}

TEST_RESET						# The default is to NOT test (TEST_CMD=""}

##________________________________________________________________________________
##
## TEST_SET - Turn on TESTing.
##   A script option of '-t' or '--test' will enable the display of TEST
##   commands rather than executing them.
function TEST_SET() {
  _TESTING_="1"
  TEST_CMD="echo -e ${RED}Testing:${DEF} "
}

##________________________________________________________________________________
##
## TMP_FILE_CREATE - Create a temporary work file/directory that can be referenced
##     by TMP_NAME_VAR. Temporary files/directories created by this function will
##     be deleted by CLEANUP_SCRIPT upon exit from the calling script.
##   Usage:
##     TMP_FILE_CREATE [ --DIR ] [ -S SUFFIX ] { [ -D DIRPATH ] TMPnameVAR }...
##   Where:
##          --DIR Treat the names (TMPnameVAR) specified in the remaining
##                arguments as directory names. --DIR must be the first argument.
##      -S SUFFIX Optional suffix used to add a file extension at the end of the
##                temp file name.
##     -D DIRPATH Optional pathname of the directory where the TMP files are
##                created (the default is: /tmp). DIRPATH is created if it
##                doesn't exist. DIRPATH remains in effect for all subsequent
##                TMPnameVAR or until another "-d DIRPATH" is encountered.
##                  EXAMPLE: cat ${TMPnameVAR}
##     TMPnameVAR The variable name used to reference the file/directory.
##   The pathname of the file/directory is
##         /tmp/TMPnameVAR.FILE.$BASHPID[.SUFFIX]
##     E.G. "TMP_FILE_CREATE -S txt MyFile" in process 2345 creates the file:
##         /tmp/MyFile.FILE.2345.txt
##   Returns 0 if TMP file created successfully otherwise returns 1.
##   Returns 2 if the temporary file or directory already exists.
##   If a temporary directory (DIRPATH) is created, the contents of DIRPATH are
##     deleted by CLEANUP_SCRIPT above.

function TMP_FILE_CREATE() {
  local _FILE_DIR_ _RETURN_=0 _SUFFIX_ _TMP_NAME_ _TMP_PATH_ _TMP_DIR_="/tmp"
  _SUFFIX_="$BASHPID"
  [[ $1 == --DIR ]] && { _FILE_DIR_="DIR" ; shift 1 ; } || _FILE_DIR_="FILE"
  while (( $# != 0 )) ; do
    case "$1" in
      -D) _TMP_DIR_="$( realpath $2 )"
          { [[ -d ${_TMP_DIR_} ]] || mkdir "${_TMP_DIR_}" ; } || _USAGE_CHOICE_ "TMP_FILE_CREATE: Directory \"$2\" cannot be created."
          shift 2
          ;;
      -S) _SUFFIX_+=".$2" ; shift 2
          ;;
       *) [[ $1 =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || _USAGE_CHOICE_ "TMP_FILE_CREATE: Parameter name \"$1\" is invalid."
          if [[ -n ${_TMP_NAMES_ARRAY_[$1]} ]] ; then
            _TMP_PATH_="${_TMP_NAMES_ARRAY_[$1]}"
            _TMP_NAME_="$( basename "${_TMP_PATH_}" )"
            _RETURN_="2"				#_USAGE_CHOICE_ "TMP_${_FILE_DIR_}_CREATE: TMP ${_FILE_DIR_,,} \"$1\" already exists."
          else
            _TMP_NAME_="${1}.${_FILE_DIR_}.${_SUFFIX_}"
            _TMP_PATH_="${_TMP_DIR_}/${_TMP_NAME_}"
          fi
          [[ -e ${_TMP_PATH_} ]] && _RETURN_="2"	#_USAGE_CHOICE_ "TMP_${_FILE_DIR_}_CREATE: TMP ${_FILE_DIR_,,} \"${_TMP_PATH_}\" already exists."
          if (( _RETURN_ != 2 )) ; then
            if [[ ${_FILE_DIR_} == FILE ]] ; then
              touch "${_TMP_PATH_}" || _USAGE_CHOICE_ "TMP_FILE_CREATE: The temporary file \"${_TMP_PATH_}\" cannot be created."
              cat /dev/null > "${_TMP_PATH_}"		# Ensure it is empty
            else
              mkdir "${_TMP_PATH_}" || _USAGE_CHOICE_ "TMP_FILE_CREATE: The temporary directory \"${_TMP_PATH_}\" cannot be created."
            fi
          fi
          _TMP_NAMES_ARRAY_[$1]="${_TMP_PATH_}"		# Store the TMP path in the array using the variable name ($1) as the index
          declare -g -x $1				# Create $1 as a (global, exportable) reference (to the _TMP_NAMES_ARRAY_)
          eval export $1="${_TMP_NAMES_ARRAY_[$1]}"	# Create the reference ==> the variable named in $1 to the array element
          shift 1
          ;;
    esac
  done
  return ${_RETURN_}
}

##________________________________________________________________________________
##
## TMP_DIR_CREATE - Like TMP_FILE_CREATE but creates a temporary directory rather
##                  than a file.
function TMP_DIR_CREATE() {
  TMP_FILE_CREATE --DIR "$@"
}

##________________________________________________________________________________
##
## TMP_FILE_DELETE - Delete TMP files or dirs created by TMP_FILE_CREATE
##   Usage: TMP_FILE_DELETE [--DIR ] { -P PATTERN | -A | TMPfileVAR ... }
##   Where: --DIR Treat the names (TMPfileVAR) specified in the remaining
##                arguments as directory names. --DIR must be the first argument.
##             -A Delete all known TMP files (or dirs) created.
##     -P PATTERN Delete all the TMP files (or dirs) matching PATTERN.
##     TMPfileVAR The Variable reference of the TMP file (or dir) to delete.
function TMP_FILE_DELETE() {
  local _FILE_DIR_ _PATTERN_ _SUFFIX_ _TMP_NAME_ _TMP_NAMES_
  _SUFFIX_="$BASHPID"
  [[ $1 == --DIR ]] && { _FILE_DIR_="DIR" ; shift 1 ; } || _FILE_DIR_="FILE"
   _PATTERN_=""
  while (( $# != 0 )) ; do
    case "$1" in
      -A) _TMP_NAMES_="${!_TMP_NAMES_ARRAY_[*]}"	# Remove all the TMP files or dirs
          break
          ;;
      -P) _PATTERN_="$2"
          _TMP_NAMES_="${!_TMP_NAMES_ARRAY_[*]}"	# Remove TMP files or dirs matching _PATTERN_
          break
          ;;
       *) _TMP_NAMES_+="$@"				# Just delete the named TMP file/dir.
          shift 1
          ;;
    esac
  done
  for _TMP_NAME_ in ${_TMP_NAMES_} ; do
#    [[ ${_TMP_NAME_} =~ ${_SUFFIX_} ]] || continue	# Omly for this process
    [[ -n ${_PATTERN_} ]] && { [[ ${_TMP_NAME_} =~ "${_PATTERN_}" ]] || continue ; }
    [[ ${_TMP_NAMES_ARRAY_[${_TMP_NAME_}]} =~ .${_FILE_DIR_}. ]] || continue	# Skip all files/dir names that don't match ${_FILE_DIR_}
    if [[ ${_FILE_DIR_} == FILE ]] ; then
      rm -f "${_TMP_NAMES_ARRAY_[${_TMP_NAME_}]}" &>/dev/null
    else
      rm -r -f "${_TMP_NAMES_ARRAY_[${_TMP_NAME_}]}" &>/dev/null
    fi
    unset _TMP_NAMES_ARRAY_[${_TMP_NAME_}]
    shift 1
  done
  (( ${#_TMP_NAMES_ARRAY_[*]} == 0 )) && unset _TMP_NAMES_ARRAY_
}

##________________________________________________________________________________
##
## TMP_DIR_DELETE - Like TMP_FILE_DELETE but deletes temporary directories
##                  instead of files.
function TMP_DIR_DELETE() {
  TMP_FILE_DELETE --DIR "$@"
}

##________________________________________________________________________________
##
## TMP_FILE_PERMANENT - Prevent CLEANUP from deleting the TMP file created by
##                      TMP_FILE_CREATE function
##   Usage: TMP_FILE_PERMANENT [--DIR ] TMPfileVAR [ NEWNAME ]
##   Where:
##          --DIR Treat the name (TMPfileVAR) as a directory name.
##     TMPfileVAR The Variable reference of the TMP file (or dir) to delete.
##        NEWNAME The TMP file/dir is renamed to the pathname NEWNAME.
function TMP_FILE_PERMANENT(){
  local Name="file" _TMP_NAME_
  [[ $1 == --DIR ]] && { Name="directory" ; shift 1 ; }	# File or Ir - just a name
  for _TMP_NAME_ in ${!_TMP_NAMES_ARRAY_[*]} ; do
    if [[ ${_TMP_NAME_} == $1 ]] ; then
      [[ -n $2 ]] && mv "${_TMP_NAMES_ARRAY_[${_TMP_NAME_}]}" "$2"
      unset ${_TMP_NAMES_ARRAY_[${_TMP_NAME_}]}
      return
    fi
  done
  _USAGE_CHOICE_ "Temporary ${Name} \"$1\" does not exist."
}

##________________________________________________________________________________
##
## TMP_DIR_PERMANENT - Like TMP_FILE_PERMANENT but works for temporary directories
##                     instead of files.
function TMP_DIR_PERMANENT() {
  TMP_FILE_PERMANENT --DIR "$@"
}

##________________________________________________________________________________
##
## TRIM - Displays STRING with surrounding whitespace removed.
##        Whitespace within STRING will not be changed.
##   Usage: TRIM [{-L|-R }] [-V VAR] "STRING"
##   Where:
##    -L Only trim whitespace on the left.
##    -R Only trim whitespace on the right.
##    -V VAR Store the result in variable VAR rather than displaying it.
function TRIM() {
  local Left Len Result Right Var
  while (( $# > 0 )) ; do
    case "$1" in
      -R) Right=$'\x1C' ; shift 1 ;;			# Use ASCII <FS> character
      -L) Left=$'\x1C'  ; shift 1 ;;			# Ditto
      -V) Var="$2" ; unset ${Var} ; shift 2 ;;
       *) break ;;
    esac
  done
  Len="${#1}"
  read Result <<<"${Right}${1}${Left}"			# Add <FS> to beginning and/or end; then read value
  [[ -n $Left ]]  && Result="${Result%${Left}}"		# Get rid of <FS>
  [[ -n $Right ]] && Result="${Result#${Right}}"	# Ditto
  [[ -n ${Var} ]] && eval ${Var}=\""${Result}"\" || echo -n "${Result}"
}

##________________________________________________________________________________
##
## USAGE - External stub for normal error processing.
##         Calls _USAGE_DEFAULT_ passing all arguments.
##   Usage: USAGE [OPTIONS] [MESSAGE]
##   Where: OPTIONS and MESSAGE are described in _USAGE_DEFAULT_ below.
##   Depending upon USAGE it will exit the script with a return code of 1
##     or will return to the script with a return code of 2
##   The calling script may redefine this function to implement its own USAGE.
function USAGE() {
  _USAGE_DEFAULT_ "$@"
  return $?
}

# ________________________________________________________________________________________________
#
# Internal _USAGE_DEFAULT_ stub for internal error processing.
# If _LOCAL_USAGE_ is not set, it will invoke the normal USAGE routine which may be redefined by the calling routine.
function _USAGE_CHOICE_() {
  _ERROR_MESSAGE_="$@"
  (( _LOCAL_USAGE_ )) && _USAGE_DEFAULT_ "$@" || USAGE "$@"
  return $?
}

##________________________________________________________________________________
##
## _USAGE_DEFAULT_ - Default help and error function.
##     Displays an optional message possibly followed by a "USAGE" suggestion.
##   Usage: USAGE [ MESSAGE... ]
##   Where: MESSAGE is the message to be displayed.
##          If missing a default message is displayed.
##   MESSAGE is displayed on stderr.
function _USAGE_DEFAULT_() {
  if (( $# > 0 )) ; then
    _ERROR_MESSAGE_="${_USAGE_ERROR_PREFIX_}${CMD}: ${*}"
  else
    _ERROR_MESSAGE_="${_USAGE_ERROR_PREFIX_}${CMD}: An error has occurred."
  fi
  echo -e "${_ERROR_MESSAGE_}${_HELP_SUGGESTION_}" 1>&2
  _LOCAL_USAGE_=""
  (( _IS_USAGE_EXIT_ )) && exit 2 || { _IS_USAGE_EXIT_="${_OLD_IS_USAGE_EXIT_}" ; return 2 ; }
}

##________________________________________________________________________________
##
## ERROR_PREFIX - Alias for ERROR_SET_PREFIX
function ERROR_PREFIX() {
  ERROR_SET_PREFIX "$@"
}

##________________________________________________________________________________
##
## USAGE_SET - Function to invoke a USAGE control function using an option.
##   Usage: USAGE_SET OPTION
##          OPTION may be:
##            -E  USAGE_SET_EXIT
##            -F  USAGE_FORCE_RETURN
##            -R  USAGE_SET_RETURN
## -P [-R] "PFX"  ERROR_SET_PREFIX [ -R ] "PFX" ...
function USAGE_SET() {
  local ARG
  case "$1" in
    -E)
      USAGE_SET_EXIT ;;
    -F)
      USAGE_FORCE_RETURN ;;
    -P)
      [[ $2 == -R ]] && ARG="$2"
      shift 2
      ERROR_SET_PREFIX ${ARG} "$@"
      ;;
    -R)
      USAGE_SET_RETURN ;;
     *)
      _USAGE_CHOICE_ "ERROR: USAGE_SET: Argument 1 must be one of -E, -F, -P OR -R."
  esac
}

##________________________________________________________________________________
##
## USAGE_SET_EXIT - Exit after displaying an error message.
##   From this point forward, the USAGE and ERROR functions exit with an
## This is the default.
function USAGE_SET_EXIT() {
  _IS_USAGE_EXIT_="1"
}
USAGE_SET_EXIT						# Default is to exit if USAGE function is called.

##________________________________________________________________________________
##
## USAGE_EXIT - Alias for USAGE_SET_EXIT
function USAGE_EXIT() {
  USAGE_SET_EXIT
}

##________________________________________________________________________________
##
## USAGE_SET_RETURN - Return after displaying an error message.
##   From this point forward, the USAGE and ERROR functions return with an
##   error code of 2 rather than exit the script.
function USAGE_SET_RETURN() {
  _IS_USAGE_EXIT_=""
}

##________________________________________________________________________________
##
## USAGE_RETURN - Alias for USAGE_SET_RETURN
function USAGE_RETURN() {
  USAGE_SET_RETURN
}

##________________________________________________________________________________
##
## USAGE_FORCE_RETURN - Issue a USAGE message and return even if set to USAGE_EXIT
function USAGE_FORCE_RETURN() {
  _OLD_IS_USAGE_EXIT_="${_IS_USAGE_EXIT_}"
  _IS_USAGE_EXIT_=""
  _USAGE_DEFAULT_ "$@"
}

##________________________________________________________________________________
##
## USAGE_OBSOLETE - Issue a default 'obsolete' message and 'exit' irrespective
##                  of USAGE_RETURN. The exit code is 2.
##   Usage: USAGE_OBSOLETE [ ARGS ]
##   If no ARGS present the default message displayed is:
##       The script "${CMD}" is obsolete.
##   If only one argument then the default message is displayed followed by the
##     contents of '$1' on a new line.
##   Otherwise the 1st argument replaces the default message and is displayed
##     followed by the contents of the remaining arguments.
##   Include this function at the beginning of an obsolete script.
##   The message is displayed on stderr.
function USAGE_OBSOLETE() {
  local DEFAULT_MESSAGE="The script \"${CMD}\" is obsolete."
  if (( $# == 1 )) ; then
    DEFAULT_MESSAGE+="\\n$1"
  elif (( $# > 1 )) ; then
    DEFAULT_MESSAGE="$@"
  fi
  echo -e "${DEFAULT_MESSAGE}" 1>&2
  exit 2
}

##________________________________________________________________________________
##
## OBSOLETE - Alias for USAGE_OBSOLETE
function OBSOLETE() {
  USAGE_OBSOLETE "$@"
}

##________________________________________________________________________________
##
## USAGE_FORCE_OBSOLETE - Call USAGE_OBSOLETE with the text "Exit forced. "
##   preceding the default message.
##   Usage: USAGE_FORCE_OBSOLETE [ ARGS... ]
##   Display the default message and ARGS.
##      Exit forced. This script "${CMD}" is obsolete.
function USAGE_FORCE_OBSOLETE() {
  USAGE_OBSOLETE "Exit forced. This script \"${CMD}\" is obsolete." "$@"
}

##________________________________________________________________________________
##
## ERROR_SET_PREFIX - Change the ERROR message prefix
##   Usage: ERROR_SET_PREFIX [ -R ] [ ARGE ARGT ]
##   Where:
##     ARGE Replace the default prefix proceding any ERROR message.
##          The default (in red characters) is: "ERROR: ".
##     ARGT Replace the default prefix proceding any TRY message.
##          The default (in red characters) is: "  TRY: ".
##       -R The prefix is printed as is (no red characters).
##   Calling this function with no ARGS resets the prefix to the default.
function ERROR_SET_PREFIX() {
  local blk red
  [[ $1 == -R ]] && { blk="" red="" ; shift 1 ; } || { blk="${DEF}" ; red="${RED}" ; }
  if (( $# )) ; then
    export _USAGE_ERROR_PREFIX_="${red}$1${blk}"
    export  _USAGE_TRY_PREFIX_="${red}$2${blk}"
    export _USAGE_ERROR_PREFIX_TEXT_="${1}"
    export _USAGE_ERROR_PREFIX_LEN_="${#1}"
    export _USAGE_TRY_PREFIX_TEXT_="${2}"
    export _USAGE_TRY_PREFIX_LEN_="${#2}"
  else
    export _USAGE_ERROR_PREFIX_TEXT_="ERROR: "
    export _USAGE_ERROR_PREFIX_="${red}${_USAGE_ERROR_PREFIX_TEXT_}${blk}"	# Default USAGE message prefix.
    export _USAGE_TRY_PREFIX_TEXT_="  Try: "
    export  _USAGE_TRY_PREFIX_="${red}${_USAGE_TRY_PREFIX_TEXT_}${blk}"	# Default TRY message prefix.
    export _USAGE_ERROR_PREFIX_LEN_="7"
    export _USAGE_TRY_PREFIX_LEN_="7"
  fi
  export ERROR_PREFIX_SPACES="$(printf "%*s" ${_USAGE_ERROR_PREFIX_LEN_} "")"
}
ERROR_SET_PREFIX					# Default USAGE message prefix.

##________________________________________________________________________________
##
## WARNING - Simple warning reporting with no USAGE message.
##   The message is displayed on stderr.
function WARNING() {
  echo -e "${WARNING_ERROR_PREFIX}""$@" 1>&2
  return 0
}

##________________________________________________________________________________
##
## WARNING_SET_PREFIX - Change the WARNING message prefix.
##   Usage: WARNING_SET_PREFIX [ -R ] [ ARGS... ]
##   Where: ARGS Replace the default prefix preceding any WARNING message.
##   No trailing space is added. The default (in purple characters) is:
##     "WARNING: "
##   If the first ARG is "-R" (raw) then the prefix is printed as is (no
##     purple characters).
##   Calling this function with no ARGS resets the prefix to the default.
function WARNING_SET_PREFIX() {
  local pur
  [[ $1 == -R ]] && { pur="${DEF}" ; shift 1 ; } || pur="${PUR}"
  if (( $# == 0 ))
    then export WARNING_ERROR_PREFIX="${pur}WARNING:${DEF} "	# Default WARNING message prefix.
    else export WARNING_ERROR_PREFIX="${pur}$*${DEF}"
  fi
}
WARNING_SET_PREFIX					# Default WARNING message prefix.

##________________________________________________________________________________
##
## ZERO_FILL - Display a NUMBER padded on the left with zeros.
##   Usage: ZERO_FILL [-L LENGTH] [-V VAR] NUMBER
##   Where:
##        NUMBER should be a decimal or integer but can be any set of characters.
##     -L LENGTH Is the size of the zero-filled result. It defaults to 8.
##        -V VAR Store the result in variable VAR rather than displaying it.
##   Note: If length NUMBER > LENGTH, NUMBER is returned.
function ZERO_FILL() {
  local Num="8" Var VarOption
  while true ; do
    case $1 in
      -L) Num="$2" ; shift 2 ;;
      -V) Var="$2"
          unset ${Var}
          VarOption="-V ${Var}"
          shift 2 ;;
       *) break ;;
    esac
  done
  PAD_IT -R ${VarOption} -L ${Num} -P "0" "$1"		# Pad NUMBER to the left with zeros
}

##________________________________________________________________________________
##
## FUNCTIONS_SH_INIT - Initialise global variables needed by functions.sh
function FUNCTIONS_SH_INIT() {
  declare -gx _functions_sh_loaded_="1"			# Indicates functions.sh exists in the environment
  declare -gx CMD_PATH="$(realpath ${0#-})"		# The parent script file pathname
  declare -gx CMD="${CMD_PATH##*/}"			# The parent script file name
  declare -gx CMD_DIR="${CMD_PATH%/*}"			# The parent script directory location
  if [[ $1 == ";" ]] ; then				# This was NOT called by a script
    CMD_LINE=""						# Initializing a terminal session - CMD_LINE not avaialable
  else							# This was...
    declare -gx CMD_LINE=$(sed -e 's/^\/bin\/bash./"/' -e 's/\x0/" "/g' -e 's/ "$//' /proc/$$/cmdline)	# The command line (quoted)
    set +o histexpand					# We don't want history expansion in scripts
  fi
  declare -gx _GET_ARGS_PARSED_HELP_DIR_
  [[ -z ${_GET_ARGS_PARSED_HELP_DIR_} ]] && _GET_ARGS_PARSED_HELP_DIR_=~/".config/${FUNCTIONS_SH_NAME}"
  declare -gx LOCAL_PCS=${LOCAL_PCS:=LOCAL_PC_NAMESUNDEFINED} # List of local PCs to be accessed
  declare -gx _LOCAL_PC_="$(hostname -s)"		# The PC's name
  _LOCAL_PC_="${_LOCAL_PC_,,}"				#   In lowercase
  declare -gx _LOCAL_DOMAIN_="$( host ${_LOCAL_PC_} | grep "has address" )"
  _LOCAL_DOMAIN_="${_LOCAL_DOMAIN_%% *}"		# Extract the first part
  _LOCAL_DOMAIN_="${_LOCAL_DOMAIN_#*.}"			# Extract the domain name
  _LOCAL_DOMAIN_="${_LOCAL_DOMAIN_,,}"			#   In lowercase
  declare -Agx _TMP_NAMES_ARRAY_			# This array holds the RMP_FILE/TMP_DIR pathnames
  _TMP_NAMES_ARRAY_[\;]="';'"				# Ensure there always is at least one (dummy) entry
  _FONT_="Sans 14" _FONT_SIZE_="medium" _FONT_STYLE_="normal" _FONT_WEIGHT_="normal"
  _MOUNTED_FS_ARRAY_IDX_="0"
  USAGE_SET_EXIT					# Default is to exit if USAGE function is called.
  if (( $# )) ; then					# Normally we don't need to do this
    _CLEANUP_INIT_
    COLORS_SET -GR					# Set the color variables for GUI dialogs
    COLORS_SET -TR					# Set the color variables for text dialogs (default).
    TEST_RESET						# The default is to NOT test (TEST_CMD=""}
    ERROR_SET_PREFIX					# Default USAGE message prefix.
    WARNING_SET_PREFIX					# Default WARNING message prefix.
  fi
}

##________________________________________________________________________________
##
## _EXPORT_ALL_ - Export everything needed for any child scripts to
##     execute these functions
##   Usage: _EXPORT_ALL_ [ set | unset ]
##   Where: set   == Export the all the function and variable names.
##          unset == Reset the exported names.
function _EXPORT_ALL_ () {
  local option
  if [[ ${BASH_SOURCE[*]} =~ "/etc/profile.d" || ! $- =~ /i/ ]] ; then	# Only if non interactive
    FUNCTIONS_SH_INIT ";"
  else
    FUNCTIONS_SH_INIT
    return 0						# No export if called by a script
  fi
  [[ ${1:-set} == set ]] && option="-x" || option="+x"
  declare -g ${option} -f DO_HELP _EXPORT_ALL_ FUNCTIONS_SH_INIT _CLEANUP_INIT_
  declare -g ${option} -f ASK ASK_GUI ASK_WITH_MENU ASK_WITH_MENU_GUI
  declare -g ${option} -f _ASK_DOIT_ _ASK_PROMPT_TEXT_ _ASK_NORMALIZE_CHOICES_RANGE_ _ASK_PROMPT_QUIT_
  declare -g ${option} -f _ASK_VERIFY_CHARACTERS_ _ASK_VERIFY_ANSWER_RANGE_ _ASK_VERIFY_WORDS_ _ASK_YN_
  declare -g ${option} -f _ASK_WRAP_CHOICES_ _ASK_WITH_MENU_DOIT_
  declare -g ${option} -f CLEANUP_SCRIPT CLEANUP_ALWAYS EXPORT_CLEANUP
  declare -g ${option} -f COLOR_MAKE _COLOR_MAKE_VERIFY_COLOR_ COLORS_DISPLAY COLORS_SET
  declare -g ${option} -f ENVIRONMENT_DISPLAY TRIM ZERO_FILL
  declare -g ${option} -f ERROR _ERROR_DOIT_ ERROR_GUI ERROR_SCRIPT ERROR_TRAP_RESET ERROR_TRAP_SET
  declare -g ${option} -f FIND_NFS_PATH_FROM_FSTAB _FIND_NFS_PATH_FROM_FSTAB_
  declare -g ${option} -f GET_ARGS GET_ARGS_DEFAULT GET_ARGS_HIGHLIGHT GET_ARGS_LIST_OPTIONS
  declare -g ${option} -f GET_ALL_PC_NAMES GET_IP_FROM_DOMAIN GET_LOCAL_DOMAIN_NAME GET_LOCAL_PC_NAME
  declare -g ${option} -f GET_MATCHING_NFS_DOMAIN_IN_FSTAB GET_OTHER_PC_NAME GET_ALL_UNIQUE_NFS_DOMAINS_IN_FSTAB
  declare -g ${option} -f IS_EXCLUSIVE IS_HEX IS_IP IS_IP_ALIVE IS_LOGICAL_VOLUME IS_MAC IS_NUMERIC
  declare -g ${option} -f IS_ROOT IS_TESTING IS_UUID
  declare -g ${option} -f MOUNT_IT _MOUNT_IT_FIND_IN_FSTAB_ UMOUNT_IT
  declare -g ${option} -f PAD_IT PAUSE PROGRESS ROOT_ONLY
  declare -g ${option} -f REVERSE_ARGS SORT_ARGS SORT_ARGS_WS
  declare -g ${option} -f TEST_DISPLAY TEST_RESET TEST_SET
  declare -g ${option} -f TMP_FILE_CREATE TMP_DIR_CREATE TMP_FILE_DELETE
  declare -g ${option} -f TMP_DIR_DELETE TMP_FILE_PERMANENT TMP_DIR_PERMANENT
  declare -g ${option} -f USAGE _USAGE_CHOICE_ _USAGE_DEFAULT_ ERROR_PREFIX USAGE_SET USAGE_SET_EXIT USAGE_EXIT
  declare -g ${option} -f USAGE_SET_RETURN USAGE_RETURN USAGE_FORCE_RETURN USAGE_OBSOLETE OBSOLETE
  declare -g ${option} -f USAGE_FORCE_OBSOLETE ERROR_SET_PREFIX
  declare -g ${option} -f WARNING WARNING_SET_PREFIX
  declare -g ${option}    REVERSE_ARGS _TMP_NAMES_ARRAY_ _MOUNTED_FS_ARRAY_
  declare -g ${option}    FUNCTIONS_SH_NAME FUNCTIONS_SH_BASENAME FUNCTIONS_SH_DIR FUNCTIONS_SH_PATH
  declare -g ${option}    FUNCTIONS_SH_SHARED_DIR FUNCTIONS_SH_SUFFIX _FONT_
}

unset _TMP_NAMES_ARRAY_
_EXPORT_ALL_

##________________________________________________________________________________
##
## END of help for "functions.sh"

