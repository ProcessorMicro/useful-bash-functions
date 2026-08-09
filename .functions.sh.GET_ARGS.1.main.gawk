#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	.functions.sh.GET_ARGS.1.main.gawk
#
# PURPOSE = "This is the main gawk script called by GET_ARGS."
# VERSION = "14.01.06 - Jul 01, 2026"
#
# This gawk script is executed by the GET_ARGS function in /usr/local/bin/functions.sh
# It provides a pre-scan of the GET_ARGS_DIRECTIVES, followed by a full scan. And a scan
# of the parent script options used at execution time.
#
# The input is a single line containing all of the GET_ARGS options, a separator "--"
# and all of the parent script options/argument. All the GET_ARGS options are separated
# by the 3-character sequence ' ' (quote space quote).

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

# #ME ==> ".functions.sh.GET_ARGS.1.main.gawk"
@include  ".functions.sh.GET_ARGS.4.ps_scan.gawk"
@include  ".functions.sh.GET_ARGS.7.restore.gawk"
#
# #ME ==>  ".functions.sh.GET_ARGS.1.main.gawk.NEW"
# @include ".functions.sh.GET_ARGS.4.ps_scan.gawk.NEW"
# @include ".functions.sh.GET_ARGS.7.restore.gawk.NEW"

BEGIN {							# Set up to do two passes on the input files
  # Note: Commented out lines define variables that don't have to be initialized.
  # BashErrorPfx = X					# BASH VAR - The prefix for error messages
  # BashErrorPfxLen = X					# BASH VAR - The prefix length for error messages
  # BashErrorTry = X					# BASH VAR - The TRY prefix
  ## BashErrorTryLen = X				# BASH VAR - The TRY prefix length
  # BashCmd = X	 					# BASH VAR - Parent script name
  # BashScriptFile = X					# BASH VAR - The current script file
  # BashHelpGlobalDefault = X				# BASH VAR - The value of _BASH_DEFAULT_HELP_DISPLAY_
  # BashGlobalDirectives = X				# BASH VAR - The value of _GET_ARGS_GLOBAL_DIRECTIVES_DEFAULTS_
  # BashIsUsageExit = X					# BASH VAR - Exit or return
  # MAINcmd = X						# Used in the END block
  # MainErrorCode = 0					# BASH The error code to be returned to the bash script
  # MainWhatToDoAtEnd = 0				# Used in the END block

  # The following are used to manage parsing of the GET_ARGS_DIRECTIVES (GAOpt).
  # GAOptsAndArgs = X					# A string containing all the GET_ARGS_DIRECTIVES and arguments
  # GAfoundQSQ = 0					# True if QSQ found in GET_ARGS_DIRECTIVES
  # GAfoundEQ = 0					# True if EQ found in GET_ARGS_DIRECTIVES
  GAcodeError = 3					# The GET_ARGS function call has argument errors
  GAerrorPrefix = sprintf("%*s",BashErrorPfxLen,"")	# Leading spaces used in error messages
  # SAVEorRESTORE = X					# BASH VAR - Save/Restore/NoSave indicator
  # SAVEme = X						# BASH VAR - Do a save
  # RESTOREme = X					# BASH VAR - Do a Restore
  # SAVEdir = X						# The ~/.config directory for the parent script
  # SAVEbashScript1 = X					# The bash variable assignments created by "GAscan"
  # SAVEbashScript2 = X					# The bash variable assignments created by "PSscan""
  GAhideSep  = "\034"					# Used to hide the separator
  GAfindQSQ  = "'\\\\'' '\\\\''"			# Identify quoted ' ' (QSQ=QuoteSpaceQuote)
  GAhideQSQ  = "\035"					# Used to hide QSQ
  GAfindEQ   = "'\\\\''"				# Identify escaped quotes (EQ=EscapedQuote)
  GAhideEQ   = "\036"					# Used to hide EQ
  GAhideSP   = "\037"					# Used to hide a space
  GAmarkGAsh = "\021"					# Marker for the highlight color GAsh
  GAmarkGAoh = "\022"					# Marker for the highlight color GAoh
  GAmarkGAth = "\023"					# Marker for the highlight color GAth
  GAmarkGAah = "\024"					# Marker for the highlight color GAah
  HELPsepFC = ";;;"					# Separates the <FC> from the rest of every help line
  HELPtab = "\011"					# A <TAB> character
  HELPcolumnSep = "?"					# Used for brief help to columnize output
  HELPnl = "\012"					# A <NL> character
  HELPleadingNL = HELPnl				# All help lines separated by a blank line (the default)
  HELPnoTabNL = "[" HELPtab HELPnl "]+"			# For brief help - remove <TAB> & <NL> sequences
  HELPesc = "\033"					# An escape character
  HELPglobalDefault[Cat] = ""				# Initialize it

  FileCount = ARGC - 1					# Remember how many files
  for ( idx=1 ; idx<=FileCount ; idx++ ) {		# Then add all the names onto the arguments array
    ARGV[idx+FileCount] = ARGV[idx] }			# Add the pathnames onto the end of array ARGV
  ARGC = ARGC * 2 - 1					# And adjust the argument count
}

END {							# Return the result
  if ( MainErrorCode == PSforceExit ) {			# This is a "help" or "version" request
    MainErrorCode = 0					# So reset MainErrorCode
    MainWhatToDoAtEnd = "exit " }			#   And exit
  else if ( ! MainErrorCode ) {				# No errors
    MainWhatToDoAtEnd = "return " }			#   So return
  else {						# Errors so decide to return or exit
    if( BashIsUsageExit ) MainWhatToDoAtEnd = "exit "	# Either exit the parent script
    else MainWhatToDoAtEnd = "return "			# Or return from the call to GET_ARGS
  }
  mainMakeBashCommand( MainWhatToDoAtEnd MainErrorCode )	# Put the command into the script file
  if ( GAisDebug ) {						# Debug mode requested
    close ( SAVEbashScript1 )
    close ( SAVEbashScript2 )
    MAINcmd = "touch " SAVEbashScript2 " ; cat " SAVEbashScript1 " " SAVEbashScript2 HELPless	# So show the contents of the script file
    system (MAINcmd)
  }
  exit MainErrorCode
}

# =================V Main Process V==================== #
{
  BashScriptFile = SAVEbashScript1			# The (semi) permanant file containing the GA "scan" results
  mainInitialize()					# Split the GET_ARGS_DIRECTIVES and parent script options.
  if ( SAVEorRESTORE == SAVEme ) {
    printf( "" ) > SAVEbashScript1			# Ensure the GET_ARGS_DIRECTIVES script file is empty
    preScanGAOpts()					# Pre-scan for --Var --Bas_O --Filter --Action --Compress --Tab --Debug
    scanAnalyzeGAOpts()					# Analyze the GET_ARGS_DIRECTIVES
    saveEverything()					# Save the parsed GET_ARGS_DIRECTIVES
    psAnalyzeOptsAndArgs()				# Analyze the parent script options and arguments
  } else {
    psAnalyzeOptsAndArgs()				# Analyze the parent script options and arguments
  }
  if ( HELPisHelp ) restoreHelpDoIt()
  exit							# Process only one line
}
# =================^ Main Process ^==================== #

function mainError(message,errorCode) {			# Display the error message and exit
  gsub( "[^\001]\\n", "\n" GAerrorPrefix, message )	# Indent any additional (un-marked) line feeds
  gsub( "\001", "", message )				# Remove all marks
  printf( "%s%s\n", BashErrorPfx, message ) > "/dev/stderr"
  MainErrorCode = errorCode
  exit errorCode
}

# Separate GET_ARGS_DIRECTIVES and the parent args/options.
function mainInitialize(	pos,psLen,text) {
  printf( "" ) > SAVEbashScript2			# Ensure the parent script options file is empty
  text = $0						# Leave $0 unchanged
  gsub( /\\+n/,   HELPnl,  text )			# Convert all \\\\\n to <NL>
  gsub( /\\+t/,   HELPtab, text )			# Convert all \\\\\t to \t
  gsub( /\\+033/, HELPesc, text )			# Convert all \\033 to <ESC>
  gsub( /\\+"/, "\"", text )				# Convert all \" to "
  gsub( /' \$'/, "' '", text )				# Convert all bash ' $'...' to ' '...'
  # Now get the GET_ARGS_DIRECTIVES and the parent script options.
  pos = match( text " ", /' '--' '/)			# Find the first "' '--' '"
  if ( ! pos ) {
    mainError("Initialization: Malformed or missing GET_ARGS option.\nOr the final two arguments (\"--\" and \"$@\") are missing.\nOr a GET_ARGS_DIRECTIVE is mispelled.\nOr there is a missing line continuation.", GAcodeError) }
  if ( SAVEorRESTORE == SAVEme ) {
    GAOptsAndArgs = substr(text,1,pos+RLENGTH-1)	# Just the GET_ARGS_DIRECTIVES and "' '--' '"
    if ( BashGlobalDirectives ) mainIncludeDefaultDirectives()	# Add the global directives
  }
  psLen = length(text) - (pos+7+1)			# Calculate parent script options length
  PSOptsAndArgs = substr(text,pos+7,psLen)		# Get the parent script options without leading "' '--' " and trailing " '"
  mainPrepareGAandPSargs()
}

function mainIncludeDefaultDirectives(	gaArray,gaGlobDir,idx,part) {
  if ( ! split(BashGlobalDirectives,gaArray) ) return	# Split into parts (if not empty)
  for ( idx in gaArray ) {
    if ( part) {
      part = part " " gaArray[idx]
      if ( gaArray[idx] ~ /'$/ ) {			# The last part
        gaGlobDir = gaGlobDir "' '" gensub(/'$/,"",1,part)
        part = ""
      }
    } else {
      if ( gaArray[idx] ~ /^'/ ) {			# Combine parts of direcctive that contain spaces
        part = substr( gaArray[idx], 2 )
      } else {
        gaGlobDir = gaGlobDir "' '" gaArray[idx] }
    }
  }
  GAOptsAndArgs = gaGlobDir GAOptsAndArgs
}

function mainIsNumeric(theNumber,	anArray) {	# Check whether a value is numeric
  switch ( typeof(theNumber) ) {
    case "strnum":
    case "number":
      return 1						# Is it a number
    case "string":					# If only 1 column and that one is a numeric string...
      return ( split(theNumber, anArray, " ") == 1 ) && ( typeof(anArray[1]) == "strnum" )
    default:
      return 0						# Not numeric
  }
}

function mainMakeBashArray(var,idx,val,	quote) {
  if ( idx ) {						# Make the array element with an index
    if ( idx !~ /^[0-9]+$/ ) quote = "\""		# If associative array surround index with '"'
    printf( " %s[%s%s%s]=\"%s\"\n", var, quote, idx, quote, val ) >> BashScriptFile	# Return a bash array element
  } else {						# Augment the indexed array
    printf( " %s+=( \"%s\" )\n", var, val ) >> BashScriptFile	# Return a bash array augmented
  }
}

function mainMakeBashCommand(cmd) {
  printf( " %s\n", cmd ) >> BashScriptFile				# Return a bash command
}

function mainMakeBashVariable(var,val,ext,	extend) {
  if ( ext ) extend="+"
  else extend=""
  printf( " %s%s=\"%s\"\n", var, extend, val ) >> BashScriptFile	# Return a bash variable assignment
}

function mainMakeDebugComment(comment,	space) {
  if ( comment ) space = " "
  else space = ""
  printf( "#%s%s\n", space, comment ) >> BashScriptFile		# For --DEBUG: Create a comment in the bash script file
}

function mainPrepareGAandPSargs() {
  # GA and PS are done separately as have different requirements
  # Parse GAOpts ----------
  if ( GAOptsAndArgs ~ GAfindQSQ ) {			# See if any quoted ' ' in GAOptsAndArgs
    GAfoundQSQ = 1					# Remember
    gsub( GAfindQSQ, GAhideQSQ, GAOptsAndArgs ) }	# And hide them
  if ( GAOptsAndArgs ~ GAfindEQ ) {			# See if any quoted ' in GAOptsAndArgs
    GAfoundEQ = 1					# Remember
    gsub( GAfindEQ, GAhideEQ, GAOptsAndArgs ) }		# And hide them
  # Parse PS Options and Args ----------
  if ( PSOptsAndArgs ~ GAfindQSQ ) {			# See if any quoted ' ' in PSOptsAndArgs
    PSfoundQSQ = 1					# Remember
    gsub( GAfindQSQ, GAhideQSQ, PSOptsAndArgs ) }	# And hide them
  if ( PSOptsAndArgs ~ GAfindEQ ) {			# See if any quoted ' in PSOptsAndArgs
    PSfoundEQ = 1					# Remember
    gsub( GAfindEQ, GAhideEQ, PSOptsAndArgs ) }		# And hide them
  gsub( GAseparator, GAhideSep, PSOptsAndArgs)		# Temporarily hide separator ("' '")
  gsub( " ", GAhideSP, PSOptsAndArgs)	 		# Then hide all spaces so GET_ARGS only parses on ' '
  gsub( GAhideSep, GAseparator, PSOptsAndArgs)		# And change hidden separator back to ' '
}

