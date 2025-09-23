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
    owner = "ardupilot";
    repo = "Micro-XRCE-DDS-Gen";
    rev = "v4.7.1";
    hash = "sha256-6mDIa6o6lrXHxYX+7HNPvUV8XFVuMeS1rYc3KSt+hLU=";
    fetchSubmodules = true; # IDL-Parser
  };

  patches = [
    ./remove-git-dependency.patch
    ./ensure-fno-working-directory.patch
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

  # TODO: micro-xrce-dds-gen uses "cpp" (c preprocessor) at runtime so we ought
  # to declare that in propagatedBuildInputs

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
