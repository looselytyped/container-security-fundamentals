FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y \
  cgroup-tools \
  docker.io \
  runc \
  stress-ng \
  tree \
  && rm -rf /var/lib/apt/lists/*

# Set up root shell by default for interactive shells
RUN echo "sudo -i" >> /root/.bashrc
