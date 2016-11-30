" Act like less
nnoremap <buffer> <nowait>  d <C-d>
nnoremap <buffer> <nowait> <Space> <C-d>
nnoremap <buffer> u <C-u>
nnoremap <buffer> <silent> <nowait> q :bwipe<Cr>
nnoremap [[ :call search( '^[A-Z]', "bW", "")<cr>z<cr>
nnoremap ]] :call search( '^[A-Z]', "W", "")<cr>z<cr>

" find and center search term
nnoremap <buffer> n nzt

" make into a 'non' buffer
setlocal buftype=nofile
setlocal nobuflisted
setlocal bufhidden=wipe
setlocal readonly
setlocal noswapfile
setlocal nowritebackup
setlocal viminfo=
setlocal nobackup
setlocal noshelltemp
setlocal scrolloff=2
setlocal nomodifiable

" navigation
nmap <buffer> <silent> <C-]>      <Plug>InlineHelp
nmap <buffer> <silent> gf         <Plug>InlineHelp
nmap <buffer> <nowait> <silent> K <Plug>InlineHelp

nmap <buffer> <silent> <C-t> <Plug>SearchPrevious

" menmonic history navigation
nmap <buffer> <silent> <C-k> <Plug>SearchPrevious
nmap <buffer> <silent> <C-j> <Plug>SearchNext
