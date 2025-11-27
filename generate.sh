#!/bin/sh
set -eux

temp_dir="$(mktemp -d)"
# paranoid
[ -z "$temp_dir" ] && exit 1

mkdir "${temp_dir}/src"
vcs import --input ./ros2_gz.repos "$temp_dir/src"

# currently ros2nix will see that our top level repo is a git repo itself
# and then change all of the fetching to use our repo instead of the urls
# of the cloned repos. So for now we clone all of the repos into a
# temporary dir and copy the produced output back to our repo directory
prev="$PWD"
cd "$temp_dir"
ros2nix --distro jazzy --fetch --nixfmt --no-shell --output-as-nix-pkg-name $(find . -name package.xml)
cd "$prev"

find "$temp_dir" -maxdepth 1 -type f -name '*.nix' -exec mv \{\} ./generated \;

rm -rf "$temp_dir"
