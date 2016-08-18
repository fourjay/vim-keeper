
function! keeper#stack#push(url)
    call s:init_stack()
    call add(b:stack.stack, a:url)
    let b:stack.pointer += 1
endfunction

function! keeper#stack#down()
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

function! keeper#stack#up()
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

function! keeper#stack#clear()
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

function! s:init_stack()
    if ! exists('b:stack')
        let b:stack = {
            \ 'stack' : [ ],
            \ 'pointer' : -1
            \ }
    endif
endfunction
