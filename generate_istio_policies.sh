#!/bin/bash

# Verificar se gojq está instalado
if ! command -v gojq &> /dev/null; then
    echo "gojq não está instalado. Por favor, instale usando 'go install github.com/itchyny/gojq/cmd/gojq@latest'"
    exit 1
fi

config_file="config.yaml"
output_dir="istio_policies"
templates_dir="templates"

# Verificar se o arquivo de configuração existe
if [ ! -f "$config_file" ]; then
    echo "Arquivo de configuração '$config_file' não encontrado!"
    exit 1
fi

# Verificar se o diretório de templates existe
if [ ! -d "$templates_dir" ]; then
    echo "Diretório de templates '$templates_dir' não encontrado!"
    exit 1
fi

# Criar o diretório de saída se não existir
mkdir -p "$output_dir"

# Ler o YAML usando gojq e gerar arquivos de políticas
while IFS= read -r service; do
    echo "Processando serviço: $service"

    paths=$(gojq --yaml-input -r --arg service "$service" '.[$service].paths // empty' < "$config_file")

    if [ -z "$paths" ]; then
        # Caso não haja paths, redirecionar todo o tráfego do serviço
        echo "Redirecionando todo o tráfego do serviço $service"
        template=$(cat "$templates_dir/template_redirect_all.yaml")
        echo "${template//\{\{service\}\}/$service}" > "$output_dir/${service}_policy.yaml"
    else
        # Redirecionar apenas os paths especificados
        echo "Redirecionando paths específicos do serviço $service"
        http_routes=""
        for path in $(echo "$paths" | gojq -r '.[]'); do
            route_item_template=$(cat "$templates_dir/template_route_item.yaml")
            route_item="${route_item_template//\{\{path\}\}/$path}"
            http_routes="${http_routes}
${route_item}"
        done

        template=$(cat "$templates_dir/template_redirect_paths.yaml")
        echo "$template" | awk -v service="$service" -v http_routes="$http_routes" '{gsub(/\{\{service\}\}/, service); gsub(/\{\{http_routes\}\}/, http_routes); print}' > "$output_dir/${service}_policy.yaml"
    fi
done < <(gojq --yaml-input -r 'keys[]' < "$config_file")

echo "Políticas geradas com sucesso no diretório '$output_dir'."
