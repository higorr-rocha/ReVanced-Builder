#!/usr/bin/env bash

# --- Main Script ---

# Download apkeep if not present, ensuring we follow redirects with -L
if [ ! -f "apkeep" ]; then
    echo "Downloading apkeep..."
    curl -sL -o apkeep "https://github.com/EFForg/apkeep/releases/download/v0.4.0/apkeep-x86_64-unknown-linux-gnu"
    
    # Verify that the downloaded file is an executable binary
    if ! file apkeep | grep -q "executable"; then
        echo "Error: Downloaded apkeep is not a valid executable."
        cat apkeep # Print file content for debugging
        exit 1
    fi
    
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
        
        # Execute apkeep with the correct source
        ./apkeep -a "$packageName@$version" -d "google-play" .
        
        # apkeep saves the file with version info, so we rename it
        downloaded_file_xapk="${packageName}@${version}.xapk"
        downloaded_file_apk="${packageName}@${version}.apk"

        if [ -f "$downloaded_file_xapk" ]; then
            # We only need the base apk, so we unzip and find it
            unzip -o "$downloaded_file_xapk" "$packageName.apk" -d .
            rm "$downloaded_file_xapk" # Clean up the bundle
            if [ -f "$packageName.apk" ]; then
                 echo "$appName downloaded successfully as $output_apk"
            else
                echo "Error: Could not extract base APK from $downloaded_file_xapk"
                exit 1
            fi
        elif [ -f "$downloaded_file_apk" ]; then
            mv "$downloaded_file_apk" "$output_apk"
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