{ lib
, stdenv
, fetchFromGitHub
, cmake
, fast-cdr
, asio
, tinyxml-2
, foonathan-memory
, boost
}:

stdenv.mkDerivation rec {
  pname = "fast-dds";
  version = "2.14.3";

  src = fetchFromGitHub {
    owner = "eProsima";
    repo = "Fast-DDS";
    rev = "v${version}";
    hash = "sha256-5C8nhho+C5MBpm07E7pspn4oeDafUzVBVPrbmpJvXLY=";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    fast-cdr
    # CMakeLists.txt says asio 1.10.8 but really it's the latest version
    asio
    foonathan-memory
    boost
  ];

  propagatedBuildInputs = [
    tinyxml-2
  ];

  meta = with lib; {
    description = "The most complete DDS - Proven: Plenty of success cases. Looking for commercial support? Contact info@eprosima.com";
    homepage = "https://github.com/eProsima/Fast-DDS";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    mainProgram = "fast-dds";
    platforms = platforms.all;
  };
}
