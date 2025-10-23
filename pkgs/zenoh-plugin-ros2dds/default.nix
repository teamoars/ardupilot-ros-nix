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
  version = "1.6.2"; # nixpkgs-update: no auto update

  src = fetchFromGitHub {
    owner = "eclipse-zenoh";
    repo = "zenoh-plugin-ros2dds";
    tag = version;
    hash = "sha256-wyjflYKGLcga4IPGtSIUf7YGPmVO2hHdZiKDCDSyMbg=";
  };

  cargoHash = "sha256-iEmhgJdsSmJEnQre5DOsu/y1x/kxrUmutEpy86kDMf8=";

  nativeBuildInputs = [
    cmake
    # libclang
    rustPlatform.bindgenHook
    # breakpointHook
  ];

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
