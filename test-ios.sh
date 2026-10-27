#!/bin/sh
set -eu
cd "$(dirname "$0")"
[ "$#" = 1 ] || { echo "Usage: sh test-ios.sh /absolute/path/to/original-game.ipa" >&2; exit 2; }
mkdir -p build
xcrun --sdk macosx clang -Iios ios/ImportData.c tests/ios_import_tests.c -lz -o build/ios-import-tests
build/ios-import-tests "$1"
xcrun --sdk macosx clang -fobjc-arc -Iios -framework Foundation ios/SaveArchive.m tests/ios_save_tests.m -o build/ios-save-tests
build/ios-save-tests
