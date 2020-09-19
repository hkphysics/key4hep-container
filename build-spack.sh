#!/bin/bash
set -e
source /usr/sbin/proxy.sh
export DISTCC_HOSTS='172.17.0.1,lzo'
spack install -j16 -v key4hep-stack
if [ -f /home/user/.spack/linux/compilers.yaml.noproxy ] ; then
pushd /home/user/.spack/linux
cp -f compilers.yaml.noproxy compilers.yaml
popd
fi
