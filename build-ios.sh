#!/bin/sh
# Configure/build iPhone or simulator. Apple signing is deliberately optional.
set -eu
cd "$(dirname "$0")"
MODE=${1:-device}
case "$MODE" in
 device) SDK=iphoneos ;;
 simulator) SDK=iphonesimulator ;;
 *) echo "Usage: sh build-ios.sh [device|simulator]" >&2; exit 2 ;;
esac
mkdir -p build/ios-deps
fetch() {
 name=$1; repo=$2; revision=$3
 dest="build/ios-deps/$name"
 if [ ! -d "$dest/.git" ]; then
  git init "$dest"
  git -C "$dest" remote add origin "$repo"
 fi
 if [ "$(git -C "$dest" rev-parse HEAD 2>/dev/null || true)" != "$revision" ]; then
  git -C "$dest" fetch --depth 1 origin "$revision"
  git -C "$dest" checkout --detach FETCH_HEAD
 fi
}
fetch SDL https://github.com/libsdl-org/SDL.git 8acf7cfc0f88717e5c036f60f0314bfcafe39189
OUT="build/ios-$MODE-xcode"
cmake -S . -B "$OUT" -G Xcode -DCMAKE_SYSTEM_NAME=iOS  -DCMAKE_OSX_SYSROOT="$SDK" -DCMAKE_OSX_ARCHITECTURES=arm64  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0  -DDOOMRPG_BUNDLE_ID="${BUNDLE_ID:-org.doomrpg.doom2}"
if [ -n "${DEVELOPMENT_TEAM:-}" ]; then
 xcodebuild -project "$OUT/DoomIIRPG.xcodeproj" -scheme DoomIIRPG -configuration Release   -sdk "$SDK" -allowProvisioningUpdates DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" build
else
 xcodebuild -project "$OUT/DoomIIRPG.xcodeproj" -scheme DoomIIRPG -configuration Release   -sdk "$SDK" CODE_SIGNING_ALLOWED=NO build
fi
if [ "$MODE" = device ]; then
 mkdir -p dist/ios/Payload
 ditto "$OUT/Release-iphoneos/DoomIIRPG.app" dist/ios/Payload/DoomIIRPG.app
 if [ -n "${DEVELOPMENT_TEAM:-}" ]; then PACKAGE=DoomIIRPG-ios-development.ipa; else PACKAGE=DoomIIRPG-ios-unsigned.ipa; fi
 (cd dist/ios && /usr/bin/zip -qr "../$PACKAGE" Payload)
 echo "IPA: dist/$PACKAGE"
fi
