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
        execute 'normal K'
        return
    endif

    let keyword = ''
    " if we've passed in a keyword, we want a random search
    " Else look at the current word (AKA "like K")
    if  a:0
        let keyword = substitute( a:1, ' ', '+', 'g' )
    else
        let keyword = s:get_searchword()  " expand('<cword>')
    endif

    let context = 'wiki'
    if a:0 == 2
        let context = a:2
    elseif &filetype ==# 'webhelp'
        " allow recursive lookup in the help output
        let context=b:parent_filetype
    " If we don't have a better option
    elseif &filetype ==# ''
        let context = 'wiki'
    " Allow corcing context
    elseif a:0 > 1
        let context = a:2
    else
        let context = s:get_cword_context()
    endif

    let url = s:extract_url(getline('.'))
    if url !=# ''
        let context = 'url'
    endif
    let help_program = s:get_webman_syscall( context, keyword )

    call s:load_help(help_program, keyword, context)
endfunction

function! s:get_searchword()
    let cline = getline('.')
    let url = s:extract_url(cline)
    if url !=# ''
        return url
    endif
    let selected = ''
    if visualmode() ==# 'v'
        let selected = s:get_visual()
        let selected = substitute( selected, ' ', '+', 'g')
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
        let link_pattern = '[^ ][^ ]*[.]' . tld . '[:\/][/]*[^ ][^ ]*' 
        " echom "link_pattern is " . link_pattern
        let url = matchstr( a:cline, link_pattern)
        " echom "with tld " . tld . "url is " . url
        if url !=# ''
            return url
        endif
    endfor
    return ''
endfunction

function! s:get_cword_context()
    let keyword_syngrp = synIDattr(synID(line('.'), col('.'), 0), 'name')
    if keyword_syngrp =~# 'SQL'
        return 'sql'
    elseif keyword_syngrp =~? 'javascript'
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
        echohl StatusLine | echom  'found results' | echohl None
        let s:timer = timer_start( 100, 
                    \ function( 's:timer_cleanup_webpage' ),
                    \ {'repeat' : 1 } )
        " call s:display_help_window()
    endif
    " echom "got OutHandler " . a:msg
endfunction
function! s:exit_handler(jobid, status)
    echohl StatusLine | echom 'closing channel' | echohl None
    let s:browser_line_count = 0
    " call s:cleanup_webpage()
endfunction

function s:timer_cleanup_webpage(timer)
    call s:cleanup_webpage()
endfunction

let s:context = ''
function s:load_help( help_program, search_term, context )
    " let s:context = a:context
    " let parent_filetype = a:context
    " echom "searching on " . a:search_term . "..."
    " execute and load the output in a buffer
    " let external_help = system(  a:help_program . " " . a:search_term )
    " echom "help_program is " . a:help_program
    if exists('*job_start')
        echohl StatusLine | echom "running [" . a:help_program . ']' | echohl None
        " split s:helpbufname
        " call s:create_help(a:context)
        call s:reset_window()
        " sleep 1
        let job = substitute(a:help_program, "['\"]", '', 'g')
        let job_array = split( job, ' ' )
        " echo job_array
        " return
        let job = job_start(
                    \ job_array,
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
        let external_help = vimproc#system( a:help_program )
    endif
    " retry with web if local program errors
    if v:shell_error != 0 && a:help_program !~# 'http'
        call s:inline_help(a:search_term )
        return
    endif
    call Render_help( a:help_program, a:search_term, a:context, external_help )
endfunction

function! s:reset_window()
    let winnr = bufwinnr(s:helpbufname)
    let current_buffer = bufwinnr('%')
    if winnr < 1
        badd s:helpbufname
    else
        execute winnr . 'wincmd w'
        setlocal modifiable
        setlocal noreadonly
        silent normal! ggdG
        wincmd w 
        only
    endif
endfunction

function! s:display_help_window()
    let large_height = &lines * 2 / 3
    let winnr = bufwinnr(s:helpbufname)
    if winnr < 1
        silent execute large_height . 'split ' . s:helpbufname
    else
        execute winnr . 'wincmd w'
    endif
    if &filetype !=# b:parent_filetype
        execute ':setlocal filetype=' . b:parent_filetype . '.webhelp'
    endif
endfunction

function s:clean_filetype( filetype )
    return substitute( a:filetype, '\..*', '', '')
endfunction

function! s:cleanup_webpage()
    echohl StatusLine | echom 'showing results' | echohl None
    call s:display_help_window()
    set modifiable
    set noreadonly
    let browser = s:get_browser()
    if browser ==# 'curl' || browser ==# 'wget'
        call s:strip_raw_html()
    endif
    call s:cleanup_by_context(s:clean_filetype( b:parent_filetype ) )
    call s:generic_cleanup()

    let simple_search_term = substitute( b:search_term, '+.*', '', '' )

    " call append(0, '|              Ctrl-]:new search Ctrl-T:back')
    " call append(0, '|  SHORTCUT-KEYS u:up d:down n?:find next ' . simple_search_term . ' q:quit')
    call append(0, '|  RESULTS for: ' . simple_search_term . ' |   QUICKTIPS space to scroll, q to quit    ')

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
    let large_height = &lines * 2 / 3
    let winnr = bufwinnr(s:helpbufname)
    if winnr < 1
        silent execute large_height . 'split ' . s:helpbufname
    else
        execute winnr . 'wincmd w'
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
    let large_height = &lines * 2 / 3
    " reuse buffer as available
    let winnr = bufwinnr(s:helpbufname)
    if winnr > 0
        execute winnr . 'wincmd w'
    else
        silent execute large_height . 'split ' . s:helpbufname
    endif
    " If we are re-using, then temporarily make writeable warning
    setlocal noreadonly
    setlocal modifiable
    " set up clean buffer
    normal! ggdG
    if !  exists( 'b:parent_filetype' )
        let b:parent_filetype = a:context
    endif

    " Track previous searches for back
    if ! exists( 'b:search_stack' )
        let b:search_stack = [ a:search_term ]
    elseif exists ('b:search_stack_pointer')
        " don't add search term to stack
        if b:search_stack[ b:search_stack_pointer ] !=# a:search_term
            let  b:search_stack  = b:search_stack + [ a:search_term ] 
        endif
    endif

    echom 'results of: ' . a:help_program . '...'

    let simple_search_term = substitute( a:search_term, '+.*', '', '' )
    call append(0, 'Search results from ' . a:help_program )
    call append(0, '------------------------------------------')
    call append(0, split(a:results, '\v\n'))
    let browser = s:get_browser()
    if browser ==# 'curl' || browser ==# 'wget'
        call s:strip_raw_html()
    endif
    call s:cleanup_by_context(a:context)
    call s:generic_cleanup()

    call append(0, '=====================================================================')
    call append(0, '              Ctrl-]:new search Ctrl-T:back')
    call append(0, 'SHORTCUT-KEYS u:up d:down n?:find next ' . simple_search_term . ' q:quit')

    execute 'setlocal filetype=' . b:parent_filetype . '.webhelp'
    call matchadd( 'Delimiter', simple_search_term )

    normal! 3G
    call search( simple_search_term, 'w')
    normal! zt
    if a:context != 'url'
        let @/ = a:search_term
    else
        normal! gg
    endif
endfunction

function s:search_seek(offset)
    let stack_size = 0
    if ! exists('b:search_stack')
        echo 'no previous searches'
    else
        let stack_size = len(b:search_stack)
    endif
    if ! exists('b:search_stack_pointer')
        let b:search_stack_pointer = stack_size - 1
    endif
    if b:search_stack_pointer > stack_size
        echo 'at search stack end'
    elseif b:search_stack_pointer < 0
        let b:search_stack_pointer = 0
        echo 'At beginning of search stack'
    else
        let b:search_stack_pointer = b:search_stack_pointer + a:offset
        let stacked_searchword = b:search_stack[b:search_stack_pointer]
        call s:inline_help( stacked_searchword )
    endif
endfunction

nnoremap <silent> <Plug>SearchPrevious :call <SID>search_seek(-1)<cr>
nnoremap <silent> <Plug>SearchNext :call <SID>search_seek()<cr>

function! s:wikipedia(...)
    let search_term = join( a:000, '+' )
    call s:inline_help( search_term, 'wiki')
endfunction

function! s:search_multiwords(...)
    let search_term = join( a:000, '+' )
    if len(search_term) == 0
        let search_term = s:get_visual_selection()
    endif
    if len(search_term) == 0
        let cword = expand('<cword>')
        call s:inline_help( cword )
    else
        call s:inline_help( search_term )
    endif
endfunction

function! s:get_visual_selection()
    let saved_a = @a
    let saved_pos = getcurpos()
    " This moves cursor position
    normal! gv"ay
    call setpos( '.', saved_pos )
    let found = @a
    let @a = saved_a
    " don't use a non-recent visual selection.
    if exists( 'b:_last_visual_search' )
        if b:_last_visual_search =~ found
            let found = ''
        endif
    endif
    if len(found) > 0
        let b:_last_visual_search = found
    endif
    let found = substitute(found, ' [ ]*', '+', '')
    return found
endfunction

function! s:thesaurus(search_term)
    call s:inline_help( a:search_term, 'thesaurus')
endfunction

function! s:stackexchange(search_term)
    let search_filetype = &filetype
    if exists( 'b:parent_filetype' )
        let search_filetype = b:parent_filetype
    endif
    call s:inline_help(a:search_term . '+' . search_filetype , 'stackexchange', search_filetype )
endfunction

let s:browser = ''
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
                \ 'w3m'    : '-S -no-graph -4 -dump',
                \ 'curl'   : '-q -A "Lynx" -L -s',
                \ 'wget'   : '-qO- -U "Lynx"',
                \}


    let browser = s:get_browser()
    return  browser . ' ' . browser_list[browser]
endfunction

let s:ddg = 'http://duckduckgo.com/?q='
let s:glucky ='http://www.google.com/search?sourceid=navclient&btnI=I&q='
let s:URL_mappings = {
            \'ansible'    :  s:glucky . 'site:docs.ansible.com',
            \'apache'     :  s:glucky . 'site:httpd.apache.org/docs',
            \'c'          :  s:glucky . 'site:en.cppreference.com',
            \'css'        :  s:glucky . 'site:cssdocs.org',
            \'docker'     :  s:glucky . 'site:docs.docker.com',
            \'fail2ban'   :  s:glucky . 'site:www.fail2ban.org',
            \'go'         :  s:glucky . 'site:golang.org/doc',
            \'haskell'    :  s:ddg    . '!hoogle',
            \'html'       :  s:ddg    . '!mdn+html',
            \'javascript' :  s:ddg    . '!mdn+javascript',
            \'jquery'     :  s:glucky . 'site:api.jquery.com',
            \'lua'        :  s:glucky . 'site:www.lua.org',
            \'lighttpd'   :  s:glucky . 'site:redmine.lighttpd.net/projects/1/wiki/Docs',
            \'mail'       :  s:ddg    . '!ahd',
            \'make'       :  s:glucky . 'site:www.gnu.org',
            \'mason'      :  s:glucky . 'site:www.masonbook.com',
            \'muttrc'     :  s:glucky . 'site:www.mutt.org/doc/manual',
            \'nginx'      :  s:glucky . 'site:nginx.org/en/docs/',
            \'perl'       :  s:glucky . 'site:perldoc.perl.org',
            \'pfmain'     :  s:glucky . 'site:www.postfix.org',
            \'php'        :  'http://php.net/manual-lookup.php?scope=quickref&pattern=',
            \'python'     :  s:glucky . 'site:docs.python.org',
            \'ruby'       :  s:glucky . 'site:ruby-doc.org',
            \'sh'         :  s:glucky . 'site:www.gnu.org',
            \'text'       :  s:ddg    . '!ahd',
            \'thesaurus'  :  'http://www.thesaurus.com/browse/',
            \'wiki'       :  s:ddg    . '!wikipedia',
            \'stackexchange'  :  s:glucky    . 'site:stackexchange.com',
            \}

function! KeeperURLRegisterGoogle(filetype, site)
    let s:URL_mappings[a:filetype]  =  s:glucky . 'site:' . a:site
endfunction

function! KeeperURLRegisterDDG(filetype, bang)
    let s:URL_mappings[a:filetype]  =  s:ddg . '!' . a:bang
endfunction

function! s:geturl(context, search_term)
    " convention for straight URL
    if a:context ==# 'url'
        return a:search_term
    endif
    let l:context = a:context
    if l:context =~# '[.]'
        for c in split(l:context, '[.]')
            if has_key( s:URL_mappings, c )
                let l:context = c
                break
            endif
        endfor
    endif
    if ! has_key( s:URL_mappings, l:context )
        let url = s:ddg . '!' . l:context
    else
        let url = s:URL_mappings[ l:context ]
    endif
    let url .= '+' . a:search_term
    return url
endfunction

function! s:get_webman_syscall( context, search_term )
    let browser = s:get_browser()
    let browser_call = s:get_browser_syscall()
    let url = s:geturl(a:context, a:search_term)
    let prg =  browser_call .  " '" . url . "'"
    return prg
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
        silent! % s/ star$//
        silent! % s/^star$//
        silent! % s/star\>//
    endif
endfunction

function! s:cleanup_apostrophes()
        silent! % s/\<'s\>/''s/
        silent! % s/\<'re\>/''re/
        silent! % s/'[.]*$//
endfunction

function! s:generic_cleanup()
    " strip a single apostrophe in a line
    " This makes syntax highlighting more robust
    silent! g/^[^']*'[^']*$/s/'//
    " clean blamk div
    silent! g/^\s*[*-+]\s*$/d
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
    call s:crude_lexer()
    call s:strip_scripts()
    call s:delete_tags()
    call s:delete_blanks()
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
            \   "sh"      : "man",
            \   "perl"    : "perldoc",
            \   "python"  : "pydoc",
            \   "ansible" : "ansible-doc",
            \ }
function! s:suggest_manprograms(...)
    " return the cword if there's alread a man program chosen
    if a:2 =~ '\v^Xhelp \w+ '
        return expand("<cword>") . "\n"
    endif
    let list = ""
    let ft_match = get( s:man_programs, &filetype )
    if &keywordprg != ""
        let ft_match = &keywordprg
    endif
    if ft_match != ''
        if executable( ft_match )
            let list .= ft_match . "\n"
        endif
    endif
    for ft_candidate in keys(s:man_programs)
        let candidate = s:man_programs[ ft_candidate ]
        if executable( candidate )
            if ft_match != candidate
                let list .= candidate . "\n"
            endif
        endif
    endfor
    return list
endfunction

" expose raw loadhelp
function! s:format_external_help( ... )
    let context = &filetype
    let command = a:1
    if a:0 > 1
        let l:keyword = a:2
    else
        let l:keyword = expand('<cword>')
    endif
    call s:load_help(command . ' ' . l:keyword , l:keyword, context)
endfunction
command! -nargs=+ -complete=custom,<SID>suggest_manprograms XHelp call <SID>format_external_help(<f-args>)

let &cpo = s:save_cpo 
unlet s:save_cpo
