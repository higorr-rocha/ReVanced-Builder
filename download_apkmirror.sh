#!/usr/bin/env bash

# --- Main Script ---

# Download apkeep if not present, ensuring we follow redirects with -L
if [ ! -f "apkeep" ]; then
    echo "Downloading apkeep..."
    # A flag -L é crucial para seguir o redirecionamento do GitHub e baixar o binário real.
    curl -sL -o apkeep "https://github.com/EFForg/apkeep/releases/download/v0.4.0/apkeep-x86_64-unknown-linux-gnu"
    
    # Adiciona uma verificação para garantir que o arquivo baixado é um executável
    if ! file apkeep | grep -q "executable"; then
        echo "Error: O arquivo apkeep baixado não é um executável válido."
        cat apkeep # Mostra o conteúdo do arquivo para depuração
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
        
        # Executa o apkeep para baixar do Google Play, que é mais confiável
        ./apkeep -a "$packageName@$version" -d "google-play" .
        
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