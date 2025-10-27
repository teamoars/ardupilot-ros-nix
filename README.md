# launching iris runway

First enter the nix development environment:

```bash
nix develop -i -k TERM -k HOME -k XAUTHORITY -k DISPLAY
```

Then you can use the ardupilot launch file as usual:

```bash
env "GZ_SIM_RESOURCE_PATH=${GZ_SIM_RESOURCE_PATH}:${CMAKE_PREFIX_PATH}/share" "GZ_SIM_SYSTEM_PLUGIN_PATH=${GZ_SIM_PLUGIN_PATH}:${CMAKE_PREFIX_PATH}/lib" nixGLIntel ros2 launch ardupilot_gz_bringup iris_runway.launch.py
```

(note: we set GZ_SIM_RESOURCE_PATH & GZ_SIM_SYSTEM_PLUGIN_PATH to work around an issue with how environment variables are sourced in the ardupilot ros packages)

In a separate terminal bring up mavproxy:

```bash
mavproxy.py --master 127.0.0.1:14551
```

# zenoh bringup

first run the zenoh dds bridge:

```bash
zenoh-bridge-ros2dds
```

next run mavlink-server:

```bash
mavlink-server --web-server '127.0.0.1:8080' 'udpserver://0.0.0.0:14550' 'zenoh://127.0.0.1:7447' 'udpclient://127.0.0.1:14552'
```

finally publish camera images to a zenoh topic:

```bash
python all.py
```

# development notes

## to update micro-xrce-dds-gen deps

``` bash
nix build .#micro-xrce-dds-gen.mitmCache.updateScript
./result
```

## using a remote builder with nix develop

```bash
nix develop --max-jobs 0 --builders 'ssh://username@host?ssh-key=/home/user/.ssh/id_ed25519'
```

--max-jobs tells nix to not spawn any local jobs so that the entirety of the work is offloaded to the builders.

## env var breakage

The ardupilot ros2 packages have both .dsv and .sh colcon hooks. When built with colcon the standard way (vcs import ..., colcon build), the .dsv files are used and everything works. But for whatever reason nix-ros-overlay uses .sh files instead and things stop working because the .sh hooks we not kept up to date with the .dsv files!

- https://discourse.openrobotics.org/t/the-forgotten-gem-that-is-environment-hooks-and-dsv/41581

- https://github.com/ros2/ros2/issues/1613#issuecomment-2596447764

## running nix develop with a minimal environment

For maximum purity, we ignore the environment with "-i" but whitelist a few env vars so that all of the graphical applications can launch correctly.

```bash
nix develop -i -k TERM -k HOME -k XAUTHORITY -k DISPLAY
```

## generating ardupilot_sitl packages

in a "nix develop #generate" env:

```bash
./generate.sh
```

The list of all packages required by ardupilot is here: https://raw.githubusercontent.com/ArduPilot/ardupilot_gz/main/ros2_gz.repos

Some of the dependencies there are already in the ros2 package repos so there's no need to fetch them

# enable camera streaming

ardupilot-gazebo streams camera feeds over rtp but the streaming needs to be toggled on:

```bash
gz topic -t /camera-1/enable_streaming -m gz.msgs.Boolean -p "data: 1"
```

To toggle all cameras, use the supplied script:

```bash
./enable_streaming.sh
```

# run mavlink-server & zenoh

Open two tmux panes & run the following:

```bash
mavlink-server --web-server '127.0.0.1:8080' 'udpserver://0.0.0.0:14550' 'zenoh://127.0.0.1:7447' 'udpclient://127.0.0.1:14552'
```

```bash
zenohd
```
