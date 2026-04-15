final: prev:
{
  ardupilot-dds-tests = final.callPackage ./ardupilot-dds-tests.nix {};
  ardupilot-gazebo = final.callPackage ./ardupilot-gazebo.nix {};
  ardupilot-gz-application = final.callPackage ./ardupilot-gz-application.nix {};
  ardupilot-gz-bringup = final.callPackage ./ardupilot-gz-bringup.nix {};
  ardupilot-gz-description = final.callPackage ./ardupilot-gz-description.nix {};
  ardupilot-gz-gazebo = final.callPackage ./ardupilot-gz-gazebo.nix {};
  ardupilot-msgs = final.callPackage ./ardupilot-msgs.nix {};
  ardupilot-sitl = final.callPackage ./ardupilot-sitl.nix {};
  ardupilot-sitl-models = final.callPackage ./ardupilot-sitl-models.nix {};
  gazebo-ros-actor-plugin = final.callPackage ./gazebo-ros-actor-plugin.nix {};
  micro-ros-agent = final.callPackage ./micro-ros-agent.nix {};
}
