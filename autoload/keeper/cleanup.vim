" setup known state
if exists('g:did_keeper_cleanup') 
      " \ || &compatible 
      " \ || version < 700}
    finish
endif
let g:did_keeper_cleanup = '1'
let s:save_cpo = &cpoptions
set compatible&vim

"# generic web page cleanup
function! keeper#cleanup#context(context) abort
    if a:context ==# 'php'
        silent! 1,/Report a Bug/ d
        silent! 1,/Focus search box/ d
        call keeper#cleanup#apostrophes()
    elseif a:context ==# 'perl'
        silent! /^Download Perl/,/T • U • X$/ d
        silent! /^Contact details/,$ d
        silent! /^Please note: Many features of this site require JavaScript./,/Google Chrome/ d
        call keeper#cleanup#apostrophes()
    elseif a:context ==# 'thesaurus'
        silent! 1,/^show \[all/ d
        silent! % s/ star$//
        silent! % s/^star$//
        silent! % s/star\>//
    endif
endfunction

" hack to balance strings for syntax hack
function! keeper#cleanup#apostrophes() abort
        silent! % s/\S\zs's\>/''s/
        silent! % s/\S\zs're\>/''re/
        silent! % s/'[.]*$//
endfunction

function! keeper#cleanup#generic() abort
    " strip a single apostrophe in a line
    " This makes syntax highlighting more robust
    silent! g/^[^']*'[^']*$/s/'//
    " clean blamk div
    silent! g/^\s*[*-+]\s*$/d
endfunction


"# HTML stipping functions
function! s:cleanup#crude_lexer() abort
    " i.e. one tag per line
    silent! % s/\(<[^>]*>\)/\r\1\r/g
endfunction

function! keeper#cleanup#strip_scripts() abort
    silent! g/<script.*>/-1;/<\/script>/+1d
endfunction

function! keeper#cleanup#delete_tags() abort
    silent! g/^<[^>]*>$/d
endfunction

function! keeper#cleanup#delete_blanks() abort
    silent! g/^[ ]*$/d
endfunction

function keeper#cleanup#strip_raw_html() call s:crude_lexer()
    call keeper#cleanup#strip_scripts()
    call keeper#cleanup#delete_tags()
    call keeper#cleanup#delete_blanks()
endfunction

"# Return vim to users choice
let &cpoptions = s:save_cpo
