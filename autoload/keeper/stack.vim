
function! keeper#stack#push(url) abort
    call s:init_stack()
    call add(b:stack.stack, a:url)
    let b:stack.pointer += 1
endfunction

function! keeper#stack#down() abort
    call s:init_stack()
    if s:is_empty()
        return ''
    endif
    if b:stack.pointer > 0
        let b:stack.pointer -= 1
    endif
    let url = b:stack.stack[ b:stack.pointer ]
    return url
endfunction

function! keeper#stack#up() abort
    call s:init_stack()
    if s:is_empty()
        return ''
    endif
    if b:stack.pointer < len(b:stack.stack) - 1
        if b:stack.pointer >= 0
            let b:stack.pointer += 1
        endif
    endif
    let url = b:stack.stack[ b:stack.pointer ]
    return url
endfunction

function! keeper#stack#is_top() abort
    if b:stack.pointer == len(b:stack.stack) - 1
        return 1
    endif
    return 0
endfunction

function! keeper#stack#is_bottom() abort
    if b:stack.pointer == 0
        return 1
    endif
    return 0
endfunction

function! keeper#stack#clear() abort
    unlet b:stack
    call s:init_stack()
endfunction

function! s:is_empty()
    if len( b:stack.stack) == 0
        return 1
    else
        return 0
    endif
endfunction

function! s:init_stack() abort
    if ! exists('b:stack')
        let b:stack = {
            \ 'stack' : [ ],
            \ 'pointer' : -1
            \ }
    endif
endfunction
