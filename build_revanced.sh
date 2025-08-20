#!/bin/bash

# Function to get artifact download URL from GitHub releases
get_artifact_download_url() {
    local api_url result
    api_url="https://api.github.com/repos/$1/releases/latest"
    result=$(curl -s "$api_url" | jq -r ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo "$result"
}

# --- Main Script ---

# Download necessary tools
declare -A artifacts
artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
artifacts["revanced-integrations.apk"]="revanced/revanced-integrations revanced-integrations .apk"
artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"
artifacts["vanced-microG.apk"]="ReVanced/GmsCore app-release .apk"

for artifact in "${!artifacts[@]}"; do
    if [ ! -f "$artifact" ]; then
        echo "Downloading $artifact"
        # shellcheck disable=SC2086
        curl -sLo "$artifact" $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

# Create build directory
mkdir -p build

# Read the JSON config and loop through each app
jq -c '.[]' apps_config.json | while read -r app_config; do
    appName=$(echo "$app_config" | jq -r '.appName')
    packageName=$(echo "$app_config" | jq -r '.packageName')
    apk_file="${packageName}.apk"

    echo "************************************"
    echo "Processing $appName"
    echo "************************************"

    if [ ! -f "$apk_file" ]; then
        echo "APK file '$apk_file' not found, skipping build for $appName."
        continue
    fi

    # Prepare patch arguments
    patches_args=()
    excludePatches=$(echo "$app_config" | jq -r '.excludePatches[]')
    includePatches=$(echo "$app_config" | jq -r '.includePatches[]')

    for patch in $excludePatches; do
        patches_args+=("-e $patch")
    done

    for patch in $includePatches; do
        patches_args+=("-i $patch")
    done

    # Build Root APK
    echo "Building Root APK for $appName"
    java -jar revanced-cli.jar patch \
        -b revanced-patches.jar \
        -m revanced-integrations.apk \
        --merge-integrations \
        -e microg-support ${patches_args[@]} \
        -o "build/${appName}-root.apk" \
        "$apk_file"

    # Build Non-root APK
    echo "Building Non-root APK for $appName"
    java -jar revanced-cli.jar patch \
        -b revanced-patches.jar \
        -m revanced-integrations.apk \
        --merge-integrations \
        ${patches_args[@]} \
        -o "build/${appName}-nonroot.apk" \
        "$apk_file"
done

echo "************************************"
echo "All builds finished."
echo "************************************"