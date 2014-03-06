highlight KeyWordHighlight ctermbg=236 ctermfg=123

let s:base_path = expand("<sfile>:p:h")
function! s:InlineHelp(...)
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

    " Get the plugins external shell script
    let help_program = s:base_path . "/../webman.sh  -s" . &filetype
    " Allow user settings for keywordprg to override webman
    if &keywordprg !~ "^man"
        let help_program = &keywordprg
    else
        " but keep man for these filetypes
        if &filetype ==# "c" || &filetype ==# "sh"
            let help_program = &keywordprg
        endif
    endif

    " load the helpfile in a buffer
    let external_help = system(  help_program . " " . keyword )
    " open split with reasonable height
    let large_height = &lines * 2 / 3
    execute large_height . "split __HELP__" 
    " set up clean buffer
    normal! ggdG
    setlocal filetype=man
    setlocal buftype=nofile
    call append(0, split(external_help, '\v\n'))
    call matchadd( "KeyWordHighlight", keyword )
    " 
    normal! 2G
    execute "silent normal! /" . keyword  . "\<CR>"
    let @/ = keyword
endfunction
nnoremap KK :call <SID>InlineHelp()<CR>
command! -nargs=1 WebMan call <SID>InlineHelp(<f-args>)

