let s:REGEX_IRC = '^(?:@([^\r\n ]*) +|())(?::([^\r\n ]+) +|())([^\r\n ]+)(?: +([^:\r\n ]+[^\r\n ]*(?: +[^:\r\n ]+[^\r\n ]*)*)|())?(?: +:([^\r\n]*)| +())?[\r\n]*$'

" ------------------------------------------------------------------ # Connect #

function! hermes#cli#Connect(alias)
  let server = filter(copy(g:hermes_servers), 'v:key == a:alias')
  let server = server[a:alias]
  let host = printf('%s:%d', server.hostname, server.port)

  execute 'tabnew ' . a:alias
  setlocal filetype=hlog

  let s:fcall = 1
  call job_start(
    \['/bin/sh', hermes#Socket()],
    \{
      \'mode': 'nl',
      \'out_cb': function('s:ConnectCallback'),
    \},
  \)
endfunction

function! s:ConnectCallback(_, data)
  if s:fcall
    call hermes#cli#User(g:hermes_username, '0', '*', g:hermes_realname)
    call hermes#cli#Nick(g:hermes_nickname)
    let s:fcall = 0
  endif

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

" --------------------------------------------------------------------- # User #

" https://tools.ietf.org/html/rfc2812#section-3.1.3
function! hermes#cli#User(user, mode, unused, realname)
  let cmd = printf('USER %s %s %s :%s', a:user, a:mode, a:unused, a:realname)
  call hermes#core#irc#Send(cmd)
endfunction

" --------------------------------------------------------------------- # Nick #

" https://tools.ietf.org/html/rfc2812#section-3.1.2
function! hermes#cli#Nick(nickname)
  let cmd = printf('NICK %s', a:nickname)
  call hermes#core#irc#Send(cmd)
endfunction

