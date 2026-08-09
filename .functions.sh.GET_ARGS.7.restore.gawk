#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	.functions.sh.GET_ARGS.6.restore.gawk
#
# PURPOSE = "These functions restore the saved variable values necessary to scan the parent script options."
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
  HELPtabStop = 0					# The tabstop value used by help
  HELPtabstopLeading = ""
}

# Display the generated HELP text
function restoreHelpDoIt(	cmd,helpFilter,outWidth,sedDel2Empty,sedDelBlank,sedColors,sedDelFC,sedFix,workFile) {
  restoreParseHelpModifier()				# Analyze <HM>
  sedDelBlank = " -e '/^\\s*$/d' "			# Remove leading spaces
  # Replace the color markers with the current colors
  sedColors = "-e \"s/" GAmarkGAsh "/${GAsh}/g\" -e \"s/" GAmarkGAoh "/${GAoh}/g\" -e \"s/" GAmarkGAth "/${GAth}/g\" -e \"s/" GAmarkGAah "/${GAah}/g\" "
  sedDelFC = " -e 's/" HELPsepFC "[^;]*" HELPsepFC "//g' "	# Remove filter info
  if ( GAdefinedFCs ) {
    if ( HELPfilterCode == _a_ ) helpFilter = "cat -s "
    else helpFilter = "grep --no-filename \"" HELPsepFC "[^;]*" HELPfilterCode "[^;]*" HELPsepFC "\" "
    if ( ! HELPisCompact && HELPfilterCode != _a_ ) {
      sedFix = " | LC_ALL=C sed -e '/^[[:alnum:]_]\\|^.[[]/{N;s/\\n$//}' " }
  } else {
    helpFilter = "cat -s "
    SAVEhelpFI = ""
  }
  workFile = SAVEdir "/work"				# Work file prefix for displaying help
  restoreHelpMakeHeader()				# Is always the first line
  print HELPheading > workFile 3			# Create the heading file
  if ( HELPisBrief ) {					# "Brief" help
    if ( HELPpager ~ "less" ) outWidth = "--output-width=1048576 "
    cmd = helpFilter SAVEhelpb "1 " SAVEhelpFI " " SAVEhelpb "2 | LC_ALL=C sed " sedDelFC sedDelBlank sedColors \
        " | expand " HELPtabstopLeading " --tabs=" HELPtabStop " > " workFile 1
    system( cmd )					# Store it

    cmd = helpFilter SAVEhelpb "3 | LC_ALL=C sed " sedDelBlank sedDelFC sedColors \
        " | expand " HELPtabstopLeading " --tabs=" HELPtabStop \
        " | column --separator=\"" HELPcolumnSep "\" --table " outWidth "  --table-noheadings --table-columns=1,2" \
        " --table-columns-limit=2 --table-truncate=2 --table-noextreme 1 " \
        " > " workFile 2 " ; cat " workFile 3 " " workFile 1 " " workFile 2 " " workFile 3 " " HELPpager
    system( cmd )

  } else {						# "Full" help
    restoreHelpFilterInfo()				# Create filter information
    if ( HELPisCompact ) {
      sedDel2Empty = " "
    } else {
      sedDelBlank = ""
      sedDel2Empty = " | LC_ALL=C sed -e '/^$/N;/^\\n$/D' "
    }
    cmd = helpFilter workFile 3 " " SAVEhelpe 1 " " SAVEhelpFI " " SAVEhelpe 2 " " workFile 3 \
          " | LC_ALL=C sed " sedDelFC sedDelBlank sedFix sedColors \
          " | expand " HELPtabstopLeading " --tabs=" HELPtabStop \
          " | fmt --split-only --width=" BashColumns " --crown-margin " sedDel2Empty HELPpager
    system( cmd )					# Display the HELP pages
  }
  system( "rm -f " workFile "?" )			# Clean up
  MainErrorCode = PSforceExit				# Force a "help" exit/return
  exit							# And get out
}

function restoreParseHelpModifier() {
  if ( HELPmodifier == _e_ ) {				# <HM> is expand
    HELPisCompact = 0
    HELPisBrief = 0
    restoreParseHelpModifierSetup( GAtestExpand )
  } else if ( HELPmodifier == _b_ ) {			# <HM> is brief
    HELPisBrief = 1
    HELPisCompact = 0
    restoreParseHelpModifierSetup( GAtestBrief )
  } else if ( HELPmodifier == _c_ ) {			# <HM> is compact
    HELPisCompact = 1
    HELPisBrief = 0
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
  }
}

function restoreHelpMakeHeader(	cmd,cmdLen,spaces) {
  cmd = BashCmd "(1)"
  cmdLen = length( cmd )
  spaces = BashColumns - (cmdLen * 2) - HELPheadingLen - 2
  if ( spaces > 1 ) {					# Enough space for everything?
    spaces = spaces / 2
    HELPheading = sprintf("%s%*s%s%*s%s", cmd, spaces, "", HELPheading, spaces, "", cmd)
  } else {
    spaces = ( BashColumns - HELPheadingLen - 2 ) /2
    HELPheading = sprintf("%*s%s", spaces, "", HELPheading)
  }
}

