#!/bin/bash

# socket  : &3
# fifo-in : &4 /tmp/hermes-in (write to socket)
# fifo-out: -- /tmp/hermes-out (read from socket)

function fifo_to_socket {
  fifo=/tmp/hermes-in
  rm -f  $fifo
  mkfifo $fifo
  exec 4<>$fifo

  while read -r line; do
    echo -ne "$line" >&3
  done <&4
}

function socket_to_fifo {
  file=/tmp/hermes-out
  rm -f  $file
  mkfifo $file

  while read -r line; do
    echo "$line" >>$file
  done <&3
}

exec 3<>/dev/tcp/irc.freenode.net/6667
socket_to_fifo &
fifo_to_socket &

