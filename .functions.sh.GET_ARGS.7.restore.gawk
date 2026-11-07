#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	.functions.sh.GET_ARGS.6.restore.gawk
#
# PURPOSE = "These functions restore the saved variable values necessary to scan the parent script options."
# VERSION = "14.02.03 - Nov 07, 2026"
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
  HELPtabStop = 0					# The tabstop value used by help
  HELPtabstopLeading = ""
}

# Display the generated HELP text
function restoreHelpDoIt(	cmd,helpFilter,outWidth,parts,sedDel2Empty,sedDelBlank,sedColors,sedDelFC,sedFix,workFile) {
  restoreParseHelpModifier()				# Analyze <HM>
  sedDelBlank = " -e '/^\\s*$/d' "			# Remove leading spaces
  # Replace the color markers with the current colors
  sedColors = "-e \"s/" GAmarkGAsh "/${GAsh}/g\" -e \"s/" GAmarkGAoh "/${GAoh}/g\" -e \"s/" GAmarkGAth "/${GAth}/g\" -e \"s/" GAmarkGAah "/${GAah}/g\" "
  sedDelFC = " -e 's/" HELPsepFC "[^;]*" HELPsepFC "//g' "	# Remove filter info
  if ( GAdefinedFCs ) {
    if ( HELPfilterCode == _a_ ) {
      helpFilter = "cat -s "
      SAVEhelpFI = ""
    } else {
      helpFilter = "grep --no-filename \"" HELPsepFC "[^;]*" HELPfilterCode "[^;]*" HELPsepFC "\" "
      if ( HELPisBrief ) SAVEhelpFI = ""
    }
    if ( ! HELPisCompact && HELPfilterCode != _a_ ) {
      sedFix = " | LC_ALL=C sed -e '/^[[:alnum:]_]\\|^.[[]/{N;s/\\n$//}' " }
  } else {
    helpFilter = "cat -s "
    SAVEhelpFI = ""
  }
  workFile = SAVEdir "/work"				# Work file prefix for displaying help
  parts[1] = BashCmd "(1)"
  parts[2] = HELPheaderTitle
  parts[3] = BashCmd "(1)"
  restoreHelpMakeHeaderFooter(HELPheader,parts,HELPheaderTitleLen)	# Is always the first line
  print HELPheader[1] > workFile 3			# Create the heading file
  parts[1] = HELPfooterInfo
  parts[2] = HELPfooterDate
  #parts[3] = BashCmd "(1)"
  restoreHelpMakeHeaderFooter(HELPfooter,parts)	# Is always the last line
  printf( "%s\n", HELPfooter[1] ) > workFile 4			# Create the footer file
  if ( HELPisBrief ) {					# "Brief" help
    if ( HELPpager ~ "less" ) outWidth = "--output-width=1048576 "
    cmd = helpFilter SAVEhelpb "1 " SAVEhelpFI " " SAVEhelpb "2 | LC_ALL=C sed " sedDelFC sedDelBlank sedColors \
        " | expand " HELPtabstopLeading " --tabs=" HELPtabStop " > " workFile 1
    system( cmd )					# Store it
    cmd = "( echo -e \"$(cat " workFile 3")\" ; " helpFilter SAVEhelpb "3 | LC_ALL=C sed " sedDelBlank sedDelFC sedColors \
        " | expand " HELPtabstopLeading " --tabs=" HELPtabStop \
        " | column --separator=\"" HELPcolumnSep "\" --table " outWidth "  --table-noheadings --table-columns=1,2" \
        " --table-columns-limit=2 --table-truncate=2 --table-noextreme 1 " \
        " > " workFile 2 " ; cat " workFile 1 " " workFile 2 " " workFile 4 " )" HELPpager
    system( cmd )
  } else {						# "Full" help
    restoreHelpFilterInfo()				# Create filter information
    if ( HELPisCompact ) {
      sedDel2Empty = " "
    } else {
      sedDelBlank = ""
      sedDel2Empty = " | LC_ALL=C sed -e '/^$/N;/^\\n$/D' "
    }
    cmd = "( echo -e \"$(cat " workFile 3")\" ; " helpFilter " " SAVEhelpe 1 " " SAVEhelpFI " " SAVEhelpe 2 \
          " | LC_ALL=C sed " sedDelFC sedDelBlank sedFix sedColors \
          " | expand " HELPtabstopLeading " --tabs=" HELPtabStop \
          " | fmt --split-only --width=" BashColumns " --crown-margin " sedDel2Empty " ; cat " workFile 4 " ) " HELPpager
    system( cmd )					# Display the HELP pages
  }
  system( "rm -f " workFile "?" )			# Clean up
  MainErrorCode = PSforceExit				# Force a "help" exit/return
  exit							# And get out
}

function restoreParseHelpModifier() {
  HELPisCompact = 0
  HELPisBrief = 0
  HELPisExpanded = 0
  if ( HELPmodifier == _e_ ) {				# <HM> is expand
    HELPisExpanded = 1
    restoreParseHelpModifierSetup( GAtestExpand )
  } else if ( HELPmodifier == _b_ ) {			# <HM> is brief
    HELPisBrief = 1
    restoreParseHelpModifierSetup( GAtestBrief )
  } else if ( HELPmodifier == _c_ ) {			# <HM> is compact
    HELPisCompact = 1
    restoreParseHelpModifierSetup( GAtestCompact )
  } else {						# No <HM> present. Look at defaults
    if ( GAtestDefault[Key] ) {				# Was --Default EBC present
      restoreParseHelpModifierSetup( GAtestDefault )	# There might be -L and/or TAB
      restoreParseHelpModifier()			# Loop back and process it
    } else if ( BashHelpGlobalDefault ) {		# Global default set by environment variable _BASH_DEFAULT_HELP_DISPLAY_
      restoreParseGlobalHelpDefault()			# Parse it
      restoreParseHelpModifierSetup( HELPglobalDefault )	# There might be -L and/or TAB
      restoreParseHelpModifier()			# Loop back and process it
    } else {						# No other defaults
      HELPmodifier = _e_				# So set the ultimate default
      restoreParseHelpModifier()			# Loop back and process it
    }
  }
}

function restoreParseHelpModifierSetup(theArray) {
  HELPmodifier = theArray[Key]				# The default <HM>
  if ( theArray[Cnt] && ! HELPtabStop ) HELPtabStop = theArray[Cnt]	# Only if haven't got the info
  if ( theArray[Plu] && ! HELPtabstopLeading ) HELPtabstopLeading = theArray[Plu]
}

function restoreParseGlobalHelpDefault( 	anArray,elements,idxA,message1, message2) {
  message1 = "Invalid environment variable \"_GET_ARGS_GLOBAL_HELP_DEFAULT_\".\n"
  elements = split( BashHelpGlobalDefault, anArray )	# Prepare to parse
  HELPglobalDefault[Cat] = "--Global"			# Indicate the type of default
  idxA = 1
  if ( anArray[idxA] !~ /^[ebc]$/ ) {
    message2 = "The valid format is:: \"e [[-L] N]\", \"b [[-L] N]\" or \"c [[-L] N]\"."
    mainError( sprintf("%sGEBC value \"%s\" in environment vzriable \"%s\" is invalid.\n%s", \
                 message1,anArray[idxA],BashHelpGlobalDefault,message2) ) }
  switch ( anArray[idxA++] ) {				# Convert and store the EBC global default
    case "e":
      HELPglobalDefault[Key] = _e_
      break
    case "b":
      HELPglobalDefault[Key] = _b_
      break
    case "c":
      HELPglobalDefault[Key] = _c_
      break
  }
  if ( anArray[idxA] == "-L" ) {			# Is is option "-L"
    HELPglobalDefault[Plu] = "--initial"		# Want only initial <TABS> expanded
    idxA++ }
  if ( anArray[idxA] ) {				# Is there a TAB
    if ( ! mainIsNumeric(anArray[idxA]) || anArray[idxA] < 0 || anArray[idxA] > HELPtabMax ) {
      mainError( sprintf( "%sGTAB value \"%s\" in %s is invalid.\n\t The valid range is: 0 < TAB < %d", \
                   message1,anArray[idxA],BashHelpGlobalDefault,HELPtabMax) )
    }
    HELPglobalDefault[Cnt] = anArray[idxA]		# Store the TAB value
  } else delete HELPglobalDefault[Cat]
}

function restoreHelpFilterInfo(		filter,nl) {
  if ( HELPfilterCode != _a_ ) {			# Add an explanation (except for "all" help)
    filter = HELPsepFC GAdefinedFCs HELPsepFC
    if ( ! HELPisBrief ) nl = filter HELPnl
    print nl filter "\tFiltered HELP for filter code \"" HELPfilterCode "\": " GAdefinedFCdescriptions[HELPfilterCode] > SAVEhelpFI
  } else {
    if ( SAVEhelpFI ) system( "cat /dev/null > " SAVEhelpFI )
  }
}

function restoreHelpMakeHeaderFooter(theHF,theParts,theLen,	halfway,spaces,thePartsLen) {
  thePartsLen[1] = length( theParts[1] )
  if ( theLen ) thePartsLen[2] = theLen
  else thePartsLen[2] = length( theParts[2] )
  thePartsLen[3] = length( theParts[3] )
  halfway = BashColumns / 2
  spaces[123] = BashColumns - thePartsLen[1] - thePartsLen[2] - thePartsLen[3]	# The spaces available
  if ( spaces[123] > 2 ) {					# Enough space for everything?
    spaces[12] = halfway - thePartsLen[1] - ( (thePartsLen[2]+1) / 2 )
    spaces[23] = halfway - thePartsLen[3] - ( (thePartsLen[2]+1) / 2 )
    theHF[1] = sprintf("%s%*s%s%*s%s", theParts[1], spaces[12], "", theParts[2], spaces[23], "", theParts[3])
  } else {
    spaces[12] = BashColumns - (thePartsLen[2]+1) / 2
    theHF[1] = sprintf("%*s%s", spaces[12], "", theParts[2])
  }
}

