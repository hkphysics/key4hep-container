# key4hep-container

This is builds a container for the key4hep project.  https://github.com/key4hep/key4hep-spack/

Please contact joequant@bitquant.com.hk

To view continuous integration of key4hep-stack please go to http://dev1.bitquant.com.hk:8011/

To subscribe to the list of build breaks go to https://github.com/joequant/key4hep-container/issues/1

The buildbot server will automatically add a comment when the build breaks.

This makes heavy use of the compiler caching server - http://github.com/joequant/cacher/

To be notified of build breaks, add yourself to issue #1

to run

  docker run -ti -u user -v key4hep-container_home:/home -v key4hep-container_opt:/opt joequant/key4hep-container /bin/bash

This will also work on podman

  podman run -ti -u user --group-add wheel --group-add spack -v key4hep-container_home:/home -v key4hep-container_opt:/opt joequant/key4hep-container /bin/bash

This will give you a shell with user user.  Spack will be saved in /opt/spack

To build the k4 stack from a bare container

    spack install key4kep-spack

This container also works with joequant/cacher which will cache downloads
and builds.


