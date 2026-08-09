#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
# PURPOSE = "Compare the characters in the answer with the acceptable character choices."
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

# This script will compare each of a set of characters (Answer) to a set of
# acceptable characters. It will exit with a code of "1" if no match is detected.

BEGIN {
  RS="" ; FS=""					# Character by character
  if (! ScriptFile) ScriptFile = "/dev/stdout"	# Default to stdout
  printf("") >ScriptFile			# Ensure it is empty
  IsError = 0
  if ( IsArray ) Space = " "			# Need a separator between elements
  else Space = ""				# Otherwise no extra spaces
}

END {
  if ( ! IsError ) {
    if ( IsChoices ) {
      if ( IsWhitespace ) {
        printf( "_CHOICES_DISPLAY_+=\"%s  Note: CHOICES contains whitespace vis:\n\t  Spaces=%d  Tabs=%d  Vtabs=%d\"\n", Indent, Spaces, Tabs, Vtabs ) >ScriptFile
        if ( FFeeds + Creturns ) printf( "_CHOICES_DISPLAY_+=\"\n\t  FormFeeds=%d  CarriageReturns=%d\"\n", FFeeds, Creturns ) >>ScriptFile
      }
    } else {
      if ( IsArray) { Prefix = "( " ; Suffix = " )" }
      else { Prefix = "\"" ; Suffix = "\"" }
      printf( "%s=%s%s%s\n", AnswerVariable, Prefix, AnswerVerified, Suffix ) >>ScriptFile
    }
  }
  printf("_IS_ERROR_=%d\n", IsError) >> ScriptFile
  exit IsError
}

{ if ( IsAnything ) DoItForAnything()
  Count = split( $0, Answer, "" )		# Each answer character ==> array element
  if ( ! MultiChoices && Count != 1 ) {
    IsError = 2
    exit 2 }
  ChoicesLen = length(Choices)			# Choices=$_CHOICES_ORIG_ - the original ones
#  if ( ! ChoicesLen ) exit 0
  for ( Char in Answer ) {			# Compare each character in the answer
    if ( IsChoices ) {
      if ( Answer[Char] ~ /[[:space:]]/ ) CountWhitespace()
      continue }
    Where = match( Choices, gensub(/\\/,"\\\\&",1,Answer[Char]) )	# Is it one of the CHOICES?
    if ( ! Where && ChoicesLen ) {		# No match if there is a set of choices
      printf( "_RESPONSE_ERROR_=\"Character \\\"%s\\\" is not one of the choices\n%*sor occurs more than the maximum allowed.\"\n", \
              "\\" Answer[Char], length(Function)+2, "" ) >>ScriptFile
      IsError = 2
      exit 2 }
    if ( IsArray || Answer[Char] ~ /["`$\\]/ ) Escape = "\\"		# Escape every character
    else Escape = ""
    AnswerVerified = AnswerVerified Space Escape Answer[Char]
    # for each 'Answer' match, we remove that character from choices.
    if ( ChoicesLen ) {
      if ( Where == 1 ) Choices = substr( Choices, 2 - BaskSlash )	# Matches 1st char of Choices
      else {					# Not 1st char so may have a prefix & suffix
        if ( Where != ChoicesLen ) ChoicesSfx = substr( Choices, Where + 1 + BaskSlash )
        else ChoicesSfx = ""			# No suffix
        Choices = substr( Choices, 1,  Where - 1 - BaskSlash ) ChoicesSfx
      }
      ChoicesLen = ChoicesLen - 1 - BaskSlash	# We removed one choice so it is shorter
    }
  }
}

function CountWhitespace() {
  IsWhitespace = 1
  switch ( Answer[Char] ) {
    case " ":
      Spaces++
      break
    case "\011":
      Tabs++
      break
    case "\013":
      Vtabs++
      break
    case "\014":
      FFeeds++
      break
    case "\015":
      Creturns++
      break
  }
}

function DoItForAnything() {			# Multi-answer list of any characters
  Count = split( $0, Answer, "" )		# Split list
  for ( Idx in Answer ) {
    gsub( /"[$"`\\]]/, "\\\\&", Answer[Idx] )	# Escape special characters
    AnswerVerified = sprintf( "%s \"%s\"", AnswerVerified, Answer[Idx] )
  }
  IsArray = 1
  exit 0
}
