highlight KeyWordHighlight ctermbg=236 ctermfg=123

function! s:InlineHelp(...)
    if &keywordprg ==# ":help"
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
    " Get our external shell script
    let base_path = expand("<sfile>:b")
    let help_program = base_path . "../webman.sh  -s" . &filetype
    " Allow user settings for keywordprg to override webman
    if &keywordprg !~ "^man"
        let help_program = &keywordprg
    else
        " but keep man for these filetypes
        if &filetype ==# "c" || &filetype ==# "sh"
            let help_program = &keywordprg
        endif
    endif
    let external_help = system(  help_program . " " . keyword )
    let large_height = &lines * 3 / 4
    execute large_height . "split __HELP__" 
    normal! ggdG
    setlocal filetype=man
    setlocal buftype=nofile
    call append(0, split(external_help, '\v\n'))
    call matchadd( "KeyWordHighlight", keyword )
    normal! 2G
    execute "silent normal! /" . keyword  . "\<CR>"
    let @/ = keyword
endfunction
nnoremap KK :call <SID>InlineHelp()<CR>
command! -nargs=1 WebMan call <SID>InlineHelp(<f-args>)

