#!/bin/sh
function install_packages() {
    local FLAGS=()
    local pkg flag_name flag_value

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --help | -h)
                echo "Usage: ./install.sh [package1 [--flag1=value1 ...] [package2 [--flag2=value2 ...]] ...]"
                exit 0
                ;;
            --[a-zA-Z_][a-zA-Z0-9_]*)
                flag_name=${1}
                FLAGS+=("$flag_name")
                echo ${FLAGS[@]}
                shift
                ;;
            *)
                pkg=$1
                shift
                spack install -j16 -v  ${FLAGS[@]} "$pkg"
                ;;
        esac
    done
}

. /usr/sbin/proxy.sh
git config --global --add safe.directory /opt/spack
pushd /opt/spack
git fetch origin develop
git pull --unshallow

git checkout develop .
# key4hep goes into infinite loop with key4hep-stack
# see https://github.com/spack/spack/issues/47888
git checkout cb3d6549c988cb914583e4d220a2d1c0b0aa6ae2^ ./lib/spack/spack
git checkout 858c7ca1a2f4e0022e93faa9f91d7215a1c41b42 ./lib/spack/spack/util/ ./lib/spack/spack/version

curl https://github.com/spack/spack/compare/develop...hkphysics:spack:dev/fixes.patch | patch -p1
popd
git config --global --add safe.directory /opt/spack/var/spack/repos/key4hep-spack
pushd /opt/spack/var/spack/repos/key4hep-spack
git fetch --depth 1 origin main
git reset --hard origin/main
curl https://github.com/hkphysics/key4hep-spack/compare/main...hkphysics:key4hep-spack:dev/fixes.patch | patch -p1
popd

mkdir -p /opt/spack/opt/spack
pushd /opt/spack/opt/spack
find . -name "repo.yaml" -size 0 -exec rm {} \;
popd

# remove locks
set -e
pushd /home/user/.spack/linux
cp -f /etc/compilers.yaml.clang compilers.yaml
popd
rm -f /opt/spack/.spack-db/prefix_lock
export DISTCC_HOSTS='172.17.0.1,lzo'
export PATH=$PATH":/opt/spack/bin"
install_packages "$@"
