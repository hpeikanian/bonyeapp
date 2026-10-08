#!/usr/bin/env bash
set -euo pipefail
# Use the existing checkout: cloud tasks are already isolated; do not create worktrees.
cd /workspace/bonyeapp
export PUB_CACHE=/workspace/toolchains/pub-cache
export XDG_CONFIG_HOME=/workspace/toolchains/config
export ANDROID_USER_HOME=/workspace/toolchains/android-home
export ANDROID_HOME=/workspace/toolchains/android-sdk
export GRADLE_USER_HOME=/workspace/toolchains/gradle-cache
export ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/toolchains/analyzer-state
# JVM tools do not automatically use HTTPS_PROXY; configure only non-secret host/port.
python3 - "$GRADLE_USER_HOME" <<'PYPROXY'
import os,pathlib,urllib.parse,sys
raw=os.environ.get('HTTPS_PROXY') or os.environ.get('https_proxy')
if raw:
    proxy=urllib.parse.urlsplit(raw)
    if proxy.username or proxy.password: raise SystemExit('Use the platform proxy route without copying proxy credentials')
    target=pathlib.Path(sys.argv[1])/'gradle.properties'; target.parent.mkdir(parents=True,exist_ok=True)
    settings={'systemProp.https.proxyHost':proxy.hostname,'systemProp.https.proxyPort':str(proxy.port or 80),'systemProp.http.proxyHost':proxy.hostname,'systemProp.http.proxyPort':str(proxy.port or 80),'systemProp.http.nonProxyHosts':'localhost|127.*|[::1]','org.gradle.workers.max':'2'}
    if pathlib.Path('/etc/ssl/certs/java/cacerts').is_file(): settings['systemProp.javax.net.ssl.trustStore']='/etc/ssl/certs/java/cacerts'
    existing=target.read_text().splitlines() if target.exists() else []
    kept=[line for line in existing if line.split('=',1)[0].strip() not in settings]
    target.write_text('\n'.join(kept+[f'{k}={v}' for k,v in settings.items()])+'\n')
PYPROXY
export JAVA_HOME=/workspace/toolchains/java
if [ ! -x "$JAVA_HOME/bin/javac" ]; then
  jdk_archive=$(mktemp /tmp/bonye-jdk21.XXXXXX.tar.gz)
  jdk_checksum=$(mktemp /tmp/bonye-jdk21.XXXXXX.sha256)
  curl --fail --location --max-time 180 https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz -o "$jdk_archive"
  curl --fail --location --max-time 30 https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz.sha256 -o "$jdk_checksum"
  python3 - "$jdk_archive" "$jdk_checksum" <<'PYJDK'
import pathlib,hashlib,tarfile,sys
archive=pathlib.Path(sys.argv[1]); expected=pathlib.Path(sys.argv[2]).read_text().split()[0]
assert hashlib.sha256(archive.read_bytes()).hexdigest()==expected, 'Official JDK checksum mismatch'
root=pathlib.Path('/workspace/toolchains/jdk21');root.mkdir(parents=True,exist_ok=True)
with tarfile.open(archive) as tar:
    entries=tar.getmembers(); top=entries[0].name.split('/')[0]
    tar.extractall(root,filter='data')
link=pathlib.Path('/workspace/toolchains/java')
assert not link.exists(), 'Preserve and inspect an existing Java toolchain'
link.symlink_to(root/top,target_is_directory=True)
archive.unlink();pathlib.Path(sys.argv[2]).unlink()
PYJDK
fi
"$JAVA_HOME/bin/javac" -version
export PATH="$JAVA_HOME/bin:$PATH"
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
mkdir -p /workspace/toolchains "$PUB_CACHE" "$XDG_CONFIG_HOME" "$ANDROID_USER_HOME" "$ANDROID_HOME" "$GRADLE_USER_HOME"
if [ ! -d /workspace/toolchains/flutter/.git ]; then
  git clone --depth 1 --branch 3.29.3 https://github.com/flutter/flutter.git /workspace/toolchains/flutter
fi
if [ "$(git -C /workspace/toolchains/flutter rev-parse HEAD)" != ea121f8859e4b13e47a8f845e4586164519588bc ]; then
  echo 'Flutter toolchain must be version 3.29.3; preserve and inspect any existing toolchain before replacing it.' >&2
  exit 1
fi
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  android_archive=$(mktemp /tmp/bonye-android.XXXXXX.zip)
  curl --fail --location --max-time 180 https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip -o "$android_archive"
  python3 - "$android_archive" "$ANDROID_HOME" <<'PY'
import hashlib, pathlib, sys, zipfile
archive=pathlib.Path(sys.argv[1]); root=pathlib.Path(sys.argv[2])/'cmdline-tools'/'latest'
assert hashlib.sha1(archive.read_bytes()).hexdigest()=='e025545c62a8e64c7559119566a569fb1dec5f60', 'Android artifact checksum mismatch'
with zipfile.ZipFile(archive) as z:
    for item in z.infolist():
        name=pathlib.PurePosixPath(item.filename)
        assert name.parts[0]=='cmdline-tools' and '..' not in name.parts
        relative=pathlib.Path(*name.parts[1:]); target=root/relative
        if item.is_dir(): target.mkdir(parents=True,exist_ok=True)
        else:
            target.parent.mkdir(parents=True,exist_ok=True); target.write_bytes(z.read(item))
            mode=(item.external_attr>>16)&0o777
            if mode: target.chmod(mode)
archive.unlink()
PY
fi
export PATH="/workspace/toolchains/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
license_answers=$(mktemp /tmp/bonye-sdk-licenses.XXXXXX)
python3 - "$license_answers" <<'PY'
import pathlib,sys
pathlib.Path(sys.argv[1]).write_text('y\n'*100)
PY
sdkmanager --sdk_root="$ANDROID_HOME" --licenses < "$license_answers"
rm "$license_answers"
sdkmanager --sdk_root="$ANDROID_HOME" 'platform-tools' 'platforms;android-35' 'platforms;android-34' 'build-tools;35.0.0' 'build-tools;34.0.0' 'ndk;27.0.12077973' 'cmake;3.22.1'
if ! git -C /workspace/toolchains/flutter show-ref --verify --quiet refs/tags/3.29.3; then
  git -C /workspace/toolchains/flutter fetch --depth 1 origin refs/tags/3.29.3:refs/tags/3.29.3
fi
flutter --suppress-analytics --version
flutter pub get --enforce-lockfile
flutter --suppress-analytics analyze
flutter --suppress-analytics test
