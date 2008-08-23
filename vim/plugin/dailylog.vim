" Author: Eric Van Dewoestine
" Version: 0.7
"
" Description: {{{
"   Plugin for managing daily log entries.
"
"   DailyLogOpen: Opens the current daily log file in a new window.
"   Optionally the command may be followed by the date you wish to open the
"   log for.
"     Ex. Open the current log file
"       :DailyLogOpen
"     Ex. Open the log file for January 15th 2005
"       :DailyLogOpen 2005-01-15
"
"   DailyLogStart: Opens the current daily log file if necessary and starts a
"   new log entry.
"
"   DailyLogStop: Opens the current daily log file if necessary and stops the
"   currently unfinished entry.  If more than one entry is unended, then you
"   will be prompted for the entry to stop.
"
"   DailyLogRestart: Opens the current daily log file if necessary and prompts
"   you for the entry to restart.
"
"   DailyLogReport: Aggrgates per task and total times and updates the file
"   with reports of time spent on each task and overall.
"
"   DailyLogSearch: Searches your configured daily log directory via vimgrep
"   using the supplied pattern.
"     Ex. Search for "vim plugin"
"       :DailyLogSearch /vim plugin/
" }}}

" Command Declarations {{{
if !exists(":DailyLogOpen")
  command -nargs=? -complete=customlist,dailylog#CommandCompleteDate
    \ DailyLogOpen :call dailylog#Open('<args>')

  command -nargs=+ DailyLogSearch :call dailylog#Search(<q-args>)
  command DailyLogStop            :call dailylog#Stop()
  command DailyLogStart           :call dailylog#Start()
  command DailyLogRestart         :call dailylog#Restart()
endif
" }}}

" vim:ft=vim:fdm=marker
