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


