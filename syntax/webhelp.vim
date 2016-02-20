syntax include syntax/man.vim syntax/man/*.vim

"highlight KeyWordHighlight ctermbg=236 ctermfg=123
syntax match manSectionHeading '^\v[ ]*[A-Z][A-Z-_ ]*$'
syntax match manOptionDesc     '\v[a-z0-9]+\(.*\)'

syntax match webHelpUrl        '\vhttp[s]*:\/\/\S*'
syntax match webHelpUrl        '\v[a-zA-Z0-9._]+\.(com|net|edu|org)'

highlight def link webHelpUrl Identifier 

syntax match webHelpMarkers    '\([*+-•] \)\@<=.*'
highlight link webHelpMarkers Operator

let b:current_syntax = "webhelp"
