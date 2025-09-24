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

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-ros-overlay, ros2nix, nixgl }:
  let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in
  {
    # we need to export micro-xrce-dds-gen so that we could call the
    # build .mitmCache.updateScript
    #
    # we also need ardupilot-sitl on it's own for ease of debugging the build
    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          nix-ros-overlay.overlays.default
          self.overlays.regularDeps
          self.overlays.rosDistroOverlays
        ];
      };
    in {
      micro-xrce-dds-gen = pkgs.micro-xrce-dds-gen;

      ardupilot-sitl = pkgs.rosPackages.jazzy.ardupilot-sitl;
      ardupilot-msgs = pkgs.rosPackages.jazzy.ardupilot-msgs;
    };

    overlays.regularDeps = final: prev: {
      # micro-ros-agent deps
      fast-dds = prev.callPackage ./pkgs/fast-dds {};
      fast-cdr = prev.callPackage ./pkgs/fast-cdr {};
      micro-cdr = prev.callPackage ./pkgs/micro-cdr {};
      micro-xrce-dds-client = prev.callPackage ./pkgs/micro-xrce-dds-client {};
      micro-xrce-dds-agent = prev.callPackage ./pkgs/micro-xrce-dds-agent {};
      micro-xrce-dds-gen = prev.callPackage ./pkgs/micro-xrce-dds-gen {};
    };
    overlays.rosDeps = final: prev: {
      # TODO: why were these special?
      micro-ros-agent = prev.callPackage ./pkgs/micro-ros-agent {};
      # inject micro-xrce-dds-agent dep
      # micro-ros-agent = 
      ardupilot-gazebo = prev.callPackage ./pkgs/ardupilot-gazebo {};
      ardupilot-gz-application = prev.callPackage ./pkgs/ardupilot-gz-application {};
      ardupilot-gz-bringup = prev.callPackage ./pkgs/ardupilot-gz-bringup {};
      ardupilot-gz-description = prev.callPackage ./pkgs/ardupilot-gz-description {};
      ardupilot-gz-gazebo = prev.callPackage ./pkgs/ardupilot-gz-gazebo {};
      ardupilot-sitl-models = prev.callPackage ./pkgs/ardupilot-sitl-models {};
      # ardupilot-dds-tests = super.callPackage ./ardupilot-dds-tests.nix {};
      ardupilot-msgs = prev.callPackage ./pkgs/ardupilot-msgs {};
      ardupilot-sitl = prev.callPackage ./pkgs/ardupilot-sitl {};

      # the auto-generated ardupilot packages want "gz-cmake3" & "gz-sim8"
      gz-cmake3 = prev.gz-cmake-vendor;
      gz-sim8 = prev.gz-sim-vendor;
      gz-common5 = prev.gz-common-vendor;
      gz-plugin2 = prev.gz-plugin-vendor;

      # nix-ros-overlay already does this except that ros_gz_sim got an update
      # and the substitute no longer works! Wonderful stuff 
      ros-gz-sim = prev.ros-gz-sim.overrideAttrs ({
        postPatch ? "", ...
      }: {
        # This launch file attempts to run the gz tool with a Ruby interpreter, but
        # in our case it is an regular executable because it is wrapped.
        # TODO: perhaps just create a regular patch instead of this
        # substituteInPlace stuff
        postPatch = postPatch + ''
          substituteInPlace launch/gz_sim.launch.py.in \
            --replace-fail "'ruby ' + get_executable_path('gz') + ' sim'" "'gz sim'" \
            --replace-fail "'ruby ' + get_executable_path('ign') + ' gazebo'" "'ign gazebo'"
        '';
      });
    };
    # I don't remember where I found this it'd be nice to figure that out
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
            nixgl.overlay
            self.overlays.regularDeps
            self.overlays.rosDistroOverlays
          ];
          config.permittedInsecurePackages = [
            "freeimage-3.18.0-unstable-2024-04-18"
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
            pkgs.which
            pkgs.less
            pkgs.vim
            ros2nix.packages."${system}".default

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
            pkgs.mission-planner
            # don't ask my why "Intel" corresponds to amdgpu
            pkgs.nixgl.nixGLIntel

            pkgs.python3Packages.ultralytics
            pkgs.python3Packages.openvino
            pkgs.opencv

            (with pkgs.rosPackages.jazzy; buildEnv {
              paths = [
                ros-core

                ament-black
                ament-cmake
                ament-cmake-black
                ament-cmake-copyright
                ament-cmake-cppcheck
                ament-cmake-cpplint
                ament-cmake-flake8
                ament-cmake-lint-cmake
                ament-cmake-mypy
                ament-cmake-pclint
                ament-cmake-pep257
                ament-cmake-pycodestyle
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
                pkgs.gst_all_1.gst-libav
                pkgs.gst_all_1.gst-plugins-bad
                pkgs.gst_all_1.gst-plugins-base
                pkgs.gst_all_1.gstreamer
                pkgs.gz-cmake_3
                gz-common-vendor
                gz-plugin-vendor
                gz-sim-vendor
                launch
                launch-pytest
                launch-ros
                micro-ros-agent
                micro-ros-msgs
                pkgs.opencv
                pkgs.opencv.cxxdev
                pkgs.python3Packages.geopy
                pkgs.python3Packages.pytest
                pkgs.python3Packages.scipy
                pkgs.rapidjson
                rclpy
                robot-state-publisher
                ros-gz-bridge
                ros-gz-sim
                rosgraph-msgs
                rosidl-default-generators
                rosidl-default-runtime
                sdformat-urdf
                sensor-msgs
                pkgs.socat
                std-msgs
                tf2-msgs
                topic-tools

                tf2-ros

                # these are the deps that ros2nix missed?
                ament-cmake-core
                python-cmake-module
                micro-ros-agent
                python3Packages.pexpect
                rviz2

                # gazebo?
                # https://github.com/lopsided98/nix-ros-overlay/pull/591
                # https://github.com/lopsided98/nix-ros-overlay/issues/638
                # ros-gz
                ros-gz-sim
                ros-gz-sim-demos
                sdformat-urdf
                # from https://github.com/lopsided98/nix-ros-overlay/pull/422
                gz-cmake-vendor
                gz-common-vendor
                gz-dartsim-vendor
                gz-fuel-tools-vendor
                gz-gui-vendor
                gz-launch-vendor
                gz-math-vendor
                gz-msgs-vendor
                gz-ogre-next-vendor
                gz-physics-vendor
                gz-plugin-vendor
                gz-rendering-vendor
                gz-sensors-vendor
                gz-sim-vendor
                gz-tools-vendor
                gz-transport-vendor
                gz-utils-vendor
                ros-gz
                ros-core

                # at last
                # ardupilot-gazebo
                # ardupilot-gz-application
                # ardupilot-gz-bringup
                # ardupilot-gz-description
                # ardupilot-gz-gazebo
                # ardupilot-sitl-models
                # ardupilot-msgs
                # ardupilot-sitl


                # gazebo?
                ros-gz
                geometry-msgs
                turtlebot4-desktop
                turtlebot4-simulator
                slam-toolbox
                nav2-minimal-tb4-sim
                nav2-minimal-tb3-sim
                # rqt metapackages
                rqt-common-plugins
                rqt-tf-tree
                tf2-tools

                 geometry-msgs
                 turtlebot4-desktop
                 turtlebot4-simulator
                 slam-toolbox
                 nav2-minimal-tb4-sim
                 nav2-minimal-tb3-sim

                # for our node
                rclpy
                pybind11-vendor
                rqt-graph

                # for yolo-ros
                # really we should just package yolo-ros properly
                # or perhaps use our own object detection node since yolo-ros
                # does a bit more than we need
                # geometry-msgs
                # std-msgs
                # ament-cmake
                # ament-copyright
                # ament-flake8
                # ament-pep257
                # pkgs.python3Packages.pytest
                cv-bridge
                # rclpy
                # sensor-msgs
                # std-srvs
                # yolo-ros's python deps
                # pkgs.python3Packages.numpy
                # pkgs.python3Packages.opencv-python
                # pkgs.python3Packages.typing-extensions
                # pkgs.python3Packages.lap
              ];
            })
          ];
        };
      });

    # the nix-ros-overlay binary cache
    nixConfig = {
      extra-substituters = [ "https://ros.cachix.org" ];
      extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
    };

  };
}
