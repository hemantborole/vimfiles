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
function! s:Ack (args)
  if !executable('ack')
    call eclim#util#EchoError("'ack' not found on your system path.")
    return
  endif

  let escape_chars = ['|']

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
        if prev == '\' || (len(a:args) > index && a:args[index + 1] == ' ')
          let index += 1
          continue
        endif
      else
        let escape = 0
      endif

      " some characters need to be escaped for the shell.
      if index(escape_chars, char) != -1
        let arg .= '\'
      endif

      let arg .= char
    endif
    let prev = char
    let index += 1
  endwhile
  let args .= ' "' . arg . '"'
  silent exec 'grep ' . args

  if len(getqflist()) == 0
    call eclim#util#Echo('No results found: Ack' . args)
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
