#!/usr/bin/env bash

# Wget user agent
WGET_HEADER="User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"

# --- Functions ---
req() { wget -nv -O "$2" --header="$WGET_HEADER" "$1"; }

dl_apk() {
    local url=$1 regexp=$2 output=$3
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n "s;href=\"/@/g; s;.*${regexp}.*;\1;p")"
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
    req "$url" "$output"
}

download_app() {
    local appName=$1
    local version=$2
    local output_apk="${packageName}.apk"

    echo "Downloading $appName version $version"
    
    local app_url_name
    if [[ "$appName" == "YouTube" ]]; then
        app_url_name="youtube"
    elif [[ "$appName" == "YouTube Music" ]]; then
        app_url_name="youtube-music"
    else
        # Simple transformation for other apps, might need adjustment
        app_url_name=$(echo "$appName" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    fi
    
    dl_apk "https://www.apkmirror.com/apk/google-inc/${app_url_name}/${app_url_name}-${version//./-}-release/" \
        "APK</span>[^@]*@\([^#]*\)" \
        "$output_apk"

    echo "$appName downloaded successfully as $output_apk"
}

# --- Main Script ---
jq -c '.[]' apps_config.json | while read -r app_config; do
    appName=$(echo "$app_config" | jq -r '.appName')
    packageName=$(echo "$app_config" | jq -r '.packageName')
    version=$(echo "$app_config" | jq -r '.version')
    apk_file="${packageName}.apk"

    if [ ! -f "$apk_file" ]; then
        download_app "$appName" "$version"
    else
        echo "$apk_file already exists, skipping download."
    fi
done