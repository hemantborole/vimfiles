" Author: Eric Van Dewoestine

" Global Variables {{{

if !exists('g:CopyrightPattern')
  " group 1 must be the text leading up to the most recent year
  " group 2 must be the most recent year to check against the current year.
  let g:CopyrightPattern = '\(Copyright.\{-}\%\(\d\{4}\s*[-,]\s*\)\{0,1}\)\(\d\{4}\)'
endif

if !exists('g:CopyrightAddRange')
  let g:CopyrightAddRange = 1
endif

if !exists('g:CopyrightMaxLines')
  let g:CopyrightMaxLines = 25
endif

" }}}

" Script Variables {{{
  let s:year = exists('*strftime') ? strftime('%Y') : '2009'
" }}}

" Autocmds {{{

augroup copyright
  autocmd!
  autocmd BufWrite * call <SID>UpdateCopyright()
augroup END

" }}}

" s:UpdateCopyright() {{{
function! s:UpdateCopyright()
  if exists('b:copyright_checked')
    return
  endif

  let pos = getpos('.')
  try
    call cursor(1, 1)
    let lnum = search(g:CopyrightPattern, 'cnW', g:CopyrightMaxLines)
    if lnum == 0
      return
    endif

    let line = getline(lnum)
    let year = substitute(line, '.\{-}' . g:CopyrightPattern . '.*', '\2', '')
    if year == s:year
      return
    endif

    echohl WarningMsg
    try
      redraw
      echo printf(
        \ "Copyright year for file '%s' appears to be out of date.\n",
        \ expand('%:t'))
      let response = input("Would you like to update it? (y/n): ")
      while response != '' && response !~ '^\c\s*\(y\(es\)\?\|no\?\|\)\s*$'
        let response = input("You must choose either y or n. (Ctrl-C to cancel): ")
      endwhile
    finally
      echohl None
    endtry

    if response == '' || response !~ '\c\s*\(y\(es\)\?\)\s*'
      return
    endif
    if g:CopyrightAddRange && line !~ '\d\{4}\s*[-,]\s*' . year
      let sub = '\1' . year . ' - ' . s:year
    else
      let sub = '\1' . s:year
    endif
    call setline(lnum, substitute(line, g:CopyrightPattern, sub, ''))
  finally
    call setpos('.', pos)
    let b:copyright_checked = 1
  endtry
endfunction " }}}

" vim:ft=vim:fdm=marker
