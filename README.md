# launching iris runway

First enter the nix development environment:

```bash
nix develop -i -k TERM -k HOME -k XAUTHORITY -k DISPLAY
```

Then you can use the ardupilot launch file as usual:

```bash
nixGLIntel ros2 launch ardupilot_gz_bringup iris_runway.launch.py
```

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

The ardupilot ros2 packages have both .dsv and .sh colcon hooks. When built with colcon the standard way (vcs import ..., colcon build), the .dsv files are used. But nix-ros-overlay uses the .sh files instead. This leads to breakages because the .sh hooks we not kept up to date with the .dsv files!

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

# run mavlink-server & zenoh

Open two tmux panes & run the following:

```bash
mavlink-server --web-server '127.0.0.1:8080' 'udpserver://0.0.0.0:14550' 'zenoh://127.0.0.1:7447' 'udpclient://127.0.0.1:14552'
```

```bash
zenohd
```

# On specifying GZ_RENDERING_PLUGIN_PATH

Without GZ_RENDERING_PLUGIN_PATH, it's seemingly only possible to get asv_wave_sim wave graphics rendering running if we build asv_wave_sim on the commandline. The only difference that I was able to find is the RUNPATH of the nix & manually built binaries differing. The nix RUNPATH includes the /lib directory where the files are installed meanwhile for the manual build you need to specify LD_LIBRARY_PATH to get things working.

The general flow of the loading process is as follows:

1. gazebo loads libgz-waves1-rendering.so.1.0.0 (found using GZ_SIM_SYSTEM_PLUGIN_PATH)

2. libgz-waves1-rendering.so.1.0.0 attempts to load libgz-waves1-rendering-ogre2.so.1.0.0

    - On the nix build, this step fails with libgz-waves1-rendering.so.1.0.0 being unable to locate the object file. If GZ_RENDERING_PLUGIN_PATH is specified, the object file can be found.

    - On the manual build, the object file is somehow found. Looking at the plugin loading code in asv_wave_sim's systems/waves/RenderEngineExtensionManager.cc seems to suggest that this is impossible. None of the default search paths seem to include the colcon install directory. It's possible that I am simply too worn out at this point to properly read the code.

When building the project directly with cmake, it also cannot be loaded if GZ_RENDERING_PLUGIN_PATH is not specified! This suggests to me that there is something special about colcon's install directory structure. Perhaps asv_wave_sim is preconfigured to look there? Again, I probably just need to revisit the code another time to get a proper understanding.

The object files, when built using nix, are substantially smaller for whatever reason. If we tell nix to not strip or otherwise touch the objects, we can get the binaries to be very nearly identical to the manually built ones. Despite that, they still won't load without GZ_RENDERING_PLUGIN_PATH.

If GZ_RENDERING_PLUGIN_PATH is not set, the waves are not rendered in the gui. The below error gets produced:

```
[GUI] [Msg] Loading plugin [gz-waves1-rendering-ogre2]
Library [] does not export any plugins. The symbol [GzPluginHook] is missing, or it is not externally visible.
[GUI] [Err] [RenderEngineExtensionManager.cc:482] Failed to load plugin [gz-waves1-rendering-ogre2] : couldn't load library on path [].
```

# TODOs

- avoid ros2 entirely by directly bridging gz -> zenoh

    - https://github.com/srmainwaring/gz-python

    - https://gazebosim.org/api/transport/14/python.html

# blueboat experiment

launch with

```bash
GZ_SIM_RESOURCE_PATH=$PWD/worlds:$PWD/models:$GZ_SIM_RESOURCE_PATH nixGLNvidia-570.195.03 ros2 launch launch/blueboat_waves.launch.py
```
