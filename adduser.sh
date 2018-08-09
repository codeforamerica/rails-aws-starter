#!/usr/bin/env bash

USERNAME_1='christa'
KEY_1="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC48vIIsaT5wXN/B6hg80STCTEGv8x4eMOnhGCKTRCa57u0TTergNIapZqu3+3l1OPjy0NuyruPn1zUWeSqnOjiFpvCZxMbcr9GkXTzGokb9w3yCFoRRjycQCSXzh8myc+Ln2cSf91wgC0mzDIT9tQT1zyXitgYgmPO2uKyCHvzMMTnQrTZEJgWKWP9FqDpJBMHuOzUa/dLUqHPYPNg173jDi3eNCz6mZ7rJRWJY66rpSARohtU2iPMepZRPQfZeLAeLyUSf6ASqwP18fNBrErh0eL6eMioAtKM+RaS9fxzzSaznWHhYOsPyu1qPaJoPvy/nBbEStzzaxJdTjThZDhb"

USERNAME_2='whitney'
KEY_2="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCvNK8VFGVFzbtlhxO64TMUnxqMGTCPuMCayUDw6gTLg9xaW0vvA4l3NsgMVcaCcqETmi18ExJ8jZDlO4f1ryomKJJQ3mBMJnyHDhecMsNSfcGmK15eDuskztphvrboL2h5ThF88pUcd2ucghjyNN2luSVDUPeYV5ufpsBFJ7ZZiqXgaxwn0wkXAn8xEXF26kTOAYjL1qxTuVcvHkT/fbrBb24qR8O4lI4JCn3Ui5tvWjUJ5a4bh2uk0UGnsfIeuggjzCo0rpJyUReG1/gW253v5G4D3T40q2nkVyKMMQcsWjG8aOdEZgYEXCNrXpjhHTU2sMA49AIwmzo/CxJCP2my57upvdgwBV66c9CT9vuytTtEr8CgJYhqJ+1aJ0MUYXsLSif6Dv8Gg8SabBODontNCJRorc6bbWxDknsqYkDS3dq3aAAII+wFsBiMAMWQyd5vN5Q7PbivWsgBvcvVwgT6pp6Idy5wg28eth6hjiVFOl6OE61sGfdIKzj9ZXlF4dhr+AX4kf+pewgj5iAkA12Cd6/bUlQR/cSRnIVA0UqWt0UJpOWfudHnC2GJhhAZeStJfT1REGbqVKJy6hYrcoGfhQusexQHmSyVCUdjZMxJ1CQ/lRmarrlvyVkl+6HDAs2mWUBec19eNkmKne7qOhXAZ9PIdreZJ3SeRj2mFEheGQ== whitney@codeforamerica.org"

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
set_up_user ${USERNAME_2} "${KEY_2}"
