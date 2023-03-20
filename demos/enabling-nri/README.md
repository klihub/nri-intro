# Enabling NRI in the runtime

NRI is an experimental feature. It is disabled by default in the runtimes.
You need to enable NRI in the runtimes configuration before you can use it.

### Containerd

```bash
# Save original configuration.
cp /etc/containerd/config.toml /etc/containerd/config.toml.orig
containerd config dump > /etc/containerd/config.toml
# Update the configuration section [plugins."io.containerd.nri.v1.nri"]
# changing disable = true to disable = false
# The updated NRI section should look something like this:
grep -A 4 v1.nri /etc/containerd/config.toml
  [plugins."io.containerd.nri.v1.nri"]
    config_file = "/etc/nri/nri.conf"
    disable = false
    plugin_path = "/opt/nri/plugins"
    socket_path = "/var/run/nri.sock"
# Restart containerd.
systemctl restart containerd
```

### CRI-O

```bash
# Save original configuration and enable NRI.
cp /etc/crio/crio.conf /etc/crio/crio.conf.orig
crio --config /etc/crio/crio.conf.orig --enable-nri config > /etc/crio/crio.conf
# The updated NRI section should look something like this:
grep -v '^$' /etc/crio/crio.conf | grep -A 5 'NRI config'
# CRI-O NRI configuration.
[crio.nri]
# Globally enable or disable NRI.
enable_nri = true
# NRI configuration file to use.
# nri_config_file = "/etc/nri/nri.conf"
# NRI socket to listen on.
# nri_listen = "/var/run/nri.sock"
# NRI plugin directory to use.
# nri_plugin_dir = "/opt/nri/plugins"
# Restart cri-o.
systemctl restart crio
```

### Verifying NRI Is Enabled

In addition to checking the runtime logs, you can verify NRI is enabled
by checking if the NRI unix-domain socket is present in the filesystem.
The default path for this socket is `/var/run/nri.sock`.

```bash
[ -S /var/run/nri/nri.sock ] && echo "NRI is enabled" || echo "NRI is disabled"
```

You can use the sample template plugin to verify that NRI is really functional.
To do so, clone the NRI repository, compile the sample plugins, then launch
the template plugin:

```bash
git clone https://github.com/containerd/nri
cd nri
# Note that you need a recent go compiler toolchain installed...
make
./build/bin/template -idx 50
[root@nri-ctrd testing]# ./bin/template -idx 50
INFO   [0000] Created plugin 50-template (template, handles RunPodSandbox,StopPodSandbox,RemovePodSandbox,CreateContainer,PostCreateContainer,StartContainer,PostStartContainer,UpdateContainer,PostUpdateContainer,StopContainer,RemoveContainer)
INFO   [0000] Registering plugin 50-template...                                                    
INFO   [0000] Configuring plugin 50-template for runtime containerd/v1.7.0-beta.3-57-g40dfdee84... 
INFO   [0000] Connected to containerd/v1.7.0-beta.3-57-g40dfdee84...                               
INFO   [0000] Subscribing plugin 50-template (template) for events RunPodSandbox,StopPodSandbox,RemovePodSandbox,CreateContainer,PostCreateContainer,StartContainer,PostStartContainer,UpdateContainer,PostUpdateContainer,StopContainer,RemoveContainer
INFO   [0000] Started plugin 50-template...                                                       
```

Now if you create a pod with some containers you should see related NRI pod and
container lifecycle events being reported by the plugin.

```bash
cd nri-intro/demos/enabling-nri
kubectl apply -f pods/test.yaml
INFO   [2291] Started pod default/test...
INFO   [2291] Creating container default/test/init-c0...
INFO   [2291] Created container default/test/init-c0...
INFO   [2291] Starting container default/test/init-c0...
INFO   [2292] Started container default/test/init-c0...
INFO   [2292] Stopped container default/test/init-c0...
INFO   [2294] Creating container default/test/c0...
INFO   [2294] Created container default/test/c0...
INFO   [2295] Starting container default/test/c0...
INFO   [2295] Started container default/test/c0...
$ kubectl delete -f pods/test.yaml
INFO   [2298] Stopped container default/test/c0...
INFO   [2299] Stopped pod default/test...
INFO   [2300] Removed container default/test/c0...
INFO   [2300] Removed container default/test/init-c0...
INFO   [2319] Removed container default/test/c0-shared...
INFO   [2319] Removed container default/test/init-c0-shared...
INFO   [2320] Removed container default/test/c1-exclusive...
INFO   [2320] Removed pod default/test...
```
