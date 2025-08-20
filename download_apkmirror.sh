#!/usr/bin/env bash

# Função para obter a URL de download de um artefato de um release do GitHub
get_github_release_asset_url() {
    local repo=$1
    local asset_name=$2
    local api_url="https://api.github.com/repos/${repo}/releases/latest"
    
    # Usa curl para consultar a API e jq para extrair a URL de download do artefato específico
    curl -sL "$api_url" | jq -r ".assets[] | select(.name == \"$asset_name\") | .browser_download_url"
}

# --- Main Script ---

# Baixa o apkeep usando o método robusto da API
if [ ! -f "apkeep" ]; then
    echo "Downloading apkeep..."
    APKEEP_URL=$(get_github_release_asset_url "EFForg/apkeep" "apkeep-x86_64-unknown-linux-gnu")
    
    if [ -z "$APKEEP_URL" ]; then
        echo "Error: Não foi possível encontrar a URL de download para o apkeep."
        exit 1
    fi
    
    curl -sLo apkeep "$APKEEP_URL"
    
    if ! file apkeep | grep -q "executable"; then
        echo "Error: O arquivo apkeep baixado não é um executável válido."
        exit 1
    fi
    
    chmod +x ./apkeep
fi

# Lê a configuração JSON e baixa cada APK
jq -c '.[]' apps_config.json | while read -r app_config; do
    appName=$(echo "$app_config" | jq -r '.appName')
    packageName=$(echo "$app_config" | jq -r '.packageName')
    version=$(echo "$app_config" | jq -r '.version')
    output_apk="${packageName}.apk"

    if [ ! -f "$output_apk" ]; then
        echo "************************************"
        echo "Downloading $appName version $version"
        echo "************************************"
        
        # ##################################################################
        # ## CORREÇÃO DEFINITIVA: Usar "apk-pure" como fonte de download  ##
        # ##################################################################
        ./apkeep -a "$packageName@$version" -d "apk-pure" .
        
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