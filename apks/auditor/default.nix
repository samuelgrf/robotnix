# https://www.reddit.com/r/GrapheneOS/comments/bpcttk/avb_key_auditor_app/
{ callPackage, lib, substituteAll, fetchFromGitHub, androidPkgs, jdk, gradle,
  domain ? "example.org",
  applicationName ? "Robotnix Auditor",
  applicationId ? "org.robotnix.auditor",
  signatureFingerprint ? "", # Signature that this app will be signed by.
  deviceFamily ? "",
  avbFingerprint ? ""
}:
let
  androidsdk = androidPkgs.sdk (p: with p.stable; [ tools platforms.android-30 build-tools-29-0-3 ]);
  buildGradle = callPackage ./gradle-env.nix {};
in
buildGradle rec {
  name = "Auditor-${version}.apk";
  version = "21"; # Latest as of 2020-10-05

  envSpec = ./gradle-env.json;

  src = fetchFromGitHub {
    owner = "grapheneos";
    repo = "Auditor";
    rev = version;
    sha256 = "1p9wagad5p3vgw57hh0r2qdj89ngjd155ksfyglh8bzdyq0af4y4";
  };

  patches = [
    (substituteAll {
    src = ./customized-auditor.patch;
    inherit domain applicationName applicationId ;
    signatureFingerprint = lib.toUpper signatureFingerprint;

    taimen_avbFingerprint = if (deviceFamily == "taimen") then avbFingerprint else "DISABLED_CUSTOM_TAIMEN";
    crosshatch_avbFingerprint = if (deviceFamily == "crosshatch") then avbFingerprint else "DISABLED_CUSTOM_CROSSHATCH";
  }) ];

  gradleFlags = [ "assembleRelease" ];

  ANDROID_HOME = "${androidsdk}/share/android-sdk";
  nativeBuildInputs = [ jdk ];

  installPhase = ''
    cp app/build/outputs/apk/release/app-release-unsigned.apk $out
  '';
}
