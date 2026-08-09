#!/usr/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	.functions.sh.GET_ARGS.2.pre_scan.gawk
#
# PURPOSE = "These functions do a pre-scan of the GET_ARGS_OPTS to locate GAOpts that will influence
#            the information collected during the GAOpts "full" scan and the parent script options scan."
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

BEGIN {
  # Note: Commented out lines define variables that don't have to be initialized.
  # The default BASICOPTIONS, <FC> and <HM>. They may be redefined by the GAOpt --Basic_Option
  _h_="h" ; _help_="help"	; _hInt_= ""
  _H_="H" ; _HELP_="HELP"	; _HInt_= ""
  _t_="t" ; _test_="test"	; _tInt_= ""
  _v_="v" ; _version_="version"	; _vInt_= ""
  _a_="a" ; 			; _a_msg_="All:     Display all help information."
  _b_="b" ; 			; _b_msg_="Brief:   Display summarized help and use \"brief\" tabstops."
  _c_="c" ; 			; _c_msg_="Compact: Remove blank lines and use \"compact\" tabstops."
  _e_="e" ; 			; _e_msg_="Expand:  Include blank lines and use normal tabstops."
  PREmessage = ""					# Possible --Debug messages
  PREtmpMessage = ""					# Ditto
}

# Do a pre-scan to process GET_ARGS_DIRECTIVES: --Bas_O, --Filter, --Heading, --Compact and --Tab
function preScanGAOpts(		basicOptionError) {
  preGAOptSearch( "--Deb" )				# Search for a --Debug statement
  GAtestDebug[Cat] = 0					# Reset as is tested again in ga_scan

  preGAOptSearch( "--Var" )				# Locate any change in the created bash variables
  GAtestVariable[Cat] = 0				# Reset as is tested again in ga_scan
  preMergeDebugMessage()				# Merge messages

  preGAOptSearch( "--Bas" )				# Locate changes to BASIC OPTION options AND record
  HELPcodesFCandHM = _a_ _b_ _c_ _e_
  HELPhelpOptions = " " _h_ " " _help_ " " _hInt_ " " _H_ " " _HELP_ " " _HInt_ " "
  HELPtestNversionOptions = " " _t_ " " _test_ " " _tInt_ " " _v_ " " _version_ " " _vInt_ " "
  preMergeDebugMessage( "Basic Option Modifications" )				# Merge messages

  preGAOptSearch( "--Sec" )				# Locate changes to section headings
  preMergeDebugMessage( "Section Header Modifications" )

  if ( GAisDebug && length(PREmessage) > 0 ) {		# Debug mode requested
    mainMakeDebugComment( "" )
    mainMakeDebugComment( "======= Variable, Basic Option and Section Modifications =======" PREmessage )
    mainMakeDebugComment( "" ) }

  preGAOptSearch( "--Filter" )				# Search for filter statements
  if ( GAdefinedFCs ) {
    if ( GAdefinedFCs !~ _a_ ) {			# There are filters and "all" not present
      GAdefinedFCs = GAdefinedFCs _a_			# Ensure the default <FC> "a" (all) is present
      GAdefinedFCdescriptions[_a_] = _a_msg_
    }
    if ( ! HELPbasicOptsFCs ) HELPbasicOptsFCs = _a_	# Set _a_ as the default
    basicOptionError = scanValidateFCs( HELPbasicOptsFCs, 1 )	# Verify they are AOK
    if ( basicOptionError ) {
      GAthisPos = HELPbasicOptsFCsPos			# Retrieve the remembered GAOpt position
      preError( basicOptionError " \"" HELPbasicOptsFCgaOpt " -F " HELPbasicOptsFCs "\"" )
    }
  }
  preInitializeBasicOpti()				# Define the basic options help text

  preGAOptSearch( "--Hea" )				# The heading is set at help initialization
  GAtestHeading[Cat] = 0				# Reset as is tested again in ga_scan

  preGAOptSearch( "--Noc" )				# --Nocolors

  preGAOptSearch( "--Action" )				# --Action
  GAtestAction[Cat] = 0					# Reset as is tested again in ga_scan
  preSetEBCdefaults()					# The default <HM> info
}

function preError(message) {
  # Show text surrounding the error
  mainError("GET_ARGS_DIRECTIVE pre-scan: " message GAatOrNear gensub(GAseparator," ","g",substr(GAOptsAndArgs,GAthisPos-8,BashColumns-5)) "...", GAcodeError )
}

# Search for GET_ARGS_DIRECTIVES for specific GAOpts that must be processed first.
function preGAOptSearch(gaOptPart) {
  GAnextPos = 1						# In the beginning...
  while ( GAnextPos ) {					# Note: "' '" is the argument separator
    GApos = match( substr(GAOptsAndArgs,GAnextPos), "' '" gaOptPart "[[:alpha:]_]*' '" )
    if ( ! GApos ) break				# Finished
    GAthisPos = GAnextPos + RSTART + 2
    GAOpt = substr(GAOptsAndArgs,GAthisPos,RLENGTH-6)
    GAnextPos = GAnextPos + RSTART + RLENGTH - 4	# Reposition to be at the beginning ' '
    switch ( gaOptPart ) {
      case "--Filter":
        preParseFilters()
        continue
      case "--Hea":
        scanIsDuplicate( GAtestHeading, GAOpt, GAtypeIsText )
        preParseHeading()				# Analyze the heading
        continue
      case "--Sec":					# Section header changes
        preParseSectionHeader()
        continue
      case "--Action":					# --Action
        scanIsDuplicate( GAtestAction, GAOpt, GAtypeIsText )
        preGetNextArg()
        GAdes_dAction = GAmarkGAah GAOptArg ":" GArs		# Remember the ACTION keyword
        HELPsynopsisAction = " " GAmarkGAah GAOptArg GArs	# Don't really need this but code easier to read
        continue
      case "--Bas":
        preParseNewBasicOption()
        continue
      case "--Var":					# Variable name changes
        preParseVarNames()
        continue
      case "--Noc":					# No colors is requested
        preParseNoColors()
        continue
      case "--Deb":					# Debugging is requested
        preParseDebug()
        continue
    }							# END "switch ( gaOptPart ) ..."
  }							# END "while ( GAnextPos) ..."
}

function preGetNextArg(returnArg,optional,	pos,start) {
  start = GAnextPos + 3
  pos = match( substr( GAOptsAndArgs, start), GAseparator )	# Find the next character after ' '
  GAOptArg = substr( GAOptsAndArgs, start, pos - 1 )	# Extract the "argument"
  if ( GAOptArg ~ /^--[A-Z][a-z][a-z]/ ) {
    if ( ! optional ) preError( "Argument(s) missing for GAOpt: " GAOpt ) }
  else GAnextPos = GAnextPos + RSTART + RLENGTH - 1	# Reposition to start at next ' '
  if ( returnArg ) return GAOptArg			# Caller wants to reassign the value
}

function preInitializeBasicOpt(gaOpt,optFC,basicOpts,optional,key,message,	count,dash,idxO,opt_D,or,regex,space){
  for ( idxO in basicOpts ) {
    if ( basicOpts[idxO] == GAhideEQ ) continue		# This basic opt has been deleted
    count++						# count is either 1 or 2
    if ( count > 1 ) { space = " " ; or = "| " }	# Used to calculate a regular ecpression
    else or = " "
    if ( length(basicOpts[idxO]) == 1 ) dash = "-"
    else dash = "--"
    opt_D = opt_D space basicOpts[idxO] optional
    if ( optional ) regex = regex or dash basicOpts[idxO] " '"	# Make regex for ps_scan test
    else regex = regex or dash basicOpts[idxO] " "	# Ditto for non-optional option
  }
  if ( count ) {					# We have at least one that wasn't deleted
    # Create an internal basic option GAOPT for parsing by ga_scan.
    GAbasicOpts = GAbasicOpts "' '" gaOpt optFC "' '" opt_D key "' '--Dba' '" message
  }
  return regex						# Return the regex
}

# The set of internal GAOPT (--Hel, --Hlp, --Tes and --Ver) is used to generate the basic options
function preInitializeBasicOpti(	basicOpts,optKEYWORD,optDefaultMessage,optFC,optMessage,optMessageFC) {
  optDefaultMessage = "Display this information%s and exit.%s An <HM> of either b (brief), c (compact) or e (expand) will modify the default help display."
  if ( GAdefinedFCs ) {
    optKEYWORD = "@<FC>[<HM>]"
    optFC = "' '" HELPbasicOptsFCs
    optMessageFC = " Omit <FC>[<HM>] to get a list of acceptable filter (<FC>) and help modifier (<HM>) values." }
  else optKEYWORD = "@[<HM>]"
  # Process possible help #1 request
    delete basicOpts
    if ( _h_ && _h_ != GAhideEQ ) basicOpts[1] = _h_
    if ( _help_ && _help_ != GAhideEQ ) basicOpts[2] = _help_
    if ( _hInt_ && _hInt_ != GAhideEQ ) basicOpts[3] = _hInt_
    optMessage = sprintf(optDefaultMessage,"",optMessageFC)
    PSregexHelp = preInitializeBasicOpt( "--Hel", optFC, basicOpts, "::", optKEYWORD, optMessage )
  # Process possible help #2 request
    delete basicOpts
    if ( _H_ && _H_ != GAhideEQ ) basicOpts[1] = _H_
    if ( _HELP_ && _HELP_ != GAhideEQ ) basicOpts[2] = _HELP_
    if ( _HInt_ && _HInt_ != GAhideEQ ) basicOpts[3] = _HInt_
    optMessage = sprintf(optDefaultMessage," with a display pager",optMessageFC)
    PSregexHELP = preInitializeBasicOpt( "--Hlp", optFC, basicOpts, "::", optKEYWORD, optMessage )
  # Process possible testing request
    delete basicOpts
    if ( _t_ && _t_ != GAhideEQ ) basicOpts[1] = _t_
    if ( _test_ && _test_ != GAhideEQ ) basicOpts[2] = _test_
    if ( _tInt_ && _tInt_ != GAhideEQ ) basicOpts[3] = _tInt_
    optMessage = "Test the script. Commands preceded by \"${TEST_CMD}\" are displayed rather than executed. Any cleanup scripts (remove tmp files/dirs, umounts etc.) are executed. If NOCLEANUP is not null, no cleanup operations will be executed. This option may be combined with any OPTIONS or ACTIONS above."
    PSregexTest = preInitializeBasicOpt( "--Tes", optFC, basicOpts, "::", "@NOCLEANUP", optMessage )
    delete basicOpts
    if ( _v_ && _v_ != GAhideEQ ) basicOpts[1] = _v_
    if ( _version_ && _version_ != GAhideEQ ) basicOpts[2] = _version_
    if ( _vInt_ && _vInt_ != GAhideEQ ) basicOpts[3] = _vInt_
    PSregexVersion = preInitializeBasicOpt( "--Ver", optFC, basicOpts, "", "", "Display the version and exit." )
}

function preMergeDebugMessage(header) {
  if ( ! GAisDebug ) return
  if ( length(PREtmpMessage) > 0 ) {
    if ( length(header) > 0 ) PREmessage = PREmessage sprintf("\n#\n# ======= %s =======",header)
    PREmessage = PREmessage PREtmpMessage
    PREtmpMessage = ""
  }
}

function preParseDebug( 	modifier) {
  scanIsDuplicate( GAtestDebug, GAOpt, GAtypeIsText )
  GAisDebug = 1						# Turn on debugging
  preGetNextArg( 0, 1 )					# Look for options
  modifier = substr( GAOptArg, 3 )			# Is there an <FC> and/or <HM> or ...
  if ( modifier ) modifier = "=" modifier
  else modifier = "=\"\""
  if ( GAOptArg ~ /^-h/ ) {				# Internal debugging help
    _hInt_ = ";h_e_l_p"
    PSintBO = _hInt_
    }
  else if ( GAOptArg ~ /^-H/ ) {			# Internal debugging HELP
    _HInt_ = ";H_E_L_P"
    PSintBO = _HInt_
    }
  else if ( GAOptArg ~ /^-t/ ) {			# Internal debugging test
    _tInt_ = ";T_E_S_T"
    PSintBO = _tInt_
    }
  else if ( GAOptArg ~ /^-v/ ) {			# Internal debugging version
    _vInt_ = ";V_E_R_S_I_O_N"
    PSintBO = _vInt_
    modifier = ""
    }
  else return						# Nothing more to do
  PSintBO = "\"--" PSintBO modifier "\" "
  mainMakeDebugComment( "" )
  mainMakeDebugComment( "======= --Debug with Simulated Basic Option =======" )
  mainMakeDebugComment( GAOpt " " GAOptArg )
  mainMakeDebugComment( "" )
}

function preParseFilters(	filterCode,filterError,filterMsg) {
  filterCode = preGetNextArg(1)				# Pick up the argument to the --Filter
  filterError = "For \"--Filter %s %s\", the filter code \"" filterCode "\" "
  if ( length( filterCode ) != 1 || filterCode ~ /[^[:alnum:]]/ ) {
    preError( sprintf( filterError "must be a single alphanumeric character.", filterCode, "..." ) ) }
  if ( GAdefinedFCs ~ filterCode ) {
    preError( sprintf( filterError "is already assigned.", filterCode, "..." ) ) }
  GAdefinedFCs = GAdefinedFCs filterCode		# Remember the filter code
  filterMsg = preGetNextArg(1)				# Get the description
  GAdefinedFCdescriptions[filterCode] = filterMsg
}

function preParseHeading(	cmd,head,lenFixed,result,seps) {
  preGetNextArg()
  split( GAOptArg, head, "@", seps )			# Separate it
  if ( seps[1] == "@" ) {				# --Heading [N@]HEADING
    if ( ! mainIsNumeric(head[1]) ) {
      preError( sprintf("Heading length \"%s\" is not numeric.",head[1]) ) }
    HELPheading = head[2]				# Change the default
    HELPheadingLen = head[1]				# And set the length
    lenFixed = 1 }					# The length is specified
  else {
    HELPheading = head[1]				# Change the default
    HELPheadingLen = length( head[1] )			# And set the length
  }
  if ( HELPheading ~ GAansiESC && ! lenFixed ) {	# Have to adjust the length
    cmd = "ansifilter <<<'" HELPheading "'"		# Remove the <ESC> sequences
    cmd | getline result				# Get the pure text line
    close( cmd )
    HELPheadingLen = length( result )			# Set the new length without <ESC> sequences
    }
}

# Change any basic option <OLDCODE> to <NEWCODE>
function preParseNewBasicOption(	abceFCandHM,newOpt,newOptMsg,newOptOrig,oldOpt,oldOptOrig,pos) {
  preGetNextArg()					# Get the next argument
  switch ( GAOptArg ) {
    case "-D":						# Delete this BASEOPT
      preGetNextArg()					# Get the next arg
      GAbasicOptsCnt--					# Decrement the count of "basic option" options
      switch ( GAOptArg ) {				# Delete this basic option so mark it as "empty"
        case "h":
          PREtmpMessage = PREtmpMessage HELPnl "# Basic Option \"-" _h_ "\" deleted"
          _h_       = GAhideEQ
          break
        case "H":
          PREtmpMessage = PREtmpMessage HELPnl "# Basic Option \"-" _H_ "\" deleted"
          _H_       = GAhideEQ
          break
        case "help":
          PREtmpMessage = PREtmpMessage HELPnl "# Basic Option \"--" _help_ "\" deleted"
          _help_    = GAhideEQ
          break
        case "HELP":
          PREtmpMessage = PREtmpMessage HELPnl "# Basic Option \"--" _HELP_ "\" deleted"
          _HELP_    = GAhideEQ
          break
        case "t":
          PREtmpMessage = PREtmpMessage HELPnl "# Basic Option \"-" _t_ "\" deleted"
          _t_       = GAhideEQ
          break
        case "test":
          PREtmpMessage = PREtmpMessage HELPnl "# Basic Option \"--" _test_ "\" deleted"
          _test_    = GAhideEQ
          break
        case "v":
          PREtmpMessage = PREtmpMessage HELPnl "# Basic Option \"-" _v_ "\" deleted"
          _v_       = GAhideEQ
          break
        case "version":
          PREtmpMessage = PREtmpMessage HELPnl "# Basic Option \"--" _version_ "\" deleted"
          _version_ = GAhideEQ
          break
        default:
          preError( "For GET_ARGS_DIRECTIVE \"" GAOpt " -D " GAOptArg "\": Invalid BASEOPT \"" GAOptArg "\"." )
      }
      return						# And get out
    case "-F":						# Define the <FCs> for basic options
      preGetNextArg()					# Get the next arg
      HELPbasicOptsFCs = GAOptArg			# Remember them
      HELPbasicOptsFCgaOpt = GAOpt
      HELPbasicOptsFCsPos = GAthisPos			# Remember where we found it
      return
    default:
      pos = index( GAOptArg, "=" )			# Look for the required separator
      if ( pos == 0 ) {
        preError("Incorrectly formatted GET_ARGS_DIRECTIVE \"--Bas_O " GAOptArg "\".\nThe correct format is \"--Bas_O OLDOPT=NEWOPT[@MSG]\".") }
      oldOpt = substr( GAOptArg, 1, pos - 1 )
      newOpt = substr( GAOptArg, pos + 1 )
      if ( newOpt ~ GAinvalidOPTiChars ) {
        preError( "Invalid characters in NEWOPT \"" newOpt "\".\nNEWOPT" GAinvalidOPTiCharsMess ) }
  }
  oldOptOrig = oldOpt
  newOptOrig = newOpt
  abceFCandHM = substr(oldOpt,1,1)			# 1st character only - the rest may be ignored
  # The following codes can only be a single character so convert the old code and the new.
  if ( HELPcodesFCandHM ~ abceFCandHM ) {		# It's one of <FC> (a) or <HM> (bce) ==> 1 char only
    oldOpt = abceFCandHM
    pos = index(newOpt, "@")				# Look for a change of the message
    if ( pos ) newOptMsg = substr( newOpt, pos + 1 )
    else newOptMsg = ""
    newOpt = substr( newOpt, 1, 1 ) }			# It can only be 1 character long
  else {						# It's a basic option
    if ( length(oldOpt) == 1 ) {			# If the old opt is 1 character
      newOpt = substr( newOpt, 1, 1 ) }			#   Then both sides must be 1 character
    abceFCandHM = "" }					# The newOpt is a basic option - not <FC> or <HM>
  if ( HELPbasicOptions !~ " " oldOpt " " && HELPcodesFCandHM !~ oldOpt ) {
    preError( "For GET_ARGS_DIRECTIVE \"--Bas_O " GAOptArg "\": The OLDOPT \"" oldOptOrig "\" must be one of:\n\t" HELPbasicOptions gensub(/./,"& ","g",HELPcodesFCandHM)) }
  if ( HELPbasicOptions ~ " " newOpt " " || HELPcodesFCandHM ~ newOpt ) {
    preError( "For GET_ARGS_DIRECTIVE \"--Bas_O " GAOptArg "\": The NEWOPT \"" newOpt "\" is already assigned." ) }
  switch ( oldOpt ) {
    case "h":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Basic Option \"-%s\" changed to \"-%s\"", _h_, newOpt )
      _h_       = newOpt
      break
    case "H":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Basic Option \"-%s\" changed to \"-%s\"", _H_, newOpt )
      _H_       = newOpt
      break
    case "help":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Basic Option \"--%s\" changed to \"--%s\"", _help_, newOpt )
      _help_    = newOpt
      break
    case "HELP":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Basic Option \"--%s\" changed to \"--%s\"", _HELP_, newOpt )
      _HELP_    = newOpt
      break
    case "t":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Basic Option \"-%s\" changed to \"-%s\"", _t_, newOpt )
      _t_       = newOpt
      break
    case "test":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Basic Option \"--%s\" changed to \"--%s\"", _test_, newOpt )
      _test_    = newOpt
      break
    case "v":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Basic Option \"-%s\" changed to \"-%s\"", _v_, newOpt )
      _v_       = newOpt
      break
    case "version":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Basic Option \"--%s\" changed to \"--%s\"", _version_, newOpt )
      _version_ = newOpt
      break
    case "a":						# case "all":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Help filter code (<FC>) \"%s\" changed to \"%s\"", _a_, newOpt )
      _a_ = newOpt
      if ( newOptMsg ) _a_msg_ = newOptMsg
      break
    case "e":						# case "expand":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Help modifier (<HM>) \"%s\" changed to \"%s\"", _e_, newOpt )
      _e_ = newOpt
      if ( newOptMsg ) _e_msg_ = newOptMsg
      break
    case "b":						# case "brief":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Help modifier (<HM>) \"%s\" changed to \"%s\"", _b_, newOpt )
      _b_ = newOpt
      if ( newOptMsg ) _b_msg_ = newOptMsg
      break
    case "c":						# case "compact":
      PREtmpMessage = PREtmpMessage sprintf( "\n# Help modifier (<HM>) \"%s\" changed to \"%s\"", _c_, newOpt )
      _c_ = newOpt
      if ( newOptMsg ) _c_msg_ = newOptMsg
      break
    default:
      preError( "For GET_ARGS_DIRECTIVE \"--Bas_O " GAOptArg "\": Invalid OLDOPT \"" oldOpt "\"." )
  }
  # Replace OLDOPT with NEWOPT
  if ( abceFCandHM ) {
    sub( abceFCandHM, newOpt, HELPcodesFCandHM )
    delete GAdefinedFCdescriptions[oldOpt]
  }
  else {						# Reset the basic options
    HELPbasicOptions = " " _h_ " " _help_ " " _H_ " " _HELP_ " " _t_ " " _test_ " " _v_ " " _version_ " " }
}

function preParseNoColors() {				# Remove any highlighting colors
  GAmarkGAsh = ""
  GAmarkGAoh = ""
  GAmarkGAth = ""
  GAmarkGAah = ""
}

function preParseSectionHeader(	section,sectionVerified,text) {
  section = preGetNextArg(1)
  text = preGetNextArg(1)
  sectionVerified = helpValidateSection(section,"XXX")
  if ( sectionVerified == "XXX" ) {
    preError( sprintf("For GET_ARGS_DIRECTIVE \"--Sec %s '%s'\": Invalid section \"%s\". ",section,text,section) ) }
  # Determine if the section header is in a regular section (UC) or in a my... section (lc).
  sectionVerified = toupper( sectionVerified )		# The most likely
  if ( HELPsectionHeader[sectionVerified] ) {
    PREtmpMessage = PREtmpMessage sprintf( "\n# Section header \"%s\" changed from \"%s\" to \"%s\"", sectionVerified, HELPsectionHeader[sectionVerified], text )
    HELPsectionHeader[sectionVerified] = text }
  else {
    sectionVerified = tolower( sectionVerified )	# A my... section
    PREtmpMessage = PREtmpMessage sprintf( "\n# Section header \"%s\" changed from \"%s\" to \"%s\"", sectionVerified, HELPsectionHeader[sectionVerified], text )
    if ( HELPsectionHeader[sectionVerified] ) HELPsectionHeader[sectionVerified] = text
  }
}

function preParseVarNames(	count,idxV,message,varNames) {
  scanIsDuplicate( GAtestVariable, GAOpt, GAtypeIsText )
  preGetNextArg()					# Get the next argument
  count = split( GAOptArg, varNames, "," )		# Separate list items
  if ( ! count || count > PSvarListCount ) {
    preError( sprintf("Incorrect number of entries in VARLIST. found %d, expected 1 thru %d.\nThe correct format is: --Var \"OPT,VAL,OPTSALL,ALTOPT,ARGS\"", count, PSvarListCount) ) }
  for ( idxV=1 ; idxV<=count ; idxV++ ) {
    if ( varNames[idxV] ~ /[^[:alnum:]_]/ ) {
      preError( "For \"--Var\", invalid characters in reassigned variable \"" varNames[idxV] "\" (position " idxV ") of VARLIST." ) }
    switch ( idxV ) {
      case 1:						# Prefix OPT
        if ( varNames[idxV] ) {
          PREtmpMessage = PREtmpMessage "  " PSoptPrefixVar "=" varNames[idxV]
          PSoptPrefixVar = varNames[idxV]
        }
        continue
      case 2:						# Suffix VAL
        if ( varNames[idxV] ) {
          PREtmpMessage = PREtmpMessage "  " PSoptSuffixVar "=" varNames[idxV]
          PSoptSuffixVar = varNames[idxV]
        }
        continue
      case 3:						# List OPTSALL
        if ( varNames[idxV] ) {
          PREtmpMessage = PREtmpMessage "  " PSoptsAllListVar "=" varNames[idxV]
          PSoptsAllListVar = varNames[idxV]
        }
        continue
      case 4:						# Array ALTOPT
        if ( varNames[idxV] ) {
          PREtmpMessage = PREtmpMessage "  " PSaltOptsArrayVar "=" varNames[idxV]
          PSaltOptsArrayVar = varNames[idxV]
        }
        continue
      case 5:						# Array OPTALT
        if ( varNames[idxV] ) {
          PREtmpMessage = PREtmpMessage "  " PSoptsAltArrayVar "=" varNames[idxV]
          PSoptsAltArrayVar = varNames[idxV]
        }
        continue
      case 6:						# Array ARGS
        if ( varNames[idxV] ) {
          PREtmpMessage = PREtmpMessage "  " PSargsArrayVar "=" varNames[idxV]
          PSargsArrayVar = varNames[idxV]
        }
        continue
    }
  }
  if ( GAisDebug && length(PREtmpMessage) > 0 ) {	# Debug mode requested
    message = HELPnl "# " HELPnl "# ======= Variable Reassignment ======="
    message = message HELPnl "# Requested: --Var \"" GAOptArg "\""
    message = message HELPnl sprintf("#       New: --Var \"%s,%s,%s,%s,%s,%s\"", PSoptPrefixVar, PSoptSuffixVar, PSoptsAllListVar, PSaltOptsArrayVar, PSoptsAltArrayVar, PSargsArrayVar)
    message = message HELPnl "#   Changed:" substr(PREtmpMessage,2)
    PREtmpMessage = message
  }
}

function preSetEBCdefaults() {
  GAtestExpand[Key] = _e_				# Set the default <HM>
  GAtestExpand[Cnt] = BashTabStop			# Set expand tabstop default
  GAtestBrief[Key] = _b_				# Ditto
  GAtestBrief[Cnt] = int( BashTabStop / 2 )		# Set brief tabstop default
  GAtestCompact[Key] = _c_			# Ditto
  GAtestCompact[Cnt] = GAtestBrief[Cnt]		# Set compact tabstop default
}

