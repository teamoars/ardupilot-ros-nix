# based on
# https://github.com/NixOS/nixpkgs/blob/5e2a59a5b1a82f89f2c7e598302a9cacebb72a67/pkgs/by-name/ze/zenoh-plugin-mqtt/package.nix#L24

{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  libclang,
  breakpointHook,
}:

rustPlatform.buildRustPackage rec {
  pname = "zenoh-plugin-ros2dds";
  version = "1.9.0"; # nixpkgs-update: no auto update

  src = fetchFromGitHub {
    owner = "eclipse-zenoh";
    repo = "zenoh-plugin-ros2dds";
    tag = version;
    hash = "sha256-YymJVm9Y34ce60unWk0DniL47TWczP7a7A7ywnIjzNw=";
  };

  cargoHash = "sha256-2R0pxrD0wda8I1oNyxftu7N1nRQDW4iwrVkZiruC/L0=";

  nativeBuildInputs = [
    cmake
    # libclang
    rustPlatform.bindgenHook
    # breakpointHook
  ];

  # questionable bodge
  #
  # >   CMake Error at CMakeLists.txt:1 (cmake_minimum_required):
  # >     Compatibility with CMake < 3.5 has been removed from CMake.
  # >
  # >     Update the VERSION argument <min> value.  Or, use the <min>...<max> syntax
  # >     to tell CMake that the project requires at least <min> but has been updated
  # >     to work with policies introduced by <max> or earlier.
  # >
  # >     Or, add -DCMAKE_POLICY_VERSION_MINIMUM=3.5 to try configuring anyway.
  # >
  # >
  # >
  # >   thread 'main' (8292) panicked at /build/zenoh-plugin-ros2dds-1.9.0-vendor/cmake-0.1.58/src/lib.rs:1132:5:
  # >
  # >   command did not execute successfully, got: exit status: 1
  # >
  CMAKE_POLICY_VERSION_MINIMUM = "3.5";

  # Some test time out
  # doCheck = false;

  meta = {
    description = "A Zenoh plug-in for ROS2 with a DDS RMW";
    homepage = "https://github.com/eclipse-zenoh/zenoh-plugin-ros2dds";
    license = with lib.licenses; [
      epl20
      asl20
    ];
    platforms = lib.platforms.linux;
    mainProgram = "zenoh-bridge-ros2dds";
  };
}
