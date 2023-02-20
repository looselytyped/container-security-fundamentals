#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  echo "Loading Aliases"
  alias v="vagrant" \
    && alias upV1="VAGRANT_VAGRANTFILE=Vagrantfile.Ubuntu-2010 vagrant up" \
    && alias upV2="vagrant up" \
    && alias ss="vagrant ssh" \
    && alias su="vagrant suspend" \
    && alias d="vagrant destroy" \
    && alias df="vagrant destroy -f" \
  && code .
else
  echo "You need to source this script ... Please try 'source setup.sh'."
fi
