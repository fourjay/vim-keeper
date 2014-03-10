#!/usr/bin/env bash

print_help() {
    cat <<HELP_BOUNDARY
NAME
    $(basename $0)

SYNOPSIS
    $(basename $0) [-s SYNTAX] keyword

DESCRIPTION

    Looks up keyword with an available text browser in an appropriate web source

OPTIONS

    -s [SYNTAX]
        specify the type (implicly changing the URL and cleanup)

    -n
        no pager

    -h
        print this help

HELP_BOUNDARY
    exit
}

PAGER=
syntax=php

while getopts s:nh? OPT
do
    case $OPT in
        s) syntax=$OPTARG ;;
        n) PAGER="tee"    ;;
        h) print_help     ;;
    esac
done
shift $(($OPTIND - 1))

# clean underscores
search_term=$( echo $1 | sed s/_/-/g )
if [ -z "$search_term" ]; then
    echo "No word to search for"
    exit
fi

# serialized browser plus option(s)
# ordered by increasing priority
BROWSERS="
   lynx|-dump
   links|-dump
   elinks|--no-references|-dump
   w3m|-dump
"

# Find a browser
browser=
for b in $BROWSERS; do
   browser_no_flags=$( echo "$b" | sed 's/|.*//' )
   #echo $browser_no_flags
   found=$( which $browser_no_flags 2>/dev/null )
   if [ -n "$found" ]; then
      # unpack options
      browser=$( echo $b | sed 's/|/ /g' )
   fi
done
if [ -z "$browser" ]; then
   echo "no text browser found" >2
   exit
fi

# SUBROUTINES

clean_output() {
   sed -e 's/^[ ]*Description/DESCRIPTION/'         \
       -e 's/^[ ]*Parameters/PARAMETERS/'           \
       -e 's/^[ ]*Notes/NOTES/'                     \
       -e 's/^[ ]*See [Aa]lso/SEE ALSO/'            \
       -e 's/^[ ]*Return Values/RETURN VALUES/'     \
       -e 's/^[ ]*Example[(]*s[)]/EXAMPLES/'        \
       -e 's/^[ ]*Changelog/CHANGELOG/'             \
       -e 's/^[ ]*Caution/CAUTION/'                 \
       -e 's/^[ ]*[Tt]opics/TOPICS/'                \
       -e 's/^[ ]*[Ee]xample/EXAMPLE/'              \
       -e 's/^[ ]*[Aa]ttributes/ATTRIBUTES/'        \
       -e 's/^[ ]*[Ss]yntax/SYNTAX/'                \
       -e 's/^[ ]*[Ss]ummary/SUMMARY/'              \
       -e 's/^[ ]*[Ss]pecification/SPECIFICATION/'  \
       -e 's/^\[[0-9]+\]//g'
}

clean_mdn_output() {
    sed '1,/Print this page/d' |
    sed '/^See also/,$ d' |
    sed '/^In This Article/,/ 5. See also/ d' |
    sed '/Show Sidebar/d' |
    sed '/^Image:/ d'
}

live_lookup() {
    local URL="$1"
    local program=$( echo $browser | sed 's/[ ].*//' )
    ${program} ${URL}
}

lookup() {
    echo "LOOKING UP '${search_term}' with $1"
    echo "-----------------------------------"
    local URL="$1"
    $browser "$URL"
}

page_output() {
    if [ -z "$PAGER" ]; then
        less -p${search_term}
    else
        tee
    fi
}

MDN__BASE_URL="https://developer.mozilla.org/en-US"
MDN_URL="https://developer.mozilla.org/en-US/search?q="
GOOGLE_LUCKY_URL="http://www.google.com/search?&sourceid=navclient&btnI=I&q="

case $syntax in
    php)
        PHP_MAN_URL="http://us.php.net/manual/en/print/function"
        lookup ${PHP_MAN_URL}.${search_term}.php        |
            sed -n '/Description/,/Contributed Notes/p' | # skip the non-content
            clean_output                                |
            page_output
        ;;
    css)
        CSS_MAN_URL="http://cssdocs.org/"
        #lookup ${CSS_MAN_URL}${search_term} |
        lookup ${GOOGLE_LUCKY_URL}site:cssdocs.org+${search_term} |
            clean_output                    |
            page_output
        ;;
    javascript)
        lookup "${GOOGLE_LUCKY_URL}site:developer.mozilla.org+javascript+${search_term}" |
            clean_mdn_output |
            clean_output     |
            page_output
        ;;
    html)
        lookup "${MDN__BASE_URL}/docs/Web/HTML/Element/${search_term}" |
            sed -n '/^Summary/,/^Contributors/p' |
            clean_output                         |
            page_output
        ;;
    text)
        DICT="http://m.dictionary.com/definition"
        lookup "${DICT}/${search_term}"   |
            sed "1,/${search_term}LINK/d" |
            sed '/^Share:LINK/,$ d'       |
            page_output
        ;;
    apache)
        lookup "${GOOGLE_LUCKY_URL}site:httpd.apache.org+${search_term}"   |
            clean_output                    |
            sed '/^[ ]*top[ ]*$/ d'         |
            sed '/^Available Languages:/ d' |
            sed '/\[down\]/ d'              |
            page_output
        ;;
    *)
        lookup "${GOOGLE_LUCKY_URL}${syntax}+language+reference+${search_term}" |
            clean_output |
            page_output

esac


