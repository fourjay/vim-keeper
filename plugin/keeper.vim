if exists('g:loaded_keeper')
    finish
endif
let g:loaded_keeper = 1

let s:save_cpo = &cpo
set cpo&vim

let s:base_path = expand('<sfile>:p:h')
function! s:inline_help(...)
    " Account for the special case non-external keywordprg
    if &keywordprg ==# ':help' && &filetype ==# 'vim'
        execute 'normal! K'
        return
    endif

    let l:keyword = ''
    " if we've passed in a l:keyword, we want a random search
    " Else look at the current word (AKA "like K")
    if  a:0
        let l:keyword = substitute( a:1, ' ', '+', 'g' )
    else
        let l:keyword = s:get_searchword()  " expand('<cword>')
    endif

    let l:context = 'wiki'
    if a:0 == 2
        let l:context = a:2
    elseif &filetype ==# 'webhelp'
        " allow recursive lookup in the help output
        let l:context=b:parent_filetype
    " If we don't have a better option
    elseif &filetype ==# ''
        let l:context = 'wiki'
    " Allow corcing l:context
    elseif a:0 > 1
        let l:context = a:2
    else
        let l:context = s:get_cword_context()
    endif

    let l:url = s:extract_url(getline('.'))
    if l:url !=# ''
        let l:context = 'url'
    endif

    let l:help_program = keeper#browser#syscall( l:context, l:keyword )
    call s:load_help(l:help_program, l:keyword, l:context)
endfunction

function! s:get_searchword()
    let l:cline = getline('.')
    let l:url = s:extract_url(l:cline)
    if l:url !=# ''
        return l:url
    endif
    let l:selected = ''
    if visualmode() ==# 'v'
        let l:selected = s:get_visual()
        let l:selected = substitute( l:selected, ' ', '+', 'g')
        return l:selected
    endif
    return expand("\<cword>")
endfunction

function! s:get_visual()
    let l:saved_s_register = @s
    normal! gv"sy
    let l:selected = @s
    let @s = l:saved_s_register
    return l:selected
endfunction

function! s:extract_url(cline)
    " yes, this is incomplete, but in practice...
    let l:TLDs = [ 'com', 'net', 'org' ]
    " matchstr (at least in my environment) doesn't uork with match alternate
    for tld in l:TLDs
        let l:link_pattern = '[^ ][^ ]*[.]' . l:tld . '[:\/][/]*[^ ][^ ]*' 
        " echom "l:link_pattern is " . l:link_pattern
        let url = matchstr( a:cline, l:link_pattern)
        " echom "with l:tld " . l:tld . "url is " . url
        if l:url !=# ''
            return l:url
        endif
    endfor
    return ''
endfunction

function! s:get_cword_context()
    let l:keyword_syngrp = synIDattr(synID(line('.'), col('.'), 0), 'name')
    if l:keyword_syngrp =~# 'SQL'
        return 'sql'
    elseif l:keyword_syngrp =~? 'javascript'
        return 'javascript'
    endif
    if &filetype !=# ''
        return &filetype
    endif

endfunction

let s:browser_line_count = 0
let s:timer = ''
function! s:out_cb(jobid, msg)
    let s:browser_line_count += 1
    if s:browser_line_count == 10
        call s:alert('found results')
        let s:timer = timer_start( 100, 
                    \ function( 's:timer_cleanup_webpage' ),
                    \ {'repeat' : 1 } )
        " call s:display_help_window()
    endif
    " echom "got OutHandler " . a:msg
endfunction
function! s:exit_handler(jobid, status)
    call s:alert('closing channel')
    let s:browser_line_count = 0
endfunction

function s:timer_cleanup_webpage(timer)
    call s:cleanup_webpage()
endfunction

let s:context = ''
function s:load_help( help_program, search_term, context )
    if s:is_local_help( a:help_program )
        " Try local help first
        let l:local_help_results = system( a:help_program )
        if v:shell_error == 0 " || l:local_help_results !=# ''
            " if things look good then print
            call Render_help( a:help_program, a:search_term, a:context, l:local_help_results )
            return
        else
            " else recall with web
            call s:inline_help(a:search_term )
        return
    endif

    endif
    if exists('*job_start')
        call s:alert('running [' . a:help_program . ']' )
        call s:reset_window()
        let l:job = substitute(a:help_program, "['\"]", '', 'g')
        let l:job_array = split( l:job, ' ' )
        let l:job = job_start(
                    \ l:job_array,
                    \ {
                    \   'out_io'         :  'buffer',
                    \   'out_name'       :  s:helpbufname,
                    \   'out_cb'         :  function('s:out_cb'),
                    \   'out_timeout'    :  50,
                    \   'out_modifiable' :  0,
                    \   'exit_cb'        :  function('s:exit_handler')
                    \ })
        call setbufvar( s:helpbufname, 'parent_filetype', a:context )
        call setbufvar( s:helpbufname, 'search_term', a:search_term )
        return
    endif
    if exists(':VimProcBang')
        let l:external_help = vimproc#system( a:help_program )
    endif
    call Render_help( a:help_program, a:search_term, a:context, l:external_help )
endfunction

function! s:is_local_help(help_program)
    return a:help_program !~# 'http'
endfunction

function! s:reset_window()
    let l:winnr = bufwinnr(s:helpbufname)
    let current_buffer = bufwinnr('%')
    if l:winnr < 1
        badd s:helpbufname
    else
        execute l:winnr . 'wincmd w'
        setlocal modifiable
        setlocal noreadonly
        silent normal! ggdG
        wincmd w 
        only
    endif
endfunction

function! s:display_help_window()
    let l:large_height = &lines * 2 / 3
    let l:winnr = bufwinnr(s:helpbufname)
    if l:winnr < 1
        silent execute l:large_height . 'split ' . s:helpbufname
    else
        execute l:winnr . 'wincmd w'
    endif
    if &filetype !=# b:parent_filetype
        execute ':setlocal filetype=' . b:parent_filetype . '.webhelp'
    endif
endfunction

function s:clean_filetype( filetype )
    return substitute( a:filetype, '\..*', '', '')
endfunction

function! s:cleanup_webpage()
    call s:alert('showing results')
    call s:display_help_window()
    set modifiable
    set noreadonly
    call keeper#stack#push( b:search_term )
    " let browser = s:get_browser()
    let l:browser = keeper#browser#get()
    if l:browser ==# 'curl' || l:browser ==# 'wget'
        call s:strip_raw_html()
    endif
    call s:cleanup_by_context(s:clean_filetype( b:parent_filetype ) )
    call s:generic_cleanup()

    let l:simple_search_term = substitute( b:search_term, '+.*', '', '' )

    call append(0, '|  RESULTS for: ' . l:simple_search_term . ' |   QUICKTIPS space to scroll, q to quit    ')

    " execute 'setlocal filetype=' . b:parent_filetype . '.webhelp'
    call matchadd( 'Delimiter', b:search_term )
    if &filetype !=# b:parent_filetype
        execute ':setlocal filetype=' . b:parent_filetype . '.webhelp'
    endif

    normal! 3G
    " call search( simple_search_term, 'w')
    normal! zt
    let @/ = b:search_term
    if b:parent_filetype !=# 'url'
        let @/ = b:search_term
    else
        normal! gg
    endif
    call search(b:search_term, '')
    setlocal nomodifiable
    setlocal readonly
    setlocal bufhidden=hide
endfunction

let s:helpbufname = '__HELP__'
function! s:create_help(context)
    let l:large_height = &lines * 2 / 3
    let l:winnr = bufwinnr(s:helpbufname)
    if l:winnr < 1
        silent execute l:large_height . 'split ' . s:helpbufname
    else
        execute l:winnr . 'wincmd w'
    endif
    set modifiable
    set noreadonly
    normal! ggdG
    " if !  exists( 'b:parent_filetype' )
    "     let b:parent_filetype = a:context
    " endif
endfunction

function! Render_help( help_program, search_term, context, results )
    " open split with reasonable height
    " let helpbufname = '__HELP__'
    let l:large_height = &lines * 2 / 3
    " reuse buffer as available
    let l:winnr = bufwinnr(s:helpbufname)
    if l:winnr > 0
        execute l:winnr . 'wincmd w'
    else
        silent execute l:large_height . 'split ' . s:helpbufname
    endif
    " If we are re-using, then temporarily make writeable warning
    setlocal noreadonly
    setlocal modifiable
    " set up clean buffer
    normal! ggdG
    if !  exists( 'b:parent_filetype' )
        let b:parent_filetype = a:context
    endif

    call keeper#stack#push( a:search_term )

    echom 'results of: ' . a:help_program . '...'

    let l:simple_search_term = substitute( a:search_term, '+.*', '', '' )
    call append(0, 'Search results from ' . a:help_program )
    call append(0, '------------------------------------------')
    call append(0, split(a:results, '\v\n'))
    " let browser = s:get_browser()
    let l:browser = keeper#browser#get()
    if l:browser ==# 'curl' || l:browser ==# 'wget'
        call s:strip_raw_html()
    endif
    call s:cleanup_by_context(a:context)
    call s:generic_cleanup()

    call append(0, '=====================================================================')
    call append(0, '              Ctrl-]:new search Ctrl-T:back')
    call append(0, 'SHORTCUT-KEYS u:up d:down n?:find next ' . l:simple_search_term . ' q:quit')

    execute 'setlocal filetype=' . b:parent_filetype . '.webhelp'
    call matchadd( 'Delimiter', l:simple_search_term )

    normal! 3G
    call search( l:simple_search_term, 'w')
    normal! zt
    if a:context !=# 'url'
        let @/ = a:search_term
    else
        normal! gg
    endif
endfunction

function! s:search_seek(direction)
    if a:direction ==# 'down'
        if keeper#stack#is_bottom()
            echoerr 'at first search'
        else
            call s:inline_help( keeper#stack#down() )
        endif
    else
        if keeper#stack#is_top()
            echoerr 'at last search'
        else
            call s:inline_help( keeper#stack#up() )
        endif
    endif
endfunction

nmap <silent> <Plug>SearchPrevious :call <SID>search_seek('down')<cr>
nmap <silent> <Plug>SearchNext :call <SID>search_seek('up')<cr>

function! s:wikipedia(...)
    let l:search_term = join( a:000, '+' )
    call s:inline_help( l:search_term, 'wiki')
endfunction

function! s:search_multiwords(...)
    let l:search_term = join( a:000, '+' )
    if len(l:search_term) == 0
        let l:search_term = s:get_visual_selection()
    endif
    if len(l:search_term) == 0
        let l:cword = expand('<cword>')
        call s:inline_help( l:cword )
    else
        call s:inline_help( l:search_term )
    endif
endfunction

function! s:get_visual_selection()
    let l:saved_a = @a
    let l:saved_pos = getcurpos()
    " This moves cursor position
    normal! gv"ay
    call setpos( '.', l:saved_pos )
    let l:found = @a
    let @a = l:saved_a
    " don't use a non-recent visual selection.
    if exists( 'b:_last_visual_search' )
        if b:_last_visual_search =~ l:found
            let l:found = ''
        endif
    endif
    if len(l:found) > 0
        let b:_last_visual_search = l:found
    endif
    let l:found = substitute(l:found, ' [ ]*', '+', '')
    return l:found
endfunction

function! s:thesaurus(search_term)
    call s:inline_help( a:search_term, 'thesaurus')
endfunction

function! s:stackexchange(search_term)
    let l:search_filetype = &filetype
    if exists( 'b:parent_filetype' )
        let l:search_filetype = b:parent_filetype
    endif
    call s:inline_help(a:search_term . '+' . l:search_filetype , 'stackexchange', l:search_filetype )
endfunction

function! KeeperURLRegisterGoogle(filetype, site)
    call keeper#browser#register_google(a:filetype, a:site)
endfunction

function! KeeperURLRegisterDDG(filetype, bang)
    call keeper#browser#register_(a:filetype, a:bang)
endfunction

function! s:cleanup_by_context(context)
    if a:context ==# 'php'
        silent! 1,/Report a Bug/ d
        silent! 1,/Focus search box/ d
        call s:cleanup_apostrophes()
    elseif a:context ==# 'perl'
        silent! /^Download Perl/,/T • U • X$/ d
        silent! /^Contact details/,$ d
        silent! /^Please note: Many features of this site require JavaScript./,/Google Chrome/ d
        call s:cleanup_apostrophes()
    elseif a:context ==# 'thesaurus'
        silent! 1,/^show \[all/ d
        normal! silent! % s/ star$//
        normal! silent! % s/^star$//
        normal! silent! % s/star\>//
    endif
endfunction

function! s:cleanup_apostrophes()
        normal! silent! % s/\<'s\>/''s/
        normal! silent! % s/\<'re\>/''re/
        normal! silent! % s/'[.]*$//
endfunction

function! s:generic_cleanup()
    " strip a single apostrophe in a line
    " This makes syntax highlighting more robust
    normal! silent! g/^[^']*'[^']*$/s/'//
    " clean blamk div
    normal! silent! g/^\s*[*-+]\s*$/d
endfunction


" HTML stipping functions
function! s:crude_lexer()
    " i.e. one tag per line
    normal! silent! % s/\(<[^>]*>\)/\r\1\r/g
endfunction

function! s:strip_scripts()
    normal! silent! g/<script.*>/-1;/<\/script>/+1d
endfunction

function! s:delete_tags()
    normal! silent! g/^<[^>]*>$/d
endfunction

function! s:delete_blanks()
    normal! silent! g/^[ ]*$/d
endfunction

function s:strip_raw_html()
    call s:crude_lexer()
    call s:strip_scripts()
    call s:delete_tags()
    call s:delete_blanks()
endfunction

function! s:alert(message)
    echohl StatusLine
    echom a:message
    echohl None
endfunction

function s:suggest_words(A,C,P)
    return [ expand("<cword>") ] + split( getline(".") )
endfunction

" nmap <silent> <Plug>InlineHelp :call <SID>inline_help()<cr>
map <silent> <Plug>InlineHelp :call <SID>search_multiwords()<cr>
nmap <silent> KK <Plug>InlineHelp
xmap <silent> KK <Plug>InlineHelp
command! Lookup call <SID>inline_help()
command! -nargs=* -complete=customlist,<SID>suggest_words Help call <SID>search_multiwords(<f-args>)
command! -nargs=* -complete=customlist,<SID>suggest_words Wikipedia call <SID>wikipedia(<f-args>)
command! -nargs=1 -complete=customlist,<SID>suggest_words Thesaurus call <SID>thesaurus(<f-args>)
command! -nargs=1 -complete=customlist,<SID>suggest_words Stackexchange call <SID>stackexchange(<f-args>)

let s:man_programs = {
            \   'sh'      : 'man',
            \   'perl'    : 'perldoc',
            \   'python'  : 'pydoc',
            \   'ansible' : 'ansible-doc',
            \ }
function! s:suggest_manprograms(...)
    " return the cword if there's alread a man program chosen
    if a:2 =~ '\v^Xhelp \w+ '
        return expand("<cword>") . "\n"
    endif
    let l:list = ""
    let l:ft_match = get( s:man_programs, &filetype )
    if &keywordprg != ""
        let l:ft_match = &keywordprg
    endif
    if l:ft_match != ''
        if executable( l:ft_match )
            let l:list .= l:ft_match . "\n"
        endif
    endif
    for ft_candidate in keys(s:man_programs)
        let candidate = s:man_programs[ ft_candidate ]
        if executable( candidate )
            if l:ft_match != candidate
                let l:list .= candidate . "\n"
            endif
        endif
    endfor
    return l:list
endfunction

" expose raw loadhelp
function! s:format_external_help( ... )
    let l:context = &filetype
    let l:command = a:1
    if a:0 > 1
        if a:2 =~# '^-'
            let l:command .= ' ' . a:2
            let l:keyword = a:3
        else
            let l:keyword = a:2
        endif
    else
        let l:keyword = expand('<cword>')
    endif
    call s:load_help(l:command . ' ' . l:keyword , l:keyword, l:context)
endfunction
command! -nargs=+ -complete=custom,<SID>suggest_manprograms XHelp call <SID>format_external_help(<f-args>)

let &cpo = s:save_cpo 
unlet s:save_cpo
