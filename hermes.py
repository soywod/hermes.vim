#!/usr/bin/python3

import socket, string, re, time

# https://gist.github.com/DanielOaks/ef8b21a25a4db5899015
IRC_REGEX = '^(?:@([^\r\n ]*) +|())(?::([^\r\n ]+) +|())([^\r\n ]+)(?: +([^:\r\n ]+[^\r\n ]*(?: +[^:\r\n ]+[^\r\n ]*)*)|())?(?: +:([^\r\n]*)| +())?[\r\n]*$'

# ---------------------------------------------------------------- # Functions #

def irc_conn(host, port):
    irc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    irc.connect((host, port))

    return irc

def irc_send(message):
    irc.send(f'{message}\r\n'.encode())

def irc_listen():
    while (1):
        res = irc.recvmsg(4096)
        if res[0]:
            lines = res[0].decode().split('\r\n')[:-1]

            for line in lines:
                matches = re.match(IRC_REGEX, line).groups()
                if not matches:
                    continue

                prefix = matches[2]
                verb = matches[4]
                params = matches[5]
                optparams = matches[7]

                print(f'{prefix}/{verb}/{params}/{optparams}')

        time.sleep(1)

# ------------------------------------------------------------------ # Options #

host = 'irc.freenode.net'
port = 6667
channel = '#hermes.io'
user  = 'hermes-py-cli'
realname  = 'Test Hermes Python Client'

# --------------------------------------------------------------------- # Main #

irc = irc_conn(host, port)

irc_send(f'USER {user} 0 * :{realname}')
irc_send(f'NICK {user}')
irc_send(f'JOIN {channel}')

irc_listen()

