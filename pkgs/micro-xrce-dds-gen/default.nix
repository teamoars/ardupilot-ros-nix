{
  
  lib,
  stdenv,
  fetchFromGithub,
  gradle_7,
  gradle,
  jdk,
  jdk11,
}:

let
  name = "micro-xrce-dds-gen";

  jdk = jdk11;
  gradle = gradle_7;
in
stdenv.mkDerivation {
  inherit name;

  src = fetchFromGithub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Gen";
    rev = "e740511c8e6965c6837862b3884d02b604c90073";
    hash = lib.fakeHash;
    fetchSubmodules = true; # IDL-Parser
  };

  patches = [
    ./0001-remove-git-dependency.patch
    # ./0002-make-build.gradle-compatible-with-gradle-8.patch
  ];


  mitmCache = gradle.fetchDeps {
    pname = name; # ?!
    data = ./deps.json;
  };

  nativeBuildInputs = [
    gradle
    jdk
  ];

  installPhase = ''
    runHook preInstall

    cp -r share $out

    runHook postInstall
  '';
}
