#!/bin/bash

#
# asciinema rec -t "Enabling NRI" \
#     -c "/bin/bash -c '(sleep 3; ./record.sh) & tmux new -s enabling-nri'" \
#     enabling-nri.cast
#

SESSION="${session:-enabling-nri}"
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
    show-comment "NRI is disabled by default in the CRI-O configuration."
    send-command "crio config | tr -s '\t ' | grep -v '^$' | grep -A 14 'crio.nri'"
    mid-pause

    # enable NRI
    show-comment "To enable NRI we can either edit the configuration file manually"
    show-comment "or use the --enable-nri command line option to update it."
    short-pause
    send-command "systemctl stop crio"
    send-command "crio config > /etc/crio/crio.conf.orig"
    send-command "crio --enable-nri config > /etc/crio/crio.conf"
    send-command "systemctl start crio"
    short-pause

    # show CRI-O configuration, NRI enabled
    show-comment "NRI should now be enabled."
    send-command "crio config | tr -s '\t ' | grep -v '^$' | grep -A 14 'crio.nri'"
    short-pause
    show-comment "We can check that the NRI socket is present at its default location."
    send-command "ls -ls /var/run/nri/nri.sock"
    send-command "[ -S /var/run/nri/nri.sock ] && echo 'NRI is enabled'"
    mid-pause

    # clone and compile NRI repo to get template plugin
    show-comment "Let's clone and compile the sample NRI template plugin, then use it"
    show-comment "to verify that it can register itself to NRI."
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

    # create another pane start template plugin
    split-vertical
    pane=1 send-command "$(ssh-login)"
    short-pause
    pane=1 send-command "~/demo/nri/build/bin/template -idx 10"
    mid-pause

    # create in first pane a simple pod, then remove it
    pane=0 show-comment "Finally let's check that the plugin receives pod and container"
    show-comment "lifecycle events if we create a pod then delete it."
    short-pause
    send-command "cat ~/demo/pod-specs/busybox.yaml"
    mid-pause
    send-command "kubectl apply -f ~/demo/pod-specs/busybox.yaml"
    long-pause
    send-command "kubectl delete -f ~/demo/pod-specs/busybox.yaml"
    long-pause

    show-comment "That was all. Thank you for watching this demo."
    mid-pause

    pane=1 send-command exit
    pane=1 kill-pane

    pane=0 send-command exit
    return 0
}

main

