#!/bin/bash
set -e -v
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
container=$(buildah from joequant/cauldron-minimal)
buildah config --label maintainer="Joseph C Wang <joequant@gmail.com>" $container
buildah config --user root $container
mountpoint=$(buildah mount $container)
rootfsDir=$mountpoint
name=joequant/key4hep-container
releasever=cauldron
LANG=C
LANGUAGE=C
LC_ALL=C

if [ -z $buildarch ]; then
	# Attempt to identify target arch
	buildarch="$(rpm --eval '%{_target_cpu}')"
fi

. $scriptDir/proxy.sh

reposetup="--disablerepo=* --enablerepo=mageia-$buildarch --enablerepo=updates-$buildarch"

dnf --installroot="$rootfsDir" \
	install \
    --setopt=install_weak_deps=False --best -v -y \
    --nodocs --allowerasing \
    --releasever="$releasever" \
    --nogpgcheck \
    clang \
    nodejs \
    spack \
    git \
    sudo \
    glibc-static-devel \
    glibc-devel \
    procps-ng \
    libstdc++-devel \
    libstdc++-static-devel \
    kernel-userspace-headers \
    vim \
    bash \
    compiler-rt \
    distcc \
    xz

#rpm --rebuilddb --root $rootfsDir
pushd $rootfsDir
rm -rf var/cache/*
rm -f lib/*.so lib/*.so.* lib/*.a lib/*.o
rm -rf usr/lib/.build-id usr/lib64/mesa
rm -rf usr/local usr/games
rm -rf usr/lib/gcc/*/*/32
#modclean seems to interfere with verdaccio
#https://github.com/verdaccio/verdaccio/issues/1883
popd

/usr/sbin/useradd -G wheel -R $rootfsDir user || true
cat <<EOF > $rootfsDir/etc/sudoers.d/user
%wheel        ALL=(ALL)       NOPASSWD: ALL
EOF
cat <<EOF >> $rootfsDir/etc/distcc/hosts
172.17.0.1
EOF

mkdir -p $rootfsDir/var/spack/repos/
pushd $scriptDir
git clone --depth=1 https://github.com/spack/spack.git spack.$$
cp -R spack.$$/var/spack/repos/* $rootfsDir/var/spack/repos/
popd
rm -rf spack.$$

pushd $rootfsDir/var/spack/repos
git clone --depth=1 https://github.com/key4hep/key4hep-spack.git
popd

pushd $rootfsDir
patch -p1 < $scriptDir/patches/builtin.patch 
popd

pushd $rootfsDir/var/spack/repos/key4hep-spack
patch -p1 < $scriptDir/patches/key4hep-spack.patch
popd

cp $scriptDir/packages.yaml $rootfsDir/etc/spack
cp $scriptDir/packages-nightly.yaml $rootfsDir/etc/spack

buildah run $container -- usermod -a -G wheel user
buildah run $container -- usermod -a -G spack user
buildah run $container -- mkdir -p /opt/spack

buildah run $container -- mkdir -p /home/user/.spack/linux
buildah copy $container $scriptDir/config.yaml /etc/spack
buildah copy $container $scriptDir/proxy.sh /usr/sbin
buildah copy $container $scriptDir/build-spack.sh /usr/sbin
buildah copy $container $scriptDir/build-spack-nightly.sh /usr/sbin
buildah copy $container $scriptDir/build-spack-clang.sh /usr/sbin
buildah copy $container $scriptDir/mirrors.yaml /etc/spack/defaults
buildah copy $container $scriptDir/compilers.yaml.noproxy /home/user/.spack/linux
buildah copy $container $scriptDir/compilers.yaml.proxy /home/user/.spack/linux
buildah copy $container $scriptDir/compilers.yaml.clang /home/user/.spack/linux

buildah run $container -- chown -R spack:spack /opt/spack /var/spack /etc/spack
buildah run $container -- chmod -R ug+rw /opt/spack  /var/spack /etc/spack
buildah run $container -- chmod -R o+r /opt/spack  /var/spack /etc/spack
buildah run $container -- find /var/spack /opt/spack /etc/spack -type d -exec chmod 775 {} \;
chmod 0755 $rootfsDir/usr/sbin/*.sh
buildah run $container -- chown user:user -R /home/user/.spack
buildah run $container -- sudo -u user spack repo add /var/spack/repos/key4hep-spack
buildah run $container --  update-distcc-symlinks

buildah config --user "user" $container
buildah config --cmd "/bin/sh" $container
buildah tag $name ${name}:old || true
buildah commit --format docker --rm $container $name
buildah rmi --force ${name}:old || true
pump --shutdown

