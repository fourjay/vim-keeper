" setup known state
if exists('g:did_keeper_util') 
      " \ || &compatible 
      " \ || version < 700}
    finish
endif
let g:did_keeper_util = '1'
let s:save_cpo = &cpoptions
set compatible&vim

let s:man_programs = {
            \   'sh'      : 'man',
            \   'perl'    : 'perldoc',
            \   'php'     : 'pman',
            \   'python'  : 'pydoc',
            \   'ansible' : 'ansible-doc',
            \ }

function! keeper#util#suggest_manprograms(...) abort
    " return the cword if there's alread a man program chosen
    if a:2 =~? '\v^Xhelp \w+ '
        return expand('<cword>') . "\n"
    endif
    let l:list = ''
    let l:ft_match = get( s:man_programs, &filetype )
    if ! empty(&keywordprg)
        let l:ft_match = &keywordprg
    endif
    if ! empty(l:ft_match)
        if executable( l:ft_match )
            let l:list .= l:ft_match . "\n"
            return l:list
        endif
    endif
    for l:ft_candidate in keys(s:man_programs)
        let l:candidate = s:man_programs[ l:ft_candidate ]
        if executable( l:candidate )
            if l:ft_match != l:candidate
                let l:list .= l:candidate . "\n"
            endif
        endif
    endfor
    return l:list
endfunction


" Return vim to users choice
let &cpoptions = s:save_cpo
