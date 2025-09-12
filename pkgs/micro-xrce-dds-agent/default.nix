{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  micro-xrce-dds-client,
  fast-cdr,
  foonathan-memory,
  fast-dds,
  spdlog,
}:

stdenv.mkDerivation rec {
  pname = "micro-xrce-dds-agent";
  version = "2.4.3";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Micro-XRCE-DDS-Agent";
    rev = "v${version}";
    hash = "sha256-t2PZurWc8Kbkm3zFyNwHQea4Yj+zHWFXFqZ0E19km54=";
  };

  cmakeFlags = [
    # use local versions of everything
    "-DUAGENT_USE_SYSTEM_FASTDDS=ON"
    "-DUAGENT_USE_SYSTEM_FASTCDR=ON"
    "-DUAGENT_USE_SYSTEM_LOGGER=ON"
    # TODO: debug why we can't compile with logging
    "-DUAGENT_LOGGER_PROFILE=OFF"
  ];

  nativeBuildInputs = [
    cmake
  ];

  propagatedBuildInputs = [
    micro-xrce-dds-client
    fast-cdr
    foonathan-memory
    fast-dds
    spdlog
  ];

  meta = {
    description = "Micro XRCE-DDS Agent respository. Looking for commercial support? Contact info@eprosima.com";
    homepage = "https://github.com/eProsima/Micro-XRCE-DDS-Agent";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "micro-xrce-dds-agent";
    platforms = lib.platforms.all;
  };
}
