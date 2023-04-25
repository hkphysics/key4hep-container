#!/bin/sh
. /usr/sbin/proxy.sh
# remove locks
set -e
rm -f /opt/spack/.spack-db/prefix_lock
pushd /home/user/.spack/linux
cp -f compilers.yaml.clang compilers.yaml
popd
export DISTCC_HOSTS='172.17.0.1,lzo'
export PATH=$PATH":/opt/spack/bin"
for pkg in "$@"
do
    spack install -j16 -v $pkg
done

