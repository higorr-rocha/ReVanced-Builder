#!/bin/bash

# Function to get artifact download URL from GitHub releases
get_artifact_download_url() {
    local repo=$1
    local name_contains=$2
    local extension=$3
    local api_url="https://api.github.com/repos/${repo}/releases/latest"
    
    # Usar -L aqui também por segurança
    curl -sL "$api_url" | jq -r ".assets[] | select(.name | contains(\"$name_contains\") and endswith(\"$extension\")) | .browser_download_url" | head -n 1
}

# --- Main Script ---

# Download necessary tools
declare -A artifacts
artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
artifacts["revanced-integrations.apk"]="revanced/revanced-integrations revanced-integrations .apk"
artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"
artifacts["vanced-microG.apk"]="ReVanced/GmsCore GmsCore .apk" # Nome do artefato corrigido

for artifact_filename in "${!artifacts[@]}"; do
    if [ ! -f "$artifact_filename" ]; then
        echo "Downloading $artifact_filename"
        url=$(get_artifact_download_url ${artifacts[$artifact_filename]})
        if [ -n "$url" ]; then
            curl -sLo "$artifact_filename" "$url"
        else
            echo "Error: Não foi possível encontrar a URL de download para $artifact_filename"
            exit 1
        fi
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
    echo "Processando $appName"
    echo "************************************"

    if [ ! -f "$apk_file" ]; then
        echo "Arquivo APK '$apk_file' não encontrado, pulando a compilação para $appName."
        continue
    fi

    # Prepare patch arguments
    patches_args=""
    for patch in $(echo "$app_config" | jq -r '.excludePatches[]'); do
        patches_args+=" -e $patch"
    done
    for patch in $(echo "$app_config" | jq -r '.includePatches[]'); do
        patches_args+=" -i $patch"
    done

    # Build Root APK
    echo "Compilando APK Root para $appName"
    java -jar revanced-cli.jar patch \
        -b revanced-patches.jar \
        -m revanced-integrations.apk \
        --merge-integrations \
        $patches_args \
        -o "build/${appName}-root.apk" \
        "$apk_file"

    # Build Non-root APK
    echo "Compilando APK Non-root para $appName"
    java -jar revanced-cli.jar patch \
        -b revanced-patches.jar \
        -m revanced-integrations.apk \
        --merge-integrations \
        -e microg-support \
        $patches_args \
        -o "build/${appName}-nonroot.apk" \
        "$apk_file"
done

echo "************************************"
echo "Todas as compilações foram finalizadas."
echo "************************************"