" Author:  Eric Van Dewoestine
"
" Description: {{{
"   Minor tweaks to new vim 7 functionality allowing viewing of quickfix entry
"   in a new window.
"
" License:
"
"   Permission is hereby granted, free of charge, to any person obtaining
"   a copy of this software and associated documentation files (the
"   "Software"), to deal in the Software without restriction, including
"   without limitation the rights to use, copy, modify, merge, publish,
"   distribute, sublicense, and/or sell copies of the Software, and to
"   permit persons to whom the Software is furnished to do so, subject to
"   the following conditions:
"
"   The above copyright notice and this permission notice shall be included
"   in all copies or substantial portions of the Software.
"
"   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
"   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"
" }}}

nnoremap <buffer> <silent> dd :call <SID>Delete()<cr>
nnoremap <buffer> <silent> D :call <SID>Delete()<cr>
nnoremap <buffer> <silent> s :call <SID>Split(1)<cr>
nnoremap <buffer> <silent> S :call <SID>Split(0)<cr>

" s:Delete() {{{
if !exists('*s:Delete')
function! s:Delete ()
  let lnum = line('.')
  let cnum = col('.')
  let qf = getqflist()
  call remove(qf, lnum - 1)
  call setqflist(qf, 'r')
  call cursor(lnum, cnum)
endfunction
endif " }}}

" s:Split(close) {{{
function! s:Split (close)
  let bufnum = bufnr('%')

  let saved = &splitbelow
  set nosplitbelow
  exec "normal \<c-w>\<cr>"
  let &splitbelow = saved

  if a:close
    exec 'bd ' . bufnum
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
