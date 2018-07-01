let s:connections = []
let s:REGEX_IRC = '^(?:@([^\r\n ]*) +|())(?::([^\r\n ]+) +|())([^\r\n ]+)(?: +([^:\r\n ]+[^\r\n ]*(?: +[^:\r\n ]+[^\r\n ]*)*)|())?(?: +:([^\r\n]*)| +())?[\r\n]*$'

" ------------------------------------------------------------------ # Connect #

function! hermes#cli#Connect(alias)
  let server = filter(copy(g:hermes_servers), 'v:key == a:alias')
  let server = server[a:alias]
  let host = printf('%s:%d', server.hostname, server.port)

  execute 'tabnew ' . a:alias
  setlocal filetype=hlog

  let s:connections += [a:alias]

  call job_start(
    \['/bin/sh', hermes#Socket(), a:alias, server.hostname, server.port],
    \{
      \'mode': 'nl',
      \'out_cb': s:ConnectCallbackWrapper(a:alias),
    \},
  \)
endfunction

function! s:ConnectCallbackWrapper(alias)
  return {_, data -> s:ConnectCallback(a:alias, data)}
endfunction

function! s:ConnectCallback(alias, data)
  let index = index(s:connections, a:alias)
  if  index + 1
    call hermes#cli#User(a:alias, g:hermes_username, '0', '*', g:hermes_realname)
    call hermes#cli#Nick(a:alias, g:hermes_nickname)
    call remove(s:connections, index)
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
  let end = len(getbufline(a:alias, 0, '$')) + 1
  call setbufline(a:alias, end, line)
  normal! G
  setlocal nomodifiable
endfunction

" --------------------------------------------------------------------- # Nick #

" https://tools.ietf.org/html/rfc2812#section-3.1.2
function! hermes#cli#Nick(server, nickname)
  let cmd = printf('NICK %s', a:nickname)
  call hermes#core#irc#Send(a:server, cmd)
endfunction

" --------------------------------------------------------------------- # User #

" https://tools.ietf.org/html/rfc2812#section-3.1.3
function! hermes#cli#User(server, user, mode, unused, realname)
  let cmd = printf('USER %s %s %s :%s', a:user, a:mode, a:unused, a:realname)
  call hermes#core#irc#Send(a:server, cmd)
endfunction

" --------------------------------------------------------------------- # Send #

function! hermes#cli#Send(cmd)
  let server = bufname('%')
  call hermes#core#irc#Send(server, a:cmd)
endfunction

