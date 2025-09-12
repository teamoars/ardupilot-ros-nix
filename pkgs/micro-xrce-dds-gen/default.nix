{
  
  lib,
  stdenv,
  makeWrapper,
  fetchFromGitHub,
  gradle_7,
  jdk,
}:

let
  name = "micro-xrce-dds-gen";

  # Deprecated Gradle features were used in this build, making it incompatible with Gradle 8.0.
  gradle = gradle_7;
in
stdenv.mkDerivation {
  inherit name;

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Gen";
    rev = "a9016b950f82290613745219980d5f92b9cd20e5";
    hash = "sha256-hyTHQP8zA1qA5E2zd+FBqorVDVwRiUJjXQeGWwiZaCg=";
    fetchSubmodules = true; # IDL-Parser
  };

  patches = [
    ./0001-remove-git-dependency.patch
    # ./0002-make-build.gradle-compatible-with-gradle-8.patch
  ];


  # TODO: this is so screwed up. The "dependencies" task
  # (https://stackoverflow.com/questions/21814652/how-to-download-dependencies-in-gradle)
  # doesn't list all of our dependencies for whatever reason. We instead
  # opt to build the whole program(!) exclusively to fetch the deps
  gradleUpdateTask = "assemble";
  mitmCache = gradle.fetchDeps {
    pname = name; # ?!
    data = ./deps.json;
  };

  nativeBuildInputs = [
    gradle
    makeWrapper
    jdk
  ];

  installPhase = ''
    runHook preInstall

    # we make the wrapper ourselves bc micro-xrce-dds-gen doesn't provide a
    # good one
    mkdir -p $out/bin
    makeWrapper ${jdk}/bin/java $out/bin/microxrceddsgen\
      --add-flags "-jar $out/share/microxrceddsgen.jar"

    mkdir -p $out/share
    cp share/microxrceddsgen/java/microxrceddsgen.jar $out/share

    runHook postInstall
  '';
}
