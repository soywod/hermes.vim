" --------------------------------------------------------------------- # Send #

function! hermes#core#irc#Send(server, cmd)
  let cmd = printf('echo -ne "%s\r\n" >>/tmp/hfifo-%s', a:cmd, a:server)
  call system(cmd)
endfunction

