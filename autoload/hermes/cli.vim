let s:REGEX_IRC = '^(?:@([^\r\n ]*) +|())(?::([^\r\n ]+) +|())([^\r\n ]+)(?: +([^:\r\n ]+[^\r\n ]*(?: +[^:\r\n ]+[^\r\n ]*)*)|())?(?: +:([^\r\n]*)| +())?[\r\n]*$'

let s:state = {}

" ------------------------------------------------------------------ # Connect #

function! hermes#cli#Connect(alias)
  let server = filter(copy(g:hermes_servers), 'v:key == a:alias')
  let server = server[a:alias]
  let host = printf('%s:%d', server.hostname, server.port)

  execute 'edit ' . a:alias
  setlocal filetype=hlog

  let s:state[a:alias] = {'connected': 0, 'logs': [], 'scope': {'type': '*'}}

  augroup HermesLogs
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call hermes#cli#Refresh()
  augroup END

  call job_start(
    \['/bin/sh', hermes#Socket(), a:alias, server.hostname, server.port],
    \{'mode': 'nl', 'out_cb': s:ConnectCallbackWrapper(a:alias)},
  \)
endfunction

function! s:ConnectCallbackWrapper(alias)
  return {_, data -> s:ConnectCallback(a:alias, data)}
endfunction

function! s:ConnectCallback(alias, data)
  if ! s:state[a:alias].connected
    call hermes#cli#User(a:alias, g:hermes_username, '0', '*', g:hermes_realname)
    call hermes#cli#Nick(a:alias, g:hermes_nickname)
    let s:state[a:alias].connected = 1
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
  let newline = printf('%s | %s | %s %s', now, prefix, params, optparams)
  let s:state[a:alias].logs += [{
    \'prefix': prefix,
    \'verb': verb,
    \'params': params,
    \'tostring': newline,
  \}]

  if bufname('%') == a:alias
    call hermes#cli#Refresh()
  endif
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

" -------------------------------------------------------------------- # Scope #

function! hermes#cli#Scope()
  let server = bufname('%')
  let scope = input('Enter a scope (channel or user): ')
  let s:state[server].scope = scope =~? '^#'
    \? {'type': 'channel', 'value': scope}
    \: {'type': 'user', 'value': scope}

  call hermes#cli#Refresh()
endfunction

" -------------------------------------------------------------- # Scope clear #

function! hermes#cli#ScopeClear()
  let server = bufname('%')
  let s:state[server].scope = {'type': '*'}

  call hermes#cli#Refresh()
endfunction

" ------------------------------------------------------------------ # Helpers #

function! hermes#cli#Refresh()
  let server = bufname('%')
  let state = s:state[server]
  let logs = state.logs

  if state.scope.type == 'channel'
    let channel = state.scope.value
    let logs = filter(copy(logs), s:ByChannel(channel))
  elseif state.scope.type == 'user'
    let user = state.scope.value
    let logs = filter(copy(logs), s:ByUser(user))
  endif

  let logs = map(copy(logs), 'v:val.tostring')

  setlocal modifiable
  0,$d | call append(0, logs)
  setlocal nomodifiable
endfunction

function! s:ByChannel(channel)
  let channel  = printf('v:val.params =~? "%s"', a:channel)
  let userinfo = printf('v:val.prefix =~? "%s"', g:hermes_username)

  return printf('%s || %s', channel, userinfo)
endfunction

function! s:ByUser(sender)
  let verb     = printf('v:val.verb == "%s"', 'PRIVMSG')
  let sender   = printf('v:val.prefix =~? "%s"', a:sender)
  let receiver = printf('v:val.params =~? "%s"', g:hermes_username)
  let userinfo = printf('v:val.prefix =~? "%s"', g:hermes_username)
  let privmsg  = printf('%s && %s && %s', verb, sender, receiver)

  return printf('%s || %s', privmsg, userinfo)
endfunction

