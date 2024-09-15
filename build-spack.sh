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
install_packages "$@"

if [ -f /etc/compilers.yaml.noproxy ] ; then
pushd /home/user/.spack/linux
cp -f /etc/compilers.yaml.noproxy compilers.yaml
popd
fi
