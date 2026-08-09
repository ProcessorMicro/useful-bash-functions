#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
# PURPOSE = "Create a more readable format from a sorted sequence of OPTION RANGES."
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

# This script will convert a set of CHOICES or RESPONSES into a sorted sequence
#   of numbers/characters and then convert the sequence into normalized RANGES.
# The results are returned as bash variable assignments.
#   From:         _CHOICES_="1 23 a thru c 24 d e 96 4 5-7 f 8 9 3"
#   To:   _CHOICES_COMPARE_=" 1 3 4 5 6 7 8 9 23 24 96 a b c d e f "
#   And:  _CHOICES_DISPLAY_="1, 3-9, 23-24, 96, a-f"

BEGIN {
  if ( ! ScriptFile  ) ScriptFile = "/dev/stdout"	# Default to stdout
  printf( "" ) > ScriptFile				# Empty it
  if ( ! Function ) Function = "ASK"			# Defaults...
  if ( ! VariablePrefix ) VariablePrefix = "_CHOICES_"
  if ( ! VariableSuffix ) VariableSuffix = "COMPARE_"
  if ( ! DisplaySuffix ) DisplaySuffix = "DISPLAY_"
  if ( IsAnswer ) { Type = "response" ; ArticleR = "the " }
  else { Type = "CHOICES" ; ArticleR = "" }
  if ( PromptType ~ /^[au]/ ) ArticleP = "an "
  else ArticleP = "a "
  if ( ! AltRangeSep1 ) AltRangeSep1 = @/\s+thru\s+/	# This RANGE separator
  if ( ! AltRangeSep2 ) AltRangeSep2 = @/\s+to\s+/	#   and this RANGE separator
  if ( ! RangeSep ) RangeSep = "-"			# Are converted to this
  if ( ! ListSep ) ListSep = ", "			# CHOICES display separator
  if ( ! Valid ) Valid = "."				# Any character is valid (should always be overwritten)
  if ( ! Delta ) Delta = 10000
  Count = 1
  if ( ! IsNumber ) {
    for ( i=48; i<=57; i++) {				# Remember digits
      Char = sprintf( "%c", i )				# Convert ANSI to character
      if ( ! match(Char,Valid) && ! IsAnswer ) continue	# But not if invalid
      AlphaCompare = AlphaCompare Char			# A comparison sequence
      AlphaChars[Count++] = Char				# The valid character array
    }
    BeginNext[1] = Count + Delta				# Index for the beginning of uppercase
    for ( i=65; i<=90; i++) {				# Remember uppercase chars
      Char = sprintf( "%c", i )				# Convert ANSI to character
      if ( ! match(Char,Valid) && ! IsAnswer ) continue	# But not if invalid
      AlphaCompare = AlphaCompare Char			# A comparison sequence
      AlphaChars[Count++] = Char				# The valid character array
    }
    BeginNext[2] = Count + Delta				# Index for the beginning of lowercase
    for ( i=97; i<=122; i++) {				# Remember lowercase chars
      Char = sprintf( "%c", i )				# Convert ANSI to character
      if ( ! match(Char,Valid) && ! IsAnswer ) continue	# But not if invalid
      AlphaCompare = AlphaCompare Char			# A comparison sequence
      AlphaChars[Count++] = Char				# The valid character array
    }
  }
  IsError = 0
}

END {
  if ( IsError ) {					# First process errors.
    if ( IsAnswer ) {
      printf("\n_IS_ERROR_=%d\n", IsError) >> ScriptFile
      exit IsError
    }
    if ( IsUsageExit ) printf("_IS_ERROR_=%d\nexit %d\n", IsError, IsError) >> ScriptFile
    else printf("_IS_ERROR_=%d\n", IsError) >> ScriptFile
    exit IsError					# No need to do anything else
  }
  MakeRangesIntoList()					# Either choices or responses
  ExpandChoices()					# Process the choices.
}

{ # Create an array containing expanded choice or answer ranges.
  gsub( AltRangeSep1, RangeSep, $0 )			# Convert ' thru ' to '-'
  gsub( AltRangeSep2, RangeSep, $0 )			# Convert ' to ' to '-'
  if ( IsAnswer ) {
    if ( ! MultiChoices && match($0,/[[:space:]-]/) ) {
      Error( "Multiple responses are not allowed." ) }
  }
  for ( idx=1 ; idx<=NF ; idx++ ) {			# Parse through the RANGES
    Idx = gensub( /[$"`\\]/, "\\\\&", "G", $idx )
    RangeHasStarted = 0
    Count = split( $idx, Range, RangeSep )		# Split the RANGE into parts
    if ( Count == 1 ) {					# A single character
      Range[2] = Range[1]
      IsRange = 0
    } else IsRange = 1
    if ( IsNumber ) {					# RANGE expected to be numeric
      if ( Range[1] > Range[2] || Count > 2 ) {
        Error( sprintf("For the %s RANGE \\\"%s\\\", the LHS \\\"%s\\\" is greater than the RHS \\\"%s\\\".",Type,Idx,Range[1],Range[2]) ) }
      if ( IsNumeric(Range[1] Range[2]) ) {		#   So verify that
        for ( Aidx=Range[1] ; Aidx<=Range[2] ; Aidx++ ) {
          UpdateArray( Aidx, Aidx ) }			# Remember the numbers in the RANGE
      } else {
        Error( sprintf("The %s RANGE \\\"%s\\\" is not numeric.",Type,Idx) ) }
    } else {						# The RANGE is alphabetic
      Lidx = match( AlphaCompare, gensub(/[$"`\\]/,"\\\\&","G",Range[1]) )	# So find the position of the RANGE beginning
      Ridx = match( AlphaCompare, gensub(/[$"`\\]/,"\\\\&","G",Range[2]) )	# And the end
      if ( IsRange && ! Lidx && ! Ridx ) {
        Error( sprintf( "For %s%s, both LHS \\\"%s\\\" and RHS \\\"%s\\\" are not %ss.",ArticleR,Type,Range[1],Range[2],PromptType) ) }
      if ( ! IsRange && ! Lidx ) {
        Error( sprintf("For %s%s RANGE \\\"%s\\\", the RANGE is not %s%s.",ArticleR,Type,Idx,ArticleP,PromptType) ) }
      if ( ! Lidx ) {
        Error( sprintf("For %s%s RANGE \\\"%s\\\", the LHS \\\"%s\\\" is not %s%s.",ArticleR,Type,Idx,Range[1],ArticleP,PromptType) ) }
      if ( ! Ridx ) {
        Error( sprintf("For %s%s RANGE\\\"%s\\\", the RHS \\\"%s\\\" is not %s%s.",ArticleR,Type,Idx,Range[2],ArticleP,PromptType) ) }
      if ( Range[1] > Range[2] || Count > 2 ) {
        Error( sprintf("For the %s RANGE \\\"%s\\\", the LHS \\\"%s\\\" is greater than the RHS \\\"%s\\\".",Type,Idx,Range[1],Range[2]) ) }
      for ( Aidx=Lidx ; Aidx<=Ridx ; Aidx++ ) {
        UpdateArray( Aidx + Delta, AlphaChars[Aidx] ) }	# Add Delta to the position and remember the RANGE
    }
    if ( IsAnswer ) RememberRanges()			# A RANGE
  }
}

function Error(theMessage) {
  IsError = 2
  if ( IsAnswer ) \
    printf( "_RESPONSE_ERROR_=\"%s\";_IS_ERROR_=%d", theMessage, IsError ) >> ScriptFile
  else \
    printf( "ERROR \"%s: For ASKCODE of \"%s\" (%s),\n\t    %s\"\n",Function,AskCode,PromptType,theMessage ) >> ScriptFile
  exit IsError
}

function ErrorResponseNoMatch() {
  AnswerMatch = 0
  Error( sprintf("The %s RANGE \\\"%s\\\" does not match any choice.", Type, TheRange) )
}

function ExpandChoices() {
  printf( "%s%s=\"%s \"\n", VariablePrefix, VariableSuffix, Script ) >> ScriptFile
  # Create the display RANGES
  Script = sprintf( "%s%s=\"", VariablePrefix, DisplaySuffix )
  Sep = ""
  FirstOne = 1
  Element = 0
  Elements = length( Array )				# How many in the array
  Next = 1
  for ( Ridx in Array ) {
    if ( Ridx > BeginNext[Next] ) Next++		# Jump to the next section
    if ( ++Element == Elements ) LastOne = 1		# Detect the end
    Ridx = strtonum(Ridx)				# Ensure is is a number
    if ( FirstOne ) OldRidx = Ridx			# Just once
    if ( Ridx == OldRidx + 1 && Ridx != BeginNext[Next] ) {	# This is a sequence
      Sep = RangeSep					# So convert to a RANGE
      OldRidx = Ridx					# Remember this to compare with next
      if ( ! LastOne ) {				# No more lookup if the last one
        Continued = 1
        FirstOne = 0
        continue					# Get the next index
      }
    } else {						# Not a sequence
      if ( ! FirstOne && Sep != RangeSep ) Sep = ListSep
    }
    # The previous one was the end of the sequence (the last one is always the "end").
    if ( ( OldRidx != Ridx && ! FirstOne && Continued ) ) {
      Script = Script Sep Array[OldRidx]		# Record the previous RANGE
      if ( ! FirstOne ) Sep = ListSep
    }
    # Now have to process the current one.
    Script = Script Sep Array[Ridx]			# Record the current RANGE
    OldRidx = Ridx
    Continued = 0
    FirstOne = 0
  }
  if ( ! match(Script,/"$/) ) Script = Script "\""	# Add a terminating quote
  printf( "%s\n", Script ) >> ScriptFile
}

function IsNumeric(theNumber,	anArray) {		# Check whether a value is numeric
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

function MakeRangesIntoList() {				# Both for choices and responses
  Script = ""
  Lidx = 1
  if ( IsAnswer ) asort( RangesIdx )			# Need them in ascending order
  for ( Ridx in Array ) {				# Convert choices/response ranges into a list
    Ridx = strtonum(Ridx)				# Ridx must be a number
    if ( IsAnswer ) {
      if ( ValidateAnswer() ) continue			# Must selectively create the answer
      AnswerMatch = 1
    }
    Script = Script " " Array[Ridx]			# Need choices/responses as a string
  }
  if ( IsAnswer ) {					# Final processing for an answer
    if ( ! AnswerMatch ) ErrorResponseNoMatch()		# No matches in the answer
    # Return the Answer as an array and the error code as well.
    printf( "%s=(%s)\n_IS_ERROR_=%d\n", AnswerVariable, Script, IsError ) >> ScriptFile
    exit IsError					# Get out of Dodge
  }
}

function RememberRanges() {
  Ranges[Range[1]] = IsRange
  RangesIdx[++Lidx] = Range[1]
  if ( IsRange != 0 ) {
    Ranges[Range[2]] = 2
    RangesIdx[++Lidx] = Range[2]
  }
}

# Ensure the RANGE character/index is unique and store the integer value into the Array.
function UpdateArray(theIndex,theValue) {
  if ( ! Array[theIndex] ) Array[theIndex] = theValue
  else {
    Error( sprintf("The %s RANGE \\\"%s\\\", the value \\\"%s\\\" duplicates or overlaps another RANGE." ,Type,Idx,theValue) )
  }
}

function ValidateAnswer(	isValid) {
  Aidx = RangesIdx[Lidx]				# Find the range "instruction"
  isValid =  match( Valid, " " Array[Ridx] " " )
  switch ( Ranges[Aidx] ) {
    case 0:						# No RANGE
      TheRange = Array[Ridx]
      if ( ! isValid ) ErrorResponseNoMatch()
      Lidx++						# Select the next RANGE
      break
    case 1:						# RANGE start
      TheRange = Array[Ridx]
      IsFound = 0
      Lidx++						# Next time is the RANGE end
      if ( Array[Ridx] < Aidx ) return 1		# before the RANGE start
      if ( ! isValid ) return 1				# Not found in CHOICES
      IsFound = 1
      break
    case 2:						# Before, at or beyound the RANGE end
      if ( Array[Ridx] >= Aidx ) Lidx++			# After RANGE end, prepare for next RANGE
      if ( isValid ) IsFound = 1
      if ( ! IsFound && Array[Ridx] >= Aidx ) {		# Not found in CHOICES
          TheRange = TheRange "-" Array[Ridx]
          ErrorResponseNoMatch() }
      if ( ! isValid ) return 1
      break
  }
}

