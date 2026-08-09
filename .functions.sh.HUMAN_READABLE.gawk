#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:

# PURPOSE = "To convert numbers into  'si' or 'aec' format."
# VERSION = "12.01.06 - Jul 01, 2026"

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

BEGIN {							# Set the defaults
  gsub( "/", " ", TypeChoices )				# Use "/" as separator as it is hard to requote spaces
  # Convert lists to arrays
  split( Lengths, LengthsArray, "," )
  split( Rounds,  RoundsArray,  "," )
  split( ByteBs,  ByteBsArray,  "," )
  split( Spaces,  SpacesArray,  "," )
  split( Types,   TypesArray,   "," )
  split( Wholes,  WholesArray,  "," )
  if ( Var != "" ) {					# Output is a variable
    if ( Array ) {
      Output = sprintf( "%s=(", Var )			# Array format: Var=( VALUE )
      Sep1 = "\""
      Sep2 = ")" }
    else {
      Output = sprintf( "%s=\"", Var )			# Scalar format: Var="VALUE"
      Sep1 = "\\\""
      Sep2 = "\"" }
  } else {
    if ( split( Columns, ColumnsArray, "," ) ) {
      ColumnsArrayLen = length(ColumnsArray)
      Seq = 0
      for (Idx in ColumnsArray ) {			# Set missing values to the default
        if ( ColumnsArray[Idx] <= Seq || ! IsNumeric( ColumnsArray[Idx] ) ) {
          Error( "The columns in \"" Columns "\" are not numeric or are not in ascending sequence." ) }
        Seq = ColumnsArray[Idx]
        SetDefaults(Idx)
      }
    } else ColumnsArray[1] = 1
  }
  Format = "%*.*f%s%-s"					# The basic format for all numbers
  if ( FmtOut == "si" ) OneK = 1000			# Set the multiplier value
  else OneK = 1024
  First = 1
}

END {  if ( Output) print gensub( / *$/, "", 1, Output ) Sep2 }

{ if ( Var && NR > 1 ) Error("Option -V can only be used if there is one line of input.")
  Line = $0					# $0 doesn't preserve whitespace so have use a variable
  if ( ! Columns ) {				# No Column numbers defined so convert every column
    if ( NumColumns != NF ) {
      MakeColumnsArray()			# Do only if the number of columns changes
      NumColumns = NF }
  } else if ( First ) GetColumnInfo()		# Locate columns but only for the first line.
  delete ConvertedNumbers			# Reset the array
  IdxC = 1
#print "" > "/dev/stderr"
  for ( Col=1 ; Col<=NF ; Col++ ) {		# Look at every column
    if ( IdxC > ColumnsArrayLen )  break
    ColumnNumber = ColumnsArray[IdxC]
#print    "ColumnNumber = "ColumnsArray[IdxC], "IdxC="IdxC > "/dev/stderr"
    if ( ColumnNumber != Col ) continue		# Not this column
    if ( ColumnNumber > NF ) continue		# Ignore if the column doesn't exist in $0
    ConvertNumber( gensub(/[,+]/, "", "g", $ColumnNumber ) )	# Remove commas and "+" signs
    IdxC++
  }
  if ( Columns ) PrintLine()			# Apply numbers in reverse order to the input line and display it
  else if ( Var == "" ) print ""		# Final newline
}

function ConvertNumber(Number,	Cmd) {
  Cmd = sprintf("numfmt ${Options} --invalid=warn --from=auto --to=%s --format=%%%d.%df -- %s", TypesArray[IdxC], LengthsArray[IdxC], RoundsArray[IdxC], Number )
  Cmd | getline Result
  close(Cmd)
  FormatConvertedNumber( Result )
}

function Error(Message) {
  printf( "ERROR: HUMAN_READABLE: %s\n", Message ) > "/dev/stderr"
  exit 2
}

function FormatConvertedNumber(HRnumber,	Match,Mult,Num,Spaces) {
  Match = match( HRnumber ";", /[[:alpha:];]/ )		# Find the multiplier
  Num = substr( HRnumber, 1, Match - 1 ) + 0		# Extract the number part
  Mult = substr( HRnumber, Match )			# Get the multiplier
  if ( Mult == "" ) {					# No multiplier so the number is just bytes (<1K)
    if ( TypesArray[IdxC] == "iec-i" ) Spaces = "  "	# Add spaces to conserve alignment
    else Spaces = " "
    if ( WholesArray[IdxC] ) Round = 0			# Force a whole number
    else Round = RoundsArray[IdxC]			# Add the fractional part to the number
  } else {
    Spaces = ""						# There is a multiplier so no extra spaces
    Round = RoundsArray[IdxC] }				# and always use rounding
  if ( Columns ) {					# Specific columns requested, so numbers saved
    ConvertedNumbers[IdxC] = sprintf( Sep1 Format Sep1 " ", LengthsArray[IdxC], Round, Num, SpacesArray[IdxC], Mult ByteBsArray[IdxC] Spaces )
  } else {
    if ( Var == "" ) printf( "\"" Format "\" ",             LengthsArray[IdxC], Round, Num, SpacesArray[IdxC], Mult ByteBsArray[IdxC] Spaces )
    else Output = Output sprintf( Sep1 Format Sep1 " ",     LengthsArray[IdxC], Round, Num, SpacesArray[IdxC], Mult ByteBsArray[IdxC] Spaces )
  }
}

function GetColumnInfo(		Column,Idx1,Idx2,NextCol,NumLen,NumStart) {
  NumStart = 1
  NumLen = 0
  NextCol = 1
  for ( Idx1=1 ; Idx1<=ColumnsArrayLen ; Idx1++ ) {	# For each column number to convert
    Column = ColumnsArray[Idx1]				# Get the column number
    if ( Column > NF ) {				# Column doesn't exist in first line
      delete ColumnsArray[Idx1]				# So delete the column information
      continue }
    # 'match' will always find the first matching column in $0.
    # Since, in one line, there may be identical numbers in more that one column,
    # we must find the start of the correct column (including leading whotespace).
    for ( Idx2=NextCol ; Idx2<=Column ; Idx2++ ) {
      # Find the space padded column (in Line) starting right after the previous match.
      if ( ! (Match = match( " "substr(Line, NumStart ), " +" $Column )) ) break
      NumberStart[Idx1] = NumStart + RSTART - 1
      NumberLen[Idx1] = RLENGTH - 1
      NumStart = NumStart + RSTART + RLENGTH -2
      NextCol = Column + 1
      if ( Idx2 == Column ) break			# This is the column with the same number
    }
  }
  First = 0						# We have all the info so do it only once
}

function IsNumeric(theNumber,  anArray) {		# IsNumeric --- check whether a value is numeric
  switch ( typeof(theNumber) ) {
    case "strnum":					# Gawk thinks it is so that is good enough for me
    case "number":
      return 1
    case "string":					# If only 1 column and that one is a numeric string...
      return ( split(theNumber, anArray, " ") == 1 ) && ( typeof(Array[1]) == "strnum" )
    default:
      return 0						# Not numeric
  }
}

function MakeColumnsArray(	Idx) {			# No columns defined so must set values line-by-line
  delete ColumnsArray
  for ( Idx=1 ; Idx<=NF ; Idx++ ) {
    ColumnsArray[Idx] = Idx				# For each column...
    SetDefaults(Idx)					# Set the defaults
  }
}

function PrintLine(	Idx,Prefix,Suffix) {
  for ( Idx=length(ColumnsArray) ; Idx>=1 ; Idx-- ) {
    Prefix = substr(Line, 1, NumberStart[Idx] -1 )
    Suffix = substr(Line, NumberStart[Idx] + NumberLen[Idx] )
    Line = Prefix ConvertedNumbers[Idx] Suffix
  }
  print Line
}

function SetDefaults(Idx) {
  if ( LengthsArray[Idx] ) {
    if ( ! IsNumeric( LengthsArray[Idx] ) ) Error( "Some lengths in \"" Lengths "\" are not numeric.")
  } else LengthsArray[Idx] = LengthsArray[Idx-1]	# Default to the previous
  if ( RoundsArray[Idx] ) {
    if ( ! IsNumeric( RoundsArray[Idx] ) ) Error( "Some rounding numbers in \"" Rounds "\" are not numeric.")
  } else RoundsArray[Idx] = RoundsArray[Idx-1]		# Default to the previous
  if ( ByteBsArray[Idx] == "" )  ByteBsArray[Idx]  = ByteBsArray[Idx-1]	# Default to the previous
  else if ( ByteBsArray[Idx] ) ByteBsArray[Idx] = "B"	# To "B"
       else ByteBsArray[Idx] = ""			#   or not to be
  if ( SpacesArray[Idx] == "" )  SpacesArray[Idx]  = SpacesArray[Idx-1]	# Default to the previous
  else if ( SpacesArray[Idx] ) SpacesArray[Idx] = " "	# Want a space between number and multiplier
       else SpacesArray[Idx] = ""			#   or not
  if ( TypesArray[Idx] ) {
    if ( TypeChoices !~ " " TypesArray[Idx] " " ) {
      Error( "Invalid format type \"" TypesArray[Idx] "\".\nIt must be one of \"" substr( TypeChoices, 2, length(TypeChoices)-2 ) "\".") }
  } else TypesArray[Idx] = TypesArray[Idx-1]		# Default to the previous
  if ( TypesArray[Idx] == "si" ) OneKarray[Idx] = 1000
  else OneKarray[Idx] = 1024
}

