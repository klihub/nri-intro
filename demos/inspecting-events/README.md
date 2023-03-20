## Inpecting the NRI Protocol

Here is an [asciinema recording](https://asciinema.org/a/568672)
of this demo.

### Logger Plugin

You can use the sample logger plugin to take a look at what NRI events
and requests NRI generates and to see what data is associated with pods
and containers. Clone the NRI repository, compile the sample plugins,
then start the logger plugin.

```bash
git clone https://github.com/containerd/nri
cd nri
# Note that you need a recent go compiler toolchain installed...
make
./build/bin/logger -idx 10
info msg="Created plugin 50-logger (logger, handles RunPodSandbox,StopPodSandbox,RemovePodSandbox,CreateContainer,PostCreateContainer,StartContainer,PostStartContainer,UpdateContainer,PostUpdateContainer,StopContainer,RemoveContainer)"
info msg="Registering plugin 50-logger..."
info msg="Configuring plugin 50-logger for runtime containerd/v1.7.0-beta.3-57-g40dfdee84..."
info msg="got configuration data: \"\" from runtime containerd v1.7.0-beta.3-57-g40dfdee84"
info msg="Subscribing plugin 50-logger (logger) for events RunPodSandbox,StopPodSandbox,RemovePodSandbox,CreateContainer,PostCreateContainer,StartContainer,PostStartContainer,UpdateContainer,PostUpdateContainer,StopContainer,RemoveContainer"
info msg="Started plugin 50-logger..."
info msg="Synchronize: pods:"
info msg="Synchronize:    - annotations:"
info msg="Synchronize:        kubernetes.io/config.seen: \"2023-02-11T13:27:44.820352958Z\""
info msg="Synchronize:        kubernetes.io/config.source: api"
info msg="Synchronize:      id: d955e69acf303c971e1338a28926f396c60342b8f03f4fb63b087c9601e3d6c3"
info msg="Synchronize:      labels:"
info msg="Synchronize:        io.cri-containerd.kind: sandbox"
info msg="Synchronize:        io.kubernetes.pod.name: coredns-787d4
...
```

Now create and remove a pod in another terminal to generate some events...

```bash
cd nri-intro/demos/inspecting-events
kubectl apply -f pods/test.yaml && sleep 5 && kubectl delete -f pods/test.yaml
```

Now check the logs produced by the logger plugin...

```bash
# You should see the full pod and container lifecycle events...
time="2023-02-15T13:36:57Z" level=info msg="RunPodSandbox: pod:"
time="2023-02-15T13:36:57Z" level=info msg="RunPodSandbox:    annotations:"
time="2023-02-15T13:36:57Z" level=info msg="RunPodSandbox:      io.kubernetes.cri.container-type: sandbox"
time="2023-02-15T13:36:57Z" level=info msg="RunPodSandbox:      io.kubernetes.cri.sandbox-cpu-period:
...
time="2023-02-15T13:36:57Z" level=info msg="CreateContainer: pod:"
time="2023-02-15T13:36:57Z" level=info msg="CreateContainer:    annotations:"
time="2023-02-15T13:36:57Z" level=info msg="CreateContainer:      io.kubernetes.cri.container-type: sandbox"
time="2023-02-15T13:36:57Z" level=info msg="CreateContainer:      io.kubernetes.cri.sandbox-cpu-period: \"100000\""
time="2023-02-15T13:36:57Z" level=info msg="CreateContainer:      io.kubernetes.cri.sandbox-cpu-quota: \"10000\""
...
time="2023-02-15T13:37:00Z" level=info msg="PostCreateContainer: pod:"
time="2023-02-15T13:37:00Z" level=info msg="PostCreateContainer:    annotations:"
time="2023-02-15T13:37:00Z" level=info msg="PostCreateContainer:      io.kubernetes.cri.container-type: sandbox"
...
time="2023-02-15T13:36:58Z" level=info msg="StartContainer: pod:"
time="2023-02-15T13:36:58Z" level=info msg="StartContainer:    annotations:"
time="2023-02-15T13:36:58Z" level=info msg="StartContainer:      io.kubernetes.cri.container-type: sandbox"
time="2023-02-15T13:36:58Z" level=info msg="StartContainer:      io.kubernetes.cri.sandbox-cpu-period...
time="2023-02-15T13:37:00Z" level=info msg="PostStartContainer: pod:"
time="2023-02-15T13:37:00Z" level=info msg="PostStartContainer:    annotations:"
time="2023-02-15T13:37:00Z" level=info msg="PostStartContainer:      io.kubernetes.cri.container-type: sandbox"
...
time="2023-02-15T13:37:06Z" level=info msg="StopContainer: pod:"
time="2023-02-15T13:37:06Z" level=info msg="StopContainer:    annotations:"
time="2023-02-15T13:37:06Z" level=info msg="StopContainer:      io.kubernetes.cri.container-type: sandbox"
...
time="2023-02-15T13:37:16Z" level=info msg="RemoveContainer: pod:"
time="2023-02-15T13:37:16Z" level=info msg="RemoveContainer:    annotations:"
time="2023-02-15T13:37:16Z" level=info msg="RemoveContainer:      kubectl.kubernetes.io/last-applied-configuration: |"
time="2023-02-15T13:37:16Z" level=info msg="RemoveContainer:        {\"apiVersion\":\"v1\",\"kind\":\
...
time="2023-02-15T13:37:16Z" level=info msg="RemovePodSandbox: pod:"
time="2023-02-15T13:37:16Z" level=info msg="RemovePodSandbox:    annotations:"
time="2023-02-15T13:37:16Z" level=info msg="RemovePodSandbox:      kubectl.kubernetes.io/last-applied-configuration: |"
time="2023-02-15T13:37:16Z" level=info msg="RemovePodSandbox:        {\"apiVersion\":\"v1\",\"kind\":
```

The logger plugin registers to all lifecycle events and prints all messages
it receives. The data dump you see is the full protocol content on the input
side. It contains all the data the plugin receives to track the state of pods
and containers and to decide whether and how to alter or update containers.

