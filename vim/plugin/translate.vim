" Author: Eric Van Dewoestine

" Commands {{{

  if !exists(':Translate')
    command -nargs=* -range=%
      \ -complete=customlist,translate#translate#CommandCompleteLanguage
      \ Translate :call translate#translate#Translate(<line1>, <line2>, <f-args>)
  endif

" }}}

" vim:ft=vim:fdm=marker
