{
  lib,
  stdenv,
  cmake,
  buildRosPackage,
  fetchFromGitHub,
  ament-cmake,
  gz-cmake3,
  cgal,
  gmp,
  mpfr,
  fftwMpi,
  gz-cmake-vendor,
  gz-math-vendor,
  gz-plugin-vendor,
  gz-common-vendor,
  gz-msgs-vendor,
  gz-transport-vendor,
  gz-rendering-vendor,
  gz-sim-vendor,
  sdformat-vendor,
  gz-ogre-next-vendor,
  tinyxml-2,
  eigen,
}:
# buildRosPackage rec {
stdenv.mkDerivation (finalAttrs: {
  name = "gz-waves";

  src = fetchFromGitHub {
    owner = "srmainwaring";
    repo = "asv_wave_sim";
    rev = "ca8629df4e191235753dfae92ef725d30b923364";
    hash = "sha256-BUizPVrvxJ5k9ahYyCYb8wUST/Ppv+qt2gdatjSrd10=";
  };

  # tries to use git to fetch a test dependency
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail "include(Add_gnuplot-iostream)" ""
  '';

  # We set this variable so that CMakeLists.txt uses the correct dependencies.
  # This is silly because it'll only work for jazzy. I'm not sure what the
  # better solution might be though.
  GZ_VERSION = "harmonic";

  # TODO: the docs say to build with
  # -DCMAKE_BUILD_TYPE=RelWithDebInfo
  # -DCMAKE_CXX_STANDARD=17
  # buildType = "ament_cmake";
  # asv_wave_sim docs say to set these
  cmakeFlags = [ 
    "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
    "-DBUILD_TESTING=off"
    "-DCMAKE_CXX_STANDARD=17"
  ];
  dontWrapQtApps = true;
  dontPatchELF = true;
  dontStrip = true;
  sourceRoot = "${finalAttrs.src.name}/gz-waves/";
  buildInputs = [
    # ament-cmake
    cmake
  ];
  propagatedBuildInputs = [
    gz-cmake-vendor
    gz-math-vendor
    gz-plugin-vendor
    gz-common-vendor
    gz-msgs-vendor
    gz-transport-vendor
    gz-rendering-vendor
    gz-sim-vendor
    sdformat-vendor
    # ogre2 is secretly needed
    # the build doesn't fail without it but the visuals break
    # gz-ogre-next-vendor
  ];
  nativeBuildInputs = [
    cgal
    # cgal wants them and yet doesn't propagate it?!
    gmp
    mpfr

    fftwMpi # I think it's this one?
    # eigen # not mentioned in the docs

    tinyxml-2
  ];

  meta = {
    description = "This package contains plugins that support the simulation of waves and surface vessels in Gazebo.";
    license = with lib.licenses; [ "GPL-3.0" ];
  };
})
