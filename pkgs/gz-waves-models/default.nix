{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  name = "gz-waves-models";

  src = fetchFromGitHub {
    owner = "srmainwaring";
    repo = "asv_wave_sim";
    rev = "ca8629df4e191235753dfae92ef725d30b923364";
    hash = "sha256-BUizPVrvxJ5k9ahYyCYb8wUST/Ppv+qt2gdatjSrd10=";
  };

  # just moving files around
  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/gz-waves-models
    for dir in config models world_models worlds; do
      cp -r $src/gz-waves-models/$dir $out/share/gz-waves-models
    done
  '';
}
