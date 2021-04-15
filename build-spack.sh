#!/bin/sh
. /usr/sbin/proxy.sh
# remove locks
set -e
rm -f /opt/spack/.spack-db/prefix_lock
export DISTCC_HOSTS='172.17.0.1,lzo'
for pkg in "$@"
do
    spack install -j16  --deprecated -v $pkg
done
if [ -f /home/user/.spack/linux/compilers.yaml.noproxy ] ; then
pushd /home/user/.spack/linux
cp -f compilers.yaml.noproxy compilers.yaml
popd
fi
