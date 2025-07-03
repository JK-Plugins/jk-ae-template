BuildName := "{{crate_name}}"
PluginName := "{{plugin_name}}"
BundleIdentifier := "com.adobe.AfterEffects.{% raw %}{{BuildName}}{% endraw %}"
BinaryName       := replace(lowercase(BuildName), "-", "_")
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

TargetDir := env_var_or_default("CARGO_TARGET_DIR", "../target")
export AESDK_ROOT := if env("AESDK_ROOT", "") == "" { justfile_directory() / "../../sdk/AfterEffectsSDK" } else { env_var("AESDK_ROOT") }
export PRSDK_ROOT := if env("PRSDK_ROOT", "") == "" { justfile_directory() / "../../sdk/Premiere Pro 22.0 C++ SDK" } else { env_var("PRSDK_ROOT") }

[windows]
build:
    cargo build
    if (-not $env:NO_INSTALL) { \
        Start-Process PowerShell -Verb runAs -ArgumentList "-Command Set-Location '{% raw %}{{source_directory()}}{% endraw %}'; Copy-Item -Force '{% raw %}{{TargetDir}}{% endraw %}\debug\{% raw %}{{BinaryName}}{% endraw %}.dll' 'C:\Program Files\Adobe\Common\Plug-ins\7.0\MediaCore\{% raw %}{{PluginName}}{% endraw %}.aex'" \
    }

[windows]
release:
    cargo build --release
    Copy-Item -Force '{% raw %}{{TargetDir}}{% endraw %}\release\{% raw %}{{BinaryName}}{% endraw %}.dll' '{% raw %}{{TargetDir}}{% endraw %}\release\{% raw %}{{BuildName}}{% endraw %}.aex'
    if (-not $env:NO_INSTALL) { \
        Start-Process PowerShell -Verb runAs -ArgumentList "-command Set-Location '{% raw %}{{source_directory()}}{% endraw %}'; Copy-Item -Force '{% raw %}{{TargetDir}}{% endraw %}\release\{% raw %}{{BinaryName}}{% endraw %}.dll' 'C:\Program Files\Adobe\Common\Plug-ins\7.0\MediaCore\{% raw %}{{PluginName}}{% endraw %}.aex'" \
    }

[macos]
build:
    cargo build
    just -f {% raw %}{{justfile()}}{% endraw %} create_bundle debug {% raw %}{{TargetDir}}{% endraw %}

[macos]
release:
    cargo build --release
    just -f {% raw %}{{justfile()}}{% endraw %} create_bundle release {% raw %}{{TargetDir}}{% endraw %}
[macos]
create_bundle profile TargetDir:
    #!/bin/bash
    set -e
    echo "Creating plugin bundle"
    rm -Rf "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin"
    mkdir -p "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/Resources"
    mkdir -p "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/MacOS"

    echo "eFKTFXTC" >> "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/PkgInfo"
    /usr/libexec/PlistBuddy -c 'add CFBundlePackageType string eFKT' "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c 'add CFBundleSignature string FXTC' "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c 'add CFBundleIdentifier string {% raw %}{{BundleIdentifier}}{% endraw %}' "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/Info.plist"

    if [ "{% raw %}{{profile}}{% endraw %}" == "release" ]; then
        # Build universal binary
        rustup target add aarch64-apple-darwin
        rustup target add x86_64-apple-darwin

        cargo build --release --target x86_64-apple-darwin
        cargo build --release --target aarch64-apple-darwin

        cp "{% raw %}{{TargetDir}}{% endraw %}/x86_64-apple-darwin/release/{% raw %}{{BinaryName}}{% endraw %}.rsrc" "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/Resources/{% raw %}{{PluginName}}{% endraw %}.rsrc"
        lipo "{% raw %}{{TargetDir}}{% endraw %}/{x86_64,aarch64}-apple-darwin/release/lib{% raw %}{{BinaryName}}{% endraw %}.dylib" -create -output "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/MacOS/{% raw %}{{PluginName}}{% endraw %}.dylib"
        mv "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/MacOS/{% raw %}{{PluginName}}{% endraw %}.dylib" "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}"
    else
        cp "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{BuildName}}{% endraw %}.rsrc" "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/Resources/{% raw %}{{PluginName}}{% endraw %}.rsrc"
        cp "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/lib{% raw %}{{BinaryName}}{% endraw %}.dylib" "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin/Contents/MacOS/{% raw %}{{PluginName}}{% endraw %}"
    fi

    # codesign with the first development cert we can find using its hash
    if [ -z "$NO_SIGN" ]; then
        # codesign --options runtime --timestamp -strict  --sign $( security find-identity -v -p codesigning | grep -m 1 "Apple Development" | awk -F ' ' '{print $2}' ) "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin"
        # Apple Developer Programに入る必要があるが、開発中である為AdHoc署名で十分
        codesign --options runtime --timestamp -strict  --sign - "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin"
    fi

    # Install
    if [ -z "$NO_INSTALL" ]; then
        sudo cp -rf "{% raw %}{{TargetDir}}{% endraw %}/{% raw %}{{profile}}{% endraw %}/{% raw %}{{PluginName}}{% endraw %}.plugin" "/Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore/"
    fi