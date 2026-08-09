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

# This script will wrap a set of CHOICES into several rows.

BEGIN {
  ARGV[2] = ARGV[1]					# Two passes
  ARGC++
#  if ( Compressed ) {
    IndentAdjustment = match( substr(Indent,3)"a", "[^ ]" )
    IndentAdjustment = sprintf( "%*s", IndentAdjustment, " " )
#  } else IndentAdjustment = ""
}

END {
  if ( length(Str) > 0 ) {				# The last line
    if ( match(Str,/"$/) ) Quote = ""
    else Quote = "\""
    printf( "%s%s%s%s\n", Indent, IndentAdjustment, Str, Quote ) >>ScriptFile
  }
  else print "\"" >>ScriptFile				# Need a closing quote
###  else printf( "%s%s%s%s\n", Indent, IndentAdjustment, Str, "\"" ) >>ScriptFile
}

! Pass2 {						# First pass - find the largest field
  if ( AskType != "E" ) gsub( /\\t|,/, " ", $0 )	# Remove any <TABS> or commas except for "everything"
  for ( i=1;i<=NF;i++ ) {
    Flen = length($i)
    if ( Flen > MaxFlen ) MaxFlen = Flen }
  Pass2 = 1
  nextfile
}

Pass2 {							# Second pass - wrap the choices
  if ( AskType != "E" ) gsub( /\\t|,/, " ", $0 )	# Remove any <TABS> or commas except for "everything"
  printf("_CHOICES_DISPLAY_=\"") >ScriptFile		# The prefix
  Len0 = length($0)
  Lines = int(Len0/WrapLen) +1				# Remove any fraction
  LineLimit = int( (Len0+Lines)/Lines )			# Split $0 by this amount
  Sep = ""						# No separator before the 1st field
  for ( i=1 ; i<=NF ; i++ ) {				# Collect the fields
    if ( Compressed ) {
      Str = sprintf( "%s%s%s", Str, Sep, $i )
      if ( AskType == "E" ) Sep = " "
      else Sep = ", "
    } else {
      Str = sprintf( "%s%s%*s", Str, Sep, MaxFlen, $i )
      Sep = " "
    }
    if ( length(Str) > LineLimit ) {			# Reached the line limit
      printf( "%s%s%s", Indent, IndentAdjustment, Str ) >>ScriptFile	# Output the line
      Str = ""						# And start over
      Sep = ""
    }
  }
}
