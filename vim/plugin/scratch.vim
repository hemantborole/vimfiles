" Author: Eric Van Dewoestine

" Global Variables {{{

  let g:ScratchDir = '~/.vim/scratch'

" }}}

" Commands {{{
  command -nargs=? Scratch :call <SID>Scratch(<q-args>)
" }}}

" s:Scratch(ft) {{{
" open a new window with the same filetype as the current window or use the
" supplied arg.
function! s:Scratch(ft)
  let ft = len(a:ft) ? a:ft : &ft
  if ft == ''
    let ft = 'txt'
  endif

  let name = '[Scratch (' . ft . ')]'
  let escaped = '[[]Scratch (' . ft . ')[]]'
  if bufwinnr(escaped) != -1
    let index = 1
    while bufwinnr(escaped) != -1
      let name = '[Scratch_' . index . ' (' . ft . ')]'
      let escaped = '[[]Scratch_' . index . ' (' . ft . ')[]]'
      let index += 1
    endwhile
  endif

  silent exec 'belowright 10split ' . escape(name, ' ')
  let &ft = ft
  setlocal winfixheight
  setlocal noswapfile
  setlocal nobuflisted
  setlocal buftype=nofile
  setlocal bufhidden=delete

  augroup scratch
    autocmd BufWinLeave <buffer> call s:SaveScratch()
  augroup END

  command -buffer -nargs=0 ScratchPrevious :call <SID>LoadScratch()
endfunction " }}}

" s:SaveScratch() {{{
function! s:SaveScratch()
  let dir = expand(g:ScratchDir)
  if !isdirectory(dir)
    call mkdir(dir)
  endif

  call writefile(getline(1, line('$')), dir . '/' . &ft)
endfunction " }}}

" s:LoadScratch() {{{
function! s:LoadScratch()
  let file = expand(g:ScratchDir) . '/' . &ft
  if filereadable(file)
    1,$delete _
    call append(1, readfile(file))
    1,1delete _
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
