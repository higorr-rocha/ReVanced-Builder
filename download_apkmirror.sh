#!/usr/bin/env bash

# Baixa o apkeep usando wget para maior robustez
if [ ! -f "apkeep" ]; then
    echo "Downloading apkeep..."
    wget -q -O apkeep "https://github.com/EFForg/apkeep/releases/download/v0.4.0/apkeep-x86_64-unknown-linux-gnu"
    
    if ! file apkeep | grep -q "executable"; then
        echo "Error: O arquivo apkeep baixado não é um executável válido."
        exit 1
    fi
    
    chmod +x ./apkeep
fi

# Lê a configuração e baixa cada APK
jq -c '.[]' apps_config.json | while read -r app_config; do
    appName=$(echo "$app_config" | jq -r '.appName')
    packageName=$(echo "$app_config" | jq -r '.packageName')
    version=$(echo "$app_config" | jq -r '.version')
    output_apk="${packageName}.apk"

    if [ ! -f "$output_apk" ]; then
        echo "************************************"
        echo "Downloading $appName version $version"
        echo "************************************"
        
        # CORREÇÃO CRÍTICA: Usa 'apk-mirror' como fonte para evitar a necessidade de login do Google Play
        ./apkeep -a "$packageName@$version" -d "apk-mirror" .
        
        downloaded_file_xapk="${packageName}@${version}.xapk"
        downloaded_file_apk="${packageName}@${version}.apk"

        if [ -f "$downloaded_file_xapk" ]; then
            unzip -o "$downloaded_file_xapk" "$packageName.apk" -d .
            rm "$downloaded_file_xapk"
            if [ -f "$packageName.apk" ]; then
                 echo "$appName downloaded successfully as $output_apk"
            else
                echo "Error: Não foi possível extrair o APK base de $downloaded_file_xapk"
                exit 1
            fi
        elif [ -f "$downloaded_file_apk" ]; then
            mv "$downloaded_file_apk" "$output_apk"
            echo "$appName downloaded successfully as $output_apk"
        else
            echo "Error: Falha no download de $appName. Nenhum arquivo .xapk ou .apk foi encontrado."
            exit 1
        fi
    else
        echo "$output_apk já existe, pulando o download."
    fi
done

echo "************************************"
echo "Todos os downloads de APKs finalizados."
echo "************************************"