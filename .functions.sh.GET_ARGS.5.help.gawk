#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	.functions.sh.GET_ARGS.5.help.gawk
#
# PURPOSE = "This script implements GET_ARGS help functionality."
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
  HELPbasicOptions = " " _h_ " " _help_ " " _H_ " " _HELP_ " " _t_ " " _test_ " " _v_ " " _version_ " "
  # HELPbasicOptsFCs = X				# The <FC> codes to be used for basic options
  # HELPtestNversionOptions = X				# The options for invoking test and version
  # HELPhelpOptions = X					# The options for invoking help
  HELPcodesFCandHM = _a_ _b_ _c_ _e_
  # HELPbasicOptsFCsPos = 0				# Remembered position of --Bas_O -F ...
  # HELPbasicOptsFCgaOpt = X				# Remebersd spelling of --Bas...
  HELPheading = "User Script"				# The default if GET_ARGS "--Heading" is not used
  HELPheadingLen = length( HELPheading )		# The length of the heading text

  # Help Management
  # HELPsection["H","b"] = X				# An array (indexed by section ID) containing the help information
  # HELPsectionText[1] = X				# The text to be inserted into a section
  # HELPotherSectionHeader = 0				# An array indicating a header was placed in the "other" section
  # HELPsectionHeaderLength["H"]			# Marker
  # HELPsectionHeaderFCs["H"]				# Stored <FC>s for help display
  HELPsectionHeader["H"] = ""				# The Header array for each section initialized by helpInitialize()
  HELPsectionHeader["p"] = "PURPOSE"			# Internally generated and populated by "filtered help" message
  HELPsectionHeader["P"] = ""
  HELPsectionHeader["S"] = "SYNOPSIS"
  HELPsectionHeader["s"] = ""
  HELPsectionHeader["D"] = "COMMAND DESCRIPTION"
  HELPsectionHeader["A"] = "ACTION SYNTAX"
  HELPsectionHeader["O"] = "OPTIONS"
  HELPsectionHeader["b"] = "BASIC OPTIONS"
  HELPsectionHeader["B"] = ""
  HELPsectionHeader["W"] = "WHERE"
  HELPsectionHeader["I"] = "INFORMATION"
  HELPsectionHeader["E"] = "EXAMPLES"
  HELPsectionHeader["F"] = "FILES"
  HELPsectionHeader["U"] = "AUTHORS"
  HELPsectionHeader["G"] = "BUGS"
  HELPsectionHeader["C"] = "COPYRIGHT"
  HELPsectionHeader["M"] = "SEE ALSO"
  HELPsectionHeader["n"] = "NOTE"
  HELPsectionHeader["N"] = ""
  HELPvalidSections = " H HEA p myp P PUR s mys S SYN D COM DES A ACT O OPT b myb B BAS W WHE I INF E EXA F FIL U AUT G BUG C COP M SEE n myn N NOT "
  HELPbriefHelpSections = "HpPsSObB"			# Only these sections if brief help requested
  HELPfilterIgnoredSections = "HpPsSbBT"		# These sections are always displayed with filtered help
  HELPnoHeader = @/[HTs]/				# These sections don't have a header
  HELPdefaultCopyright = "Copyright © 2021 Free Software Foundation, Inc. License GPLv3+: GNU GPL version 3 or later. See: <https://gnu.org/licenses/gpl.html>. This is free software: you are free to change and redistribute it. There is NO WARRANTY, to the extent permitted by law."
  # HELPisBrief = 0					# True if brief help is requested
  # HELPisCompact = 0					# True if compact help is requested
  # HELPtext = X					# Used by HELP to create the display
  HELPsynopsis = BashCmd				# The beginning synopsis line in the SYNOPSIS section
  # HELPsynopsisAction = X				# ACTION keyword in the SYNOPSIS section
  HELPsynopsisOpts[1] = ""				# Options string in the SYNOPSIS section
  HELPsynopsisArgs[1] = ""				# Argument string in the SYNOPSIS section
  HELPhideArgs = "HELPargsHELP"				# A placeholder for --Act_D lines to add "HELPsyntaxArgs"
}

function helpError(message) {
  mainError( "Help: " message, PSuserError )
}

function helpMakePurpose() {
  split( GAOptInst["--Pur"], GAinst, "" )		# Get the instructions for the PURPOSE section
  helpSectionInsert( BashScriptPurpose )
}

function helpMakeSynopsis() {
  split( GAOptInst["--Syn"], GAinst, "" )		# Get the instructions for the SYNOPSYS section
  if ( ! HELPsynopsisOpts[1] && GAopt_dCount ) HELPsynopsisOpts[1] = " [OPTIONS]"
  helpSectionInsert( HELPsynopsis HELPsynopsisAction HELPsynopsisOpts[1] HELPsynopsisArgs[1] )
}

function helpNormalizeText() {
  if ( GAinst[Nor] ) {					# Some things need to be normalized - some not
    gsub( /\\'/, "'", HELPsectionText )			# Fix up single quotes
    if ( GAfoundQSQ ) {
      gsub( GAhideQSQ, GAfindQSQ, HELPsectionText ) }	# Unhide imbedded ' '
  }
}

function helpPrepareDisplay() {
  if ( GAfoundQSQ ) {
    gsub( GAhideQSQ, GAseparator, HELPtext ) }		# Change QSQ to ' '
  gsub( GAhideEQ, "'", HELPtext )			# Change hidden quoted single-quote ("'\''") to '
  gsub( /\\+E/, HELPesc, HELPtext )
}

function helpSectionInsert(text) {
  HELPsectionText = text
  helpSectionInsertDoIt( "e" )				# Insert text for expanded help
  HELPsectionText = text
  helpSectionInsertDoIt( "b", 1 )			# Insert text for brief help
}

function helpSectionInsertDoIt(helpType,briefHelp,	filterPfx,headerFilterPfx,helpNL,leadingNL,leadingHeaderNL,idxH,idxS,indent,trailingNL) {
  if ( GAinst[Tab] == 1 ) indent = HELPtab		# This GAOpt requires a leading <TAB>
  else if ( briefHelp ) indent = ""			# Unless it is brief help
  else if ( GAinst[Tab] == 2 ) indent = HELPtab HELPtab	# Another leading <TAB> is needed
  else indent = ""
  if ( GAinst[Lnl] ) leadingNL = HELPleadingNL		# Do we need an extra <NL>
  else leadingNL = ""
  idxS = GAinst[Sec]					# Get the SECTION ID from GAinst[Sec]
  helpNormalizeText()					# Some things may need to be normalized
  if ( briefHelp ) {
    if ( HELPbriefHelpSections !~ idxS ) return		# Do nothing if brief help and not a brief help section
    gsub( HELPnoTabNL, " ", HELPsectionText )		# For brief help no <TAB> or <NL>
    if ( GAinst[Grp] == GAopt_dGrp ) {			# --Opt_D
      helpNL = HELPcolumnSep }				# For --Opt_D, --Act_D, --Hid_D change <NL> to a column separator
    if ( GAinst[Grp] == GAdes_dGrp ) {			# --Des_D
      helpNL = HELPnl }					# Set the <NL> to use if not --Opt_D ...
    leadingNL = "" }					# No leading <NL>
  else helpNL = HELPnl
  if ( GAinst[My] ) idxH = GAinst[My]			# The header ix in the "my" section
  else idxH = idxS					# The header is in this section
  if ( GAdefinedFCs ) {					# Filtering is configured
    helpStoreFCsForHeader(idxH)				# Remember the header section <FC>s
    if ( idxS != idxH ) helpStoreFCsForHeader(idxS)	# Remember the section <FC>s
    if ( HELPfilterIgnoredSections ~ "[" GAinst[Sec] GAinst[My] "]" ) {
      filterPfx = HELPsepFC GAdefinedFCs HELPsepFC	# Set "all filters" for these sections
      headerFilterPfx = filterPfx
    } else {
      if ( GAOptFCs == _a_ ) filterPfx = HELPsepFC GAdefinedFCs HELPsepFC	# All <FC>s
      else filterPfx = HELPsepFC GAOptFCs HELPsepFC	# Set filter prefix to the GAOpt one
      headerFilterPfx = HELPsepFC HELPsepFC		# <FC>s to be filled in later
    }
  } else {
    filterPfx = HELPsepFC _a_ HELPsepFC			# Always "all"
    headerFilterPfx = filterPfx
  }
  if ( ! HELPsection[idxH,helpType] && idxS !~ HELPnoHeader ) {	# Add header if empty and not a "no header" section
    if ( leadingNL ) leadingHeaderNL = headerFilterPfx leadingNL	# The FCs to be added later
    if ( HELPsectionHeader[idxH] ) {
      HELPsection[idxH,helpType] = leadingHeaderNL headerFilterPfx GAmarkGAsh HELPsectionHeader[idxH] GArs HELPnl
      leadingNL = ""
    } else if ( helpType != "e" ) leadingNL = ""	# Don't want an extra blank line
    HELPsectionHeaderLength[idxH,helpType] = length( HELPsection[idxH,helpType] )
  }
  if ( HELPsectionText ) {				# There is some text to insert
    if ( HELPotherSectionHeader[idxH,helpType] ) {
      HELPotherSectionHeader[idxH,helpType] = 0
      if ( HELPsectionHeaderLength[idxH,helpType] == "" ) leadingNL = ""
      if ( briefHelp ) trailingNL = "" }
    else trailingNL = ""
    if ( leadingNL ) leadingNL = filterPfx leadingNL
    if ( idxH != idxS ) HELPotherSectionHeader[idxH,helpType] = 1
    gsub( /\n/, "&" filterPfx, HELPsectionText )		# Ensure each line begins with a filter code
    HELPsection[idxS,helpType] = HELPsection[idxS,helpType] leadingNL filterPfx indent HELPsectionText helpNL trailingNL
  }
  return 1						# Indicate success
}

function helpStoreFCsForHeader(idxH,	idxF,theFCs) {
  split( GAOptFCs, theFCs, "" )				# Separate the FC codes for this GET_ARGS_DIRECTIVE
  for (idxF in theFCs ) {				# The index is the filter code
    HELPsectionHeaderFCs[idxH,theFCs[idxF]] = 1 }	# Separately store each filter code in the header FCs array
}

function helpValidateSection(section,error) {
  if ( ! section || HELPvalidSections !~ " " substr(section,1,3) " " ) {
    if ( error) return error				# Let the "caller" ,amage the error message
    scanError( "For GAOpt \"" GAOpt "\", invalid section \"" section "\".") }
  if ( section ~ /^my/ ) return substr( section, 3, 1 )	# Normalize the "funny" ones
  else if ( section ~ /^COM/ ) return "D"		# Ditto
  else return substr( section, 1, 1 )			# Just one character as the index
}

