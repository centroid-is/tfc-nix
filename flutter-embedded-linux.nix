{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "flutter-embedded-linux";
  version = "db49896cf2";

  src = fetchurl {
    url = "https://github.com/sony/flutter-embedded-linux/releases/download/${version}/elinux-x64-release.zip";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Replace with actual hash
  };

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    mkdir -p $out/lib
    unzip $src -d $out/lib
  '';

  meta = with stdenv.lib; {
    description = "Prebuilt binaries of Sony's Flutter embedding for Linux devices";
    homepage = "https://github.com/sony/flutter-embedded-linux";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];  # You can add your name here
    platforms = platforms.linux;
  };
}
