#!/usr/bin/env bash

print_help() {
    cat <<HELP_BOUNDARY
NAME
    $(basename $0)

SYNOPSIS
    $(basename $0) [-h] [-s syntax_name ]

DESCRIPTION
    Return a (partially) reformatted text lookup

OPTIONS
    -h
        print help

    -s [SYNTAX]
        specify the type (implicly changing the URL and cleanup)

    -b [browser]
        specify browser

BUGS
    Almost certainly

HELP_BOUNDARY
    exit
}

syntax=php

while getopts s:b:h? OPT
do
    case $OPT in
        s) syntax=$OPTARG  ;;
        b) browser=$OPTARG ;;
        h) print_help      ;;
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
    ${program} "${URL}"
}

lookup() {
    echo "LOOKING UP '${search_term}' with $1"
    echo "-----------------------------------"
    local URL="$1"
    timeout 15 $browser "$URL"
}

MDN__BASE_URL="https://developer.mozilla.org/en-US"
MDN_URL="https://developer.mozilla.org/en-US/search?q="
GOOGLE_LUCKY_URL="http://www.google.com/search?sourceid=navclient&btnI=I&q="
DUCKDUCKGO_URL="http://duckduckgo.com/?q="

case $syntax in
    php)
        #lookup "${GOOGLE_LUCKY_URL}site:php.net+${search_term}" |
        lookup "${DUCKDUCKGO_URL}!phpnet+${search_term}" |
        sed -e '1,/\(Description\|Closest matches:\)/ d' -e '/Contributed Notes/,$ d' |
              clean_output
              #sed -n '/Description/,/Contributed Notes/p' | # skip the non-content
              #clean_output
        ;;
    css)
        #CSS_MAN_URL="http://cssdocs.org/"
        lookup "${GOOGLE_LUCKY_URL}site:cssdocs.org+${search_term}" |
            clean_output
        ;;
    javascript)
        lookup "${GOOGLE_LUCKY_URL}site:developer.mozilla.org+javascript+${search_term}" |
            clean_mdn_output |
            clean_output
        ;;
    html)
        lookup "${MDN__BASE_URL}/docs/Web/HTML/Element/${search_term}" |
            sed -n '/^Summary/,/^Contributors/p' |
            clean_output
        ;;
    mail|text)
        DICT="http://m.dictionary.com"
        DICT="m.dictionary.com"
        #lookup "${DUCKDUCKGO_URL}!ducky+site:m.dictionary.com+${search_term}"   #|
        #lookup "${DICT}/${search_term}"   |
        # lookup ${DUCKDUCKGO_URL}site:${DICT}+inurl=definition+${search_term}
        #lookup "${GOOGLE_LUCKY_URL}site:${DICT}+inurl=definition+${search_term}"
        #lookup ${DUCKDUCKGO_URL}!dictionary+${search_term}
        lookup "http://www.thefreedictionary.com/p/${search_term}" #|
            # sed "1,/${search_term}LINK/d" |
            # sed '/^Share:LINK/,$ d'
        ;;
    apache)
        lookup "${GOOGLE_LUCKY_URL}site:httpd.apache.org+${search_term}"   |
            clean_output                    |
            sed '/^[ ]*top[ ]*$/ d'         |
            sed '/^Available Languages:/ d' |
            sed '/\[down\]/ d'
        ;;
    wiki*)
        lookup "${DUCKDUCKGO_URL}!wikipedia+${search_term}"   |
            sed -e '/^From Wikipedia/ d'  \
                -e '/^Jump to/ d'         \
                -e '/\[down\]/ d'         \
                -e 's/\[[0-9]*\]//g'      \
                -e 's/\[[0-9]*px.*\]//'   \
                -e 's/\[edit\]//'         |
                clean_output
        ;;
    git*)
        lookup "${GOOGLE_LUCKY_URL}site:git-scm.com+${search_term}"   |
            sed -e '/^Git --/,/Index of Commands/ d' \
                -e '/\[[0-9]*fig[0-9]*\]/ d' |
            clean_output
        ;;
    sql*)
        # it's cross db....
        lookup "${GOOGLE_LUCKY_URL}site:www.w3schools.com+${search_term}+sql"   |
            sed -e '/^Your suggestion/,$ d' \
                -e '1,/^SQL Quiz/ d' |
            clean_output
        ;;
    awk*)
        lookup "${DUCKDUCKGO_URL}awk+!ducky+${search_term}"   |
            clean_output
        ;;

    *)
        lookup "${DUCKDUCKGO_URL}!${syntax}+${search_term}+!ducky" |
            clean_output

esac

