# key4hep-container

to run

  docker run -ti -u user -v key4hep-container_home:/home -v key4hep-container_opt:/opt joequant/key4hep-container /bin/bash

This will also work on podman

This will give you a shell with user user.  Spack will be saved in /opt/spack

To build the k4 stack

    spack install key4kep-spack

