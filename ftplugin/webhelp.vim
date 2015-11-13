" Act like less
nnoremap <nowait>  d <C-d>
nnoremap <Space> <C-d>
nnoremap <Space><Space> <C-d>
nnoremap u <C-u>
nnoremap <silent> q :bdelete<Cr>

" find and center search term
nnoremap n nzt

" make into a 'non' buffer
set buftype=nofile
set nobuflisted
set bufhidden=wipe
set readonly
set noswapfile
set nowritebackup
set viminfo=
set nobackup
set noshelltemp
set scrolloff=2

" navigation
nmap <silent> <C-]> <Plug>InlineHelp
nmap <silent> gf    <Plug>InlineHelp

nmap <silent> <C-t> <Plug>SearchPrevious

" menmonic history navigation
nmap <silent> <C-k> <Plug>SearchPrevious
nmap <silent> <C-j> <Plug>SearchNext
