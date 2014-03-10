if exists("g:loaded_keeper")
    finish
endif
let g:loaded_keeper = 1


let s:base_path = expand("<sfile>:p:h")
function! s:inline_help(...)
    " Account for the special case non-external keywordprg
    if &keywordprg ==# ":help" && &filetype ==# "vim"
        execute "normal K"
        return
    endif

    let keyword = ""
    " if we've passed in a keyword, we want a random search
    " Else look at the current word (AKA "like K")
    if  a:0
        let keyword = a:1
    else
        let keyword = expand('<cword>')
    endif

    let context = &filetype
    if &filetype ==# ""
        let context = "wiki"
    endif

    " Get the plugins external shell script
    let help_program = s:base_path . "/../webman.sh  -s" . context
    " Allow user settings for keywordprg to override webman
    if &keywordprg !~ "^man" && executable( &keywordprg )
        let help_program = &keywordprg
    else
        " but keep man for these filetypes
        if &filetype ==# "c" || &filetype ==# "sh"
            let help_program = &keywordprg
        endif
    endif
    call <SID>load_help(help_program, keyword)
endfunction

function s:load_help( help_program, search_term )
    echo "searching on " . a:search_term . "..."
    " execute and load the output in a buffer
    let external_help = system(  a:help_program . " " . a:search_term )
    " open split with reasonable height
    let helpbufname = "__HELP__"
    let large_height = &lines * 2 / 3
    " reuse buffer as available
    let winnr = bufwinnr(helpbufname)
    if winnr > 0
        execute winnr . "wincmd w"
    else
        execute large_height . "split " helpbufname
    endif
    " set up clean buffer
    normal! ggdG

    setlocal filetype=webhelp
    setlocal buftype=nofile
    call append(0, split(external_help, '\v\n'))
    call append(0, "===========================================================")
    call append(0, "Shortcut-keys u:up d:down n?:find next " . a:search_term . " q:quit")
    call matchadd( "manReference", a:search_term )

    normal! 2G
    execute "silent normal! /" . a:search_term  . "\<CR>"
    let @/ = a:search_term
    nnoremap <buffer> d <C-d>
    nnoremap <buffer> <Space> <C-d>
    nnoremap <buffer> u <C-u>
    nnoremap <buffer> <silent> q :bdelete<Cr>
endfunction

function s:wikipedia(search_term)
    let help_program = s:base_path . "/../webman.sh  -swiki " . a:search_term
    call <SID>load_help(help_program, a:search_term)
endfunction

nnoremap <silent> KK :call <SID>inline_help()<CR>
command! -nargs=1 Help call <SID>inline_help(<f-args>)
command! -nargs=1 Wikipedia call <SID>wikipedia(<f-args>)

