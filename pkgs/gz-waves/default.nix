{
  lib,
  cmake,
  buildRosPackage,
  fetchFromGitHub,
  ament-cmake,
  cgal,
  gmp,
  mpfr,
  fftwMpi,
  gz-math-vendor,
  gz-plugin-vendor,
  gz-common-vendor,
  gz-msgs-vendor,
  gz-transport-vendor,
  gz-rendering-vendor,
  gz-sim-vendor,
  sdformat-vendor,
}:
buildRosPackage rec {
  name = "gz-waves";

  src = fetchFromGitHub {
    owner = "j-aub";
    repo = "asv_wave_sim";
    rev = "0574e1485fd80a74a88e2a900d806cf6995c9c56";
    hash = "sha256-s9jbvSS9Od5jbbyugM8v3OWWIBFfP3Yz/0QFemhsuhk=";
  };

  # tries to use git to fetch a test dependency
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail "include(Add_gnuplot-iostream)" ""
  '';

  # We set this variable so that CMakeLists.txt uses the correct dependencies.
  GZ_VERSION = "ionic";

  buildType = "ament_cmake";
  # asv_wave_sim docs say to set these
  cmakeFlags = [ 
    "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
    "-DBUILD_TESTING=off"
    "-DCMAKE_CXX_STANDARD=17"
  ];
  sourceRoot = "${src.name}/gz-waves/";
  buildInputs = [
    ament-cmake
  ];
  propagatedBuildInputs = [
    gz-math-vendor
    gz-plugin-vendor
    gz-common-vendor
    gz-msgs-vendor
    gz-transport-vendor
    gz-rendering-vendor
    gz-sim-vendor
    sdformat-vendor
  ];
  nativeBuildInputs = [
    cgal
    # cgal wants these and yet doesn't propagate them as build inputs?
    gmp mpfr

    fftwMpi # I think it's this one?
  ];

  meta = {
    description = "This package contains plugins that support the simulation of waves and surface vessels in Gazebo.";
    license = with lib.licenses; [ "GPL-3.0" ];
  };
}
