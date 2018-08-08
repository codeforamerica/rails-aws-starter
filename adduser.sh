#!/usr/bin/env bash

USERNAME_1='christa'
KEY_1="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC48vIIsaT5wXN/B6hg80STCTEGv8x4eMOnhGCKTRCa57u0TTergNIapZqu3+3l1OPjy0NuyruPn1zUWeSqnOjiFpvCZxMbcr9GkXTzGokb9w3yCFoRRjycQCSXzh8myc+Ln2cSf91wgC0mzDIT9tQT1zyXitgYgmPO2uKyCHvzMMTnQrTZEJgWKWP9FqDpJBMHuOzUa/dLUqHPYPNg173jDi3eNCz6mZ7rJRWJY66rpSARohtU2iPMepZRPQfZeLAeLyUSf6ASqwP18fNBrErh0eL6eMioAtKM+RaS9fxzzSaznWHhYOsPyu1qPaJoPvy/nBbEStzzaxJdTjThZDhb"

function set_up_user() {
  USERNAME=$1
  KEY=$2

  if ! id -u ${USERNAME}
  then
    echo "setting up $USERNAME"
    sudo adduser ${USERNAME}
    sudo su - ${USERNAME} <<COMMAND
      mkdir .ssh
      chmod 700 .ssh
      touch .ssh/authorized_keys
      chmod 600 .ssh/authorized_keys
      echo ${KEY} >> .ssh/authorized_keys
COMMAND
  fi
}

set_up_user ${USERNAME_1} "${KEY_1}"
