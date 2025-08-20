#!/usr/bin/env bash

# --- Main Script ---

# Download apkeep if not present
if [ ! -f "apkeep" ]; then
    echo "Downloading apkeep..."
    curl -sLo apkeep "https://github.com/EFForg/apkeep/releases/download/v0.4.0/apkeep-x86_64-unknown-linux-gnu"
    chmod +x apkeep
fi

# Read the JSON config and loop through each app
jq -c '.[]' apps_config.json | while read -r app_config; do
    appName=$(echo "$app_config" | jq -r '.appName')
    packageName=$(echo "$app_config" | jq -r '.packageName')
    version=$(echo "$app_config" | jq -r '.version')
    output_apk="${packageName}.apk"

    if [ ! -f "$output_apk" ]; then
        echo "************************************"
        echo "Downloading $appName version $version"
        echo "************************************"
        
        # Use apkeep to download the specific version
        ./apkeep -a "$packageName@$version" .
        
        # apkeep saves the file with version info, so we rename it
        if [ -f "${packageName}@${version}.apk" ]; then
            mv "${packageName}@${version}.apk" "$output_apk"
            echo "$appName downloaded successfully as $output_apk"
        else
            echo "Error: Failed to download $appName. The file ${packageName}@${version}.apk was not found."
            exit 1
        fi
    else
        echo "$apk_file already exists, skipping download."
    fi
done

echo "************************************"
echo "All APK downloads finished."
echo "************************************"