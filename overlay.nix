final: prev:
{
  ardupilot-dds-tests = prev.callPackage ./ardupilot-dds-tests.nix {};
  ardupilot-gazebo = prev.callPackage ./ardupilot-gazebo.nix {};
  ardupilot-gz-application = prev.callPackage ./ardupilot-gz-application.nix {};
  ardupilot-gz-bringup = prev.callPackage ./ardupilot-gz-bringup.nix {};
  ardupilot-gz-description = prev.callPackage ./ardupilot-gz-description.nix {};
  ardupilot-gz-gazebo = prev.callPackage ./ardupilot-gz-gazebo.nix {};
  ardupilot-msgs = prev.callPackage ./ardupilot-msgs.nix {};
  ardupilot-sitl = prev.callPackage ./ardupilot-sitl.nix {};
  ardupilot-sitl-models = prev.callPackage ./ardupilot-sitl-models.nix {};
  micro-ros-agent = prev.callPackage ./micro-ros-agent.nix {};
}
