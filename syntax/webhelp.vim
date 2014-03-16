syntax include syntax/man.vim syntax/man/*.vim
" if exists("b:current_syntax")
"     finish
" endif
"let b:current_syntax = "webhelp"

"highlight KeyWordHighlight ctermbg=236 ctermfg=123
syn match  manSectionHeading  "^\v[ ]*[A-Z][A-Z-_ ]*$"
syntax match manOptionDesc "\v[a-z0-9]+\(.*\)"
syntax match webHelpUrl "\vhttp[s]*:\/\/\S*"

highlight def link webHelpUrl String 


let b:current_syntax = "webhelp"
