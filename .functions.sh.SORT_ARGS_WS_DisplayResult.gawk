#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
# PURPOSE = "Return the sorted values as a variable or an array."
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

BEGIN {
  if ( Var ) {
    if ( Array ) { Sep1 = "( " ; Sep2 = " )" }
    else { Sep1 = "'" ; Sep2 = Sep1 }
    printf( "%s=%s", Var, Sep1 )
  } else {
    Sep1 = "\"" ; Sep2 = Sep1
    if ( Lines ) Format = "%s\n"
    else Format = "\"%s\" "
  }
}

END {
  if ( Var ) printf( "%s", Sep2 )
}

{ if ( Var ) {
    if ( Array ) printf( "\"%s\" ", gensub("\"", "\\\\\"", "g", $0) )
    else {
      gsub( "\"", "\\\"", $0 )
      printf( "\"%s\" ", gensub("'", "'\"'\"'", "g", $0) ) }
  } else {
    printf( Format, gensub("\"", "\\\\\"", "g", $0) ) > "/dev/stderr"
  }
  }
