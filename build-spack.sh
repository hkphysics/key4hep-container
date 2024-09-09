#!/bin/sh
. /usr/sbin/proxy.sh
git config --global --add safe.directory /opt/spack
pushd /opt/spack
git fetch --depth 1 origin develop
git reset --hard origin/develop
curl https://github.com/spack/spack/compare/develop...joequant:spack:dev/fixes.patch | patch -p1
popd
git config --global --add safe.directory /opt/spack/var/spack/repos/key4hep-spack
pushd /opt/spack/var/spack/repos/key4hep-spack
git fetch --depth 1 origin main
git reset --hard origin/main
curl https://github.com/joequant/key4hep-spack/compare/main...joequant:key4hep-spack:dev/fixes.patch | patch -p1
popd



# remove locks
set -e
rm -f /opt/spack/.spack-db/prefix_lock
export DISTCC_HOSTS='172.17.0.1,lzo'
export PATH=$PATH":/opt/spack/bin"
for pkg in "$@"
do
    spack install -j16 --fresh -v $pkg
done
if [ -f /home/user/.spack/linux/compilers.yaml.noproxy ] ; then
pushd /home/user/.spack/linux
cp -f compilers.yaml.noproxy compilers.yaml
popd
fi
