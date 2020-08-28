#!/bin/bash
source /usr/sbin/proxy.sh
spack install -v key4hep-stack
if [ -f /home/user/.spack/linux/compilers.yaml.noproxy ] ; then
pushd /home/user/.spack/linux
cp -f compilers.yaml.noproxy compilers.yaml
popd
fi
