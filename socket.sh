#!/bin/bash

# socket: &3
# fifo  : &4 /tmp/hermes

function fifo_to_socket {
  fifo=/tmp/hfifo
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

exec 3<>/dev/tcp/irc.freenode.net/6667
socket_to_fifo &
fifo_to_socket &

