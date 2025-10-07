# TODO: the mavlink crate uses 'git' so we need to patch that out somehow if we
# want to compile mavlink-server in nix
#
# https://artemis.sh/2023/07/08/nix-rust-project-with-git-dependencies.html
# https://discourse.nixos.org/t/rust-app-fails-to-build-help-figuring-out-why/53847
# https://discourse.nixos.org/t/how-to-vendor-a-dependency-with-cargo-and-buildrustpackage/59579
# https://www.reddit.com/r/rust/comments/brd8oa/trouble_with_patch_in_cargotoml/
# https://discourse.nixos.org/t/help-with-rust-overlay-for-transitive-dependency/59534
# https://discourse.nixos.org/t/how-to-include-a-local-dependency-in-a-rust-build/15793
# https://doc.rust-lang.org/cargo/reference/build-scripts.html
#
# { lib, fetchFromGitHub, rustPlatform }:
#
# rustPlatform.buildRustPackage rec {
#   pname = "mavlink-server";
#   version = "0.5.10";
#
#   src = fetchFromGitHub {
#     owner = "bluerobotics";
#     repo = pname;
#     rev = version;
#     hash = "sha256-3nFlZoMEhfN+vqgl9xxUHOKoWwKodJhiJqzuKanDHqQ=";
#   };
#
#   cargoHash = "sha256-3LBrcW0a3zECc1G1cmjhIZZdOt6u0HASdKzEfLwRseo=";
#
#   meta = with lib; {
#     description = "Ultimate MAVLink server, with support to: REST API, WebSocket, UDP, TCP, Serial, TLog and more!";
#     homepage = "https://github.com/bluerobotics/mavlink-server";
#     license = licenses.mit; # TODO: is 'mit" specifically or some mit variant
#     maintainers = [];
#   };
# }

# for now use the prebuilt version on github
# based on https://nixos.wiki/wiki/Packaging/Binaries

# TODO: for maximum hackiness, we'll only support x86_64 linux :D fix it!
{ stdenv, lib
, fetchurl
, alsaLib
, openssl
, zlib
, pulseaudio
, autoPatchelfHook
}:

stdenv.mkDerivation rec {
  pname = "mavlink-server";
  version = "0.5.10";

  src = fetchurl {
    url = "https://github.com/bluerobotics/mavlink-server/releases/download/${version}/mavlink-server-x86_64-unknown-linux-musl";
    hash = "sha256-4FdaNn0o9MsM8HMHIuziEtpVAtV2ltjMtlLM125Bs78=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  dontUnpack = true; # direct binary download

#   buildInputs = [
#     alsaLib
#     openssl
#     zlib
#     pulseaudio
#   ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -m755 -D ${src} $out/bin/mavlink-server
    runHook postInstall
  '';

  meta = with lib; {
    description = "Ultimate MAVLink server, with support to: REST API, WebSocket, UDP, TCP, Serial, TLog and more!";
    homepage = "https://github.com/bluerobotics/mavlink-server";
    license = licenses.mit; # TODO: is 'mit" specifically or some mit variant
    maintainers = [];
    platforms = platforms.linux;
  };
}
