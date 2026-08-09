#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	.functions.sh.GET_ARGS.3.ga_scan.gawk
#
# PURPOSE = "These functions will scan the GET_ARGS_DIRECTIVES
#            and create the necessaty environment for parsing parent script options."
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

function scanAnalyzeAct_D() {
  # --Act[ion]_D[efinition] [FCLIST] OPTLIST [-K ACTKEY] [-O] [-A] [-I ACTINFO]
  # --Act[ion]_D[efinition] [FCLIST] "" [-K ACTKEY] [-O] [-A] [-I ACTINFO]
  GAactionKey="";GAactionArgs="";GAactionInfo="";GAactionOpt="";GAactionOptions=""
  GAact_dCount++					# Count the --Act_D encountered
  while ( ++Gdx < GdxNext ) {				# Look at the --Act_D options
    switch( GAOpts[Gdx] ) {
      case "-O":					# Include a reference to [OPTIONS]
        GAactionOptions = " [OPTIONS]"
        continue
      case "-A":					# Include a reference to arguments
        GAactionArgs = HELPhideArgs
        continue
    }
    if ( GAOpts[Gdx+1] ~ /^-/ ) {
      scanError( sprintf("For \"%s ... %s %s\" neither ACTKEY nor INFO can start with a \"-\".",GAOpt,GAOpts[Gdx],GAOpts[Gdx+1]) ) }
    switch( GAOpts[Gdx] ) {
      case "-K":					# Include a reference to ACTKEY
        GAactionKeyCount++				# Count the times -K has been encountered
        if ( GAactionKeys ~ " " GAOpts[++Gdx] " " ) {
          scanError( sprintf("Duplicate ACTKEY \"%s\"",GAOpts[Gdx]) ) }
        GAactionKeys = " " GAOpts[Gdx] GAactionKeys
        GAactionKey = " " GAmarkGAah GAOpts[Gdx] GArs
        continue
      case "-C":					# Add a comment
        GAactionInfo = " # " GAOpts[++Gdx]
        continue
      case "-I":					# Add some information
        GAactionInfo = " " GAOpts[++Gdx]
        continue
    }
    scanError( "Invalid syntax for " GAOpt )
  }
  if ( GAactionKeyCount < 1 ) GAactionKeyCount--		# Count the number of times -K ACTKEY is NOT used
  if ( GAactionKeyCount != GAact_dCount && (GAactionKeyCount*-1) != GAact_dCount ) {
    scanError( "Inconsistant -K ACTKEY usage. For \"--Act_D\",\nthe option \"-K ACTKEY\" must be used in all --Act_D or must not be used in any." ) }
}

function scanAnalyzeGAOpts(	foundDes_D,foundOpt_D,gaMessage,plural1,plural2,plural3,plural4,plural5,plural6,prefix) {
  if ( GAisDebug ) {
    mainMakeDebugComment( "======= Generated Basic Option GET_ARGS_DIRECTIVES =======" )
    mainMakeDebugComment( GAbasicOpts )
    mainMakeDebugComment( "")
    mainMakeDebugComment( "======= Parent Script GET_ARGS_DIRECTIVES =======" )
    mainMakeDebugComment( gensub(HELPnl, " " , "g", GAOptsAndArgs) )
    mainMakeDebugComment( "" )
    mainMakeDebugComment( "======= Initialize Parent Script Variables =======" )
  }
    mainMakeBashCommand( "unset " PSaltOptsArrayVar " " PSoptsAltArrayVar )
    mainMakeBashCommand( "declare -gA " PSaltOptsArrayVar " " PSoptsAltArrayVar )
    mainMakeBashCommand( "unset " PSoptsAllListVar " " PSargsArrayVar )
    mainMakeBashCommand( "declare -ga " PSargsArrayVar )
  if ( GAisDebug ) {
    mainMakeDebugComment( "" )
    mainMakeDebugComment( "======= Alternate Spellings for Parent Script GET_ARGS_DIRECTIVES =======" )
  }
  GAOptsAndArgsCount = split( GAbasicOpts GAOptsAndArgs, GAOpts, GAseparator )	# Create the GAOpts array: "' '" separates each element
  GdxNext = 0
  scanGetNextGAOpt( GAscanCount )			# "Prime the pump" - prepare for 1st GAOpt
  foundOpt_D = 0					# Simulate first --Opt_D not found
  foundDes_D = 1					# Simulate --Des_D found for the first --Opt_D
  while ( 1 ) {						# Extra loop to enable GET_ARGS_DIRECTIVES "defaults"
    while ( scanGetNextGAOpt( ++GAscanCount ) ) {	# Locate each GAOpt and prepare it
      switch ( GAinst[Grp] ) {

        case 0:						# GAOpt option definition
          # --Opt[ion]_D[efinition] [FCLIST] OPTLIST or --Hid[den]_D[efinition] [FCLIST] OPTLIST or --Act_D
          GAopt_dCount++				# Count the number of options defined
          if ( GAinst[Typ] == GAactionType ) {		# Is --Act_D...
            if ( ! GAdes_dAction) {
              GAdes_dAction = GAmarkGAah "ACTION" GArs	# Remember the ACTION keyword
              HELPsynopsisAction = " " GAdes_dAction	# Don't need this. Makes the code easier to read
            }
            scanAnalyzeAct_D()				# Analyze the --Act_D arguments
            if ( ! GAOptArg ) {				# Special case for --Act_D "" (no OPTi)
              scanParseOPTi()
              continue }
          }
          # The previous --Opt_D, --Hid_D or (some) --Act_D MUST be followed by --Des_D
          if ( foundOpt_D ) {				# Whoops. Two Opt_D in a row
            scanError("Found\"" GAOpt "\". Expected \"--Des_D\"." ) }
          foundOpt_D = 1				# Must not get another Opt_D before the next Des_D
          foundDes_D = 0				# And must get Des_D before the next --Opt_D
          scanParseOPTi()				# Parse the OPTi declared
          continue

        case 1:						# --Des_D or --Dba OPTION_DESCRIPTION
          if ( foundDes_D ) {
            scanError("Found\"" GAOpt "\". Expected \"--Opt_D\", \"--Act_D\" or \"--Hid_D\"." ) }
          foundDes_D = 1				# Must not get another Des_D before the next --Opt_D
          foundOpt_D = 0				# And must get Opt_D before the next Des_D
          if ( GAskipDes_D ) {				# Forget about it - hidden (previous --Hid_D)
            GAskipDes_D = 0
            continue }
          if ( GApreviousGAOptPart == "--Act" ) prefix = GAdes_dAction " "
          else prefix = ""
          helpSectionInsert( prefix GAOptArg )
          continue

        case 2:						# --Args... or --Opts...
          if ( GAinst[Typ] < GAoptsType ) {
            scanIsDuplicate( GAtestArgs, GAinst[Typ], GAtypeIsArg)
          } else {
            scanIsDuplicate( GAtestOpts, GAinst[Typ], GAtypeIsOpt)
          }
          if ( GAtestArgs[Cnt1] == 1 ) { plural1 = "" ; plural2 = " is" }
          else { plural1 = "s" ; plural2 = "s are" }
          if ( GAtestArgs[Cnt2] == 1 ) { plural3 = "" ; plural4 = " is" }
          else { plural3 = "s" ; plural4 = "s are" }
          if ( GAtestOpts[Cnt] == 1 ) { plural5 = "" ; plural6 = " is" }
          else { plural5 = "s" ; plural6 = "s are" }
          switch ( GAinst[Typ] ) {
            case 1:					# --Args_Array [FCLIST] [@KEYWORD]
              gaMessage = "Zero to any number of arguments may be specified"
              HELPsynopsisArgs[1] = " [" GAtestArgs[Key] "]..."
              break
            case 2:					# --Args_Ma[ximum] [FCLIST] N[@KEYWORD]
              gaMessage = "A maximum of " GAtestArgs[Cnt] " argument" plural1 " can be specified"
              scanMakeSyntax( GAtestArgs, HELPsynopsisArgs, " [", "]" )
              break
            case 3:					# --Args_Mi[nimum] [FCLIST] N[@KEYWORD]
              gaMessage = "A minimum of " GAtestArgs[Cnt] " argument" plural2 " required"
              scanMakeSyntax( GAtestArgs, HELPsynopsisArgs, " ", "" )
              break
            case 4:					# --Args_None [FCLIST]
              gaMessage = "No arguments are allowed"
              HELPsynopsisArgs[1] = ""
              break
            case 5:					# --Args_Op[tional] [FCLIST] N[@KEYWORD]
              gaMessage = "Either zero or " GAtestArgs[Cnt] " argument" plural2 " required"
              scanMakeSyntax( GAtestArgs, HELPsynopsisArgs, " [", "]" )
              break
            case 6:					# --Args_Re[quired] [FCLIST] N[@KEYWORD]
              gaMessage = "Exactly " GAtestArgs[Cnt] " argument" plural2 " required"
              scanMakeSyntax( GAtestArgs, HELPsynopsisArgs, " ", "" )
              break
            case 7:					# --Args_Li[st] [FCLIST] [NUM]@KEYWORD
              HELPsynopsisArgs[1] = " " GAtestArgs[Key]	# The syntax is copied exactly (no changes)
              # Parse the --Args_List argument and create the appropriate messages.
              if ( GAtestArgs[Cnt1] GAtestArgs[Plu] GAtestArgs[Cnt2] == "" ) {
                gaMessage = ""						# NUM is empty - no message, no testing
                break }
              else if ( GAtestArgs[Cnt1] && GAtestArgs[Cnt2] ) {	#       N1 and N2 present
                if ( GAtestArgs[Plu] == "=" ) {				# N1=N2 Either N1 or N1+N2 args
                  gaMessage = sprintf("Exactly %d argument%s required \001followed by zero or %d optional argument%s",GAtestArgs[Cnt1],plural2,GAtestArgs[Cnt2],plural3 )
                } else {						# N1+N2 Between argCount and sumArgCount
                  gaMessage = sprintf("Exactly %d argument%s required \001followed by up to %d additional optional argument%s",GAtestArgs[Cnt1],plural2,GAtestArgs[Cnt2],plural3 )
                }
              } else if ( GAtestArgs[Cnt1] ) {				#       Just N1 present
                if ( ! GAtestArgs[Plu] || GAtestArgs[Plu] == "=" ) {	# N1    or N1=   N1 args required
                  gaMessage = sprintf("Exactly %d argument%s required. \001No optional arguments are allowed",GAtestArgs[Cnt1],plural2 )
                } else {						# N1+   At least argCount
                  gaMessage = sprintf("At least %d argument%s required",GAtestArgs[Cnt1],plural2)
                }
              } else if ( GAtestArgs[Cnt2] ) {				#       Just N2 present
                if ( GAtestArgs[Plu] == "=" ) {				#   =N2 Zero or N2 optional
                  gaMessage = sprintf("Zero or %d argument%s may be specified",GAtestArgs[Cnt2],plural3)
                } else {						#   +N2 No required and max optional
                  gaMessage = sprintf("Up to %d argument%s may be specified",GAtestArgs[Cnt2],plural3)
                }
              } else if ( GAtestArgs[Plu] == "=" ) {			#   =   No arguments allowed
                gaMessage = sprintf("No arguments are allowed")
              } else if ( GAtestArgs[Plu] == "+" ) {			#   +   All arguments optional
                gaMessage = sprintf("Zero to any number of arguments may be specified")
              }
              break
            case "a":					# --Opts_Min[imum] [FCLIST] N
              gaMessage = sprintf("A minimum of %s option %s required", GAtestOpts[Cnt], plural6 )
              scanMakeSyntax( GAtestOpts, HELPsynopsisOpts, " ", "" )
              break
            case "b":					# --Opts_Req[uired] [FCLIST] N
              scanMakeSyntax( GAtestOpts, HELPsynopsisOpts, " ", "" )
              gaMessage = sprintf("Exactly %d option%s required",GAtestOpts[Cnt],plural6)
              break
            case "c":					# --Opts_Non[e]
              gaMessage = "No options are allowed. One valid basic option may be specified\n\tbut it must be the first parent script argument"
              HELPsynopsisOpts[1] = " [BASICOPTION]"
              GAnoOpts = 1
              break
          }
           if ( gaMessage ) {
             helpSectionInsert( gaMessage "." )		# Insert the message then save it
             if ( GAinst[Typ] < GAoptsType ) GAtestArgs[Msg] = gaMessage
             else GAtestOpts[Msg] = gaMessage
           }
          continue

      # case 3:						# Not implemented
      #   switch ( GAinst[Typ] ) {
      #   }
      #   continue

        case 4:
          # All GET_AGS_OPTIONS in this group create text in their respective sections
          # --Where, --Info, --Examples, --Files, --Author, --Bugs, --See_Also, --Note
          helpSectionInsert( GAOptArg )
          continue

        case 5:						# --Title [FCLIST] [-N] SECTION TITLE --Para[graph] [FCLIST] [-N] SECTION PARAGRAPH
          if ( GAOptArg == "-N" ) {			# Request no extra <NL>
            GAinst[Lnl] = 0				# so set "no extra <NL>"
            GAOptArg = GAOpts[++Gdx]			# The text is in the next argument
            GAOptArgCount-- }				# Adjust the arg count
          if ( GAOptArgCount != 2 ) {			# There must be 2 arguments remaining
            scanError( sprintf("Incorrect number of arguments for \"%s\".\nValid syntax is: %s [FCLIST] [-N] SECTION PARAGRAPH",GAOpt,GAOpt) ) }
          if ( HELPisBrief ) continue			# If brief help, don't insert --Title or -- Para
          GAinst[Sec] = helpValidateSection( GAOptArg )	# Get the section
          if ( GAinst[Typ] == GAisTitle ) helpSectionInsert( GAmarkGAth GAOpts[++Gdx] GArs )	# And save the highlighted title
          else helpSectionInsert( GAOpts[++Gdx] )	# And save the --Para text
          continue

        case 6:
          switch ( GAinst[Typ] ) {
            case 0:					# --Cmd_D[escription] [FCLIST] CMD_DESCRIPTION
              scanIsDuplicate( GAtestCmd, GAOpt )	# Check for duplicates
              helpSectionInsert( GAOptArg )
              continue
            case 1:					# --Copy[right] [FCLIST] [COPYRIGHT]
              scanIsDuplicate( GAtestCopyright, GAOpt )	# Check for duplicates
              if ( GAOptArgCount ) helpSectionInsert( GAOptArg )
              else helpSectionInsert( HELPdefaultCopyright )
              continue
            case 2:					# --Expand [-L] ENUM
              scanVerifyTabInfo( GAtestExpand, GAOpt )
              GAtestExpand[Key] = _e_
              continue
            case 3:					# --Brief [-L] BNUM
              scanVerifyTabInfo( GAtestBrief, GAOpt )
              GAtestBrief[Key] = _b_
              continue
            case 4:					# --Compact [-L] CNUM
              scanVerifyTabInfo( GAtestCompact, GAOpt )
              GAtestCompact[Key] = _c_
              continue
            case 5:					# --Tabstop NUM
              scanVerifyTabInfo( GAtestTabstop, GAOpt )
              GAtestExpand[Cnt] = GAtestTabstop[Cnt]	# Set expand tabstop (ETAB) default
              GAtestExpand[Plu] = GAtestTabstop[Plu]	# Set expand "-L" default
              GAtestBrief[Cnt] = int( GAtestTabstop[Cnt] / 2 )		# Set brief tabstop (BTAB) default
              GAtestBrief[Plu] = GAtestTabstop[Plu]	# Set brief "-L" default
              GAtestCompact[Cnt] = GAtestBrief[Cnt]	# Set compact tabstop (CTAB) default
              GAtestCompact[Plu] = GAtestTabstop[Plu]	# Set compact "-L" default
              continue
            case 6:					# --Default
              if ( GAOptArg !~ "[" _e_ _b_ _c_ "]" ) {
                mainError( sprintf("Invalid EBC value for directive \"--Default %s\".\nValid values are \"%s\", \"%s\" or \"%s\".",GAOptArg,_e_,_b_,_c_ ) )
              }
              GAtestDefault[Key] = GAOptArg		# Save the default <HM>
              GAOptArg = GAOpts[++Gdx]			# Look at the next arg
              scanVerifyTabInfo( GAtestDefault, GAOpt )
              continue
            case 7:					# --Pager
              scanIsDuplicate( GAtestPager, GAOpt )	# Check for duplicates
              HELPless = " |& " GAOptArg " "		# Change the default help pager
          }						# End of "switch ( GAinst[Typ] )"

        case 9:						# These were pre-processed. So only for syntax checking
          switch ( GAinst[Typ] ) {
            case /[05]/:
              continue					# Ignore: --Bas_O, --Filter, --Section, --nocolor
            case 1:					# --Heading
              scanIsDuplicate( GAtestHeading, GAOpt )
              continue
            case 2:					# --Action [FCLIST] ACTION
              scanIsDuplicate( GAtestAction, GAOpt )	# Only check for duplicates - processed by pre-scan
              continue
            case 3:					# --Variable
              scanIsDuplicate( GAtestVariable, GAOpt )
              continue
            case 4:					# --Debug
              scanIsDuplicate( GAtestDebug, GAOpt )
              continue
          }						# End of "switch ( GAinst[Typ] )"
      }							# END of "switch ( GAinst[Grp] )"
    }							# END of "while ( scanGetNextGAOpt( 1 ) )"
    # Now process GAOpts "defaults"
    if ( GAtestArgs[1] ) break				# Found an "--Args_..." so get out
    GAOpts[++GAOptsAndArgsCount] = "--Args_None"	# Simulate --Args_None
    GdxNext = GAOptsAndArgsCount			#   Ditto
    continue						# And process it
  }							# END of "while ( 1 )" - "defaults" processing
  if ( GAnoOpts && length(GAdefinedOPTi) > GAbasicOptsCnt ) {
    mainError( "GET_ARGS: Conflicting directives: GET_ARGS Options defined but \"--Opts_None\" specified.", GAcodeError )
  }
  if ( length(BashUnsetVars) > 7 ) {
    mainMakeDebugComment( "" )
    mainMakeDebugComment( "======= More  Parent Script Stuff =======" )
    mainMakeBashCommand( BashUnsetVars ) }		# Unset all the defined "first option" vars
  scanSetHelpDefault( GAtestDefault )			# Set the default <HM> (if present)
}

function scanSetHelpDefault(testArray, cnt,plu) {
  if ( testArray[Cat] ) {
    if ( testArray[Key] == _e_ ) {
      cnt = GAtestExpand[Cnt]
      plu = GAtestExpand[Plu]
    } else if ( testArray[Key] == _b_ ) {
      cnt = GAtestBrief[Cnt]
      plu = GAtestBrief[Plu]
    } else if ( testArray[Key] == _c_ ) {
      cnt = GAtestCompact[Cnt]
      plu = GAtestCompact[Plu]
    }
    if ( ! testArray[Cnt] ) testArray[Cnt] = cnt
    if ( ! testArray[Plu] ) testArray[Plu] = plu
  }
}

function scanError(theMessage,gaoptCount,	idx,message) {
  if ( gaoptCount) {					# Found at least 1 GAOpt
    if ( gaoptCount > 0 ) gaoptCount = "-" gaoptCount	# Negate
    for ( idx=GdxNext-1; idx>=GdxNext+gaoptCount; idx--) {	# Count backwards
      GAOptText = GAOpts[idx] " " GAOptText }		# Add to the error text
  }
  message = theMessage GAatOrNear substr( sprintf("%s %s %s %s %s",GAOptText,GAOpts[GdxNext],GAOpts[GdxNext+1],GAOpts[GdxNext+2],GAOpts[GdxNext+3]), 1, BashColumns-5)
  mainError( "GET_ARGS_DIRECTIVE: " message, GAcodeError )
}

function scanGetNextGAOpt(gaScanCount) {		# Get the next GAOpt and its arguments
  Gdx = GdxNext						# Set the index to the next GAOpt
  GAOptArgCount = 0					# Prepare to count the GAOpt arguments
  GAOptText = GAOpts[Gdx]				# And initialize the GAOpt text for error processing
  GApreviousGAOpt = GAOpt				# Remember the previous GAOpt
  GApreviousGAOptPart = GAOptPart			# Ditto GAOptPart
  while ( ++GdxNext < GAOptsAndArgsCount ) {		# Look at each argument (except the '--' last one)
    if (GAOpts[GdxNext] ~ /^--[A-Z][a-z]{2,}|^--$/ ) {	# Is this a GAOpt or the last one?
      if ( gaScanCount == 1 && Gdx != 2 ) {		# First arg is not a GAOpt
        GAOptText = "" ; GdxNext = 2
        scanError( "The GET_ARGS argument \"" GAOpts[GdxNext] "\" is not a GAOpt." ) }
      if ( gaScanCount ) scanPrepareGAOpt()		# if NOT the first time verify and manage the <FC> (if any)
      return 1 }					# All done for this arg
    else {						# This is an GAOpt argument
      GAOptArgCount++					# So count it
      if ( GAOpts[GdxNext] ~ " ") {			# Does the argument contain spaces
        GAOptText = GAOptText " \"" GAOpts[GdxNext] "\"" }	# Yes - add surrounding quotes and remember it
      else GAOptText = GAOptText " " GAOpts[GdxNext]	# Or just remember the argument
    }
  }							# End while. Only one more to go
  if ( GdxNext == GAOptsAndArgsCount + 1 ) {		# Beyond the last one?
    scanPrepareGAOpt()					# Yup. For the last one, verify and manage <FC>
    return 1 }
  else return 0						# Indicate there are no more
}

function scanIsDuplicate(testArray,testID,testType,	error,keyWord,message,parsed,parsedLen,regex,seps) {
  if ( testArray[Cat] ) {				# Is True so the GAOpt has been encountered before
    message = "Duplicate or conflicting GET_ARGS_DIRECTIVE: "
    if ( GAinst[Grp] == GAisPreScan ) preError( message testID )
    else scanError( message GAOpt ) }
  if ( testType ) {					# Is --Args_Xxx or --Opts_Xxx
    testArray[Cat] = testID
    if ( GAOptPart ~ "--Aon|--Oon" ) return		# --Args_None or --Opts_None - Nothing more to do
    if ( testType > GAtypeIsNone ) {			# A count is expected for all these ones
      if ( GAOptPart == "--Arr" ) testArray[Cnt] = 0	# The count doesn't matter for --Ags_Array
      if ( testID == GAisList ) regex = "[+=@]"		# --Args_List parses differently
      else regex = "@"
      match( GAOptArg, /@(.*)/, keyWord )		# Find the KEYWORD/ARGLIST following the "@"
      parsedLen = split( GAOptArg, parsed, regex, seps )	# Get the count(s) (and KEYWORD)
      if ( testID == GAisList ) {				# --Atgs_Li[st] [N1][{=|+}][N2]@"ARGLIST"
        if ( seps[1] == "@" ) error = 0
        else if ( seps[1] ~ /^[+=]$/ && seps[2] == "@" ) error = 0
        else error = 1
        if ( error ) \
          scanError( sprintf("For %s, the argument \"%s\" is invalid..\nThe correct format is: --Args_List [FCLIST] [N1][{+|=}][N2]@\"ARGLIST\"..",GAOpt,GAOptArg) )
        if ( parsed[1] != "" ) {
          if ( ! mainIsNumeric(parsed[1]) ) {		# Not numeric
            scanError( sprintf( "For \"%s\", N1 (\"%s\") is not numeric.", GAOpt, parsed[1] ) ) }
          if ( parsed[1] < 1 || int(parsed[1]) != parsed[1] ) {
            scanError( sprintf( "For \"%s\", N1 (\"%s\") must be an integer greater than 0.", GAOpt, parsed[1] ) ) }
        }
        testArray[Cnt1] = parsed[1]			# Remember the count even if not present
        testArray[Cnt] = parsed[1]			# Remember the count (2 places) even if not present
        if (seps[1] ~ /[+=]/ ) {
          testArray[Plu] = seps[1]
          if ( parsed[2] != "" ) {
            if ( ! mainIsNumeric(parsed[2]) ) {		# Not numeric
              scanError( sprintf("For \"%s\", N2 (\"%s\") is not numeric.", GAOpt, parsed[2]) ) }
            if ( parsed[2] < 1 || int(parsed[2]) != parsed[2] ) {
              scanError( sprintf("For \"%s\", N2 (\"%s\") must be an integer greater than 0.", GAOpt, parsed[2]) ) }
            testArray[Cnt2] = parsed[2]			# Remember the count
          }
        }
        if ( ! parsed[parsedLen] ) {
          scanError( "The \"ARGLIST\" is missing for: " GAOpt " " GAOptArg ) }
        testArray[Key] = keyWord[1]			# Remember the ARGLIST
      } else {						# Any other --Args... and --Opts...
        if ( GAOptPart == "--Arr" ) parsed[1] = GAbigNum	# --Args_Array
        if ( ! mainIsNumeric(parsed[1]) ) {			# Not numeric
          message = sprintf( "For \"%s\", N1 (\"%s\") is not numeric or is missing.", GAOpt, parsed[1] )
          if ( GAinst[Grp] == GAisPreScan ) preError( message )
          else scanError( message )
        }
        if ( parsed[1] < 1 || int(parsed[1]) != parsed[1] ) {
          message = sprintf( "For \"%s\", N1 (\"%s\") must be an integer greater than 0.", GAOpt, parsed[1] )
          if ( GAinst[Grp] == GAisPreScan ) preError( message )
          else scanError( message )
        }
        testArray[Cnt] = parsed[1]			# Remember the count
        testArray[Cnt1] = parsed[1]			# Remember the count (2 places)
        if ( parsed[2] ) {				# There was an "@KEYWORD"
          if ( parsed[2] ~ /\s/ ) {
            scanError( sprintf("For \"%s\", the KEYWORD \"%s\" contains spaces.", GAOpt, parsed[2]) ) }
          testArray[Key] = keyWord[1]
        } else {
          if ( GAinst[Cat] == GAisArgOpt ) {		# No @KEYWORD so supply the default
            if (testID < GAoptsType ) testArray[Key] = "ARG"
            else testArray[Key] = "OPTION"
          }
        }
      }
    }
  } else testArray[Cat] = 1				# This GAOpt has been encountered
}

# Make help syntax text for --Args_... and --Opts_...
function scanMakeSyntax(array,syntax,begin,end,		ending,idxC,sep,suffix) {
  if ( GAinst[Typ] == GAisList ) {
    syntax[1] = "[BASICOPTION]"
    return}
  for ( idxC=1 ; idxC<=array[Cnt]; idxC++ ) {
    ending = end					# May need to change it incrementally
    if ( array[Cnt] == 1 && GAinst[Typ] != GAisMin ) suffix = ""
    else suffix = idxC					# Counter aka: ARG1, ARG2 ...
    syntax[1] = begin syntax[1] sep array[Key] suffix	# Variable "syntax" is array so passed by reference
    if ( GAinst[Typ] == GAisMax ) {			# --Args_Max or --Opts_Max
      if ( idxC > 1 ) ending = ending end		# More than 1 so manage optional ending. AKA: [ARG1 [ARG2 [ARG3]]]
      sep = begin }					# And insert "[" or " " in between
    else sep = " "					# Separator always " "
    begin = ""						# Passed by value so calling arg not modified
  }
  if ( GAinst[Typ] == GAisMin ) {			# --Args_Min
    syntax[1] = syntax[1] " [" array[Key] idxC "]..." }	# Need one extra (optional) arg/opt
  else syntax[1] = syntax[1] ending			# Otherwise need just the ending
}

# Normalize all GAOpt into a 5-characters like "--Xxx"
function scanNormalizeGAOpt(	gaOptPart) {
  gaOptPart = substr(GAOpt,1,7)
  if ( gaOptPart ~ /^--Act/ && GAOpt !~ /^--Act.*_D/ ) {	# Make --Action unique
    GAOptPart = "--Atn" }
  else if ( gaOptPart ~ /^--Fil/ && GAOpt != "--Filter" ) {	# Make --Files unique
    GAOptPart = "--Fle" }
  else if ( gaOptPart == "--Args_" || gaOptPart == "--Opts_" ) {	# Make these GAO unique
    GAOptPart = substr(GAOpt,1,3) substr(GAOpt,9,2) }	# What is needed to make it unique
  else {
    GAOptPart = substr(GAOpt, 1, 5) }			# first 5 characters is unique
}

function scanParseOPTi(		actOpen,actNext,actClose,bashAlt_Opts,count,gaOPTi,idxT,
      optClose,optComma,optDash,optDash1,optEqual,optPart,optKeyword,optMultiple,optOpen,
      optOptional,optValue,seps,sepsLen,token,tokenAlt,tokenFirst,tokens,tokensLen,tokenVar) {
  GAOptArg = gensub( /^\s+|\s+$/, "", "g", GAOptArg )	# Trim surrounding spaces
  optPart = GAOptArg
  count = sub( /^\*/, "", optPart)			# Look for a beginning "*"
  if ( count ) optMultiple = 1				# This option can occur multiple times in parent args
  count = 0
  tokensLen = split( optPart, tokens, /\s+|@|::|:/, seps )	# Split into tokens for parsing
  sepsLen = length(seps)				# The number of separators
  if ( seps[1] ~ ":" ) {				# Must be a required or optional <VALUE>
    optValue = seps[1]					# Remember the first ":" or "::"
    if ( seps[sepsLen] == "@" ) {			# Have a <KEYWORD> as well
      optKeyword = tokens[tokensLen]			# Substitute <KEYWORD> for "VALUE"
      tokensLen-- }					#   And ignore it in the loop
    else optKeyword = "VALUE" }
  else {						# No <VALUE>
    optValue = ""					# Make separator a space
    optKeyword = "" } 					#   And no <KEYWORD>}
  optOpen = "" ; optClose = ""				# Initialize
  for ( idxT=1 ; idxT<=tokensLen ; idxT++ ) {		# Look at each token
    if ( seps[idxT] == "@" ) { 				# Error check: found a KEYWORD
      if ( idxT != sepsLen ) {				# Is the last separator "@" ==> KEYWORD
        scanError( sprintf("For \"%s\", \"@KEYWORD\" must be the last argument.", GAOpt) ) }
      if ( ! tokens[sepsLen+1] ) {			# Found "@" but there is no KEYWORD
        scanError( sprintf("For \"%s\", the KEYWORD is missing after \"@\".", GAOpt) ) }
    }
    token = tokens[idxT]
    if ( ! token ) continue				# Got an empty token
    count++
    if ( token ~ GAinvalidOPTiChars ) {
      scanError( "Invalid characters in OPT" count " of OPTLIST \"" token seps[idxT] "\".\nOPTi" GAinvalidOPTiCharsMess ) }
    if ( GAdefinedOPTi[token] ) {			# This Opti already used
      scanError( sprintf("For \"%s '%s'\", OPTi \"%s\" is defined more than once.", GAOpt, GAOptArg, token ) ) }
    if ( (optValue ~ ":" && seps[idxT] != optValue) || (seps[idxT] && seps[idxT] !~ optValue) ) {
      # Each OPTi must have the same " ", ":" or "::"
      if ( optValue ~ /\s/ ) scanError( sprintf( "The OPTi option definition \"%s\" must not use a value specifier of \"@\", \":\" or \"::\".", token ) )
      else scanError( sprintf( "The OPTi option definition \"%s%s\" must use the value specifier \"%s\".", token, seps[idxT], optValue ) ) }
    if ( seps[idxT] ~ ":" ) {				# A VALUE is either expected or optional
      optEqual = "=" ; optOptional = seps[idxT]
      if ( seps[idxT] == "::" ) {			# An optional value
        if ( HELPhelpOptions !~ " " token " " ) {	# But for the "help" text display is is not optional
        optOpen = "[" ; optClose = "]" }
      }
      else { optOpen = "" ; optClose = "" }
    }
    else {						# No VALUE for this option
      optEqual = "" ; optOptional = ""
      optOpen = ""  ; optClose = ""
    }
    if ( length(token) == 1 ) {				# A single-character option
      optDash = "-"
      if ( idxT == 1 ) optDash1 = "-"
      if ( optValue ) {					# A VALUE is either expected or optional
        if ( optValue == "::" ) optEqual = ""		# It is optional: (-a[VALUE])
        else optEqual = " " }				# It is expected: (-a VALUE) so the "=" is a space
      else optEqual = ""				# No VALUE - optEqual is empty
      PSshortOptions = PSshortOptions token optOptional }	# Remember for getopt parsing
    else {						# A multi-character option
      optDash = "--"
      if ( idxT == 1 ) optDash1 = "--"
      PSlongOptions = PSlongOptions "," token optOptional	# Remember for getopt parsing
    }
    if ( idxT == 1 ) {					# The first OPTi
      optComma = ""
      tokenFirst = token				# Remember the first token
      tokenAlt = optDash token
      bashAlt_Opts = " " optDash token " "		# Initialize the collection of alternate OPTi
      GAdefinedOPTi[token] = token			# Remember OPT1 as OPT1
      if ( optOptional ) GAOptValueNeeded[token] = 1	# This Opti needs a value or an optional value
      if ( optMultiple ) GAOptsMulti[token] = 1		# Remember the options that can be used more than once
      if ( GAinst[Typ] == GAactionType ) {
        GAactionOpt = "" ; actOpen = "" ; actNext = "" ; actClose = "" }
      }
    else {
      optComma = ", "					# A separator between option aliases
      bashAlt_Opts = bashAlt_Opts optDash token " "	# Remember this OPTi
      GAdefinedOPTi[token] = tokenFirst			# Remember Opti --> Opt1 so we can find the first option
      if ( GAinst[Typ] == GAactionType ) {		# It is --Act_D do format the output
        actNext = "|"
        if ( idxT == 2 ) actOpen = "{"
        if ( idxT == tokensLen ) actClose = "}"
      }
    }
    tokenVar = PSoptPrefixVar token
    gsub( /[^[:alnum:]_]/, "_", tokenVar )		# Create a bash variable name
    if ( length(BashUnsetVars) > BashUnsetVarsLen ) {
      BashUnsetVars = BashUnsetVars HELPnl " unset "
      BashUnsetVarsLen = BashUnsetVarsLen + BashUnsetVarsMax }
    BashUnsetVars = BashUnsetVars tokenVar " "	 	# Unset variable Opt_OPTi
    if ( optOptional ) BashUnsetVars = BashUnsetVars tokenVar PSoptSuffixVar " "	# Unset Opt_OPTi_Val if OPTi has a value
    GAsavedOPTLIST[tokenFirst] = GAsavedOPTLIST[tokenFirst] " " optDash token	# Remember the OPTLIST
    mainMakeBashArray(PSoptsAltArrayVar, optDash token, tokenAlt)
    Bash_ALL_OPTIONS_ = Bash_ALL_OPTIONS_ token " "		# Create a list of every defined option
    # Add the parsed option definition to the OPTIONS section
    gaOPTi = gaOPTi optComma GAmarkGAoh optDash tokens[idxT] optOpen optEqual optKeyword optClose GArs
    if ( GAinst[Typ] == GAactionType ) {		# It is --Act_D
      GAactionOpt = actOpen GAactionOpt actNext optDash tokens[idxT] actClose }
    actOpen = ""
  }							# END: for ( idxT=1 ... ==> Look at each token
  if ( GAinst[Typ] == GAhiddenType ) {
    GAskipDes_D = 1					# Never process the --Des_D for preceding --Hid_D
    return }
  helpSectionInsert( gaOPTi )				# Insert it into the OPTIONS section
  if ( GAinst[Typ] == GAactionType ) {			# Is is --Act_D
    split( GAOptInst[GAact_dInst1], GAinst, "" )	# Set the instructions for the ACTION section
    # Insert the ACTION text.
    if ( helpSectionInsert( BashCmd GAactionKey " " GAactionOpt GAactionOptions GAactionArgs GAactionInfo) ) {
      if ( GAinst[Lnl] ) GAact_dInst1 = GAact_dInst2 }	# Turn off the leading <NL> after the first time
    }
  # Create the bash "alternate option spellings" variable for GET_ARGS
  if ( tokenFirst ) {					# Don't do this if it is: --Act_D "" ...
    mainMakeBashArray(PSaltOptsArrayVar, tokenAlt, bashAlt_Opts )
    tokenAlt = PSoptPrefixVar gensub( /[^[:alnum:]_]/, "_", "g", tokenFirst )
    mainMakeBashArray(PSaltOptsArrayVar, tokenAlt, bashAlt_Opts )
  }
}

function scanPrepareGAOpt() {
  GAOpt = GAOpts[Gdx]					# Store the GAOpt as a scalar for slightly better performance
  scanNormalizeGAOpt()					# Normalize GAOpt into GAOptPart - 5 characters like "--Xxx"
  if ( ! GAOptInst[GAOptPart] ) {			# Not in the array, so invalid
    scanError( "\"" GAOpt "\" is not a valid GAOpt option." ) }
  # For each GAOpt create the array GAinst, determine the number of args, manage <FCs> and ignore some GAOpt
  split( GAOptInst[GAOptPart], GAinst, "" )		# Extract the instructions character-by-character
  scanValidateFCs()					# Increment Gdx and verify the <FCs>
  scanValidateArgCount()				# Is the arg count within accepted range
  # One argument after the GAOpt is most likely so get it.
  if ( GAOptArgCount ) GAOptArg = GAOpts[++Gdx]		# If expecting at least one argument
  else GAOptArg = ""
}

function scanValidateArgCount(	countFC,textFC) {
  if ( GAinst[Opt] == "*" ) GAinst[Opt] = GAbigNum	# An unlikely large number for --Args_...
  if ( GAOptArgCount < GAinst[Req] || GAOptArgCount > GAinst[Req] + GAinst[Opt] ) {
    if ( GAdefinedFCs && GAinst[Fil] ) {
      if ( GAOpt == "--Filter" ) {
        GAOpt = GAOpt " " GAOpts[Gdx] " " GAOpts[Gdx+1] " ..."
        textFC = "<FC>, " }
      else textFC = "<FClist>, "
      countFC = 1 }
    else {
      textFC = ""
      countFC = 0
    }
    scanError( sprintf("Incorrect number of arguments for GAOpt \"%s\".\nArguments expected: %sRequired=%d, Optional=%d. Arguments found=%d.",GAOpt,textFC,GAinst[Req],GAinst[Opt],GAOptArgCount + countFC) ) }
}

function scanValidateFCs(gaOptFCs,basicOptionError,	charFC,idxF) {
  if ( ! GAdefinedFCs ) return				# Filters not defined - so return
  if ( ! GAinst[Fil] && ! basicOptionError ) return	# Only the GAOpts requiring a filter code
  if ( gaOptFCs ) GAOptFCs = gaOptFCs			# Argument present - use it
  else GAOptFCs = GAOpts[++Gdx]				# Or get it
  if ( ! match(GAOptFCs,_a_) ) GAOptFCs = GAOptFCs _a_	# Ensure the "all" filter code is also accepted
  split( GAOptFCs, charFC, "" )				# Get them one-by-one
  for ( idxF in charFC ) {
    if ( GAdefinedFCs !~ charFC[idxF] ) {		# A mis-match
      if ( basicOptionError ) return sprintf( "Undefined <FC> \"%s\" in GAOpt ", charFC[idxF] )
      scanError( sprintf("Undefined <FC> \"%s\" in GAOpt \"%s\".", charFC[idxF], GAOpt) ) }
  }
  GAOptArgCount--					# <FC> doesn't count so adjust the arg count.
}

function scanVerifyTabInfo(testArray,catType, theMessage) {
  if ( GAOptArg == "-L" ) {				# Is is option "-L"
    testArray[Plu] = "--initial"			# Want only initial <TABS> expanded
    GAOptArg = GAOpts[++Gdx]				# Look at the next arg
  } else delete testArray[Plu]
  if ( GAOptArg ~ /^--[A-Z]/ ) {			# If the next arg is a GAOpt ...
    scanIsDuplicate( testArray, catType, GAtypeIsText )	# No TAB so just see if there is a duplicate
    if ( testArray[Key] == _e_ ) testArray[Cnt] = BashTabStop	# Set it to the default
    else testArray[Cnt] = int( BashTabStop / 2 )	# Or 1/2 the default
  } else {
    scanIsDuplicate( testArray, catType, GAtypeIsNum )	# Otherwise is there is a duplicate and TAB
  }
  theMessage = "\nAny of --Expand, --Brief or --Compact is mutually exclusive with --Tabstops."
  if ( GAOptPart == "--Tab" ) {
    if ( GAtestEBC[Cat] ) scanError( theMessage )
  } else {
    if ( GAtestTabstop[Cat] ) scanError( theMessage )
    GAtestEBC[Cat] = 1					# --Exp, --Bri, --Com has been encountered
  }
  if ( testArray[Cnt] > HELPtabMax ) {
    scanError( sprintf("\nThe tabstop \"%s\" is not numeric or is unreasonable (greater than %d).",GAOptArg,HELPtabMax) ) }
}
