#!/bin/sh
set -eux

WRAPPER="$1"

tmux kill-session -t wilthumper || true

tmux new -s wildthumper -d

## SIMULATION
# gazebo
tmux send-keys -t wildthumper "${WRAPPER} ros2 launch launch/wildthumper_playpen.launch.py" C-m
# zenoh bridge
tmux split-window -t wildthumper
tmux send-keys -t wildthumper 'zenoh-bridge-ros2dds' C-m
# camera publishing
tmux split-window -t wildthumper
tmux send-keys -t wildthumper 'python ../../all.py' C-m

tmux new-window -t wildthumper
tmux send-keys -t wildthumper 'mavlink-server --web-server 127.0.0.1:8080 tcpclient://127.0.0.1:5762 udpclient://127.0.0.1:14552 zenoh:127.0.0.1:7447' C-m

# mission-planner
tmux new-window -t wildthumper
tmux send-keys -t wildthumper "${WRAPPER} mission-planner" C-m

# teleop
tmux new-window -t wildthumper
tmux send-keys -t wildthumper 'ros2 run teleop_twist_keyboard teleop_twist_keyboard' C-m

exec tmux attach -t wildthumper
