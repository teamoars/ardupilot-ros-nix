{ lib
, stdenv
, fetchFromGitHub
, cmake
, micro-cdr
}:

stdenv.mkDerivation rec {
  pname = "micro-xrce-dds-client";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Client";
    rev = "v${version}";
    hash = "sha256-bh9Om36idZ1ybUNn6vHsm6TUDjIccZHTNKgeT8wr+DU=";
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
