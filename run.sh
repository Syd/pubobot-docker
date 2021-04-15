#!/usr/bin/env bash
set -euo pipefail

esh -o config.cfg config.esh
esh -o client_config.py client_config.esh
touch modules/gtvd_config.py
#python3 pubobot.py
#!/bin/bash

coproc python3 pubobot.py  # replace 'cat -n' with actual server program to be launched

# first some necessary file-descriptors fiddling
exec {srv_input}>&${COPROC[1]}-
exec {srv_output}<&${COPROC[0]}-

# background commands to relay normal stdin/stdout activity
cat <&0 >&${srv_input} &
cat <&${srv_output} >&1 >&2 &

# set signal handler up
term_received=false ; trap 'term_received=true' SIGTERM

# endless loop waiting for events
while true; do
    # wait for server to exit or sigterm received
    wait ${COPROC_PID}
    exit_status=$?
    # if sigterm received:
    if [ $exit_status -gt 128 ] && $term_received ; then
        echo "sending quit message to pubobot"
        # kill proxy command relaying stdin to server
        kill %2
        # send quit to server's stdin
        echo $'\n'quit >&${srv_input}
        # close server's stdin
        exec {srv_input}<&-
        # wait for actual server to exit
        wait ${COPROC_PID}
        exit $?
    # something else happened: kill proxy commands and exit with server's own exit status
    else
        kill %2
        kill %3
    fi
    exit $exit_status
done

