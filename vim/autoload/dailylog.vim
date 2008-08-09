" Author:  Eric Van Dewoestine
" Version: 0.7
"
" Description: {{{
"   Plugin for managing daily log entries.
"   See plugin/dailylog.vim for details.
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

" Global Variables {{{
  if !exists("g:dailylog_home")
    let g:dailylog_home = expand('~/dailylog/')
  else
    if g:dailylog_home !~ '/$'
      let g:dailylog_home = g:dailylog_home . '/'
    endif
    let g:dailylog_home = expand(g:dailylog_home)
  endif
  if !exists("g:dailylog_todo_files")
    let g:dailylog_todo_files = g:dailylog_home . 'todo/'
  else
    if g:dailylog_todo_files !~ '/$'
      let g:dailylog_todo_files = g:dailylog_todo_files . '/'
    endif
    let g:dailylog_home = expand(g:dailylog_todo_files)
  endif
  if !exists("g:dailylog_date_format")
    let g:dailylog_date_format = '%F'
  endif
  if !exists("g:dailylog_time_format")
    let g:dailylog_time_format = '%R'
  endif
  if !exists("g:dailylog_path")
    let g:dailylog_path = '<year>-<month>-<day>.txt'
    "let g:dailylog_path = '<year>/<month>/<day>.txt'
  endif
  if !exists("g:dailylog_delimiter")
    let g:dailylog_delimiter =
      \ "--------------------------------------------------------------------------------"
    let g:dailylog_delimiter_regex =
      \ '^' . g:dailylog_delimiter . '$'
  endif
  if !exists("g:dailylog_header")
    let g:dailylog_header =
        \ [g:dailylog_delimiter, "daily_log_<date>", g:dailylog_delimiter]
  endif
  if !exists("g:dailylog_entry_template")
    let g:dailylog_entry_template =
        \ ["<time> -", "\t<cursor>", "", g:dailylog_delimiter]
  endif
  if !exists("g:dailylog_win_cmd")
    let g:dailylog_win_cmd = 'botright split'
  endif
  if !exists("g:dailylog_link_cmd")
    let g:dailylog_link_cmd = 'aboveleft split <file>'
  endif
  if !exists("g:dailylog_win_size")
    let g:dailylog_win_size = 15
  endif
  if !exists("g:dailylog_time_pattern")
    let g:dailylog_time_pattern = '[0-9][0-9]:[0-9][0-9]'
  endif
  if !exists("g:dailylog_duration_pattern")
    let g:dailylog_duration_pattern = '\d\+hrs\. \d\+min\. (\d\+\.\d\+hrs\.)'
  endif
  if !exists("g:dailylog_delimiter_pattern")
    let g:dailylog_delimiter_pattern = '[-]\{5,}'
  endif
  if !exists("g:dailylog_field_pattern")
    let g:dailylog_field_pattern = '^\s*\(Description\|Priority\)\s*:'
  endif
  if !exists("g:dailylog_link_pattern")
    let g:dailylog_link_pattern = '|.\{-}|'
  endif
  if !exists("g:dailylog_summary_length")
    let g:dailylog_summary_length = 65
  endif
  if !exists("g:dailylog_time_report")
    let g:dailylog_time_report = '<hours>hrs. <mins>min. (<hours_decimal>hrs.)'
  endif
  if !exists("g:dailylog_todo_file")
    let g:dailylog_todo_file = 'todo.txt'
  endif
  if !exists("g:dailylog_todo_header")
    let g:dailylog_todo_header =
        \ [g:dailylog_delimiter, "Todo", g:dailylog_delimiter]
  endif
  if !exists("g:dailylog_todo_entry_template")
    let g:dailylog_todo_entry_template = [
        \ "\tDescription: <cursor>",
        \ "\tPriority: <priority>",
        \ g:dailylog_delimiter]
  endif
  if !exists("g:dailylog_todo_priority_regex")
    let g:dailylog_todo_priority_regex = '^\s\+Priority:\s*'
  endif
  if !exists("g:dailylog_todo_priorities_0")
    let g:dailylog_todo_priorities_0 = "Low"
    let g:dailylog_todo_priorities_1 = "Medium"
    let g:dailylog_todo_priorities_2 = "High"
  endif
" }}}

" Script Variables {{{
  let s:time_range_pattern =
    \ '^\(\s*' .
    \ g:dailylog_time_pattern .
    \ '\s*-\s*' .
    \ g:dailylog_time_pattern .
    \ '\)\s*' .
    \ '\(' . g:dailylog_duration_pattern . '\)\?' .
    \ '$'

  let s:header_report_pattern =
    \ '^\(daily_log_.\{-}\)\s\+.*$'
" }}}

" Open(date) {{{
function! dailylog#Open (date)
  if !s:ValidateEnv()
    return
  endif

  let date = a:date
  if date == ""
    let date = strftime(g:dailylog_date_format)
  endif

  let parts = split(date, '-')
  let path = g:dailylog_path
  let path = substitute(path, '<year>', parts[0], '')
  let path = substitute(path, '<month>', parts[1], '')
  let path = substitute(path, '<day>', parts[2], '')
  let file = g:dailylog_home . path
  let dir = fnamemodify(file, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p')
  endif

  if s:OpenFile(file)
    call s:DailyLogFileHeader(g:dailylog_header, date, file)
  endif

  noremap <silent> <buffer> <cr> :call DailyLogOpenLink()<cr>
  call <SID>DailyLogSyntax()
endfunction
" }}}

" Start() {{{
function! dailylog#Start ()
  call dailylog#Open("")

  let time = strftime(g:dailylog_time_format)
  let entry = deepcopy(g:dailylog_entry_template)
  call map(entry, "substitute(v:val, '<time>', time, 'g')")

  call append(line('$'), entry)
  retab

  call s:StartInsert()
endfunction
" }}}

" Stop() {{{
function! dailylog#Stop ()
  call dailylog#Open("")

  call cursor(1,1)

  " first get all open entries
  let line = 1
  let entry = -1
  while line
    let line = search(g:dailylog_time_pattern . ' -\s*$', 'W')
    if line != 0
      let entry = entry + 1
      let entries_{entry} = line
    endif
  endwhile

  if entry == -1
    echom "No unfinished entries found."
    return
  endif

  if entry != 0
    " build a summary for each entry to help user choose.
    let prompt = ""
    let index = 0
    while index <= entry
      let prompt = prompt . "\n" . index . ") " . s:Summarize(entries_{index})
      let index = index + 1
    endwhile
    let prompt = prompt . "\nChoose entry to stop: "

    " prompt the user for which entry they wish to stop.
    let result = s:Prompt(prompt, 0, entry)

    if result == ""
      echom "No entry chosen, aborting."
      return
    endif
  else
    let result = 0
  endif

  " stop the entry.
  let line = entries_{result}
  if line != 0
    call cursor(line, 1)

    let time = strftime(g:dailylog_time_format)
    if getline(".") !~ '$\s'
      let time = " " . time
    endif

    call cursor(line("."), strlen(getline(".")))

    let save = @p
    let @p = time
    put p
    normal kJ
    let @p = save
  endif

endfunction
" }}}

" Restart() {{{
function! dailylog#Restart ()
  call dailylog#Open("")

  call cursor(1,1)

  " first get all entries
  let line = 1
  let entry = -1
  while line
    let line = search(s:time_range_pattern, 'W')
    if line != 0 && s:IsCommentLine(line + 1)
      let entry = entry + 1
      let entries_{entry} = line
    endif
  endwhile

  if entry == -1
    echom "No entries found."
    return
  endif

  if entry != 0
    " build a summary for each entry to help user choose.
    let prompt = ""
    let index = 0
    while index <= entry
      let prompt = prompt . "\n" . index . ") " . s:Summarize(entries_{index})
      let index = index + 1
    endwhile
    let prompt = prompt . "\nChoose entry to restart: "

    " prompt the user for which entry they wish to restart.
    let result = s:Prompt(prompt, 0, entry)

    if result == ""
      echom "No entry chosen, aborting."
      return
    endif
  else
    let result = 0
  endif

  " restart the entry.
  let line = entries_{result}
  if line != 0
    call cursor(line, 1)

    let time = strftime(g:dailylog_time_format)

    let save = @p
    let @p = time . " -"
    put p
    let @p = save
  endif

endfunction
" }}}

" Search(pattern) {{{
function! dailylog#Search (pattern)
  call dailylog#Open('')
  let path = g:dailylog_path
  let path = substitute(path, '<year>', '*', '')
  let path = substitute(path, '<month>', '*', '')
  let path = substitute(path, '<day>', '*', '')
  exec 'vimgrep ' . a:pattern . ' ' . g:dailylog_home . path
endfunction
" }}}

" Report(date) {{{
function! dailylog#Report (date)
  call dailylog#Open(a:date)

  let pos = getpos('.')
  call cursor(1,1)

  " first get all entries
  let line = 1
  let entries = -1
  let total_duration = 0
  while line
    let line = search(s:time_range_pattern, 'W')
    if line != 0 && getline(line - 1) =~ g:dailylog_delimiter_pattern
      let entries = entries + 1
      let dur = s:GetEntryDuration(line)
      let lastline = dur[0]
      let duration = dur[1]
      let total_duration = total_duration + duration
      let entry_report = s:Report(g:dailylog_time_report, duration)
      let updated = substitute(getline(lastline), s:time_range_pattern, '\1', '')
      call setline(lastline, updated . '    ' . entry_report)
    endif
  endwhile

  if entries == -1
    echom 'No entries found.'
    return
  endif

  let header = substitute(getline(2), s:header_report_pattern, '\1', '')
  let total_report = 'Total: ' . s:Report(g:dailylog_time_report, total_duration)
  call setline(2, header . '    ' . total_report)

  call setpos('.', pos)
endfunction
" }}}

" TodoOpen() {{{
function! dailylog#TodoOpen ()
  if !s:ValidateEnv()
    return
  endif

  let file = g:dailylog_home . g:dailylog_todo_file
  if s:OpenFile(file)
    call s:DailyLogFileHeader(g:dailylog_todo_header, "", file)
  endif

  noremap <silent> <buffer> <cr> :call DailyLogOpenLink()<cr>
  call <SID>DailyLogSyntax()
endfunction
" }}}

" TodoNew() {{{
function! dailylog#TodoNew ()
  call dailylog#TodoOpen()

  let priority_index = 0
  let priority_prompt = ""
  while exists("g:dailylog_todo_priorities_" . priority_index)
    let priority_prompt = priority_index . ") " .
      \ g:dailylog_todo_priorities_{priority_index} . "\n" . priority_prompt
    let priority_index = priority_index + 1
  endwhile
  let priority_prompt = priority_prompt . "Choose a priority: "

  let priority_result = input(priority_prompt)
  while priority_result !~ '[0-9]'
      \ || priority_result < 0
      \ || priority_result >= priority_index
    let priority_result = input(priority_prompt)
  endwhile

  let priority = g:dailylog_todo_priorities_{priority_result}

  " move the cursor to the location of the last entry with the specified
  " priority, if none after the last entry of the next highest priority,
  " if none again, then before the last entry of lower priority, or if no
  " other entries, put at end of the file.
  let regex = g:dailylog_todo_priority_regex . priority
  call cursor(line('$'), 1)

  "search up for the last occurrence of the selected priority
  if search(regex, 'bW') > 0
    call search(g:dailylog_delimiter_regex, 'W')
  else
    " search up for the last occurrence of higher priority
    let priority_index = priority_result + 1
    while exists("g:dailylog_todo_priorities_" . priority_index)
      let regex = g:dailylog_todo_priority_regex .
        \ g:dailylog_todo_priorities_{priority_index}
      if search(regex, 'bW') > 0
        call search(g:dailylog_delimiter_regex, 'W')
        break
      endif
      let priority_index = priority_index + 1
    endwhile

    " if still haven't found an entry, search for the first occurrence of a
    " lower priority.
    if line('.') == line('$')
      let priority_index = priority_result - 1
      while exists("g:dailylog_todo_priorities_" . priority_index)
        let regex = g:dailylog_todo_priority_regex .
          \ g:dailylog_todo_priorities_{priority_index}
        if search(regex, 'w') > 0
          call search(g:dailylog_delimiter_regex, 'bW')
          break
        endif
        let priority_index = priority_index - 1
      endwhile
    endif
  endif

  " put the new entry
  let entry = deepcopy(g:dailylog_todo_entry_template)
  call map(entry, "substitute(v:val, '<priority>', priority, 'g')")
  call append(line('.'), entry)
  retab

  call s:StartInsert()
endfunction
" }}}

" ValidateEnv() {{{
" Validates that the current environment is setup for the daily log plugin.
function! s:ValidateEnv ()
  if filewritable(g:dailylog_home) != 2
    echoe "Cannot write to directory '" . g:dailylog_home . "'."
    return 0
  endif
  if !exists("*strftime")
    echoe "Required function 'strftime()' not available on this system."
    return 0
  endif
  return 1
endfunction
" }}}

" DailyLogSyntax() {{{
function! s:DailyLogSyntax ()
  set ft=dailylog
  hi link DailyLogTime Constant
  hi link DailyLogDuration Constant
  hi link DailyLogDelimiter Constant
  hi link DailyLogField Keyword
  hi link DailyLogLink Special
  " match time in the form of 08:12
  exec "syntax match DailyLogTime /" . g:dailylog_time_pattern . "/"
  " match durations in the form of 1hrs. 16min. (1.266hrs.)
  exec "syntax match DailyLogDuration /" . g:dailylog_duration_pattern . "/"
  exec "syntax match DailyLogDelimiter /" . g:dailylog_delimiter_pattern . "/"
  exec "syntax match DailyLogField /" . g:dailylog_field_pattern . "/"
  exec "syntax match DailyLogLink /" . g:dailylog_link_pattern . "/"
  syntax match DailyLogLink /#[0-9]\+/
endfunction
" }}}

" DailyLogFileHeader(header, date, file) {{{
function! s:DailyLogFileHeader (header, date, file)
  let header = a:header
  call map(header, "substitute(v:val, '<date>', a:date, 'g')")
  call map(header, "substitute(v:val, '<file>', a:file, 'g')")

  call append(1, header)
  silent 1delete
endfunction
" }}}

" OpenFile(file) {{{
function! s:OpenFile (file)
  let isNew = 0
  " determine if the file is new.
  if !filereadable(a:file) && bufnr(a:file) == -1
    let isNew = 1
  endif

  " before opening it, see if it's in an open window or buffer
  if bufwinnr(bufnr(a:file)) != -1
    exec bufwinnr(bufnr(a:file)) . 'wincmd w'
  else
    let filename = expand('%:p')

    exec g:dailylog_win_cmd . ' ' . a:file
    exec "resize " . g:dailylog_win_size
    set winfixheight

    let b:filename = filename
    augroup eclim_temp_window
      autocmd! BufUnload <buffer>
      call eclim#util#GoToBufferWindowRegister(b:filename)
    augroup END
  endif

  return isNew
endfunction
" }}}

" DailyLogOpenLink() {{{
function! DailyLogOpenLink ()
  let line = getline('.')
  let link = substitute(
    \ getline('.'), '.*|\(.\{-}\%' . col('.') . 'c.\{-}\)|.*', '\1', '')
  if link != line && filereadable(expand(link))
    echom 'link = ' . link
    silent exec substitute(g:dailylog_link_cmd, '<file>', link, 'g')
    return
  endif

  let link = substitute(
    \ getline('.'), '.*#\([0-9]\{-}\%' . col('.') . 'c.\{-}\)\W.*', '\1', '')
  if link != line
    if !exists("g:dailylog_tracker_url")
      echoe "Linking to tickets requires setting " .
        \ "'g:dailylog_tracker_url' to be set."
      return
    endif
    let url = substitute(g:dailylog_tracker_url, '<id>', link, '')
    call eclim#web#OpenUrl(url)
  endif
endfunction
" }}}

" Prompt(prompt, min,max) {{{
function! s:Prompt (prompt, min, max)
  let result = -1
  while (result < a:min) || (result > a:max)
    let result = input(a:prompt)
  endwhile

  return result
endfunction
" }}}

" Summarize(entry) {{{
function! s:Summarize (entry)
  call cursor(a:entry, 1)

  let line = 0
  while line == 0
    let text = getline(".")
    if text =~ g:dailylog_delimiter_pattern
      break
    elseif s:IsCommentLine(line("."))
      let line = line(".")
    else
      call cursor(line(".") + 1, 1)
    endif
  endwhile

  " no text found
  if line == 0
    return "No Summary."
  endif

  let summary = substitute(getline(line), '^\s\+', '', '')
  if strlen(summary) > g:dailylog_summary_length
    let summary = strpart(summary, 0, g:dailylog_summary_length - 3) . "..."
  endif
  return summary
endfunction
" }}}

" GetEntryDuration(entry) {{{
function! s:GetEntryDuration (entry)
  let duration = 0

  let linenum = a:entry
  let line = getline(linenum)
  while line =~ s:time_range_pattern
    let line = substitute(line, s:time_range_pattern, '\1', '')
    call setline(linenum, line)
    let duration = duration + s:GetDuration(line)
    let linenum = linenum + 1
    let line = getline(linenum)
  endwhile

  return [linenum - 1, duration]
endfunction " }}}

" Report(report, duration) {{{
function! s:Report (report, duration)
  let mins = a:duration / 60
  let hours = mins / 60
  if hours >= 1
    let mins = (a:duration - (hours * 60 * 60)) / 60
  endif

  " accuracy isn't to the 100ths, it's actually to the 1000ths
  let accuracy = 100
  let mins_decimal = (mins * accuracy) / 6
  let pad = strlen(accuracy) - strlen(mins_decimal)
  let index = 0
  while index < pad
    let mins_decimal = "0" . mins_decimal
    let index = index + 1
  endwhile

  let hours_decimal = hours . "." . mins_decimal

  let report = a:report
  let report = substitute(report, '<hours>', hours, 'g')
  let report = substitute(report, '<mins>', mins, 'g')
  let report = substitute(report, '<hours_decimal>', hours_decimal, 'g')

  return report

endfunction
" }}}

" GetDuration(line) {{{
function! s:GetDuration (line)
  let time1 = substitute(a:line,
    \ '\s*\(' . g:dailylog_time_pattern . '\)\s*-.*', '\1', '')
  let time2 = substitute(a:line,
    \ '.*-\s*\(' . g:dailylog_time_pattern . '\).*', '\1', '')

  let time1 = substitute(
    \ system("date --date=\"" . time1 . "\" +%s"), '\n', '', '')
  let time2 = substitute(
    \ system("date --date=\"" . time2 . "\" +%s"), '\n', '', '')

  return time2 - time1
endfunction
" }}}

" IsCommentLine(line) {{{
function! s:IsCommentLine (line)
  let text = getline(a:line)
  if text !~ '^\s*$' &&
      \ text !~ '^' . g:dailylog_time_pattern &&
      \ text !~ g:dailylog_delimiter_pattern
    return 1
  endif

  return 0
endfunction
" }}}

" StartInsert() {{{
function! s:StartInsert ()
  if search('<cursor>')
    let save = @"
    normal df>
    startinsert!
    let @" = save
  endif
endfunction
" }}}

" vim:ft=vim:fdm=marker
