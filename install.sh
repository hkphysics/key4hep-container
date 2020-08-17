#!/bin/bash
set -e -v

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
container=$(buildah from joequant/cauldron)
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
    spack-repos \
    git \
    curl \
    sudo \
    tar \
    make \
    glibc-static-devel \
    glibc-devel \
    patch \
    spack-repos-k4 \
    distcc \
    unzip \
    gcc-gfortran
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
buildah run $container -- usermod -a -G wheel user
buildah run $container -- usermod -a -G spack user
buildah run $container -- mkdir -p /opt/spack
buildah run $container -- chown spack:spack /opt/spack
buildah run $container -- chmod ug+rw /opt/spack
buildah run $container -- sudo -u user spack repo add /var/spack/repos/k4
buildah copy $container $scriptDir/proxy.sh /usr/sbin
buildah copy $container $scriptDir/build-spack.sh /usr/sbin
#buildah run $container -- sudo -u user /usr/sbin/build-spack.sh

buildah config --user "user" $container
buildah config --cmd "/bin/bash" $container
buildah commit --format docker --rm $container $name
buildah push $name:latest docker-daemon:$name:latest
pump --shutdown

