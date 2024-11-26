#!/bin/bash -v
# SPDX-License-Identifier: LGPL-3.0-or-later
# This script takes the volume and creates an unified image and then copies it
# from podman to docker

podman rm key4hep_target
podman rm key4hep_base
podman create --name key4hep_target -u user --group-add wheel --group-add spack localhost/joequant/key4hep-container
podman create --name key4hep_base -u user --group-add wheel --group-add spack -v key4hep-container_home:/home -v key4hep-container_opt:/opt/spack/opt  localhost/joequant/key4hep-container
podman cp key4hep_base:/home key4hep_target:/home
podman cp key4hep_base:/opt/spack/opt key4hep_target:/opt/spack/opt
podman commit key4hep_target localhost/joequant/key4hep-image
skopeo copy containers-storage:localhost/joequant/key4hep-image docker-daemon:joequant/key4hep-image:latest





