# to update micro-xrce-dds-gen deps

nix build .#micro-xrce-dds-gen.mitmCache.updateScript

./result

# initial generation of nix packages

mkdir src

vcs import --input ros2_gz.repos src

ros2nix --fetch --nixfmt --no-overlay --no-shell --output-as-nix-pkg-name $(find -name package.xml)

The whole list is available at: https://raw.githubusercontent.com/ArduPilot/ardupilot_gz/main/ros2_gz.repos

Some of the dependencies there are already in the ros2 package repos so there's no need to fetch them

# launching with gpu acceleration

nixGLIntel ros2 launch ardupilot_gz_bringup iris_runway.launch.py

mavproxy.py

# running nix develop with a minimal environment

For maximum purity, we ignore the environment with "-i" but whitelist a few env vars so that all of the graphical applications can launch correctly.

nix develop --max-jobs 0 --builders 'ssh://jakub@10.10.0.3?ssh-key=/home/jakub/.ssh/id_ed25519 x86_64-linux' -i -k TERM -k HOME -k XAUTHORITY -k DISPLAY
