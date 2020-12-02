" setup known state
if exists('g:keeper_browser') 
      " \ || &compatible 
      " \ || version < 700}
    finish
endif
let g:keeper_browser = '1'
let s:save_cpo = &cpoptions
set cpoptions&vim

"echo 'main code'

let s:browser = ''

let s:ordered_browsers = [ 
            \  'w3m',
            \  'links',
            \  'lynx',
            \  'elinks',
            \  'curl',
            \  'wget',
            \ ]

let s:browser_list = {
            \ 'w3m'    : '-no-graph -4 -dump',
            \ 'links'  : '-dump',
            \ 'lynx'   : '-dump -nonumbers ',
            \ 'elinks' : '--no-references -dump --no-numbering',
            \ 'curl'   : '-q -A "Lynx" -L -s',
            \ 'wget'   : '-qO- -U "Lynx"',
            \}

function! keeper#browser#get() abort
    if len(s:browser) == 0
        for l:browser in s:ordered_browsers
            if executable( l:browser )
                let s:browser = l:browser
                break
            endif
        endfor
    endif
    return s:browser
endfunction

function! keeper#browser#set(browser, options) abort
    let s:browser = a:browser
    let s:browser_list[s:browser] = a:options
endfunction

function! keeper#browser#command() abort
    let l:browser = keeper#browser#get()
    return  l:browser . ' ' . s:browser_list[l:browser]
endfunction

function! keeper#browser#command_list() abort
    return split( keeper#browser#command(), ' ' )
    let l:browser = keeper#browser#get()
endfunction

let s:ddg = 'https://duckduckgo.com/?q='
let s:glucky ='https://www.google.com/search?sourceid=navclient&btnI=I&q='

let s:URL_mappings = {
            \'ansible'    :  s:glucky . 'site:docs.ansible.com',
            \'apache'     :  s:glucky . 'site:httpd.apache.org/docs',
            \'c'          :  s:glucky . 'site:en.cppreference.com',
            \'css'        :  s:glucky . 'site:cssdocs.org',
            \'docker'     :  s:glucky . 'site:docs.docker.com',
            \'fail2ban'   :  s:glucky . 'site:www.fail2ban.org',
            \'go'         :  s:glucky . 'site:golang.org/doc',
            \'haskell'    :  s:ddg    . '!hoogle',
            \'gitconfig'  :  s:glucky . 'site:git-scm.com',
            \'html'       :  s:ddg    . '!mdn+html',
            \'javascript' :  s:ddg    . '!mdn+javascript',
            \'jquery'     :  s:glucky . 'site:api.jquery.com',
            \'lua'        :  s:glucky . 'site:www.lua.org',
            \'lighttpd'   :  s:glucky . 'site:redmine.lighttpd.net/projects/1/wiki/Docs',
            \'mail'       :  s:ddg    . '!ahd',
            \'make'       :  s:glucky . 'site:www.gnu.org',
            \'mason'      :  s:glucky . 'site:www.masonbook.com',
            \'muttrc'     :  s:glucky . 'site:www.mutt.org/doc/manual',
            \'nagios'     :  'https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/objectdefinitions.html#',
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
            \'cheatsheet' : 'http://cheat.sh/',
            \'stackexchange' :  s:glucky    . 'site:stackexchange.com',
            \}

function! keeper#browser#register_google(filetype, site) abort
    let s:URL_mappings[a:filetype]  =  s:glucky . 'site:' . a:site
endfunction

function! keeper#browser#register_(filetype, bang) abort
    let s:URL_mappings[a:filetype]  =  s:ddg . '!' . a:bang
endfunction

function! keeper#browser#make_url(context, search_term) abort
    " convention for straight URL
    if a:context ==# 'url'
        return a:search_term
    endif
    let l:context = a:context
    if l:context =~# '[.]'
        for l:c in split(l:context, '[.]')
            if has_key( s:URL_mappings, l:c )
                let l:context = l:c
                break
            endif
        endfor
    endif
    if ! has_key( s:URL_mappings, l:context )
        let l:url = s:ddg . '!' . l:context
    else
        let l:url = s:URL_mappings[ l:context ]
    endif
    let l:prefix = ''
    if ( match( l:url, 'duckduckgo', '')  != -1 )
                \ || ( match( l:url, 'sourceid=navclient', '') != -1 )
        let l:prefix = '+'
    endif
    let l:url .= l:prefix . a:search_term
    return l:url
endfunction

function! keeper#browser#syscall( context, search_term ) abort
    let l:browser = keeper#browser#get()
    let l:browser_call = keeper#browser#command()
    let l:url = keeper#browser#make_url(a:context, a:search_term)
    let l:prg =  l:browser_call .  " '" . l:url . "'"
    return l:prg
endfunction

" Return vim to users choice
let &cpoptions = s:save_cpo

