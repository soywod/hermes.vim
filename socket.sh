#!/bin/bash

# socket &3
socket=/dev/tcp/$2/$3

# fifo &4
fifo=/tmp/hfifo-$1

# log
log=/tmp/hlog-$1

function fifo_to_socket {
  rm -f   $fifo
  mkfifo  $fifo
  exec 4<>$fifo

  while read -r line; do
    echo -ne "$line" >&3
  done <&4
}

function socket_to_fifo {
  rm -f $log

  while read -r line; do
    echo "$line"
    echo "$line" >>$log
  done <&3
}

exec 3<>$socket
fifo_to_socket &
socket_to_fifo &

