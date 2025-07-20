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
. /opt/spack/share/spack/setup-env.sh

mkdir -p /opt/spack/opt/spack
pushd /opt/spack/opt/spack
find . -name "repo.yaml" -size 0 -exec rm {} \;
popd
spack repo update

# remove locks
set -e
pushd /home/user/.spack/linux
cp -f /etc/compilers.yaml.clang compilers.yaml
popd
rm -f /opt/spack/.spack-db/prefix_lock
export DISTCC_HOSTS='172.17.0.1,lzo'
export PATH=$PATH":/opt/spack/bin"
install_packages "$@"
