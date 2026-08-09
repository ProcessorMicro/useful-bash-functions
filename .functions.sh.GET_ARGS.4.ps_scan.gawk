#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	.functions.sh.GET_ARGS.4.ps_scan.gawk
#
# PURPOSE = "These functions analyze the parent script args when it is invoked."
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
  BashOpts_All = " "					# BASH VAR - A list (in order) of all the parent script options encountered
  # BashScriptVersion = X				# BASH VAR - The version if the parent script
  # BashColumns = X					# BASH VAR - The column width of the terminal
  # GAdefinedFCdescriptions[X] = X			# Array of the descriptions for all defined filter codes
  # PSOptsAndArgs = X					# A string containing all the parent script options and args
  # PSOpts[1] = X					# Array of the parent script opts/args
  # PSOpt = X						# The current PS opt/arg
  # PSOptsAndArgsCount = 0				# The number of elements in PSOpts
  # PSshortOptions = X					# The parsed short options for 'getopt'
  # PSlongOptions = X					# The parsed long options for 'getopt'
  # PSfoundQSQ = 0					# True if QSQ found in parent script options
  # PSfoundEQ = 0					# True if EQ found in parent script options
  # PSparsedOptsAndArgs = X				# Parent script opts/args returned from the 'getopt' command
  # PSregexHelp = X					# Regex to locate -h and --help
  # PSregexHELP = X					# Regex to locate -H and --HELP
  # PSregexTest = X					# Regex to locate -t and --test
  # PSregexVersion = X					# Regex to locate -v and --version
  # PSdebugParsedOptsAndArgs = X			# For debugging output
  # PSintBO = X						# Simulated basic option created with --Debug
  # PSerrorMessage = X					# Manage parent script option parsing errors
  PSforceExit = 8					# Used to signal "help" or "version" requested
  PSuserError = 1					# The execution of the parent script has option/argument errors
  # PShelpSuggestion = X				# Contains the "Try; ..." help message
  # HELPfilterCode = X					# The <FC> for help
  # HELPmodifier = X					# The <HM> specified by the parent script -h<HM> or -h<FC>[<HM>]
  # HELPisHelp = X					# True if help requested
  HELPtabMax = 16					# The maximum <TAB> width
  # HELPpager = X					# Use to control the help display
}

function psAnalyzeOptsAndArgs(	comment,getoptParsed) {
  close( BashScriptFile )
  BashScriptFile = SAVEbashScript2			# Parent script generated bash commands are collected here
  if ( Bash_ALL_OPTIONS_ != " " ) {			# For GET_ARGS "IS_EXCLUSIVE"
    if ( GAisDebug ) {
      mainMakeDebugComment( "" )
      mainMakeDebugComment( "======= Variable Assignment for IS_EXCLUSIVE =======" ) }
    mainMakeBashVariable( "_ALL_OPTIONS_", Bash_ALL_OPTIONS_ ) }
  if ( GAisDebug ) {
    mainMakeDebugComment( "" )
    mainMakeDebugComment( "======= Variables Created for the Parent Script =======" )
  }
  sub( /^,/, "", PSlongOptions )			# Remove leading comma from long options
  psGetOptsAndArgs( PSshortOptions, PSlongOptions, PSintBO PSOptsAndArgs, getoptParsed )
  PSparsedOptsAndArgs = getoptParsed[1]
  psParseOptsAndArgs()
  if ( BashOpts_All != " " ) {
    mainMakeBashVariable( PSoptsAllListVar, BashOpts_All) }	# For the parent script
  if ( GAisDebug ) {
    mainMakeDebugComment( "" )
    if ( PSintBO ) comment = " (with generated debug help)"
    mainMakeDebugComment( "======= Command Line" comment " =======" )
    mainMakeDebugComment( BashCmd " " gensub(/'/, "", "g", PSintBO PSOptsAndArgs) )
    mainMakeDebugComment( "" )
    mainMakeDebugComment( "======= Additional Parent Script Commands =======" )
  }
  psIsPShelp()						# Check if help requested (as there might be <FC> or <HM>)
  psMakeHelpSuggestion()				# Create the HELP suggestion "Try: ..."
  if ( PSerrorMessage ) {
    mainError( PSerrorMessage PShelpSuggestion, PSuserError ) }
  psIsPStestOrVersion()					# Look for basic opts test or version
  close( SAVEbashScript2 )				# For a clean exit
}

function psError(message) {
  if ( PSerrorMessage ) PSerrorMessage = PSerrorMessage "\n" BashErrorPfx message
  else {
    PSerrorMessage = message }
}

function psGetOptsAndArgs(shortOpts,longOpts,optsNargs,parsed,	cmd,errorMsg,line,returnCode) {
  cmd = "getopt --name "BashCmd " --options='" shortOpts "' --longoptions='" longOpts "' -- " optsNargs " 2>&1 ; echo \"ReturnCode: $?\""
  while ( cmd | getline line ) {			# Execute the getopt command
    if ( line ~ "^" BashCmd ": " || line ~ /^getopt: / ) {	# If there was a getopt error
      if ( errorMsg ) errorMsg = errorMsg "\n" line
      else errorMsg = line
    } else {
      if ( line ~ /^ReturnCode:/ ) {			# This is the return code
        split( line, returnCode ) }
      else {
        parsed[1] = line				# Return line into the array[1]
        if ( GAisDebug ) PSdebugParsedOptsAndArgs = PSdebugParsedOptsAndArgs parsed[1] "\\n" }
    }
  }
  close( cmd )
  if ( returnCode[2] ) {				# Got some errors
    gsub( /'/, "", errorMsg )				# Remove "'"
    if ( GAisDebug ) PSdebugParsedOptsAndArgs = PSdebugParsedOptsAndArgs parsed[1] "   ( Invalid:" errorMsg ")\\n"
    psError( errorMsg)					# Display an error message
  }
}

function psFilterError(	idxF,message) {
  message = sprintf("Help requested but invalid or missing help filter <FC> \"%s\".\nFor more help, use one of:\n", HELPfilterCode )
  if ( _h_ != GAhideEQ ) message = message sprintf( "  -%s<FC>[<HM>]", _h_ )
  if ( _H_ != GAhideEQ ) message = message sprintf( "  -%s<FC>[<HM>]", _H_ )
  if ( _help_ != GAhideEQ ) message = message sprintf( "  --%s=<FC>[<HM>]", _help_ )
  if ( _HELP_ != GAhideEQ ) message = message sprintf( "  --%s=<FC>[<HM>]", _HELP_ )
  message = message "\n  \nAcceptable <FC> and <HM> are:\n    FC/HM   TYPE    HELP TO BE DISPLAYED\n"
  for ( idxF in GAdefinedFCdescriptions ) {
    if ( idxF == _a_ ) continue
    message = message sprintf( "      %s     <FC>    %s\n", idxF, GAdefinedFCdescriptions[idxF] )
  }
  message = message sprintf( "      %s     <FC>    %s\n", _a_, _a_msg_ )
  message = message sprintf( "      %s     <HM>    %s\n", _b_, _b_msg_ )
  message = message sprintf( "      %s     <HM>    %s\n", _c_, _c_msg_ )
  message = message sprintf( "      %s     <HM>    %s\n", _e_, _e_msg_ )
  mainError( message, PSuserError )
}

# Examine parent script options following the GET_ARGS_DIRECTIVES (after '--')
#   to see if help has been requested. If so, detect if a help filter
#   code and/or a help modifier has been specified.
function psIsPShelp(	allowed,helpOpt,helpMod) {
  HELPmodifier = ""
  if ( PSregexHelp && match(PSparsedOptsAndArgs,PSregexHelp) ) {	# "help" requested
    if ( HELPisBrief ) HELPpager = HELPless		# Brief "help" always uses "less"
    else HELPpager = HELPcat}				# "help" without "less"
  else if ( PSregexHELP && match(PSparsedOptsAndArgs,PSregexHELP) ) {	# "HELP" requested
    HELPpager = HELPless}				# "HELP" with "less"
  else return 0						# No help
  HELPisHelp = 1					# Help requested
  mainMakeBashVariable( "HELPisHelp", HELPisHelp )
  helpOpt = substr( PSparsedOptsAndArgs, RSTART + 1, RLENGTH - 3 )	# Get the help option (-h, --help ...)
  helpMod = substr( PSparsedOptsAndArgs, RSTART+RLENGTH )		# Get the <FC>[<HM>]
  sub( /'.*$/, "", helpMod )				# Remove trailing "'..." stuff
  if ( GAdefinedFCs ) {					# This is filtered help
    allowed = "<FC>[<HM>]"				#   Like this
    HELPfilterCode = substr(helpMod,1,1)		# Extract the filter code <FC>
    if ( HELPfilterCode !~ "[" GAdefinedFCs "]") {	#   and check it
      psFilterError() }
    HELPmodifier = substr(helpMod,2)			# Get the (optional) <HM> if there is one
  } else {
    allowed = "[<HM>]"					#   Like this
    HELPmodifier = helpMod				# Extract the (optional) <HM>
    HELPfilterCode = _a_ }
  if ( HELPmodifier && HELPmodifier !~ "[" _e_ _b_ _c_ "]" ) {	# No match
    if ( length(helpOpt) > 2 ) allowed = "=" allowed
    psError( sprintf( "Invalid help modifier \"%s\".\nValid format is: %s%s. Valid <HM> codes are: $s, $s or$s",helpOpt,allowed,_e_,_b_,_c_ ) )
  }
  restoreHelpDoIt()					# And display the help message
}

function psIsPStestOrVersion() {			# See if "test" or "version" is detected.
  if ( PSregexTest && PSparsedOptsAndArgs ~ PSregexTest ) {	# Testing mode requested.
    mainMakeBashCommand( "TEST_SET" )				# Turn on testing
    if ( PSparsedOptsAndArgs ~ _t_ " +''|" _test_ " +''|" _tInt_ " +''" ) {	# Is there a NOCLEANUP value present?
      mainMakeBashVariable( "_CLEANUP_ALWAYS_", 1 ) }		# No, so force CLEANUP
    else mainMakeBashCommand( "unset _CLEANUP_ALWAYS_" )	# Yes, so no CLEANUP
  }
  if ( PSregexVersion && PSparsedOptsAndArgs ~ PSregexVersion ) {	# Version requested so display it.
    print BashCmd ": The current version is: " BashScriptVersion
    MainErrorCode = PSforceExit				# Force an exit
    exit 0						# And get out
  }
}

function psMakeHelpSuggestion(	fc) {
  if ( GAdefinedFCs ) fc = "<FC>"
  PShelpSuggestion = "\001\n" BashErrorTry BashCmd " <H>\t  # Where: <H> is one of:"
  if ( _h_ != GAhideEQ ) PShelpSuggestion = PShelpSuggestion " -" _h_ fc
  if ( _H_ != GAhideEQ ) PShelpSuggestion = PShelpSuggestion " -" _H_ fc
  if ( GAdefinedFCs ) fc = "=<FC>"
  if ( _help_ != GAhideEQ ) PShelpSuggestion = PShelpSuggestion " --" _help_ fc
  if ( _HELP_ != GAhideEQ ) PShelpSuggestion = PShelpSuggestion " --" _HELP_ fc
  mainMakeBashVariable( "_HELP_SUGGESTION_", PShelpSuggestion )
}

function psNormalizeOptsAndArgs(	escapeDoubleQuotes) {
  gsub( /^'*|'$/, "", PSOpt )				# Remove the surrounding single quotes (if any)
  if ( PSfoundQSQ ) {
    gsub( GAhideQSQ, "' '", PSOpt ) }			# Replace ' '
  if ( PSfoundEQ ) {
    gsub( GAhideEQ, "'", PSOpt ) }			# Replace '
  gsub( GAhideSP, " ", PSOpt )				# Replace the spaces
  if ( escapeDoubleQuotes ) gsub( /"/, "\\\"", PSOpt )	# Escape double quotes
}

function psParseOptsAndArgs(	argsCount,idxA,idxP,isArgs,nextIsValue,optError,optFound,optsCount,psOptUsed,psVar) {
  PSOptsAndArgsCount = split( PSparsedOptsAndArgs, PSOpts )	# Create an array
  idxA = 1						# The Args array is origin 1
  optsCount = 0						# Initialize the options counter
  for ( idxP=1 ; idxP<=PSOptsAndArgsCount ; idxP++ ) {	# Look at each parent script option and arg
    PSOpt = gensub( /^'(.*)'$/, "\\1" ,1 ,PSOpts[idxP] )	# Remove surrounding "'"
    if ( isArgs ) {					# Collect the Args into an array
      psNormalizeOptsAndArgs()
      mainMakeBashArray( PSargsArrayVar, idxA++, PSOpt )	# Add to the Args[X] array
      argsCount++
      continue }
    switch ( PSOpt ) {					# Look at each one
      case "--":					# This is a separator
        isArgs = 1					# So the remainder are arguments
        continue					# And no more "switch (..."
      case /^-/:					# It is an option
        if ( ! nextIsValue ) {				# This one is an option
          optsCount++					# Count the options
          sub( /^-{1,2}/, "", PSOpt )			# Strip the leading "-"
          PSOpt = GAdefinedOPTi[PSOpt]			# Convert to the first one defined
          if ( GAOptValueNeeded[PSOpt] ) nextIsValue = 1	# Next one is a value even if it starts with "-"
          psVar = PSoptPrefixVar gensub( /[^[:alnum:]_]/, "_", "g", PSOpt )	# Make a bash variable changing "illegal chars" to "_"
          if ( length(PSOpt) == 1 ) psOptUsed = "-" PSOpt	# Add the leading - or --
          else psOptUsed = "--" PSOpt
          if ( GAOptsMulti[PSOpt] ) {			# Can specify more that once...
            # The following will override any previous "Opt_" variable
            mainMakeBashVariable( psVar, GAOptsMulti[PSOpt]++ )	# With the count of the number of times encountered
          } else {
            if ( optFound[psVar] ) {			# Whoops - already specified once
              optFound[psVar] = optFound[psVar] " " PSOpts[idxP]	# Remember each time
              optError[psVar] = 1
            } else {					# The first time for tis Option
              mainMakeBashVariable( psVar, 1 )	# Create the option variable
              optFound[psVar] = sprintf("Option %s can only be used once. Note: Options%s are synonyms.\nMultiple options detected are: %s", PSOpts[idxP], GAsavedOPTLIST[PSOpt], PSOpts[idxP] )
            }
          }
          BashOpts_All = BashOpts_All psOptUsed " "	# The parent script opts encountered (in order)
          continue }
      default:						# Must be an option value
        psNormalizeOptsAndArgs( 1 )			# Fix up and escape double quotes
        mainMakeBashArray( psVar PSoptSuffixVar, 0, PSOpt )	# Augment xxx_Val array (index == 0)
        nextIsValue = 0
        continue
    }							# END switch ( PSOpt )
  }							# END for ( idxP=1 ;...
    if ( length(optError) > 0 ) {			# Found some errors
      for ( idxP in optError ) {
        psError( optFound[idxP] )			# Collect all the error messages
      }
    }
  psVerifyArgCount( argsCount )				# Check if there is an arument count "requirement"
  psVerifyOptCount( optsCount )				# Check if there is an option count "requirement"
}

function psVerifyArgCount(argCount,	error,plural,sumArgCount) {
  if ( GAtestArgs[Cat] ) {
    switch ( GAtestArgs[Cat] ) {
      case 1:						# --Args_Ar[ray] [FC] [@KEYWORD] - no arg count restriction
        break
      case 2:						# --Args_Ma[ximum] [FC] N[@KEYWORD]
        if ( argCount > GAtestArgs[Cnt] ) error = 1
        break
      case 3:						# --Args_Mi[nimum] [FC] N[@KEYWORD]
        if ( argCount < GAtestArgs[Cnt] ) error = 1
        break
      case 4:						# --Args_No[ne] [FC]
        if ( argCount ) error = 1
        break
      case 5:						# --Args_Op[tional] [FC] N[@KEYWORD]
        if ( argCount + GAtestArgs[Cnt] == 0 ) break	# N == 0 No arg count restriction
        if ( argCount > GAtestArgs[Cnt] ) error = 1	# N > 0  Too many args
        break
      case 6:						# --Args_Re[quired] [FC] N[@KEYWORD]
        if ( argCount != GAtestArgs[Cnt] ) error = 1
        break
      case 7:						# --Args_Li[st] [FC] [N2][{+|=}][N2]@"ARGLIST"
        sumArgCount = GAtestArgs[Cnt1] + GAtestArgs[Cnt2]
        if ( GAtestArgs[Cnt1] GAtestArgs[Plu] GAtestArgs[Cnt2] == "" ) error = 0	# NUM empty: no further testing
        else if ( GAtestArgs[Cnt1] != "" && GAtestArgs[Cnt2] != "" ) {			# N1 and N2
          if ( GAtestArgs[Plu] == "=" ) {
            if (GAtestArgs[Cnt1] != argCount || sumArgCount != argCount) error = 1	# N1=N2 Either N1 or N1+N2 args
          } else if ( argCount < GAtestArgs[Cnt1] || argCount > sumArgCount ) error = 1	# N1+N2 Between N1-1 and N1+N2+1
        } else if ( GAtestArgs[Cnt1] ) {						# Just N1
          if ( ! GAtestArgs[Plu] || GAtestArgs[Plu] == "=" ) {				# N1    or N1=  N1 args required
            if ( GAtestArgs[Cnt1] != argCount ) error = 1
          } else if ( argCount < GAtestArgs[Cnt1] ) error = 1				# N1+   At least argCount
        } else if ( GAtestArgs[Cnt2] ) {						# Just N2
          if ( GAtestArgs[Plu] == "=" ) {
            if ( GAtestArgs[Cnt2] != argCount ) error = 1 }				#   =N2 Zero or N2 optional
          else if ( argCount > GAtestArgs[Cnt2] ) error = 1				#   +N2 No required and max optional
        } else if ( GAtestArgs[Plu] == "=" && argCount ) error = 1			#   =   No arguments allowed
          else if ( GAtestArgs[Plu] == "+" ) error = 0					#   +   All arguments optional
        else error = 0									# No error detected
        break
    }
    if ( error ) {
      if ( argCount == 1 ) plural = ""
      else plural = "s"
      gsub( " \001", ",\n" GAtestArgs[Msg] )
      psError( sprintf("%s.\nArgument%s encountered: %d",GAtestArgs[Msg],plural,argCount) )
    }
  }
}

function psVerifyOptCount(optCount,	error,plural1) {
  if ( GAtestOpts[Cat] ) {
    switch ( GAtestOpts[Cat] ) {
      case "a":						# --Opts_Mi[nimum] [FC] N
        if ( optCount < GAtestOpts[Cnt] ) error = 1
        break
      case "b":						# --Opts_Re[quired] [FC] N
        if ( optCount != GAtestOpts[Cnt] ) error = 1
        break
    }
    if ( error ) {
      if ( optCount == 1 ) plural1 = ""
      else plural1 = "s"
      gsub( " \001", ",\n" GAtestOpts[Msg] )
      psError( sprintf("%s.\nOption%s encountered: %d ",GAtestOpts[Msg],plural1,optCount) )
    }
  }
}

