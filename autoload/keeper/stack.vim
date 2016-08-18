
let s:stack = {
            \ 'stack' : [ ],
            \ 'pointer' : -1
            \ }

function! keeper#stack#push(url)
    call add(s:stack.stack, a:url)
    let s:stack.pointer += 1
    echo s:stack.stack[0]
endfunction

function! keeper#stack#down()
    if s:is_empty()
        return ''
    endif
    let s:stack.pointer -= 1
    let url = s:stack.stack[ s:stack.pointer ]
    return url
endfunction

function! s:is_empty()
    if len( s:stack.stack) == 0
        return 1
    else
        return 0
    endif
endfunction
