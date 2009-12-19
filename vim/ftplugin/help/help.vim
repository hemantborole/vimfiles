" Author:  Eric Van Dewoestine
"
" Some settings and convience mappings to make navigating vim help files
" easier.  Also includes an auto command which updates the help tags when
" saving a help file.

setlocal nolist

" make navigating help tags easier.
nnoremap <silent> <buffer> <cr> <c-]>
nnoremap <silent> <buffer> <bs> <c-t>

augroup help
  autocmd!
  " after changing a help file, update the help tags.
  autocmd BufWritePost *.txt silent! exec "helptags " . expand('%:p:h')
augroup END

" vim:ft=vim:fdm=marker
