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
        ];
      };
    in {
      micro-xrce-dds-gen = pkgs.micro-xrce-dds-gen;

      ardupilot-sitl = pkgs.rosPackages.jazzy.ardupilot-sitl;
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
    };
    # make nvidia drivers work without auto-detection
    overlays.nixglFix = final: prev: {
      nixgl = prev.nixgl.override {
        nvidiaVersion = "570.190";
        nvidiaHash = "sha256-qGBYp+0gO/dp6gWycP7SeURfXU6DPq/v36f6Rf6quPw=";
      };
    };
    overlays.rosOverlay = final: prev: {
      rosPackages = applyDistroOverlay (import ./overlay.nix) prev.rosPackages;
    };
    # the auto-generated ros packages are a bit broken so we apply some fixes
    # TODO: why does the applyDistroOverlay "final'" and "prev'" not have some
    # of pkgs? e.g. micro-xrce-dds-gen & fetchFromGitHub
    overlays.rosFixes = final: prev: {
      rosPackages = applyDistroOverlay (final': prev': {
        ardupilot-sitl = prev'.ardupilot-sitl.overrideAttrs (finalAttrs: previousAttrs: {
          # the ardupilot build system is contained within a submodule...
          src = previousAttrs.src.override {
            sha256 = "cSCgsOBVAXJDEG/WWxbYDA8kvwOHLm2JwwmxabB2sIg=";
            fetchSubmodules = true;
          };

          # some of the build inputs aren't declared in the package.xml
          nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [
            # can we avoid this somehow?
            ((prev'.callPackage ./fake-git.nix { }) finalAttrs.src)

            # prev'.python3
            prev.micro-xrce-dds-gen
            # TODO: submit an ardupilot patch to include pexpect in package.xml
            # https://github.com/ArduPilot/ardupilot/issues/26811#issuecomment-2913010021
            prev'.python3Packages.pexpect
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
            # silly patch bc otherwise compiler rejects isn't happy
            substituteInPlace /build/source/libraries/AP_Scripting/generator/src/main.c \
              --replace-fail 'char *var_type_name;' 'char *var_type_name = NULL;'

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

        # nix-ros-overlay already does this except that ros_gz_sim got an update
        # and the substitute no longer works! Wonderful stuff 
        ros-gz-sim = prev'.ros-gz-sim.overrideAttrs ({
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

        default = pkgs.mkShellNoCC {
          # Otherwise the spawned tmux will be the system-wide tmux server and
          # then whenever a tmux session is spawned outside of the devshell, it
          # will use the devshell's bash?! why can't nix just have a
          # containerized devshell like guix :(
          shellHook = ''
            export TMUX_TMPDIR="$TMPDIR"
          '';

          packages = [
            pkgs.colcon

            pkgs.vcstool

            # for development
            pkgs.tmux
            pkgs.which
            pkgs.less
            pkgs.vim
            
            # for building & using the sitl
            # see https://github.com/tpwrules/ardupilot-dev-flake/blob/main/flake.nix
            pkgs.micro-xrce-dds-gen
            pkgs.git
            pkgs.rsync
            pkgs.mavproxy
            pkgs.mission-planner
            pkgs.mavlink-server
            pkgs.zenoh
            # don't ask me why "Intel" corresponds to amdgpu
            # pkgs.nixgl.nixGLIntel
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

            (with pkgs.rosPackages.jazzy; buildEnv {
              paths = [
                ros-core
                # "ros2 launch"
                launch
                launch-pytest
                launch-ros

                sdformat-urdf
                rviz2

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
