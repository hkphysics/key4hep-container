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

(
    dnf --installroot="$rootfsDir" \
	install \
    --setopt=install_weak_deps=False --best -v -y \
    --nodocs --allowerasing \
    --releasever="$releasever" \
    --nogpgcheck \
    gcc-c++ \
    nodejs \
    spack \
    git \
    curl \
    sudo \
    tar \
    make \
    glibc-static-devel \
    glibc-devel \
    patch \
    distcc \
    unzip \
    gcc-gfortran \
    libstdc++-static-devel \
    vim \
    cmake \
    gzip \
    bzip2 \
    which
)

rpm --rebuilddb --root $rootfsDir
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

mkdir -p $rootfsDir/var/spack/repos/
pushd $scriptDir
git clone --depth=1 https://github.com/spack/spack.git spack.$$
cp -R spack.$$/var/spack/repos/* $rootfsDir/var/spack/repos/
popd
rm -rf spack.$$

pushd $rootfsDir/var/spack/repos
git clone --depth=1 https://github.com/key4hep/k4-spack.git
popd

cp -R repos/* $rootfsDir/var/spack/repos/
pushd $rootfsDir/var/spack/repos/
find  -name "package.py.patch" -type f -exec sh -c 'f="{}"; patch "${f%.*}" "$f"' \;
popd

buildah run $container -- usermod -a -G wheel user
buildah run $container -- usermod -a -G spack user
buildah run $container -- mkdir -p /opt/spack
buildah run $container -- sudo -u user spack repo add /var/spack/repos/k4-spack
buildah run $container -- mkdir -p /home/user/.spack/linux
buildah copy $container $scriptDir/config.yaml /etc/spack
buildah copy $container $scriptDir/proxy.sh /usr/sbin
buildah copy $container $scriptDir/build-spack.sh /usr/sbin
buildah run $container -- chown -R spack:spack /opt/spack /var/spack /etc/spack
buildah run $container -- chmod -R ug+rw /opt/spack  /var/spack /etc/spack
buildah run $container -- chmod -R o+r /opt/spack  /var/spack /etc/spack
buildah run $container -- find /var/spack /opt/spack /etc/spack -type d -exec chmod 755 {} \;
chmod 0755 $rootfsDir/usr/sbin/*.sh
buildah copy $container $scriptDir/mirrors.yaml /etc/spack/defaults
buildah copy $container $scriptDir/compilers.yaml.noproxy /home/user/.spack/linux
buildah copy $container $scriptDir/compilers.yaml.proxy /home/user/.spack/linux
buildah run $container -- chown user:user -R /home/user/.spack

buildah config --user "user" $container
buildah config --cmd "/bin/bash" $container
buildah commit --format docker --rm $container $name
pump --shutdown

