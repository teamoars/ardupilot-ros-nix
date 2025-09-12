{
  description = "A development environment for ardupilot's ROS2 integration";

  inputs = {
    # TODO: newer nixpkgs versions break builds of python packages in
    # nix-ros-overlay so we pin our nixpkgs to whatever nix-ros-overlay
    # uses
    # > error: python3.13-colcon-core-0.20.0 does not configure a `format`. To build with setuptools as before, set `pyproject = true` and `build-system = [ setuptools ]`.`
    # nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";

    flake-utils.url = "github:numtide/flake-utils"; # for dedup
     
    nix-ros-overlay = {
      url = "github:muellerbernd/nix-ros-overlay/develop";
      # inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    ros2nix = {
      url = "github:wentasah/ros2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nix-ros-overlay.follows = "nix-ros-overlay";
    };

    gradle2nix = {
      url = "github:tadfisher/gradle2nix/v2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

#     gradle2nix = {
#       url = "github:tadfisher/gradle2nix/v2";
#       inputs.nixpkgs.follows = "nixpkgs";
#       inputs.flake-utils.follows = "flake-utils";
#     };
# 
#     nixgl = {
#       url = "github:nix-community/nixGL";
#       inputs.nixpkgs.follows = "nixpkgs";
#       inputs.flake-utils.follows = "flake-utils";
#     };
  };

  outputs = { self, nixpkgs, flake-utils, nix-ros-overlay, ros2nix, gradle2nix }:
  let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in
  {
    # we need to export micro-xrce-dds-gen so that we could call the
    # build .mitmCache.updateScript
    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ self.overlays.regularDeps ];
      };
    in {
      micro-xrce-dds-gen = pkgs.micro-xrce-dds-gen;
    };

    overlays.regularDeps = final: prev: {
      # micro-ros-agent deps
      fast-dds = prev.callPackage ./pkgs/fast-dds {};
      # TODO: foonathan-memory-vendor exists
      # foonathan-memory = prev.callPackage ./pkgs/foonathan-memory {};
      fast-cdr = prev.callPackage ./pkgs/fast-cdr {};
      micro-cdr = prev.callPackage ./pkgs/micro-cdr {};
      micro-xrce-dds-client = prev.callPackage ./pkgs/micro-xrce-dds-client {};
      micro-xrce-dds-agent = prev.callPackage ./pkgs/micro-xrce-dds-agent {};
      micro-xrce-dds-gen = prev.callPackage ./pkgs/micro-xrce-dds-gen {};

      # is this a fine way to do this?
      buildGradlePackage = self.inputs.gradle2nix.builders.${prev.system}.buildGradlePackage;
    };
    overlays.rosDeps = final: prev: {
      # TODO: why were these special?
      micro-ros-agent = prev.callPackage ./pkgs/micro-ros-agent {};
      # inject micro-xrce-dds-agent dep
      # micro-ros-agent = 
      # ardupilot-dds-tests = super.callPackage ./ardupilot-dds-tests.nix {};
      ardupilot-msgs = prev.callPackage ./pkgs/ardupilot-msgs {};
      ardupilot-sitl = prev.callPackage ./pkgs/ardupilot-sitl {};
    };
    overlays.rosDistroOverlays = let
      applyDistroOverlay =
        rosOverlay: rosPackages:
        rosPackages
        // builtins.mapAttrs (
          rosDistro: rosPkgs: if rosPkgs ? overrideScope then rosPkgs.overrideScope rosOverlay else rosPkgs
        ) rosPackages;
    in final: prev: {
      rosPackages = applyDistroOverlay self.overlays.rosDeps prev.rosPackages;
    };

    devShells = forAllSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nix-ros-overlay.overlays.default
            self.overlays.regularDeps
            self.overlays.rosDistroOverlays
          ];
        };
      in
      {
        default = pkgs.mkShellNoCC {
          packages = [
            # ardupilot won't build with gcc14
            pkgs.gcc13Stdenv.cc

            pkgs.colcon

            pkgs.vcstool

            # for development
            pkgs.tmux

            # pkgs.micro-xrce-dds-agent
            # pkgs.micro-xrce-dds-client
            # pkgs.fast-dds

            # for building MicroXRCEDDSGen
            # pkgs.gradle
            # pkgs.jdk11

            # for building & using the sitl
            # see https://github.com/tpwrules/ardupilot-dev-flake/blob/main/flake.nix
            pkgs.micro-xrce-dds-gen
            pkgs.git
            pkgs.rsync
            pkgs.mavproxy

            (with pkgs.rosPackages.jazzy; buildEnv {
              paths = [
                ros-core

                ament-black
                ament-cmake
                ament-cmake-black
                ament-cmake-copyright
                ament-cmake-gtest
                ament-cmake-lint-cmake
                ament-cmake-pep257
                ament-cmake-pytest
                ament-cmake-python
                ament-cmake-uncrustify
                ament-cmake-xmllint
                ament-copyright
                ament-index-python
                ament-lint-auto
                ament-lint-common
                ament-pep257
                ament-uncrustify
                ament-xmllint
                builtin-interfaces
                geographic-msgs
                geometry-msgs
                launch
                launch-pytest
                launch-ros
                micro-ros-msgs
                python3Packages.geopy
                python3Packages.pytest
                python3Packages.scipy
                rclpy
                rcutils
                rmw
                rmw-dds-common
                rmw-fastrtps-shared-cpp
                rosgraph-msgs
                rosidl-default-generators
                rosidl-default-runtime
                rosidl-typesupport-fastrtps-cpp
                sensor-msgs
                pkgs.socat
                std-msgs
                tf2-msgs

                # these are the deps that ros2nix missed?
                ament-cmake-core
                python-cmake-module
                micro-ros-agent
                python3Packages.pexpect
              ];
            })

            ros2nix.packages."${system}".default
          ];
        };
      });

    nixConfig = {
      extra-substituters = [ "https://ros.cachix.org" ];
      extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
    };

  };
}
