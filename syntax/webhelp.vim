syntax include syntax/man.vim syntax/man/*.vim

"highlight KeyWordHighlight ctermbg=236 ctermfg=123
" syntax match WebHelpSection '^\v[ ]{0,3}[A-Z][A-Z-_]*$'
syntax match WebHelpSection '\v^[ ]{0,3}[A-Z][a-zA-Z-_]+([ ]+[a-zA-Z0-9_-]+){0,4}$'
highlight link WebHelpSection FoldColumn

syntax match manOptionDesc     '\v[a-z0-9]+\(.*\)'

syntax match WebHelpBody '\v(\w+\s+){10,}'
highlight link WebHelpBody None

syntax match webHelpUrl        '\vhttp[s]*:\/\/\S*'
syntax match webHelpUrl        '\v[a-zA-Z0-9._]+\.(com|net|edu|org)'

highlight def link webHelpUrl Identifier 

syntax match webHelpMarkers    '\(^\s*[*+-] \)\@<=.*'
highlight link webHelpMarkers String

syntax match WebHelpHelp   '^[|]  .*'

highlight link WebHelpHelp StatusLine

let b:current_syntax = "webhelp"
