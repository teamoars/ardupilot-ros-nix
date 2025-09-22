# to update micro-xrce-dds-gen deps

nix build .#micro-xrce-dds-gen.mitmCache.updateScript
./result
vcs import --input https://raw.githubusercontent.com/ArduPilot/ardupilot_gz/main/ros2_gz.repos --recursive src
nixGLIntel ros2 launch ardupilot_gz_bringup iris_runway.launch.py
mavproxy.py
nix develop --max-jobs 0 --builders 'ssh://jakub@10.10.0.3?ssh-key=/home/jakub/.ssh/id_ed25519 x86_64-linux' -i -k TERM -k HOME -k XAUTHORITY -k DISPLAY
