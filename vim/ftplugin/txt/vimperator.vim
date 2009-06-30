" Author: Eric Van Dewoestine

if expand('%:t') !~ '^vimperator-.*\.tmp$'
  finish
endif

" Global Variables {{{

  if !exists("g:VimperatorEditHistoryStore")
    let g:VimperatorEditHistoryStore = '~/.vimperator/info/history-editor'
  endif

" }}}

" Autocmds {{{

  augroup vimperator_editor
    autocmd BufWritePost <buffer> call <SID>Save()
  augroup END

" }}}

" Commands {{{

  command VimperatorEditorPrevious :call <SID>RestorePrevious()

" }}}

" s:Save() {{{
function s:Save()
  let domain = substitute(expand('%:t:r'), 'vimperator-\(.\{-}\)', '\1', '')
  let domain = substitute(domain, '-[0-9]\+$', '', '')

  let store = expand(g:VimperatorEditHistoryStore)
  let path = fnamemodify(store, ':h')
  if !isdirectory(path)
    call mkdir(path)
  endif

  let history = {}
  if filereadable(store)
    try
      let history = eval(readfile(store)[0])
    catch
      " ignore
    endtry
  endif

  let history[domain] = getline(1, '$')
  call writefile([string(history)], store)
endfunction " }}}

" s:RestorePrevious() {{{
function s:RestorePrevious()
  let domain = substitute(expand('%:t:r'), 'vimperator-\(.\{-}\)', '\1', '')
  let domain = substitute(domain, '-[0-9]\+$', '', '')

  let store = expand(g:VimperatorEditHistoryStore)
  if filereadable(store)
    try
      let history = eval(readfile(store)[0])
      if has_key(history, domain)
        silent 1,$delete _
        call append(1, history[domain])
        silent 1,1delete _
      else
        call eclim#util#Echo('No previous text found: ' . domain)
      endif
    catch
      " ignore
    endtry
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
