# to update micro-xrce-dds-gen deps

nix build .#micro-xrce-dds-gen.mitmCache.updateScript
./result
vcs import --input https://raw.githubusercontent.com/ArduPilot/ardupilot_gz/main/ros2_gz.repos --recursive src
