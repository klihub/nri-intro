## Annotated Device Injection

There occasionally cases where one need a quick hack to overcome
temporarily but quickly some unforeseen problems. NRI might come
handy in some of those situation. The device injector NRI plugin
was inspired by some similar functionality spotted while reading
the CRI-O code. It is perhaps an adequate example to demonstrate
the idea.

### Annotation Syntax

Using the device injector plugin, devices can be annotated using
the `devices.nri.io/$CONTAINER_NAME` or `devices.nri.io/pod` key.
The former annotates a device to be injected into one container.
The latter annotates injection for all containers within the pod.

The format of the annotation is

```
- path: device #1 path
  type: {c|b}
  major: major device number
  minor: minor device number
  file_mode: device node fs permissions
  uid: device node user ID
  gid: device node group ID
- path: device #2 path
  ...
```

Clone, compile and start the sample device injector plugin.

```bash
$ git clone https://github.com/containerd/nri
$ cd nri
$ # Note that you need a recent go compiler toolchain installed...
$ make
$ ./build/bin/device-injector -idx 10
```

Create an pod with per-container device annotations using the sample
pods spec.

```bash
$ head -35 nri-intro/demos/device-injection/pods/device-demo.yaml
...
apiVersion: v1
kind: Pod
metadata:
  name: device-demo
  annotations:
    devices.nri.io/container.c0: |+
      - path: /dev/nri-null
        type: c
        major: 1
        minor: 3
    devices.nri.io/container.c1: |+
      - path: /dev/nri-zero
        type: c
        major: 1
        minor: 5
    devices.nri.io/container.c2: |+
      - path: /dev/nri-null
        type: c
        major: 1
        minor: 3
      - path: /dev/nri-zero
        type: c
        major: 1
        minor: 5
spec:
  containers:
  - name: c0
    image: busybox
$ kubectl apply -f nri-intro/demos/device-injection/pods/device-demo.yaml
```

Now verify that the devices were properly injected into the right containers.

```bash
$ kubectl exec -c c0 device-demo -- ls -ls /dev/ | grep nri
     0 crw-rw-rw-    1 root     root        1,   3 Feb 15 16:49 nri-null
$ kubectl exec -c c1 device-demo -- ls -ls /dev/ | grep nri
     0 crw-rw-rw-    1 root     root        1,   5 Feb 15 16:49 nri-zero
$ kubectl exec -c c2 device-demo -- ls -ls /dev/ | grep nri
     0 crw-rw-rw-    1 root     root        1,   3 Feb 15 16:49 nri-null
     0 crw-rw-rw-    1 root     root        1,   5 Feb 15 16:49 nri-zero
```
