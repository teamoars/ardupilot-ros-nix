{ lib
, stdenv
, fetchFromGitHub
, cmake
}:

stdenv.mkDerivation rec {
  pname = "fast-cdr";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Fast-CDR";
    rev = "v${version}";
    hash = "sha256-hhYNgBLJCTZV/fgHEH7rxlTy+qpShAykxHLbPtPA/Uw=";
  };

  nativeBuildInputs = [
    cmake
  ];

  meta = with lib; {
    description = "EProsima FastCDR library provides two serialization mechanisms. One is the standard CDR serialization mechanism, while the other is a faster implementation of it. Looking for commercial support? Contact info@eprosima.com";
    homepage = "https://github.com/eProsima/Fast-CDR";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "fast-cdr";
    platforms = platforms.all;
  };
}
