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
        for browser in s:ordered_browsers
            if executable( browser )
                let s:browser = browser
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

function! keeper#browser#filetypes()
    return sort(keys(s:URL_mappings))
endfunction

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
    let l:prefix = ''
    if ( match( url, 'duckduckgo', '')  != -1 )
                \ || ( match( url, 'sourceid=navclient', '') != -1 )
        let l:prefix = '+'
    endif
    let url .= l:prefix . a:search_term
    return url
endfunction

function! keeper#browser#syscall( context, search_term ) abort
    let browser = keeper#browser#get()
    let browser_call = keeper#browser#command()
    let url = keeper#browser#make_url(a:context, a:search_term)
    let prg =  browser_call .  " '" . url . "'"
    return prg
endfunction

