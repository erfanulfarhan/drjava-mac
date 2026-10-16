#!/bin/zsh
# Builds DrJava-for-Mac.zip: DrJava with Java 8 inside, a native launcher, and a Read Me.
#
# Inputs (override with environment variables):
#   DRJAVA_JAR  the official drjava-beta-20190813-220051.jar from SourceForge
#   JDK         Amazon Corretto 8 for Apple Silicon, unpacked (a .jdk bundle)
#   OUT         where the zip goes
set -euo pipefail
cd "${0:A:h}"

DRJAVA_JAR=${DRJAVA_JAR:-$HOME/Downloads/drjava-beta-20190813-220051.jar}
DRJAVA_MD5=d40c4584078750c344ffe72aa00823b3
JDK=${JDK:-$HOME/Library/Java/JavaVirtualMachines/amazon-corretto-8.jdk}
OUT=${OUT:-$HOME/Downloads/DrJava-for-Mac.zip}

STAGE="build/DrJava for Mac"
APP="$STAGE/DrJava.app"
JAVA8="$APP/Contents/PlugIns/Java8.jdk"

[[ $(md5 -q "$DRJAVA_JAR") == $DRJAVA_MD5 ]] || { print -u2 "Not the official DrJava jar: $DRJAVA_JAR"; exit 1; }
[[ $(lipo -archs "$JDK/Contents/Home/jre/lib/server/libjvm.dylib") == arm64 ]] || { print -u2 "Need Corretto 8 for Apple Silicon at $JDK"; exit 1; }

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/PlugIns"

# One launcher binary for Apple Silicon and Intel Macs.
clang -O2 -Wall -Werror -fobjc-arc -arch arm64 -arch x86_64 -mmacosx-version-min=10.13 \
  -framework Foundation -o "$APP/Contents/MacOS/DrJava" launcher.m

# DrJava, with its debugger port kept on the Mac (see patch_jar.py).
python3 -I patch_jar.py "$DRJAVA_JAR" "$APP/Contents/Resources/drjava.jar"
unzip -p "$DRJAVA_JAR" edu/rice/cs/drjava/LICENSE > "$APP/Contents/Resources/LICENSE-DrJava.txt"
cp Info.plist "$APP/Contents/Info.plist"

# App icon from DrJava's own 64 px artwork.
unzip -p "$DRJAVA_JAR" edu/rice/cs/drjava/ui/icons/drjava64.png > build/drjava64.png
mkdir build/DrJava.iconset
for size in 16 32 128 256 512; do
  sips -z $size $size build/drjava64.png --out build/DrJava.iconset/icon_${size}x${size}.png >/dev/null
  sips -z $((size * 2)) $((size * 2)) build/drjava64.png --out build/DrJava.iconset/icon_${size}x${size}@2x.png >/dev/null
done
iconutil -c icns build/DrJava.iconset -o "$APP/Contents/Resources/DrJava.icns"

# Java 8: an APFS clone of Corretto (no extra disk space), without its 50 MB source archive.
cp -cR "$JDK" "$JAVA8"
rm "$JAVA8/Contents/Home/src.zip"

# Removing src.zip breaks Amazon's seal on the Java bundle, so seal it again (ad hoc). The
# programs inside keep Amazon's signatures and entitlements; --deep would strip them.
codesign --force --sign - "$JAVA8"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"

{ cat readme.txt; cat "$APP/Contents/Resources/LICENSE-DrJava.txt"; } > "$STAGE/Read Me.txt"

rm -f "$OUT"
ditto -c -k --sequesterRsrc --keepParent "$STAGE" "$OUT"
print "Built $OUT ($(du -h "$OUT" | cut -f1))"
