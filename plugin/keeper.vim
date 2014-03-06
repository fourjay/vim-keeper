highlight KeyWordHighlight ctermbg=236 ctermfg=123
function! s:InlineHelp(...)
    let keyword = ""
    if  a:0
        let keyword = a:1
    else
        let keyword = expand('<cword>')
    endif
    let help_program = "~/.vim/manprograms/webman.sh -s" . &filetype
    if &keywordprg !~ "^man"
        let help_program = &keywordprg
    else
        if &filetype ==# "c" || &filetype ==# "sh" || &filetype ==# "vim"
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

