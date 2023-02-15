### OCI Hook Injection for Containerd

Containerd does not have native OCI hook injection support. By enabling
NRI and using the sample NRI OCI hook injector plugin you can plug in
OCI hook support to containerd.

```bash
$ git clone https://github.com/containerd/nri
$ cd nri
$ # Note that you need a recent go compiler toolchain installed...
$ make
$ # Put the sample hook script and configuration in place.
$ mkdir -p /etc/containers/oci/hooks.d
$ cp ../nri-intro/demos/oci-hooks/etc/containers/oci/hooks.d/* /etc/containers/oci/hooks.d
$ mkdir -p /usr/local/sbin
$ cp ../nri-intro/demos/oci-hooks/usr/local/sbin/demo-hook.sh /usr/local/sbin
$ # Pre-create the demo hook log an watch its content...
$ touch /tmp/demo-hook.log && tail -f /tmp/demo-hook.log
$ # In another terminal start the hook injector plugin
$ ./build/bin/hook-injector -idx 10
$ # In another terminal create the sample pod and examine the injector and hook logs
$ kubectl apply -f pods/hook-demo.yaml
$ ./bin/hook-injector -idx 10
INFO   [0000] Created plugin 10-hook-injector (hook-injector, handles CreateContainer)
INFO   [0000] Registering plugin 10-hook-injector...
INFO   [0000] Configuring plugin 10-hook-injector for runtime containerd/v1.7.0-beta.3-57-g40dfdee84..
INFO   [0000] Started plugin 10-hook-injector...
INFO   [0011] hook-demo/shell: OCI hooks injected
INFO   [0011] hook-demo/busybox: OCI hooks injected
INFO   [0109] hook-demo/shell: OCI hooks injected
INFO   [0110] hook-demo/busybox: OCI hooks injected
$ cat /tmp/hook-demo.log
========== [pid 14312] Wed Feb 15 15:02:21 UTC 2023 ==========
command: /usr/local/sbin/demo-hook.sh hook is always injected
environment:
    PWD=/run/containerd/io.containerd.runtime.v2.task/k8s.io/ffb4d827fca3213d8229bec00a2df5621579fb8e0bf25480b893c3a2bdc9393d
    DEMO_HOOK_ALWAYS_INJECTED=true
    SHLVL=0
    _=/usr/bin/env
========== [pid 14381] Wed Feb 15 15:02:21 UTC 2023 ==========
command: /usr/local/sbin/demo-hook.sh hook is always injected
environment:
    PWD=/run/containerd/io.containerd.runtime.v2.task/k8s.io/e5a0ff3c49f2a8c25b50da2ab5d4ba29db819541adc750e247c6068e17f8141f
    DEMO_HOOK_ALWAYS_INJECTED=true
    SHLVL=0
    _=/usr/bin/env
========== [pid 14386] Wed Feb 15 15:02:21 UTC 2023 ==========
command: /usr/local/sbin/demo-hook.sh is injected into busybox
environment:
    PWD=/run/containerd/io.containerd.runtime.v2.task/k8s.io/e5a0ff3c49f2a8c25b50da2ab5d4ba29db819541adc750e247c6068e17f8141f
    SHLVL=0
    DEMO_HOOK_ARGV0=busybox
    DEMO_HOOK_BUSYBOX_INJECTED=true
    _=/usr/bin/env
```