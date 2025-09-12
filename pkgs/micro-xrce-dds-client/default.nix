{ lib
, stdenv
, fetchFromGitHub
, cmake
, micro-cdr
}:

stdenv.mkDerivation rec {
  pname = "micro-xrce-dds-client";
  version = "2.4.3";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Client";
    rev = "v${version}";
    hash = "sha256-sru77aJvJYKbpQeCaR/3Xx3X3us+4N3dcAKtzBfgyik=";
  };

  nativeBuildInputs = [
    cmake
  ];

  propagatedBuildInputs = [
    micro-cdr
  ];

  meta = with lib; {
    description = "Micro XRCE-DDS Client repository. Looking for commercial support? Contact info@eprosima.com";
    homepage = "https://github.com/eProsima/Micro-XRCE-DDS-Client.git";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "micro-xrce-dds-client";
    platforms = platforms.all;
  };
}
