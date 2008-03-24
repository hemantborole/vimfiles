" Author: Eric Van Dewoestine
" Version: 0.6
"
" Description: {{{
"   Plugin for managing daily log entries.
"
"   DailyLogOpen: Opens the current daily log file in a new window.  Optionally
"   the command may be followed by the date you wish to open the log for.
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
"   DailyLogReport: Opens the current daily log file if necessary and echos a
"   summary of each task and the duration that the entry was running.  You may
"   also run the report for another day by supplying the date just like for
"   DailyLogOpen.
"     Ex. Running the report for the current daily log
"       :DailyLogReport
"     Ex. Running the report for January 15th 2005
"       :DailyLogReport 2005-01-15
"
"   DailyLogSearch: Searches your configured daily log directory for the string
"   you supply and displays the results in the vim quickfix window.
"     Note: You must place quotes around the search string or you will receive
"     an error.
"     Ex. Search for "vim plugin"
"       :DailyLogSearch "vim plugin"
" }}}

" Command Declarations {{{
if !exists(":DailyLogOpen")
  command -nargs=? DailyLogOpen   :call dailylog#Open('<args>')
  command -nargs=1 DailyLogSearch :call dailylog#Search(<args>)
  command -nargs=? DailyLogReport :call dailylog#Report('<args>')
  command DailyLogStop            :call dailylog#Stop()
  command DailyLogStart           :call dailylog#Start()
  command DailyLogRestart         :call dailylog#Restart()
  command DailyLogTodoOpen        :call dailylog#TodoOpen()
  command DailyLogTodoNew         :call dailylog#TodoNew()
  "command DailyLogTodoReport      :call dailylog#TodoReport()
endif
" }}}

" vim:ft=vim:fdm=marker
