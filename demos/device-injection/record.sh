#!/bin/bash

#
# asciinema rec -t "device-injection" \
#     -c "/bin/bash -c '(sleep 3; ./record.sh) & tmux new -s device-injection'" \
#     device-injection.cast
#

SESSION="${session:-device-injection}"
DEMO_USER='root'
DEMO_HOST='172.17.0.2'

PV='pv -qL'
COMMENT_SPEED=40
COMMAND_SPEED=40
PVLINE='pv -qlL'

SHORT_PAUSE="${SHORT_PAUSE:-2}"
MID_PAUSE="${MID_PAUSE:-4}"
LONG_PAUSE="${LONG_PAUSE:-6}"

setup() {
    tmux new -s ${session:-$SESSION}
}

show-comment() {
    echo -e "# $@" | $PV ${speed:-$COMMENT_SPEED} |
    while read -N 1 ch; do
        tmux send-keys -t ${session:-$SESSION}:${window:-0}.${pane:-0} "$ch"
    done
}

send-command() {
    echo -e "$@" | $PV ${speed:-$COMMAND_SPEED} |
    while read -N 1 ch; do
        [ "$ch" = ";" ] && ch=';;'
        tmux send-keys -t ${session:-$SESSION}:${window:-0}.${pane:-0} "$ch"
    done
}

split-vertical() {
    tmux splitw -t ${session:-$SESSION}:${window:-0} -h
}

split-horizontal() {
    tmux splitw -t ${session:-$SESSION}:${window:-0} -v
}

kill-pane() {
    tmux kill-pane -t ${session:-$SESSION}:${window:-0}.${pane:-1}
}

ssh-login() {
    echo ssh $DEMO_USER@$DEMO_HOST
}

short-pause() {
    sleep $SHORT_PAUSE
}

mid-pause() {
    sleep $MID_PAUSE
}

long-pause() {
    sleep $LONG_PAUSE
}

main() {
    send-command "$(ssh-login)"
    short-pause

    # show node info
    show-comment "We have a single node cluster set up with recent versions of"
    show-comment "Kubernetes and CRI-O."
    short-pause
    send-command "kubectl get nodes"
    short-pause
    send-command "kubectl version --short"
    short-pause
    send-command "crictl version"
    mid-pause

    # show CRI-O configuration
    show-comment "NRI is already enabled in the CRI-O configuration."
    send-command "crio config | tr -s '\t ' | grep -v '^$' | grep -A 14 'crio.nri'"
    mid-pause
    send-command "ls -ls /var/run/nri/nri.sock"
    mid-pause

    # clone and compile NRI repo to get the sample device-injector plugin
    show-comment "Let's clone and compile the sample NRI device injector plugin..."
    short-pause
    send-command "rm -rf demo/nri"
    send-command "mkdir -p demo"
    send-command "cd demo"
    send-command "git clone https://github.com/containerd/nri"
    long-pause
    send-command "cd nri"
    send-command "make"
    long-pause
    send-command "ls -ls build/bin"
    short-pause

    # create another pane to start the device-injector plugin
    split-vertical
    pane=1 send-command "$(ssh-login)"
    short-pause
    pane=1 send-command "~/demo/nri/build/bin/device-injector -idx 10"
    mid-pause

    # create in first pane create a simple pod with annotated devices
    pane=0 show-comment "We have a simple pod spec with annotated devices."
    show-comment "Let's see the annotations."
    short-pause
    send-command "head -35 ~/demo/pod-specs/device-demo.yaml"
    long-pause
    show-comment "Let's create the pod and check if our devices get injected."
    mid-pause
    send-command "kubectl apply -f ~/demo/pod-specs/device-demo.yaml"
    mid-pause
    send-command "kubectl exec -c c0 device-demo -- ls -ls /dev/ | grep nri"
    short-pause
    send-command "kubectl exec -c c1 device-demo -- ls -ls /dev/ | grep nri"
    short-pause
    send-command "kubectl exec -c c2 device-demo -- ls -ls /dev/ | grep nri"
    long-pause

    send-command "kubectl delete -f ~/demo/pod-specs/device-demo.yaml"
    mid-pause
    show-comment "That was all. Thank you for watching this demo."
    mid-pause

    pane=1 send-command exit
    pane=1 kill-pane

    pane=0 send-command exit
    return 0
}

main

