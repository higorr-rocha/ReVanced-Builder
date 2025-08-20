#!/usr/bin/env bash

# Wget user agent
WGET_HEADER="User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"

# --- Functions ---
req() {
    wget -nv -O "$2" --header="$WGET_HEADER" "$1"
}

dl_apk() {
    local url=$1
    local output=$2

    # 1. Get the page for the specific version
    local page_content
    page_content=$(req "$url" -)
    local download_page_path
    download_page_path=$(echo "$page_content" | grep -oP '(?<=href=")[^"]*?download-button' | sed 's/"//' | head -n 1)

    if [ -z "$download_page_path" ]; then
        echo "Error: Could not find download page URL for $output on page $url"
        return 1
    fi
    local download_page_url="https://www.apkmirror.com${download_page_path}"
    
    # 2. Get the final download link from the download page
    local final_download_path
    final_download_path=$(req "$download_page_url" - | grep -oP '(?<=href=")[^"]*?key=[^"]*')

    if [ -z "$final_download_path" ]; then
        echo "Error: Could not find final download URL for $output on page $download_page_url"
        return 1
    fi
    local final_download_url="https://www.apkmirror.com${final_download_path}"

    # 3. Download the file
    echo "Downloading from $final_download_url"
    req "$final_download_url" "$output"
}

download_app() {
    local appName=$1
    local version=$2
    local packageName=$3
    local output_apk="${packageName}.apk"

    echo "Downloading $appName version $version"
    
    local publisher="google-inc" # Default
    if [[ "$appName" == "Spotify" ]]; then
        publisher="spotify-ltd"
    fi
    
    local app_url_name
    app_url_name=$(echo "$appName" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    
    local version_url_part="${version//./-}"
    local base_url="https://www.apkmirror.com/apk/${publisher}/${app_url_name}/${app_url_name}-${version_url_part}-release/"

    dl_apk "$base_url" "$output_apk"

    if [ $? -eq 0 ]; then
        echo "$appName downloaded successfully as $output_apk"
    else
        echo "Failed to download $appName."
        # exit 1 # You might want to exit here if a download fails
    fi
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