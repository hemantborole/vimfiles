" Author: Eric Van Dewoestine

" s:Init() {{{
function s:Init()
  if !exists("s:translate")
    let savewig = &wildignore
    set wildignore=""
    let file = findfile('autoload/translate/translate.vim', escape(&rtp, ' '))
    let &wildignore = savewig

    let separator = has('win32') || has('win64') ? ';' : ':'
    let dir = fnamemodify(file, ':h')
    let cp = substitute(glob(dir . '/*.jar', 1), "\n", separator, 'g')

    " compile Translate.java if necessary.
    if !filereadable(dir . '/Translate.class') ||
      \ (getftime(dir . '/Translate.java') > getftime(dir . '/Translate.class'))
      let cmd = 'javac -cp ' . cp . ' ' . dir . '/Translate.java'
      let result = system(cmd)
      if v:shell_error
        echom 'Failed to compile Translate.java: ' . result
        return
      endif
    endif

    let s:translate = 'java -cp ' . cp . separator . dir . ' Translate '
    let s:complete = 'java -cp ' . cp . separator . dir . ' Translate -c'
  endif
  return 1
endfunction " }}}

" Translate(line1, line2, slang, tlang) {{{
function translate#translate#Translate(line1, line2, slang, tlang)
  if !s:Init()
    return
  endif

  " get the test to send (whole file or visual selection).
  let lines = getline(a:line1, a:line2)
  let mode = visualmode(1)
  if mode != '' && line("'<") == a:line1
    if mode == "v"
      let start = col("'<") - 1
      let end = col("'>")
      let lines[0] = lines[0][start :]
      let lines[-1] = lines[-1][: end]
    elseif mode == "\<c-v>"
      let start = col("'<")
      if col("'>") < start
        let start = col("'>")
      endif
      let start = start - 1
      call map(lines, 'v:val[start :]')
    endif
  endif
  let text = join(lines, "\n")

  " perform the translation.
  let command = s:translate . '"' . text . '" ' . a:slang . ' ' . a:tlang
  let translation = system(command)

  " display the results.
  let s:name = '[Translation]'
  let s:escaped = '[[]Translation[]]'
  if bufwinnr(s:escaped) != -1
    exec bufwinnr(s:escaped) . "winc w"
    setlocal modifiable
    setlocal noreadonly
    silent 1,$delete _
  else
    silent noautocmd exec "botright 10split " . escape(s:name, ' ')
    setlocal nowrap
    setlocal winfixheight
    setlocal noswapfile
    setlocal nobuflisted
    setlocal buftype=nofile
    setlocal bufhidden=delete
    " autocmd to close if last window.
    augroup translate
      autocmd BufEnter * nested
        \ if winnr('$') == 1 && bufwinnr(s:escaped) != -1 |
        \   quit |
        \ endif
    augroup END
  endif

  call append(1, split(translation, "\n"))
  silent 1,1delete _

  setlocal nomodified
  setlocal nomodifiable
  setlocal readonly
endfunction " }}}

" CommandCompleteLanguage(argLead, cmdLine, cursorPos) {{{
" Custom command completion for project names.
function! translate#translate#CommandCompleteLanguage(argLead, cmdLine, cursorPos)
  if !s:Init()
    return []
  endif

  let cmdLine = strpart(a:cmdLine, 0, a:cursorPos)
  let cmdTail = strpart(a:cmdLine, a:cursorPos)
  let argLead = substitute(a:argLead, cmdTail . '$', '', '')

  if !exists('s:langs')
    let s:langs = split(system(s:complete))
  endif

  let langs = copy(s:langs)
  if cmdLine !~ '[^\\]\s$'
    call filter(langs, 'v:val =~ "^' . argLead . '"')
  endif

  return langs
endfunction " }}}

" vim:ft=vim:fdm=marker
