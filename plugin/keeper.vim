if exists("g:loaded_keeper")
    finish
endif
let g:loaded_keeper = 1

let s:save_cpo = &cpo
set cpo&vim

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
        let keyword = <SID>get_searchword()  " expand('<cword>')
    endif

    let context = 'wiki'
    if a:0 == 2
        let context = a:2
    elseif &filetype == 'webhelp'
        " allow recursive lookup in the help output
        let context=b:parent_filetype
    " If we don't have a better option
    elseif &filetype ==# ""
        let context = "wiki"
    " Allow corcing context
    elseif a:0 > 1
        let context = a:2
    else
        let context = <SID>get_cword_context()
    endif

    let url = <SID>extract_url(getline("."))
    if url != ""
        let context = "url"
    endif
    let help_program = <SID>get_webman_syscall( context, keyword )

    " Allow user settings for keywordprg to override webman
    if &keywordprg !~ "^man" && executable( &keywordprg )
        let help_program = &keywordprg
    else
        " but keep man for these filetypes
        if &filetype ==# "c" || &filetype ==# "sh"
            let help_program = &keywordprg
        endif
    endif

    call <SID>load_help(help_program, keyword, context)
endfunction

function! s:get_searchword()
    let cline = getline(".")
    let url = <SID>extract_url(cline)
    if url != ""
        return url
    endif
    let selected = ""
    if visualmode() == 'v'
        let selected = <SID>get_visual()
        let selected = substitute( selected, " ", "+", "g")
        return selected
    endif
    return expand("\<cword>")
endfunction

function! s:get_visual()
    let saved_s_register = @s
    normal! gv"sy
    let selected = @s
    let @s = saved_s_register
    return selected
endfunction

function! s:extract_url(cline)
    " yes, this is incomplete, but in practice...
    let TLDs = [ 'com', 'net', 'org' ]
    " matchstr (at least in my environment) doesn't uork with match alternate
    for tld in TLDs
        let link_pattern = "[^ ][^ ]*[.]" . tld . "[:\/][/]*[^ ][^ ]*" 
        " echom "link_pattern is " . link_pattern
        let url = matchstr( a:cline, link_pattern)
        " echom "with tld " . tld . "url is " . url
        if url != ""
            return url
        endif
    endfor
    return ""
endfunction

function! s:get_cword_context()
    let keyword_syngrp = synIDattr(synID(line('.'), col('.'), 0), 'name')
    if keyword_syngrp =~# "SQL"
        return "sql"
    elseif keyword_syngrp =~? "javascript"
        return "javascript"
    endif
    if &filetype != ""
        return &filetype
    endif

endfunction

function s:load_help( help_program, search_term, context )
    let parent_filetype = a:context
    " echom "searching on " . a:search_term . "..."
    " execute and load the output in a buffer
    "let external_help = system(  a:help_program . " " . a:search_term )
    " echom "help_program is " . a:help_program
    silent let external_help = system(  a:help_program )
    " open split with reasonable height
    let helpbufname = "__HELP__"
    let large_height = &lines * 2 / 3
    " reuse buffer as available
    let winnr = bufwinnr(helpbufname)
    if winnr > 0
        execute winnr . "wincmd w"
    else
        silent execute large_height . "split " helpbufname
    endif
    " If we are re-using, then temporarily make writeable warning
    setlocal noreadonly
    " set up clean buffer
    normal! ggdG
    if !  exists( "b:parent_filetype" )
        let b:parent_filetype = parent_filetype
    endif

    " Track previous searches for back
    if ! exists( "b:search_stack" )
        let b:search_stack = [ a:search_term ]
    elseif exists ("b:search_stack_pointer")
        " don't add search term to stack
        if b:search_stack[ b:search_stack_pointer ] !=# a:search_term
            let  b:search_stack  = b:search_stack + [ a:search_term ] 
        endif
    endif

    echom "results of: " . a:help_program . "..."

    call append(0, "Search results from " . a:help_program )
    call append(0, "------------------------------------------")
    call append(0, split(external_help, '\v\n'))
    let browser = <SID>get_browser()
    if browser == "curl" || browser == "wget"
        call <SID>strip_raw_html()
    endif
    call <SID>cleanup_by_context(a:context)

    call append(0, "=====================================================================")
    call append(0, "              Ctrl-]:new search Ctrl-T:back")
    call append(0, "SHORTCUT-KEYS u:up d:down n?:find next " . a:search_term . " q:quit")

    setlocal filetype=webhelp
    execute "setlocal syntax=" . b:parent_filetype . ".webhelp"
    call matchadd( "manReference", a:search_term )
    setlocal buftype=nofile nobuflisted bufhidden=wipe readonly
    setlocal noswapfile nowritebackup viminfo= nobackup noshelltemp history=0
    setlocal scrolloff=2

    normal! 3G
    execute "silent normal! /" . a:search_term  . "\<CR>zt"
    if a:context != "url"
        let @/ = a:search_term
    else
        normal! gg
    endif

    " Emulate tagstack
    nnoremap <buffer> <C-]> :call <SID>inline_help()<CR>
    nnoremap <buffer> <silent> <C-t> :call <SID>search_previous()<CR>
    " menmonic history navigation
    nnoremap <buffer> <silent> <C-k>  :call <SID>search_previous()<CR>
    nnoremap <buffer> <silent> <C-j>  :call <SID>search_next()<CR>
    " Act like less
    nnoremap <buffer> d <C-d>
    nnoremap <buffer> <Space> <C-d>
    nnoremap <buffer> u <C-u>
    nnoremap <buffer> <silent> q :bdelete<Cr>
    nnoremap <buffer> n nzt
endfunction

function s:search_previous()
    call <SID>search_seek(-1)
endfunction
function s:search_next()
    call <SID>search_seek(1)
endfunction

function s:search_seek(offset)
    let stack_size = 0
    if ! exists("b:search_stack")
        echo "no previous searches"
    else
        let stack_size = len(b:search_stack)
    endif
    if ! exists("b:search_stack_pointer")
        let b:search_stack_pointer = stack_size - 1
    endif
    if b:search_stack_pointer > stack_size
        echo "at search stack end"
    elseif b:search_stack_pointer < 0
        let b:search_stack_pointer = 0
        echo "At beginning of search stack"
    else
        let b:search_stack_pointer = b:search_stack_pointer + a:offset
        let stacked_searchword = b:search_stack[b:search_stack_pointer]
        call <SID>inline_help( stacked_searchword )
    endif
endfunction

function! s:wikipedia(search_term)
    call <SID>inline_help( a:search_term, "wiki")
endfunction

function! s:thesaurus(search_term)
    call <SID>inline_help( a:search_term, "thesaurus")
endfunction

let s:browser = ""
function s:get_browser()
    let ordered_browsers = [ 
               \  'w3m',
               \  'links',
               \  'lynx',
               \  'elinks',
               \  'curl',
               \  'wget',
               \ ]
    if len(s:browser) == 0
        for browser in ordered_browsers
            if executable( browser )
                let s:browser = browser
                break
            endif
        endfor
    endif
    return s:browser
endfunction

function! s:get_browser_syscall()
    let browser_list = {
                \ 'lynx'   : '-dump -nonumbers ',
                \ 'links'  : '-dump',
                \ 'elinks' : '--no-references -dump --no-numbering',
                \ 'w3m'    : '-dump',
                \ 'curl'   : '-q -A "Lynx" -L -s',
                \ 'wget'   : '-qO- -U "Lynx"',
                \}


    let browser = <SID>get_browser()
    return  browser . "  " . browser_list[browser]
endfunction

let s:ddg = "http://duckduckgo.com/?q="
let s:glucky ="http://www.google.com/search?sourceid=navclient&btnI=I&q="
let s:URL_mappings = {
            \"php"        :  s:ddg    . "!phpnet",
            \"css"        :  s:glucky . "site:cssdocs.org",
            \"perl"       :  s:glucky . "site:perldoc.perl.org",
            \"ansible"    :  s:glucky . "site:docs.ansible.com",
            \"javascript" :  s:ddg    . "!mdn+javascript",
            \"html"       :  s:ddg    . "!mdn+html",
            \"text"       :  s:ddg    . "!ahd",
            \"mail"       :  s:ddg    . "!ahd",
            \"make"       :  s:glucky . "site:www.gnu.org",
            \"wiki"       :  s:ddg    . "!wikipedia",
            \"thesaurus"  :  "http://www.thesaurus.com/browse/",
            \}

function! s:geturl(context, search_term)
    " convention for straight URL
    if a:context ==# "url"
        return a:search_term
    endif
    if ! has_key( s:URL_mappings, a:context )
        let url = s:ddg . "!" . a:context
    else
        let url = s:URL_mappings[ a:context ]
    endif
    let url .= "+" . a:search_term
    return url
endfunction

function! s:get_webman_syscall( context, search_term )
    let browser = <SID>get_browser()
    let browser_call = <SID>get_browser_syscall()
    let url = <SID>geturl(a:context, a:search_term)
    let prg =  browser_call .  " '" . url . "'"
    return prg
endfunction

function! s:cleanup_by_context(context)
    if a:context ==# 'php'
        silent! 1,/Report a Bug/ d
        silent! 1,/Focus search box/ d
    elseif a:context ==# 'thesaurus'
        silent! 1,/^show \[all/ d
        silent! % s/ star$//
        silent! % s/^star$//
    endif
endfunction

" HTML stipping functions
function! s:crude_lexer()
    " i.e. one tag per line
    silent! % s/\(<[^>]*>\)/\r\1\r/g
endfunction

function! s:strip_scripts()
    silent! g/<script.*>/-1;/<\/script>/+1d
endfunction

function! s:delete_tags()
    silent! g/^<[^>]*>$/d
endfunction

function! s:delete_blanks()
    silent! g/^[ ]*$/d
endfunction

function s:strip_raw_html()
    call <SID>crude_lexer()
    call <SID>strip_scripts()
    call <SID>delete_tags()
    call <SID>delete_blanks()
endfunction

function s:suggest_words(A,C,P)
    return [ expand("<cword>") ] + split( getline(".") )
endfunction

nnoremap <silent> <Plug>InlineHelp :call <SID>inline_help()<cr>
nmap <silent> KK <Plug>InlineHelp
xmap <silent> KK <Plug>InlineHelp
command! Lookup call <SID>inline_help()
command! -nargs=1 -complete=customlist,<SID>suggest_words Help call <SID>inline_help(<f-args>)
command! -nargs=1 -complete=customlist,<SID>suggest_words Wikipedia call <SID>wikipedia(<f-args>)
command! -nargs=1 -complete=customlist,<SID>suggest_words Thesaurus call <SID>thesaurus(<f-args>)

" expose raw loadhelp
function! s:format_external_help( program, keyword )
    let context = &filetype
    let command = a:program . " " . a:keyword
    call <SID>load_help(command, 'man', context)
endfunction
command! -nargs=+ ExternalHelp call <SID>format_external_help(<f-args>)

let &cpo = s:save_cpo 
unlet s:save_cpo
