#!/bin/sh
. /usr/sbin/proxy.sh
# remove locks
set -e
rm -f /opt/spack/.spack-db/prefix_lock
export DISTCC_HOSTS='172.17.0.1,lzo'
cp /etc/spack/packages-nightly.yaml /etc/spack/packages.yaml
for pkg in "$@"
do
    spack install -j16 -v $pkg
done
if [ -f /home/user/.spack/linux/compilers.yaml.noproxy ] ; then
pushd /home/user/.spack/linux
cp -f compilers.yaml.noproxy compilers.yaml
popd
fi
