#!/bin/sh
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

#
# uniClass.tcl --
#
#	Generates the character ranges and singletons that are used in
#	generic/regc_locale.c for translation of character classes.
#	This file must be generated using a tclsh that contains the
#	correct corresponding tclUniData.c file (generated by uniParse.tcl)
#	in order for the class ranges to match.
#

proc emitRange {first last} {
    global ranges numranges chars numchars extchars extranges

    if {$first < ($last-1)} {
	if {!$extranges && ($first) > 0xFFFF} {
	    set extranges 1
	    set numranges 0
	    set ranges [string trimright $ranges " \n\r\t,"]
	    append ranges "\n#if CHRBITS > 16\n    ,"
	}
	append ranges [format "{0x%X, 0x%X}, " \
		$first $last]
	if {[incr numranges] % 4 == 0} {
	    set ranges [string trimright $ranges]
	    append ranges "\n    "
	}
    } else {
	if {!$extchars && ($first) > 0xFFFF} {
	    set extchars 1
	    set numchars 0
	    set chars [string trimright $chars " \n\r\t,"]
	    append chars "\n#if CHRBITS > 16\n    ,"
	}
	append chars [format "0x%X, " $first]
	incr numchars
	if {$numchars % 9 == 0} {
	    set chars [string trimright $chars]
	    append chars "\n    "
	}
	if {$first != $last} {
	    append chars [format "0x%X, " $last]
	    incr numchars
	    if {$numchars % 9 == 0} {
		append chars "\n    "
	    }
	}
    }
}

proc genTable {type} {
    global first last ranges numranges chars numchars extchars extranges
    set first -2
    set last -2

    set ranges "    "
    set numranges 0
    set chars "    "
    set numchars 0
    set extchars 0
    set extranges 0

    for {set i 0} {$i <= 0x10FFFF} {incr i} {
	if {$i == 0xD800} {
	    # Skip surrogates
	    set i 0xE000
	}
	if {[string is $type [format %c $i]]} {
	    if {$i == ($last + 1)} {
		set last $i
	    } else {
		if {$first >= 0} {
		    emitRange $first $last
		}
		set first $i
		set last $i
	    }
	}
    }
    emitRange $first $last

    set ranges [string trimright $ranges "\t\n ,"]
    if {$extranges} {
	append ranges "\n#endif"
    }
    set chars  [string trimright $chars "\t\n ,"]
    if {$extchars} {
	append chars "\n#endif"
    }
    if {$ranges ne ""} {
	puts "static const crange ${type}RangeTable\[\] = {\n$ranges\n};\n"
	puts "#define NUM_[string toupper $type]_RANGE (sizeof(${type}RangeTable)/sizeof(crange))\n"
    } else {
	puts "/* no contiguous ranges of $type characters */\n"
    }
    if {$chars ne ""} {
	puts "static const chr ${type}CharTable\[\] = {\n$chars\n};\n"
	puts "#define NUM_[string toupper $type]_CHAR (sizeof(${type}CharTable)/sizeof(chr))\n"
    } else {
	puts "/*\n * no singletons of $type characters.\n */\n"
    }
}

puts "/*
 *	Declarations of Unicode character ranges.  This code
 *	is automatically generated by the tools/uniClass.tcl script
 *	and used in generic/regc_locale.c.  Do not modify by hand.
 */
"

foreach {type desc} {
    alpha "alphabetic characters"
    control "control characters"
    digit "decimal digit characters"
    punct "punctuation characters"
    space "white space characters"
    lower "lowercase characters"
    upper "uppercase characters"
    graph "unicode print characters excluding space"
} {
    puts "/*\n * Unicode: $desc.\n */\n"
    genTable $type
}

puts "/*
 *	End of auto-generated Unicode character ranges declarations.
 */"
