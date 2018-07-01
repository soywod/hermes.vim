#!/bin/bash

# socket &3
socket=/dev/tcp/irc.freenode.net/6667

# fifo   &4
fifo=/tmp/hfifo

function fifo_to_socket {
  rm -f   $fifo
  mkfifo  $fifo
  exec 4<>$fifo

  while read -r line; do
    echo -ne "$line" >&3
  done <&4
}

function socket_to_fifo {
  rm -f /tmp/hlog

  while read -r line; do
    echo "$line"
    echo "$line" >>/tmp/hlog
  done <&3
}

exec 3<>$socket
fifo_to_socket &
socket_to_fifo &

