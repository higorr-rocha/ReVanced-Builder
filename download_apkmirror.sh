#!/usr/bin/env bash

# Wget user agent
WGET_HEADER="User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"

# --- Functions ---
req() {
    wget -nv -O "$2" --header="$WGET_HEADER" "$1"
}

dl_apk() {
    local url=$1
    local regexp=$2
    local output=$3

    # 1. Get the page for the specific version
    local download_page_url="https://www.apkmirror.com$(req "$url" - | grep -oP 'href="([^"]+)"' | grep 'download-button' | sed 's/href="//;s/"//' | head -n 1)"
    
    if [ -z "$download_page_url" ]; then
        echo "Error: Could not find download page URL for $output"
        return 1
    fi
    
    # 2. Get the final download link from the download page
    local final_download_url="https://www.apkmirror.com$(req "$download_page_url" - | grep -oP 'href="([^"]+)"' | grep 'key=' | sed 's/href="//;s/"//')"

    if [ -z "$final_download_url" ]; then
        echo "Error: Could not find final download URL for $output"
        return 1
    fi

    # 3. Download the file
    req "$final_download_url" "$output"
}

download_app() {
    local appName=$1
    local version=$2
    local packageName=$3
    local output_apk="${packageName}.apk"

    echo "Downloading $appName version $version"
    
    local app_url_name
    if [[ "$appName" == "YouTube" ]]; then
        app_url_name="youtube"
        publisher="google-inc"
    elif [[ "$appName" == "YouTube Music" ]]; then
        app_url_name="youtube-music"
        publisher="google-inc"
    elif [[ "$appName" == "Spotify" ]]; then
        app_url_name="spotify"
        publisher="spotify-ltd"
    else
        app_url_name=$(echo "$appName" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        publisher="google-inc" # Default publisher, might need adjustment
    fi
    
    local version_url_part="${version//./-}"
    local base_url="https://www.apkmirror.com/apk/${publisher}/${app_url_name}/${app_url_name}-${version_url_part}-release/"

    dl_apk "$base_url" "APK</span>[^@]*@\([^#]*\)" "$output_apk"

    echo "$appName downloaded successfully as $output_apk"
}

# --- Main Script ---
jq -c '.[]' apps_config.json | while read -r app_config; do
    appName=$(echo "$app_config" | jq -r '.appName')
    packageName=$(echo "$app_config" | jq -r '.packageName')
    version=$(echo "$app_config" | jq -r '.version')
    apk_file="${packageName}.apk"

    if [ ! -f "$apk_file" ]; then
        download_app "$appName" "$version" "$packageName"
    else
        echo "$apk_file already exists, skipping download."
    fi
done