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
    xz \
    python3-devel \
    patchelf \
    python3-pip \
    libomp-devel \
    gcc-gfortran \
    tar \
    shadow-utils \
    curl \
    make \
    fish \
    patch \
    zip \
    unzip \
    gcc-c++ \
    cmake \
    gzip \
    bzip2 \
    which \
    procps-ng


buildah run $container /usr/sbin/install-certs.sh

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
/usr/sbin/useradd -G wheel -R $rootfsDir spack || true
cat <<EOF > $rootfsDir/etc/sudoers.d/user
%wheel        ALL=(ALL)       NOPASSWD: ALL
EOF
cat <<EOF >> $rootfsDir/etc/distcc/hosts
172.17.0.1
EOF

git clone --depth=1 https://github.com/spack/spack.git $rootfsDir/opt/spack

pushd $rootfsDir/opt/spack/var/spack/repos
git clone --depth=1 https://github.com/key4hep/key4hep-spack.git
pushd key4hep-spack
curl https://github.com/joequant/key4hep-spack/compare/main...joequant:key4hep-spack:dev/fixes.patch | patch -p1
popd
popd

pushd $rootfsDir/opt/spack
curl https://github.com/spack/spack/compare/develop...joequant:spack:dev/fixes.patch | patch -p1
popd

cp $scriptDir/packages.yaml $rootfsDir/opt/spack/etc/spack
cp $scriptDir/packages-nightly.yaml $rootfsDir/opt/spack/etc/spack

buildah run $container -- usermod -a -G wheel user
buildah run $container -- usermod -a -G spack user
buildah run $container -- mkdir -p /opt/spack

buildah run $container -- mkdir -p /home/user/.spack/linux
buildah copy $container $scriptDir/config.yaml /opt/spack/etc/spack
buildah copy $container $scriptDir/proxy.sh /usr/sbin
buildah copy $container $scriptDir/build-spack.sh /usr/sbin
buildah copy $container $scriptDir/build-spack-nightly.sh /usr/sbin
buildah copy $container $scriptDir/build-spack-clang.sh /usr/sbin
buildah copy $container $scriptDir/mirrors.yaml /opt/spack/etc/spack/defaults
buildah copy $container $scriptDir/compilers.yaml.noproxy /home/user/.spack/linux
buildah copy $container $scriptDir/compilers.yaml.proxy /home/user/.spack/linux
buildah copy $container $scriptDir/compilers.yaml.clang /home/user/.spack/linux

buildah run $container -- chown -R spack:spack /opt/spack
buildah run $container -- chmod -R ug+rw /opt/spack
buildah run $container -- chmod -R o+r /opt/spack
buildah run $container -- find /opt/spack -type d -exec chmod 775 {} \;
chmod 0755 $rootfsDir/usr/sbin/*.sh
buildah run $container -- chown user:user -R /home/user/.spack
buildah run $container -- chmod a+x /opt/spack/bin/spack
buildah run $container -- chmod a+x /opt/spack/lib/spack/env/cc
buildah run $container -- sudo -u user /opt/spack/bin/spack repo add /opt/spack/var/spack/repos/key4hep-spack
buildah run $container --  update-distcc-symlinks
#bootstrap clingo
buildah run $container -- pip install clingo

buildah config --user "user" $container
buildah config --cmd "/bin/sh" $container
buildah tag $name ${name}:old || true
buildah commit --format docker --rm $container $name
buildah rmi --force ${name}:old || true
pump --shutdown

