" Author:  Eric Van Dewoestine

setlocal nolist

" make navigating help tags easier.
nnoremap <silent> <buffer> <cr> <c-]>
nnoremap <silent> <buffer> <bs> <c-t>

augroup help
  autocmd!
  " after changing a help file, update the help tags.
  autocmd BufWritePost *.txt silent! exec "helptags " . expand('%:p:h')
  autocmd BufRead ev_*.txt setlocal modifiable | setlocal noreadonly
augroup END

" vim:ft=vim:fdm=marker
