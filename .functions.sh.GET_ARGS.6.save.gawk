#!/bin/gawk -f
# vim:set number nowrap foldmethod=indent foldnestmax=2 nofoldenable:
#
#	.functions.sh.GET_ARGS.6.save.gawk
#
# PURPOSE = "These functions save the variable values necessary to scan the parent script options."
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
  # SAVEgawkScript = X					# The generated gawk script
  SAVEhelpe = SAVEdir "/helpe"				# The saved expanded help files prefix
  SAVEhelpb = SAVEdir "/helpb"				# The saved brief help files prefix
  SAVEhelpFI = SAVEdir "/helpFI"			# The saved filtered help info file
}

function saveEverything() {
  printf( "#!/bin/gawk -f\n\nBEGIN {\n" ) > SAVEgawkScript	# Start of a BEGIN block for gawk script
  saveVars()						# Save variables as "assignments"
  saveArrays()						# Save array elements as assignments
  printf( "}\n" ) >> SAVEgawkScript			# End of the BEGIN block
  saveHelp()						# Save brief help and expanded help files
return
  close( SAVEgawkScript )				# Close all the files
  close( SAVEbashScript1 )
  close( SAVEhelpb 1 )
  close( SAVEhelpb 2 )
  close( SAVEhelpb 3 )
  close( SAVEhelpb 4 )
  close( SAVEhelpe 1 )
  close( SAVEhelpe 2 )
}

function saveHelp() {					# Save the generated HELP text
  helpMakePurpose()
  helpMakeSynopsis()
  gsub( HELPhideArgs, HELPsynopsisArgs[1], HELPsection["A","e"] )	# Now we know the argument patterns
  if ( GAdefinedFCs ) saveUpdateSectionHeaders()

  # Save brief help files
  HELPtext = HELPnl HELPsection["p","b"] HELPsection["P","b"]
  helpPrepareDisplay()					# Create the help file
  print HELPtext > SAVEhelpb 1				# Create part 1 of brief help
  # On restore, a posssible <FC> info line goes here (between helpb1 and helpb2
  HELPtext = HELPsection["S","b"] HELPsection["s","b"]
  helpPrepareDisplay()					# Create the help file
  print HELPtext > SAVEhelpb 2				# Create part 2 of brief help
  HELPtext = HELPsection["O","b"] HELPsection["b","b"] HELPsection["B","b"]	# These sections have to be columnized
  helpPrepareDisplay()					# Create the help file again
  print HELPtext > SAVEhelpb 3				# Create part 3 of brief help
  HELPtext = HELPsection["T","b"]
  helpPrepareDisplay()
  print HELPtext > SAVEhelpb 4				# Create part 4 of brief help

  # Save expanded help files
  HELPtext = HELPsection["p","e"] HELPsection["P","e"]
  helpPrepareDisplay()
  print HELPtext > SAVEhelpe 1				# Create part 1 of expanded help
  # On restore, a posssible <FC> info line goes here (between helpe1 and helpe2
  HELPtext = HELPsection["S","e"] HELPsection["s","e"] HELPsection["D","e"] HELPsection["A","e"] \
       HELPsection["O","e"] HELPsection["b","e"] HELPsection["B","e"] HELPsection["W","e"] \
       HELPsection["I","e"] HELPsection["E","e"] HELPsection["F","e"] HELPsection["U","e"] \
       HELPsection["G","e"] HELPsection["C","e"] HELPsection["M","e"] HELPsection["n","e"] \
       HELPsection["N","e"] HELPsection["T","e"]
  helpPrepareDisplay()
  print HELPtext > SAVEhelpe 2				# Create part 2 of expanded help
}

function saveUpdateSectionHeaders(	fcs,headerInfo,idxI,sortedInfo,thisSec) {
  asorti( HELPsectionHeaderFCs, sortedInfo )
  for ( idxI in sortedInfo ) {
    split( sortedInfo[idxI], headerInfo, SUBSEP )
    if ( headerInfo[1] == thisSec ) fcs = fcs headerInfo[2]	# Collect the <FC>s
    else {
      if ( fcs ) {
  if ( fcs == _a_ ) fcs = GAdefinedFCs
  gsub( HELPsepFC HELPsepFC, HELPsepFC fcs HELPsepFC, HELPsection[thisSec,"b"] )
  gsub( HELPsepFC HELPsepFC, HELPsepFC fcs HELPsepFC, HELPsection[thisSec,"e"] ) }
      thisSec = headerInfo[1]
      fcs = headerInfo[2]
    }
  }
}

function saveArrays() {					# The array data that must be saved
  saveArrayDoIt( GAdefinedOPTi, "GAdefinedOPTi" )
  saveArrayDoIt( GAOptValueNeeded, "GAOptValueNeeded" )
  saveArrayDoIt( GAOptsMulti, "GAOptsMulti" )
  saveArrayDoIt( GAsavedOPTLIST, "GAsavedOPTLIST" )
  saveArrayDoIt( GAtestArgs, "GAtestArgs" )
  saveArrayDoIt( GAtestOpts, "GAtestOpts" )
  saveArrayDoIt( GAtestExpand, "GAtestExpand" )
  saveArrayDoIt( GAtestBrief, "GAtestBrief" )
  saveArrayDoIt( GAtestCompact, "GAtestCompact" )
  saveArrayDoIt( GAtestDefault, "GAtestDefault" )
  saveArrayDoIt( GAdefinedFCdescriptions, "GAdefinedFCdescriptions", 1 )
}

function saveArrayDoIt(theArray,arrayName,normalize,	idxA) {
  # Save as assignments: name[idx] = "value"
  if ( ! length(theArray) ) {				# An empty array
    saveComment( arrayName )				# So make it a comment
  } else {
    for ( idxA in theArray ) {				# Process all the elements
      if ( normalize ) {
  gsub( /"/, "\\\"", theArray[idxA] )		# Escape double quotes
      }
      if ( mainIsNumeric(theArray[idxA]) ) printf("  %s[\"%s\"] = %s\n", arrayName, idxA, theArray[idxA] ) >> SAVEgawkScript
      else printf("  %s[\"%s\"] = \"%s\"\n", arrayName, idxA, gensub(/\\n/,"\\\\n","g",theArray[idxA]) ) >> SAVEgawkScript
    }
  }
}

function saveComment(theName) {
  print "# " theName " = X	# Not needed" >> SAVEgawkScript
}

function saveVars() {
  saveVarDoIt( Bash_ALL_OPTIONS_, "Bash_ALL_OPTIONS_" )
  saveVarDoIt( HELPless, "HELPless" )
  saveVarDoIt( HELPcolumnSep, "HELPcolumnSep" )
  saveVarDoIt( HELPisCompact, "HELPisCompact" )
  saveVarDoIt( HELPisBrief, "HELPisBrief" )
  saveVarDoIt( HELPheading, "HELPheading" )
  saveVarDoIt( HELPheadingLen, "HELPheadingLen" )
  saveVarDoIt( SAVEhelpb, "SAVEhelpb" )
  saveVarDoIt( SAVEhelpe, "SAVEhelpe" )
  saveVarDoIt( SAVEhelpFI, "SAVEhelpFI" )
  saveVarDoIt( GAseparator, "GAseparator" )
  saveVarDoIt( GAfindEQ, "GAfindEQ" )
  saveVarDoIt( GAfindQSQ, "GAfindQSQ" )
  saveVarDoIt( GAdefinedFCs, "GAdefinedFCs" )
  saveVarDoIt( GAisDebug, "GAisDebug" )
  saveVarDoIt( PSlongOptions, "PSlongOptions" )
  saveVarDoIt( PSshortOptions, "PSshortOptions" )
  saveVarDoIt( PSregexHELP, "PSregexHELP" )
  saveVarDoIt( PSregexHelp, "PSregexHelp" )
  saveVarDoIt( PSregexTest, "PSregexTest" )
  saveVarDoIt( PSregexVersion, "PSregexVersion" )
  saveVarDoIt( PSoptPrefixVar, "PSoptPrefixVar" )
  saveVarDoIt( PSoptSuffixVar, "PSoptSuffixVar" )
  saveVarDoIt( PSoptsAllListVar, "PSoptsAllListVar" )
  saveVarDoIt( PSargsArrayVar, "PSargsArrayVar" )
  saveVarDoIt( Cat, "Cat" )				# Indices for arrays GAtestArgs and GAtestOpts
  saveVarDoIt( Cnt, "Cnt" )
  saveVarDoIt( Cnt1, "Cnt1" )
  saveVarDoIt( Plu, "Plu" )
  saveVarDoIt( Cnt2, "Cnt2" )
  saveVarDoIt( Key, "Key" )
  saveVarDoIt( Msg, "Msg" )
  saveVarDoIt( _a_, "_a_" )
  saveVarDoIt( _a_msg_, "_a_msg_", 1 )
  saveVarDoIt( _b_, "_b_" )
  saveVarDoIt( _b_msg_, "_b_msg_", 1 )
  saveVarDoIt( _c_, "_c_" )
  saveVarDoIt( _c_msg_, "_c_msg_", 1 )
  saveVarDoIt( _e_, "_e_" )
  saveVarDoIt( _e_msg_, "_e_msg_", 1 )
  saveVarDoIt( _h_, "_h_" )
  saveVarDoIt( _help_, "_help_" )
  saveVarDoIt( _H_, "_H_" )
  saveVarDoIt( _HELP_, "_HELP_" )
  saveVarDoIt( _t_, "_t_" )
  saveVarDoIt( _test_, "_test_" )
  saveVarDoIt( _tInt_, "_tInt_" )
  saveVarDoIt( _v_, "_v_" )
  saveVarDoIt( _version_, "_version_" )
}

function saveVarDoIt(varVal,varName,normalize) {	# Save as assignemts: name=value
  if ( normalize ) {
    gsub( /"/, "\\\"", varVal )				# Escape double quotes
  }
  if ( mainIsNumeric(varVal) ) printf("  %s = %s\n", varName, varVal ) >> SAVEgawkScript
  else printf("  %s = \"%s\"\n", varName, gensub(/\\n/,"\\\\n","g",varVal) ) >> SAVEgawkScript
}

