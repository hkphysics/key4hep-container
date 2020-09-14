#!/bin/bash
source /usr/sbin/proxy.sh
spack install -j12 -v key4hep-stack
export DISTCC_HOSTS='172.17.0.1'
spack install -j12 -v bison
export DISTCC_HOSTS='172.17.0.1,cpp,lzo'
spack install -j12 -v key4hep-stack
if [ -f /home/user/.spack/linux/compilers.yaml.noproxy ] ; then
pushd /home/user/.spack/linux
cp -f compilers.yaml.noproxy compilers.yaml
popd
fi
