if exists("b:current_syntax")
     finish
endif

syntax keyword thesauruskeyword noun verb definition Synonyms synonym adj Related
highlight link thesauruskeyword keyword

let b:current_syntax = "thesaurus"

