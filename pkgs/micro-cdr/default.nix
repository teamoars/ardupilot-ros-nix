{ lib
, stdenv
, fetchFromGitHub
, cmake
}:

stdenv.mkDerivation rec {
  pname = "micro-cdr";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-CDR";
    rev = "v${version}";
    hash = "sha256-X5kE8dMpwXL2hzpT6vY+BHa70Fw21z++vs8nVARpxNk=";
  };

  nativeBuildInputs = [
    cmake
  ];

  # >  Imported target "microcdr" includes non-existent path
  # > 
  # >  "/nix/store/nqmwd7ymw9mdliiwdzgfklv9ndl7vpwd-micro-cdr-2.0.1/microcdr-2.0.1/include"
  # > 
  # >  in its INTERFACE_INCLUDE_DIRECTORIES.  Possible reasons include:
  # 
  # https://github.com/NixOS/nixpkgs/pull/238621 
  postInstall = ''
    substituteInPlace $out/microcdr-2.0.1/share/microcdr/cmake/microcdrTargets.cmake \
    --replace "\''${_IMPORT_PREFIX}/include" "$out/include"
  '';

  meta = with lib; {
    description = "";
    homepage = "https://github.com/eProsima/Micro-CDR.git";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "micro-cdr";
    platforms = platforms.all;
  };
}
