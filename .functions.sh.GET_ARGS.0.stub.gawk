#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	.functions.sh.GET_ARGS.0.globals.gawk
#
# PURPOSE = "This gawk script identifies/defines some of the global variables."
# VERSION = "14.01.06 - Jul 01, 2026"
#
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

@include ".functions.sh.GET_ARGS.2.pre_scan.gawk"
@include ".functions.sh.GET_ARGS.3.ga_scan.gawk"
@include ".functions.sh.GET_ARGS.5.help.gawk"
@include ".functions.sh.GET_ARGS.6.save.gawk"

# @include ".functions.sh.GET_ARGS.2.pre_scan.gawk.NEW"
# @include ".functions.sh.GET_ARGS.3.ga_scan.gawk.NEW"
# @include ".functions.sh.GET_ARGS.5.help.gawk.NEW"
# @include ".functions.sh.GET_ARGS.6.save.gawk.NEW"

# The BEGIN block in this script and in the ..GET_ARGS.5.help... script define all the global variables used.
# The definitions for some global variables are not really necessary but help in creating consistent variable names.
BEGIN {
  # Note: Commented out lines define variables that don't have to be initialized.
  ## These variables and values are passed (using -v ...) to gawk by the bash GET_ARGS function.
  # Variables passed/set by awk option '-v'
  # BashScriptPurpose = X 				# BASH VAR - What was set by the parent script (spaces hidden by \034)
  # BashTabStop = X					# BASH VAR - The terminal tabstop value
 ## GAah	 					# BASH VAR - The ANSII code for ACTION highlights
 ## GAoh	 					# BASH VAR - The ANSII code for OPTION highlights
  # GArs	 					# BASH VAR - The ANSII code to reset all colors
 ## GAsh	 					# BASH VAR - The ANSII code for SECTION headers
 ## GAth	 					# BASH VAR - The ANSII code for TITLE lines

  Bash_ALL_OPTIONS_ = " "				# A list of all options defined (no "-"). Becomes _ALL_OPTIONS_ for IS_EXCLUSIVE

  # The following are used to manage parsing of the GET_ARGS_DIRECTIVES (GAOpt).
  # GAOptsAndArgsCount = 0				# The number of elements in GAOpts
  # GAbasicOpts = X					# Additional internally generated GAOPTS (basic opts)
  # GAOpts[1] = X					# Array of the GET_ARGS_DIRECTIVES
  # Gdx = 0						# The index into the GAOpts array
  # GdxNext = 0						# The index into the next GAOpt in the GAOpts array
  # GAOpt = X						# The current GET_ARGS_DIRECTIVE
  # GAOptPart = X 					# 5-char normalized GAOpt
  # GApreviousGAOpt = X					# Remember the previous GAOpt
  # GApreviousGAOptPart = X				# Ditto GAOptPart
  # GAOptArg = X 					# The current GAOpt argument
  # GAOptArgCount = 0					# The number of arguments following any single GAOpt
  # GAOptText = X					# The current GAOpt and all arguments (for error reporting)
  # GAnoOpts = 0					# True if --Opts_None defined
  GAbasicOptsCnt = 8					# The count of basic options defined
  GAatOrNear = "\nError occurred at or near:\n    "	# Standard error text
  # GApos = 0						# The current position of the current GAOpt or GAOptArg
  # GAthisPos = 0					# The remembered position of the current GAOpt or GAOptArg
  # GAnextPos = 0					# The position of the next GAOpt or GAOptArg
  GAinvalidOPTiChars = @/^-|^[:?]$|\s+/			# Characters not allowed in any OPTi
  GAinvalidOPTiCharsMess = " cannot start with \"-\", or contain whitespace, \":\" or \"?\"."	# Message for characters not allowed in any OPTi
  # GAdefinedOPTi[*] = X				# An array of all defined options
  # GAOptValueNeeded[*] = X				# An array of all defined options that need a value
  # GAsavedOPTLIST[*] = X				# The array or all defined OPTLIST
  GAOptsMulti[""] = 1					# Array of GAOpts that can be used more than once (indexed by OPT1, value=1)
  GAactionKeys = " "					# A space separated list of valid ACTION keys
  # GAopt_dCount = 0					# The count of --Opt_D
  # GAact_dCount = 0					# The count of --Act_D
  # GAskipDes_D = 0					# The --Des_D to be skipped because of --Hid_D or <FC>
  # GAdes_dAction = X					# The ACTION keyword for --Act_D. ... --Des_D
  # GAactionKey = X					# The value of ACTKEY
  # GAactionKeyCount = 0				# The count of -K ACTKEY used (<0=no -K used; >0=-K used)
  # GAscanCount = 0					# Count of GAOpts excountered
  # GAactionArgs = X					# Manage --Act_D items
  # GAactionInfo = X					# Ditto
  # GAactionOpt = X					# Ditto
  # GAactionOptions = X					# Ditto

  # GAdefinedFCs = X					# A list (characters, no separators) of all defined filter codes
  # GAOptFCs = X					# A Character list of filter codes defined for one GAOpt
  GAansiESC = "\033"					# The <ESC> character
  # The following manage the separators between/within GET_ARGS_DIRECTIVES and parent script options.
  GAseparator = "' '"					# The separator for the GET_ARGS arguments

  ## The indices of the GAOptInst array define the normalized names of all possible GET_ARGS_DIRECTIVES (GAOpt).
  ## The value of each GAOptInst element is a set of single-character "instructions" (arg counts and actions) as follows:
  ##    Char1=Primary Groups: 0=Option def, 1=Description def, 2=Args/Opts control, 3=Pre/Post execution
  ##                          4=Help info,  5=Help augment,    6=Misc help info,    7=Internal - for help
  ##                          9=Pre-scanned GAOpt
  ##    Char2=subType of OPTi  Char3=Num args required,  Char4=Num args optional
  ##    Char5=Need <FC>,       Char6=Leading <NL>,       Char7=Num leading <TABs>
  ##    Char8=Section,         Char9=Just help,         Char10=Normalize help text
  ##    Char11=header in my... section
  ##      "Need <FC>": If True (1) the GAOpt may require a filter code - but only if filters are defined.
  ##      "Section":   Which help section to display info.
  ##                   Plus codes: x=ignore, X=No display, *=Section obtained from the GAOpt argument.
  ##      "Just help": If True (1) the GAOpt is processed by "ga-scan" only if help was requested.

  # GAinst[...] = X					# The instruction characters are split into this array
  Grp=1;Typ=2;Req=3;Opt=4;Fil=5;Lnl=6;Tab=7;Sec=8;Nor=10;My=11	# CharPos indices into the array GAinst[CharPos]
  ## Note: Hlp=9 not used anymore.
  ##                             11
  ##                    12345678901
  GAOptInst["--Opt"] = "0010111O00"			# --Option_Definition
  GAOptInst["--Act"] = "0116111O00"			# --Action_Definition - 1 arg required, 4 args optional
  GAOptInst["--ac1"] = "0116111A00"			# Internal - for first --Act_D entriy in the ACTION section
  GAOptInst["--ac2"] = "0114101A00"			# Internal - for remaining --Act_D entries in the ACTION section
  GAOptInst["--Hid"] = "0210111X00"			# --Hidden_Definition
  GAOptInst["--Hel"] = "0310111B10b"			# Internal automatic --Help_Definition (lowercase)
  GAOptInst["--Hlp"] = "0310111B10b"			# Internal automatic --Help_Definition (uppercase)
  GAOptInst["--Tes"] = "0311111B10b"			# Internal automatic --Test
  GAOptInst["--Ver"] = "0310111B10b"			# Internal automatic --Version

  GAOptInst["--Des"] = "1010002O11"			# --Description_Definition
  GAOptInst["--Dba"] = "1010002B11"			# Internal - --Description_Definition for basic options

  GAOptInst["--Arr"] = "2101111N00n"			# --Args_Array
  GAOptInst["--Aax"] = "2210111N00n"			# --Args_Maximum
  GAOptInst["--Ain"] = "2310111N00n"			# --Args_Minimum
  GAOptInst["--Aon"] = "2400111N00n"			# --Args_None
  GAOptInst["--Apt"] = "2510111N00n"			# --Args_Optional
  GAOptInst["--Aeq"] = "2610111N00n"			# --Args_Required
  GAOptInst["--Ais"] = "2710111N00n"			# --Args_list
  GAOptInst["--Oin"] = "2a10111N00n"			# --Opts_Minimum
  GAOptInst["--Oeq"] = "2b10111N00n"			# --Opts_Required
  GAOptInst["--Oon"] = "2c00111N00n"			# --Opts_None

  GAOptInst["--Whe"] = "4010111W11"			# --Where
  GAOptInst["--Inf"] = "4110111I11"			# --Info_
  GAOptInst["--Exa"] = "4310111E11"			# --Examples
  GAOptInst["--Fle"] = "4410111F11"			# --Files
  GAOptInst["--Aut"] = "4510111U11"			# --Author
  GAOptInst["--Bug"] = "4610111G11"			# --Bugs
  GAOptInst["--See"] = "4710111M11"			# --Seealso
  GAOptInst["--Not"] = "4810111N11n"			# --Note (may be geneerated automatically)

  GAOptInst["--Tit"] = "5021110*11"			# --Title - 2 args required, 1 optional arg
  GAOptInst["--Par"] = "5121111*11"			# --Paragraph - 2 args required, 1 optional arg

  GAOptInst["--Cmd"] = "6010111D11"			# --Cmd_Description
  GAOptInst["--Cop"] = "6101111C11"			# --Copyright - 1 arg optional
  GAOptInst["--Exp"] = "6211000x00"			# --Expand
  GAOptInst["--Bri"] = "6311000x00"			# --Brief
  GAOptInst["--Com"] = "6411000x00"			# --Compact
  GAOptInst["--Tab"] = "6511000x00"			# --Tabstops
  GAOptInst["--Def"] = "6612000x00"			# --Default
  GAOptInst["--Pag"] = "6710000x00"			# --Pager

  # The following are pre-processed so only processed by ga_scan for arg count check.
  GAOptInst["--Bas"] = "9011011x01b"			# --Basic_Option arguments
  GAOptInst["--Fil"] = "9010100x01"			# --Filter - <FC> and 1 extra argument required
  GAOptInst["--Sec"] = "9020000x00"			# --Section_Header - 2 required arguments
  GAOptInst["--Hea"] = "9110000H11"			# --Heading
  GAOptInst["--Atn"] = "9210010S11"			# --Action
  GAOptInst["--Var"] = "9310000x00x"			# --Variable
  GAOptInst["--Deb"] = "9401000x00"			# --Debug - one optional argument
  GAOptInst["--Noc"] = "9500000x00"			# --Nocolor
  # The following are used for generation of a section text
  GAOptInst["--Tra"] = "9410010T11"			# Internal - --Trailer
  GAOptInst["--Pur"] = "9800011P01p"			# Automatic PURPOSE section
  GAOptInst["--Syn"] = "9800011S01"			# Automatic SYNTAX section
  # The following deliniate "Typ" sets within a group
  GAopt_dGrp = 0					# For GRP=0 and GRP=1
  GAdes_dGrp = 1					# For GRP=0 and GRP=1
  GAact_dInst1 = "--ac1"				# First time use this instruction
  GAact_dInst2 = "--ac2"				# Remainder use this instruction
  GAactionType = 1					# For Grp 0: --Act_D
  GAhiddenType = 2					# For Grp 0: --Hid_D
  GAoptsType = "a"					# For Grp 2: Typ < GAactionType: are --Args_..., otherwise --Opts_...
  GAisArgOpt = 2					# For Grp 2: --Args... and --Opts_...
  GAisMax = 2						# For Grp 2: --Args_Max or --Opts_Max
  GAisMin = 3						# For Grp 2: --Args_Min or --Opts_Min
  GAisList = 7						# For Grp 2: --Args_List
  GAisTitle = 0						# For Grp 5 Typ 0: --Title
  GAisPreScan = 9					# For GRP 9
  GAbigNum = 1024^4					# Hopefully more than the number or arguments ever encounteres

  # Manage analysis of GAOpts: --Args_... (Cat=1 thru 6) and --Opts_... (Cat=7 or 8)
  # Cat: Category 1 thru 8 (the value of GAinst[Typ])
  # Cnt: Count expected.
  # Cnt1, Plu, Cnt2 Only used for --Args_List
  # Key: KEYWORD or "-L"
  # Msg: The --Args_... --Opts_.. message for "Note" or for an error
  Cat=1;Cnt=2;Cnt1=3;Plu=4;Cnt2=5;Key=6;Msg=7	# Indices into the arrays GAtest...
  # The following 2 arrays have 6 elements parsed from the GAOpt argument:
  ## IE for the GAOpt "--Args_Opt 3@FILES":
  ## GAtestArgs[Cat]=5, GAtestArgs[Cnt]=3, GAtestArgs[Key]="FILES"
  # GAtestArgs[Cat] = 0					# If TRUE --Args_... has been encountered before
  # GAtestOpts[Cat] = 0					#   Ditto --Opts_...
  ## For the remaining arrays, values are: [Cat]=TRUE if the GAOPT was used.
  # GAtestAction[Cat] = 0				# If TRUE --Action has been encountered before
  # GAtestExpand[Cat] = 0				#   Ditto --Expand
  # GAtestBrief[Cat] = 0				#   Ditto --Brief
  # GAtestCompact[Cat] = 0				#   Ditto --Compact
  # GAtestEBC[Cat] = 0					#   Ditto - special case
  # GAtestDefault[Cat] = 0				#   Ditto --Default
  # GAtestTabstop[Cat] = 0				#   Ditto --Tabs
  # GAtestCopyright[Cat] = 0				#   Ditto --Copyright
  # GAtestCmd[Cat] = 0					#   Ditto --Cmd
  # GAtestHeading[Cat] = 0				#   Ditto --Heading
  # GAtestPager[Cat] = 0				#   Ditto --Pager
  # GAtestDebug[Cat] = 0				#   Ditto --Debug
  # GAtestVariable[Cat] = 0				#   Ditto --Variable
  GAisDebug = 0						# True if GAOpt == --Debug

  # The following are used by scanIsDuplicate() to determine what to do with the above GAtest....
  GAtypeIsArg  =  2					# The test is for args (--Args_...)
  GAtypeIsOpt  =  3					# The test is for opts (--Opts_...)
  GAtypeIsNum  =  1					# The test is for a numeric arg
  GAtypeIsNone =  0					# The test is for pre-scan no arg
  GAtypeIsText = -1					# The test is for pre-scan text arg

  # Variables whose contents are returned to GET_ARGS() in functions.sh
  BashUnsetVars = "unset "				# BASH A string of bash variables (Opt_OPT1) to be unset
  BashUnsetVarsMax = 150				# BASH Max length of the "unset" command
  BashUnsetVarsLen = BashUnsetVarsMax			# BASH current length allowed for the "unset" command
  ## BashOpt_X = BASH VAR				# BASH VAR (Opt_x & Opt_x_Val) Created for each option encountered upon parent script execution
  ## BashArgs[1] = BASH VAR				# BASH VAR Array (origin 1) for each non-option encountered upon parent script execution
  ## BashPreCmd = X					# BASH The bash command to be executed before PS parsing
  ## BashPostCmd = X					# BASH The bash command to be executed after PS parsing

  # The following define the variable names created by the parent script option/argument scan
  PSvarListCount = 6					# The number of varile names in the VARLIST
  PSoptPrefixVar = "Opt_"				# The bash variable prefix for options discovered
  PSoptSuffixVar = "_Val"				# The bash variable suffix for option values discovered
  PSoptsAllListVar = "Opts_All"				# The bash list variable containg each option encountered
  PSaltOptsArrayVar = "Alt_Opts"			# The bash array containing alternate option spellings
  PSoptsAltArrayVar = "Opts_Alt"			# The bash array containing alternate option to option 1
  PSargsArrayVar = "Args"				# The bash array containing the arguments

  # HELP display pager variables
  HELPless= " |& less -R -S "				# The pager for displaying help
  HELPcat= ""						# The non-pager for displaying help
}
