final: prev:
{
  ardupilot-dds-tests = final.callPackage ./src/ardupilot/Tools/ros2/ardupilot_dds_tests/package.nix {};
  ardupilot-msgs = final.callPackage ./src/ardupilot/Tools/ros2/ardupilot_msgs/package.nix {};
  ardupilot-sitl = final.callPackage ./src/ardupilot/Tools/ros2/ardupilot_sitl/package.nix {};
  micro-ros-agent = final.callPackage ./src/micro_ros_agent/micro_ros_agent/package.nix {};
}
