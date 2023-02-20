# Container Security Fundamentals

## Highlights

- This **is a workshop**. Please come with a laptop that has the necessary installed software.
- Please follow **all of the installation instructions** in this document before coming to the workshop.
  Debugging Docker/Git installation takes time away from all attendees.

## Installation

You will need the following installed

- [Docker](https://www.docker.com/get-started/)
- [Git](https://git-scm.com/downloads)
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://developer.hashicorp.com/vagrant/downloads)

Optionally, a good text editor.
I highly recommend [VS Code](https://code.visualstudio.com/).

### Testing your installation

#### Testing Vagrant installation

```bash
❯ # cd to /path/where/you/cloned/this/repo
❯ VAGRANT_VAGRANTFILE=Vagrantfile.Ubuntu-2010 vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'generic/ubuntu2010'...
==> default: Matching MAC address for NAT networking...
...
❯ # now try SSH'ing into the VM
❯ vagrant ssh
# within the VM, try running a command
root@container-security:~# ls
# exit the console
root@container-security:~# exit
logout
vagrant@container-security:~$ exit
logout
❯ # shut down and throw away the VM
❯ vagrant destroy -f
```
#### Testing Docker installation

```bash
❯ docker version
# should print out some info
❯ docker container run hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

You are all set.
Woot!

See you all soon.
