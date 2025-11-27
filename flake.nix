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
      # the build is failing with:
      # > configuration error: `project.license` must be valid exactly by one definition (2 matches found):
      # so we use the upstream nix-ros-overlay for now
      # inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      # inputs.nix-ros-overlay.follows = "nix-ros-overlay";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    nix-flamegraph = {
      url = "github:crabdancing/nix-flamegraph";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-ros-overlay, ros2nix, nixgl, nix-flamegraph }:
  let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

    applyDistroOverlay =
      rosOverlay: rosPackages:
      rosPackages
      // builtins.mapAttrs (
        rosDistro: rosPkgs: if rosPkgs ? overrideScope then rosPkgs.overrideScope rosOverlay else rosPkgs
      ) rosPackages;
  in
  {
    # we need to export micro-xrce-dds-gen so that we can build
    # .mitmCache.updateScript
    #
    # we have ardupilot-sitl on it's own for ease of debugging the build
    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          nix-ros-overlay.overlays.default
          self.overlays.regularDeps
          self.overlays.rosOverlay
          self.overlays.rosFixes
          self.overlays.rosManual
        ];
        config.permittedInsecurePackages = [
          "freeimage-3.18.0-unstable-2024-04-18"
        ];
      };
    in {
      micro-xrce-dds-gen = pkgs.micro-xrce-dds-gen;

      ardupilot-sitl = pkgs.rosPackages.jazzy.ardupilot-sitl;

      gz-waves = pkgs.rosPackages.jazzy.gz-waves;
      gz-waves-models = pkgs.gz-waves-models;

      ardupilot-sitl-models = pkgs.rosPackages.jazzy.ardupilot-sitl-models;
    };

    overlays.regularDeps = final: prev: {
      # micro-ros-agent deps
      fast-dds = prev.callPackage ./pkgs/fast-dds {};
      fast-cdr = prev.callPackage ./pkgs/fast-cdr {};
      micro-cdr = prev.callPackage ./pkgs/micro-cdr {};
      micro-xrce-dds-client = prev.callPackage ./pkgs/micro-xrce-dds-client {};
      micro-xrce-dds-agent = prev.callPackage ./pkgs/micro-xrce-dds-agent {};
      micro-xrce-dds-gen = prev.callPackage ./pkgs/micro-xrce-dds-gen {};

      mavlink-server = prev.callPackage ./pkgs/mavlink-server {};

      zenoh-plugin-ros2dds = prev.callPackage ./pkgs/zenoh-plugin-ros2dds {};

      gz-waves-models = prev.callPackage ./pkgs/gz-waves-models {};
    };
    overlays.rosManual = final: prev: {
      rosPackages = applyDistroOverlay (final: prev: {
        gz-waves = prev.callPackage ./pkgs/gz-waves {};
      }) prev.rosPackages;
    };
    # make nvidia drivers work without auto-detection
    overlays.nixglFix = final: prev: {
      nixgl = prev.nixgl.override {
        nvidiaVersion = "570.195.03";
        nvidiaHash = "sha256-1H3oHZpRNJamCtyc+nL+nhYsZfJyL7lgxPUxvXrF3B4=";
      };
    };
    overlays.rosOverlay = final: prev: {
      rosPackages = applyDistroOverlay (import ./generated/overlay.nix) prev.rosPackages;
    };
    # the auto-generated ros packages are a bit broken so we apply some fixes
    # TODO: why does the applyDistroOverlay "final'" and "prev'" not have some
    # of pkgs? e.g. micro-xrce-dds-gen & fetchFromGitHub
    overlays.rosFixes = final: prev: {
      rosPackages = applyDistroOverlay (final': prev': {
        ardupilot-sitl = prev'.ardupilot-sitl.overrideAttrs (finalAttrs: previousAttrs: {
          # the ardupilot build system is contained within a submodule. It might
          # be possible to use the waf package in nixpkgs instead
          src = previousAttrs.src.override {
            sha256 = "cSCgsOBVAXJDEG/WWxbYDA8kvwOHLm2JwwmxabB2sIg=";
            fetchSubmodules = true;
          };

          # from Ardupilot/Tools/scripts/build_ci.sh
          GIT_VERSION = "abcdef";
          GIT_VERSION_EXTENDED = "0123456789abcdef";
          GIT_VERSION_INT = "15";
          CHIBIOS_GIT_VERSION = "12345667";
          # our patch is based in the root of the ardupilot repo but we have
          # sourceRoot set
          # https://discourse.nixos.org/t/how-to-apply-patches-with-sourceroot/59727/2
          patchFlags = [ "-d" "/build/source" "-p1" ];
          patches = [
            # gcc complains about uninitialized variables
            ./0001-initialize-var_type_name.patch
            # git is quite heavily depended upon in the build process. This
            # patch is a crude hack to avoid needing "keepDotGit". There is a
            # patch floating around to properly remove the git depedency
            # (https://github.com/ArduPilot/ardupilot/pull/22848) but I am not
            # sure if it's still compatible with newer ardupilot versions
            ./0002-remove-git-dependency.patch
          ];

          # some of the build inputs aren't declared in the package.xml
          nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [
            prev.micro-xrce-dds-gen
            # TODO: submit an ardupilot patch to include pexpect in package.xml
            # https://github.com/ArduPilot/ardupilot/issues/26811#issuecomment-2913010021
            prev'.python3Packages.pexpect
            # ardupilot expects to find a 'git' executable even though it
            # doesn't get used
            prev.git
          ];

          # setting sourceRoot makes only sourceRoot writable but the ardupilot build
          # process expects to have the whole source directory writable. To be frank I'm
          # not sure if it's the build itself or just the shebang patching.
          #
          # I previously tried to chmod in preBuild but that gives permission denied
          # errors. Is chmod explictly allowed in postUnpack or does
          # "dontMakeSourcesWritable" allow us to chmod?
          #
          # https://discourse.nixos.org/t/unpack-phase-permission-denied/13382/4
          dotMakeSourcesWritable = true;
          postUnpack = ''
            chmod -R +w /build/source
          '';

          postPatch = ''
            patchShebangs /build/source/waf # why so long?
          '';
        });

        # adjust micro-ros-agent to use our build of micro-xrce-dds-agent
        micro-ros-agent = prev'.micro-ros-agent.overrideAttrs (finalAttrs: previousAttrs: {
            cmakeFlags = [
              # use local versions of everything
              "-DMICROROSAGENT_SUPERBUILD=OFF"
              "-DUAGENT_USE_SYSTEM_LOGGER=ON"
            ];

            propagatedBuildInputs = previousAttrs.propagatedBuildInputs ++ [
              prev.micro-xrce-dds-agent
            ];

            buildInputs = previousAttrs.buildInputs ++ [
              prev'.ament-lint-auto # missing dependency (TODO: submit a patch?)
            ];
        });

        # the auto-generated ardupilot packages want "gz-cmake3" & "gz-sim8"
        gz-cmake3 = prev'.gz-cmake-vendor;
        gz-sim8 = prev'.gz-sim-vendor;
        gz-common5 = prev'.gz-common-vendor;
        gz-plugin2 = prev'.gz-plugin-vendor;
      }) prev.rosPackages;
    };

    devShells = forAllSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nix-ros-overlay.overlays.default
            nixgl.overlay
            self.overlays.nixglFix
            self.overlays.regularDeps
            self.overlays.rosOverlay
            self.overlays.rosManual
            self.overlays.rosFixes
          ];
          config.permittedInsecurePackages = [
            "freeimage-3.18.0-unstable-2024-04-18"
          ];
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
             "nvidia"
          ];
        };
      in
      {
        generate = pkgs.mkShellNoCC {
          packages = [
            pkgs.vcstool
            ros2nix.packages."${system}".default

            pkgs.nix-tree
          ];
        };

        # default = pkgs.mkShellNoCC {
        default = pkgs.mkShell {
          shellHook = ''
            # Otherwise the spawned tmux will be the system-wide tmux server and
            # then whenever a tmux session is spawned outside of the devshell, it
            # will use the devshell's bash?! why can't nix just have a
            # containerized devshell like guix :(
            export TMUX_TMPDIR="$TMPDIR"
            
            # The ardupilot colcon hook has some incompatabilities with
            # nix-ros-overlay. Their hook is written in an unusual way to work
            # around an issue with resolving model file paths and I guess
            # combined with whatever nix-ros-overlay is doing everything breaks.
            #
            # Our silly fix is to inject the correct paths here. In the future,
            # consider submitting a patch upstream to fix this issue properly.
            export GZ_SIM_RESOURCE_PATH=$GZ_SIM_RESOURCE_PATH:$CMAKE_PREFIX_PATH/share
            # NOTE: GZ_SIM_PLUGIN_PATH is used intentionally here
            export GZ_SIM_SYSTEM_PLUGIN_PATH=$GZ_SIM_PLUGIN_PATH:$CMAKE_PREFIX_PATH/lib

            # asv_waves_sim does not use colcon hook and ask us to manually
            # set up our env :/
            #
            # ensure the model and world files are found
            export MODELS="${pkgs.gz-waves-models}/share/gz-waves-models"
            export PLUGINS="${pkgs.rosPackages.jazzy.gz-waves}"
            export GZ_SIM_RESOURCE_PATH=$GZ_SIM_RESOURCE_PATH:$MODELS/models:$MODELS/world_models:$MODELS/worlds

            # ensure the system plugins are found
            export GZ_SIM_SYSTEM_PLUGIN_PATH=$GZ_SIM_SYSTEM_PLUGIN_PATH:$PLUGINS/lib
            # TODO: I have not determined why we need to explictly specify this.
            # Things work without this variable in a typical ros setup
            export GZ_RENDERING_PLUGIN_PATH=$GZ_RENDERING_PLUGIN_PATH:$PLUGINS/lib
          '';

          packages = [
            pkgs.colcon

            pkgs.vcstool

            # for development
            pkgs.tmux
            pkgs.which
            pkgs.less
            pkgs.vim
            # had attempted to generate a flamegraph to see if 'nix develop'
            # could be sped up:
            # > nix-flamegraph -t '#devShells.x86_64-linux.default'
            # nix-flamegraph.packages.${system}.default
            pkgs.jq
            pkgs.strace
            pkgs.ltrace
            
            # for building & using the sitl
            # see https://github.com/tpwrules/ardupilot-dev-flake/blob/main/flake.nix
            pkgs.micro-xrce-dds-gen
            pkgs.git
            pkgs.rsync
            pkgs.mavproxy
            # otherwise mavproxy crashes
            # related: https://discourse.nixos.org/t/fritzing-no-gsettings-schemas-are-installed-on-the-system/64603
            pkgs.gsettings-desktop-schemas
            pkgs.mission-planner
            pkgs.mavlink-server
            pkgs.zenoh
            # zenoh bridge so that we don't have to deal with ros
            pkgs.zenoh-plugin-ros2dds
            # don't ask me why "Intel" corresponds to amdgpu
            pkgs.nixgl.nixGLIntel
            pkgs.nixgl.nixGLNvidia

            # ardupilot-gazebo needs gst available
            # Video/Audio data composition framework tools like "gst-inspect", "gst-launch" ...
            pkgs.gst_all_1.gstreamer
            # Common plugins like "filesrc" to combine within e.g. gst-launch
            pkgs.gst_all_1.gst-plugins-base
            # Specialized plugins separated by quality
            pkgs.gst_all_1.gst-plugins-good
            pkgs.gst_all_1.gst-plugins-bad
            pkgs.gst_all_1.gst-plugins-ugly
            # Plugins to reuse ffmpeg to play almost every video format
            pkgs.gst_all_1.gst-libav

            # a zenoh node that publishes /camera/image
            pkgs.python3Packages.zenoh
            pkgs.python3Packages.cyclonedds-python

            # asv_waves_sim deps
            pkgs.cgal
            pkgs.gmp
            pkgs.mpfr
            pkgs.fftwMpi
            pkgs.eigen

            (with pkgs.rosPackages.jazzy; buildEnv {
              paths = [
                ros-core
                # "ros2 launch"
                launch
                launch-pytest
                launch-ros

                sdformat-urdf
                rviz2

                # python script to publish images to zenoh
                cv-bridge

                # at last
                # TODO: ardupilot-gz-bringup doesn't properly declare it's
                # dependencies so we're forced to manually list of all the
                # required packages
                ardupilot-gazebo
                ardupilot-gz-application
                ardupilot-gz-bringup
                ardupilot-gz-description
                ardupilot-gz-gazebo
                ardupilot-msgs
                ardupilot-sitl
                ardupilot-sitl-models
                micro-ros-agent

                # waves
                gz-waves
                pkgs.gz-waves-models

                # asv_waves_sim deps
                gz-cmake-vendor
                gz-math-vendor
                gz-plugin-vendor
                gz-common-vendor
                gz-msgs-vendor
                gz-transport-vendor
                gz-rendering-vendor
                gz-sim-vendor
                sdformat-vendor
                # gz-ogre-next-vendor
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
