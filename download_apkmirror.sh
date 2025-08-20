#!/usr/bin/env bash

# --- Main Script ---

# Download apkeep if not present
if [ ! -f "apkeep" ]; then
    echo "Downloading apkeep..."
    # Use a direct link to the binary for the runner's architecture
    curl -sLo apkeep "https://github.com/EFForg/apkeep/releases/download/v0.4.0/apkeep-x86_64-unknown-linux-gnu"
    # Make sure it's executable
    chmod +x ./apkeep
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
        
        # Execute apkeep correctly
        ./apkeep -a "$packageName@$version" -d "google-play" .
        
        # apkeep saves the file with version info, so we rename it
        # The downloaded file might be a .xapk bundle, which is a zip file
        if [ -f "${packageName}@${version}.xapk" ]; then
            # We only need the base apk, so we unzip and find it
            unzip -o "${packageName}@${version}.xapk" "$packageName.apk" -d .
            rm "${packageName}@${version}.xapk" # Clean up the bundle
            echo "$appName downloaded successfully as $output_apk"
        elif [ -f "${packageName}@${version}.apk" ]; then
            mv "${packageName}@${version}.apk" "$output_apk"
            echo "$appName downloaded successfully as $output_apk"
        else
            echo "Error: Failed to download $appName. Neither .xapk nor .apk was found."
            exit 1
        fi
    else
        echo "$output_apk already exists, skipping download."
    fi
done

echo "************************************"
echo "All APK downloads finished."
echo "************************************"