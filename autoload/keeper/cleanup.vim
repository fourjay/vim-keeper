" setup known state
if exists('g:did_keeper_cleanup') 
      " \ || &compatible 
      " \ || version < 700}
    finish
endif
let g:did_keeper_cleanup = '1'
let s:save_cpo = &cpoptions
set compatible&vim

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

function! s:syntax_adjustments() abort
    if b:parent_filetype ==# 'perl'
        syntax clear perlStringUnexpanded
    endif
endfunction

function! keeper#cleanup#generic() abort
    " strip a single apostrophe in a line
    " This makes syntax highlighting more robust
    silent! g/^[^']*'[^']*$/s/'//
    " clean blamk div
    silent! g/^\s*[*-+]\s*$/d
endfunction


" HTML stipping functions
function! s:crude_lexer() abort
    " i.e. one tag per line
    normal! silent! % s/\(<[^>]*>\)/\r\1\r/g
endfunction

function! s:strip_scripts() abort
    normal! silent! g/<script.*>/-1;/<\/script>/+1d
endfunction

function! s:delete_tags() abort
    normal! silent! g/^<[^>]*>$/d
endfunction

function! s:delete_blanks() abort
    normal! silent! g/^[ ]*$/d
endfunction

" Return vim to users choice
let &cpoptions = s:save_cpo
