" Author: Eric Van Dewoestine
"
" Description: {{{
"   Plugin for invoking ack.
" }}}

" Command Declarations {{{
if !exists(":Ack")
  command -nargs=+ Ack :call <SID>Ack(<q-args>)
endif
" }}}

" s:Ack(args) {{{
" Executes ack and populates the quickfix buffer with the results.
function! s:Ack(args)
  if !executable('ack')
    call s:Echo("'ack' not found on your system path.", 'Error')
    return
  endif

  let index = 0
  let args = ''
  let arg = ''
  let quote = 0
  let escape = 0
  let prev = ''
  while index < len(a:args)
    let char = a:args[index]
    " spaces that are not escaped or inside of a quoted expression, delimit
    " args
    if char == ' ' && !quote && !escape
      let args .= ' "' . arg . '"'
      let arg = ''
    " double or single quote, when not escaped, start or end a quoted
    " expression
    elseif char =~ "['\"]" && !escape
      let quote = !quote
    else
      if char == '\'
        let escape = !escape
        " handle escaping of spaces and '\'
        if len(a:args) > index && a:args[index + 1] == ' '
          let index += 1
          continue
        endif
      else
        let escape = 0
      endif

      let arg .= char
    endif
    let prev = char
    let index += 1
  endwhile
  let args .= ' "' . arg . '"'

  let saveerrorformat = &errorformat
  try
    set errorformat=%-Gack:%.%#,%-Gvimack:%.%#,%f:%l:%c:%m,%f:%l:%m,%-G%.%#
    let cmd = 'vimack ' . escape(args, '|')
    cexpr system(cmd)
    if exists('g:EclimHome')
      call eclim#display#signs#Show('i', 'qf')
    endif
  finally
    let &errorformat = saveerrorformat
  endtry

  " ack returns 1 on no results found, so errors are greater than that.
  if v:shell_error > 1
    let error = system(cmd)
    call s:Echo(error, 'Error')
  elseif len(getqflist()) == 0
    call s:Echo('No results found: Ack' . args, 'WarningMsg')
  endif
endfunction " }}}

" s:Echo(message, hightlight) {{{
function s:Echo(message, highlight)
  exec "echohl " . a:highlight
  redraw
  for line in split(a:message, '\n')
    echom line
  endfor
  let b:eclim_last_message_line = line('.')
  echohl None
endfunction " }}}

" vim:ft=vim:fdm=marker
