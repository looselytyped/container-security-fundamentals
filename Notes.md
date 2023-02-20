# Container Security

## Discussion: What does a container look like from the host?

```bash
# on the host make sure no sleep process is running
ps -C sleep
# start a alpine:3.17 container
docker container run  --rm --name demo alpine:3.17 sleep 1000 &
# check PID of sleep process within container
docker container exec demo ps eaf
# back on the host, do you now see a sleep process?
ps -C sleep
# note the PID
```

## Exercise: What does a container look like from the host?

```bash
#
```


## Discussion: Investigating how `cgroups` V1 looks

Looking around the `cgroups` filesystem.

```bash
# Start a Ubuntu 2010 VM with
VAGRANT_VAGRANTFILE=Vagrantfile.Ubuntu-2010 vagrant up
```

```bash
sudo su;
cd /sys/fs/cgroup;
ls;
cd memory;
ls;
```

To find what cgroups _any_ process is a member of:

```bash
# print out the pid
echo $$;
# look under /proc/<PID>/cgroup;
cat /proc/$$/cgroup;
```

Notice how the current process is under the _relative_ path to the `cgroup` mount point under the corresponding controllers—for example, `memory` and `pids` (for e.g `10:memory:/user.slice/user-1000.slice/session-6.scope`), delimited by `:/`.

### Discussion: Constraining PIDs

Let's see what the `pids` `cgroup` looks like:

```bash
cd /sys/fs/cgroup/pids;
ls user.slice/user-1000.slice/session-6.scope;
# Notice the `tasks` file which lists the processes under this cgroup
# You should spot your current PID in that list
cat user.slice/user-1000.slice/session-6.scope/tasks;
# how many pids are we allowed?
cat user.slice/user-1000.slice/session-6.scope/pids.max
# `max` means unlimited
```

So what can we do here?
Well, we can _manually_ create a `cgroup` by simply creating a new folder under `pids`:

```bash
mkdir /sys/fs/cgroup/pids/pid-demo
# the OS automatically populates this with a certain set of files
ls /sys/fs/cgroup/pids/pid-demo;
# notice the tasks file is empty
cat /sys/fs/cgroup/pids/pid-demo/tasks
```

And now, let's make the current process a part of this new `cgroup`:

```bash
echo $$ | tee /sys/fs/cgroup/pids/pid-demo/tasks
# and make sure it worked
cat /proc/$$/cgroup;
# notice the pids cgroup now says :/pid-demo
```

Sub-processes under the current process are automatically in the same cgroup as the parent process.
Let's see that:

```bash
# list the process list of the current user as a ascii tree
ps f
# start a bunch of processes
for j in $(seq 1 5); do sleep 10 & done
# and QUICKLY list again
ps f;
# start a bunch of processes
for j in $(seq 1 5); do sleep 10 & done
# QUICKLY list processes in new cgroup (there will be one more since cat also gets listed)
cat /sys/fs/cgroup/pids/pid-demo/tasks;
```

Now let's add some limitations:

```bash
# this is currently unlimited
cat /sys/fs/cgroup/pids/pid-demo/pids.max
# cap it
echo 2 | tee /sys/fs/cgroup/pids/pid-demo/pids.max
# lets make sure it worked
cat /sys/fs/cgroup/pids/pid-demo/pids.max
# now try running more than 2 processes
for j in $(seq 1 5); do sleep 10 & done
# and now this shell is hosed!

# open another terminal via SSH into the VM so you can continue
```

### Discussion: Constraining CPUs and controlling cgroups programatically

```bash
sudo su
# cgcreate is a utility to create control groups
cgcreate -g cpu:groupA
cgcreate -g cpu:groupB

# cgget can be used to interrogate cgroups (both will be 1024)
cgget -r cpu.shares groupA
cgget -r cpu.shares groupB

# spin up two processes that hog the CPU, one in each group (we have a 2-cpu VM)
cgexec -g cpu:groupA stress-ng -c 2 &
cgexec -g cpu:groupB stress-ng -c 2 &

# make sure they are running as you'd expect
top

# now constrain the CPU shares for both of them using cgset
cgset -r cpu.shares=768 groupA
cgset -r cpu.shares=256 groupB

# make sure the cgroups constraint the process as you'd expect
top

# kill all stress-ng processes
killall stress-ng-cpu
```

### Exercise: Constraining memory

```bash
sudo su
# start a process that is a member of the exercise cgroup and stresses the memory
stress-ng --vm 1 --vm-bytes 75% --vm-method all --verify &
# see if its running. GRAB the PID!!!
top;
# kill it
kill <PID>

# let's create a cgroup to constrain the memory
cgcreate -g memory:exercise
# see what the max memory limit (this is all the memory on the VM)
cgget -r memory.limit_in_bytes exercise
# now constrain the memory using cgset
cgset -r memory.limit_in_bytes=500000 exercise
cgset -r memory.swappiness=0 exercise
# check to see if it stuck
cgget -r memory.limit_in_bytes exercise
cgget -r memory.swappiness exercise

# start the stressor again
cgexec -g memory:exercise stress-ng  --vm 1 --vm-bytes 75% --vm-method all --verify &

# do you see it in top?
top
```

### Discussion: How does Docker use cgroups?

```bash
# start a container constraining it's MEMORY
docker container run --rm --memory 100M -d --name demo alpine:3.17 sleep 10000
# inspect /sys/fs/cgroup/memory/docker <- NOTICE WE ARE UNDER THE MEMORY CGROUP
ls /sys/fs/cgroup/memory/docker/
# you'll see the name of the container as a nested hierarchy within this folder
# cat limit_in_bytes
cat /sys/fs/cgroup/memory/docker/<container-id>/memory.limit_in_bytes

# what does it look from _inside_ the container
docker container exec -it demo sh
# inside the container the memory is set at the root hierarchy
cat /sys/fs/cgroup/memory/memory.limit_in_bytes
```

### Exercise: How does Docker use cgroups?

```bash
# start a container constraining CPU SHARES
docker container run --rm --cpu-shares 512 -d --name demo alpine:3.17 sleep 10000
# Can you figure out where to go looking for the correct cgroup?
# HINT: You are constraining the cpu so look for that cgroup under /sys/fs/cgroup

# What does it look like from inside the container?
# use docker container exec -it demo sh and look for cpu/cpu.shares at the root hierarchy
```

## Discussion: Investigating how `cgroups` V2 looks

The biggest difference is that in `cgroups` `v2` you can't have a process join `memory/group1` and `cpu,cpuacct/group2`.
Most tools, including Docker have migrated over to using `cgroups` V2, but there still remains some legacy tooling that requires V1.

### Discussion: Looking at Docker using cgroups V2

```bash
# Start a Ubuntu 2010 VM with
vagrant up
```

```bash
sudo su
docker container run --rm --memory 100M -d alpine:3.17 sleep 10000
# find the controller on the host
find . -name "*docker*"
# look inside the system.slice/docker-<container-id>
cat memory.max
```

### Exercise: Looking at Docker using cgroups V2

```bash
sudo su
docker container run --rm --memory 100M -d alpine:3.17 sleep 10000
# find the controller
find . -name "*docker*"
# look inside the system.slice/docker-<container-id>
cat memory.max
```

## Discussion: Investigating namespaces

Namespaces help in controlling visibility.
Namespaces can make it appear to a process that it has it's own copy of an isolated resource.
To isolate namespaces, one Linux system call is `unshare` (there are others like `clone` and `setns`).

```bash
# list all namespaces
lsns
```

### Discussion: Isolating UNIX Time-sharing System

```bash
# docker containers have their own hostname
docker container run --rm --name demo alpine:3.17 hostname

# so how does this work?
# as root
hostname;
# process with isolated uts namespace
unshare --uts sh
# inherits hostname from parent process
hostname;
# set a new one
hostname demo;
# hostname is now changed
# on the host the hostname is unchanged
hostname
```

### Discussion: Isolating networks

```bash
# list network interfaces
ip link
# use unshare to create
unshare --net bash
# now list network interfaces
ip link
exit
```

### Discussion: Isolating users

```bash
# be sure to Ctrl-d so you are NO LONGER ROOT and become the vagrant user
# YOU DO NOT NEED TO BE SUDO TO CREATE USER NS
# list user details
id
# use unshare to create
unshare --user bash
# now list user details
id
exit
```

### Exercise: Isolating networks and users

```bash
# on the host list interfaces
ip link
# create a process with an isolated network namespace
# see what this offers
ip link
# exit out of it

# BE SURE TO FIRST CTRL-d so you are the vagrant user if you are not already
# create a process with an isolated network namespace
# see user details
id
exit
```

### Discussion: Mapping users

```bash
# be sure to Ctrl-d so you are NO LONGER ROOT and become the vagrant user
# lets combine unsharing network and user
# be suer to be the vagrant user
unshare --net --user bash
# see only loopback
ip link
# see user details
id
# try creating a new interface
ip link add type veth
# womp womp! You are nobody and you need to be root
# find the process ID
echo $$

## in a different terminal, where you are root
echo "0 1000 1" > /proc/<PID>/uid_map

## back in the other terminal
## now you are root
id
# you can now add a network interface
ip link add type veth
exit
```

There was no process escalation here!
`0 1000 1` means that UID `0` in the child process is mapped to UID `1000` on the host (and we are adding just one UID).

```asciiflow
   ┌─────────────┐
   │   H O S T   │
   ├─────────────┤
   │             │
   │ 1           │
   │             │
   │ 2           │
   │             │      ┌────────────────────────────────┐
   │ ...         │      │   C H I L D    P R O C E S S   │
   │             │      ├────────────────────────────────┤
   │ 1000 ───────┼──────┼─► 1                            │
   │             │      │                                │
   │ 1001        │      │   2                            │
   │             │      │                                │
   └─────────────┘      └────────────────────────────────┘
```

### Exercise: Mapping users

```bash
# BE SURE TO BE THE VAGRANT USER
ip link
id
# create a process with it's own network and user namespace
# check network interfaces and user/group ID
ip link
id
# see if you can now add a network interface
ip link add type veth
# fix this by mapping the current user in the current process to 0 under /proc/<PID>/uid_map IN ANOTHER TERMINAL WHERE YOU ARE ROOT!

# did it work?
id
# then try adding a new interface again
ip link add type veth
# list it
ip link
```

### Discussion: Mapping users (continued)

Note that the `group` is still wrong, and we can always supply `deny` to `/proc/<PID>/gid_map`.
**Or** we can do this:

```bash
# as vagrant user
unshare --map-root-user --net bash
# you are root
id
# find process ID
$$
# IN ANOTHER TERMINAL
cat /proc/<PID>/uid_map
cat /proc/<PID>/gid_map
```

### Discussion: Isolating PIDs

```bash
# list processes on the host
ps -eaf
# a container only sees the processes running inside the container
docker container run --rm --name demo alpine:3.17 ps -eaf
```

Can we replicate this?

```bash
# doesn't quite work
unshare --pid sh
# what it's PID? ... Hmm
echo $$
# this works
whoami
# now it won't work
whoami
exit
```

We have to `--fork` the process so that the new process is a child of `unshare`

```bash
unshare --pid --fork sh
# it's PID 1
echo $$
# now it works
whoami
# and again
whoami
# till it doesn't—this will list ALL processes!
ps -eaf
exit
```

### Exercise: Isolating PIDs

```bash
# start a new process with an isolated PID namespace
# be sure to "fork" it

# list processes using ps -eaf
# exit out of it
```

The issue here is that `ps` is reading `/proc`, on the host.
We can work around this by giving this process it's own `/proc` directory.
Let's do that!

## Discussion: `chroot`

```bash
# become root and switch to the home directory
cd
# from within a container you only see the containers filesystem
ls
# a container only sees the processes running inside the container
docker container run --rm --name demo alpine:3.17 ls
# lists the alpine fs
```

Can we make this happen with some Linux primitive trickery?

```bash
# be root!
mkdir some-dir
chroot some-dir
# GAH!
```

`chroot` means "Run COMMAND with root directory set to NEWROOT."
By default, `chroot` runs `bash`, which given that the "root" directory for this process is empty, can't be found!
Let's fix that.

```bash
# be root
mkdir alpine
cd alpine
curl -o alpine.tar.gz http://dl-cdn.alpinelinux.org/alpine/v3.17/releases/x86_64/alpine-minirootfs-3.17.0-x86_64.tar.gz
tar xvf alpine.tar.gz
rm alpine.tar.gz
```

Now that we have a usable filesystem, let's try `chroot` again:

```bash
# be root, else sudo
# in the alpine directory
# change root to current directory and list files
chroot . ls
# how about a sh?
chroot . sh
# can we get back?
chroot . bash
# womp womp! Alpine does not ship with bash!
chroot . ps eaf
# Uh oh!
```

The issue here is that while there is a `/proc` folder independent of the host, it needs to be populated correctly, so we have to mount it as a pseudofilesystem.

```bash

```bash
# in alpine directory as root
unshare --pid --fork \
  --mount --mount-proc \
  chroot . sh -c "mount -t proc proc /proc && sh"
# list processes
ps eaf
# yes!
# inspect /proc
ls /proc
# Oh yeah!
exit
```

## Exercise: `chroot`

```bash
# as root!
# go to some directory, say home
# make an alpine directory and cd into it
# get the alpine fs
curl -o alpine.tar.gz http://dl-cdn.alpinelinux.org/alpine/v3.17/releases/x86_64/alpine-minirootfs-3.17.0-x86_64.tar.gz
tar xvf alpine.tar.gz
rm alpine.tar.gz
# use the snippet above to start a `sh` process
# - with it's own PID namespace
# - chroot-ing the current directory as it's root directory
# don't forget to mount the proc directory
```

## Discussion: Altogether now! Let's combine namespacing and `chroot`.

```bash
# as root, IN alpine directory
# first create cpu/memory cgroups
cgcreate -g cpu,cpuacct,memory:docker-demo

# using the new cgroups, start an pid/user/net namespaced process
# - create a PID ns and be sure to fork
# - create a net ns
# - isolate the uts
# - create a user ns and ensure uid/gid map correctly
# - change root to current directory
# Finally,
# - create a mount and mount-proc
# - set hostname to be unique
# - start a shell and mount /proc
cgexec -g cpu,cpuacct,memory:docker-demo \
unshare --pid --fork \
        --net \
        --uts \
        --user --map-root-user \
        --mount --mount-proc \
        chroot "$PWD" \
        sh -c "mount -t proc proc /proc && hostname my-very-own-container && sh"
###

# test it out
# do we have the right cgroups?
ls /sys/fs/cgroup/cpu,cpuacct/docker-demo/
ls /sys/fs/cgroup/memory/docker-demo/
# list networks
ip link
# show user info
id
# list processes
ps eaf
```

Woot!!!

## Exercise: Altogether now! Let's combine namespacing and `chroot`.

```bash
# as root
# use cgcreate to create new cgroups for cpu,cpuacct,memory called my-demo
# using cgexec to constraint the new process within "my-demo" cgroup
# use the snippet above to start a `sh` process
# - with it's own PID namespace (don't forget to "fork")
# - with it's own net namespace
# - and user namespace (don't forget to map the root user)
# - with a custom hostname
# - don't forget to chroot!
# with the proc pseudo fs mounted correctly

# test it out
# check cgroups directory for your newly created cgroups
# list network interfaces with ip link
# list user info with id
# list processes with ps eaf
# take a look at /proc
```

## Risk Mitigation

### Exercise: Using `FROM`

- Start with a Dockerfile (If you don't have one, then use Dockerfile in the repository you cloned)
- Build it without supplying a version — Inspect `docker image ls <image-name>` and ensure it has the `latest` tag
- Make a change to the Dockerfile and now build it with a version. Inspect `docker image ls <image-name>`

**Hints**

```bash
# build an image with "latest"
docker image build -t demo -f Dockerfile .
# build with a version
docker image build -t demo:1.1.1 -f Dockerfile .
```

### Discussion: Using `COPY`

```bash
# build an image that leaks secrets
docker image build -t bad-image -f Dockerfile.reveal.secrets .
# try it out
docker container run --rm --name demo bad-image ls /secrets.txt
# Seems to work ... except
docker image save bad-image > revealing-secrets.tar
mkdir revealing-secrets
cd revealing-secrets
tar -xf ../revealing-secrets.tar
ls
cat manifest.json | jq
tar -tvf dd9a47e48e9c5bec2e62dce8c6f23602cc517ed1d3d70327dbb2c18d4e583838/layer.tar
cd ..
docker image rm bad-image
rm -rf revealing-secrets
```

### Exercise: Using `COPY`

```bash
# - Inspect Dockerfile.reveal.secrets
# - Build a new image using Dockerfile.reveal.secrets
# - "save" it to create a new tar file
# - extract the tar into a new directory
# - see if you can find the layer with the secret file (manifest.json is your friend)
```

## Exercise: Multi-stage Dockerfiles

- Explore the `Dockerfile` in `multi-stage-build-demo`
- `docker pull amazoncorretto:19-alpine3.17` and inspect it's size
- Build the `multi-stage-build-demo` and inspect it's size
- Can you run it?

## Shifting Left

### Discussion: Using a linter for Dockerfile

```bash
docker container run --rm -i hadolint/hadolint < Jenkins-Dockerfile
```

### Discussion: Using an image scanner

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                -v $HOME/Library/Caches:/root/.cache/ \
                aquasec/trivy:latest \
                image python:3.4-alpine
```

### Exercise: Using a linter & image scanner

```bash
# lint the Jenkins-Dockerfile in this project
# Can you fix at least one of the issues listed?

# build an image using Dockerfile.reveal.secrets
# use trivy to inspect the newly constructed image.

# What do you see?
```

```bash
# scan python:3.4-alpine image using trivy

# can you figure out how to limit the severity to just "critical" ones?
```

## Securing the runtime

### Discussion: "docker from docker"

```bash
# on your workstation or in the VM
docker container ls
# launch a container with the docker socket mounted
docker run --rm -it --name d-from-d -v /var/run/docker.sock:/var/run/docker.sock ubuntu:22.04
# install docker in the container
apt update && apt install -y docker.io
# list containers — notice d-from-d is listed!
docker container ls
```
