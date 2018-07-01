" ------------------------------------------------------------------ # Connect #
let s:REGEX_IRC = '^(?:@([^\r\n ]*) +|())(?::([^\r\n ]+) +|())([^\r\n ]+)(?: +([^:\r\n ]+[^\r\n ]*(?: +[^:\r\n ]+[^\r\n ]*)*)|())?(?: +:([^\r\n]*)| +())?[\r\n]*$'

function! hermes#cli#Connect(alias)
  let server = filter(copy(g:hermes_servers), 'v:key == a:alias')
  let server = server[a:alias]

  " let stop = 'exec 3<>&-'
  " let start = printf('exec 3<>/dev/tcp/%s/%d', server.hostname, server.port)

  " call system(stop)
  " call system(start)

  execute 'tabnew ' . a:alias
  setlocal filetype=hlog

  call job_start(
    \['/bin/sh', hermes#Socket()],
    \{'out_cb': function('s:ConnectCallback'), 'mode': 'nl'},
  \)
endfunction

function! s:ConnectCallback(_, data)
  pythonx import re, vim
  pythonx data = vim.eval('a:data')
  pythonx regex = vim.eval('s:REGEX_IRC')

  let matches = pyxeval('re.match(regex, data).groups()')
  let now = strftime('%d/%m/%y %H:%M:%S')
  let prefix = matches[2]
  let verb = matches[4]
  let params = matches[5]
  let optparams = matches[7]
  let line = printf('%s | %s | %s %s', now, prefix, params, optparams)

  setlocal modifiable
  call setbufline('freenode', line('$') + 1, line)
  setlocal nomodifiable
endfunction

