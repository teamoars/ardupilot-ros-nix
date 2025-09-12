{ lib
, stdenv
, fetchFromGitHub
, cmake
, doctest
}:

stdenv.mkDerivation rec {
  pname = "foonathan-memory";
  version = "0.7-3";

  src = fetchFromGitHub {
    owner = "foonathan";
    repo = "memory";
    rev = "v${version}";
    hash = "sha256-nLBnxPbPKiLCFF2TJgD/eJKJJfzktVBW3SRW2m3WK/s=";
  };

  # https://discourse.nixos.org/t/dealing-with-cmake-fetchcontent/34768/5
  cmakeFlags = [
    "-DFETCHCONTENT_SOURCE_DIR_DOCTEST=${doctest.src}"
  ];

  nativeBuildInputs = [
    cmake
  ];

  propagatedBuildInputs = [
    doctest
  ];

  meta = with lib; {
    description = "STL compatible C++ memory allocator library using a new RawAllocator concept that is similar to an Allocator but easier to use and write";
    homepage = "https://github.com/foonathan/memory";
    changelog = "https://github.com/foonathan/memory/blob/${src.rev}/CHANGELOG.md";
    license = licenses.zlib;
    maintainers = with maintainers; [ ];
    platforms = platforms.all;
  };
}
