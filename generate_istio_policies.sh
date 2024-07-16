#!/bin/bash

# Verificar se gojq está instalado
if ! command -v gojq &> /dev/null; then
    echo "gojq não está instalado. Por favor, instale usando 'go install github.com/itchyny/gojq/cmd/gojq@latest'"
    exit 1
fi

config_file="config.yaml"
output_dir="istio_policies"
templates_dir="templates"

# Variáveis de ambiente
default_ns="${NAMESPACE:-default}"
default_newHost="${NEW_HOST:-new-destination}"
default_port="${PORT:-80}"
default_labelKey="${LABEL_KEY:-app}"
default_labelValue="${LABEL_VALUE:-default}"
default_prefix="${PREFIX:-/}"

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

# Função para obter valores do YAML ou usar valores padrão
get_value_or_default() {
    local value
    value=$(gojq --yaml-input -r --arg service "$1" --arg key "$2" '.[$service][$key] // empty' < "$config_file")
    echo "${value:-$3}"
}

# Ler o YAML usando gojq e gerar arquivos de políticas
while IFS= read -r service; do
    echo "Processando serviço: $service"

    ns=$(get_value_or_default "$service" "namespace" "$default_ns")
    newHost=$(get_value_or_default "$service" "host" "$default_newHost")
    port=$(get_value_or_default "$service" "port" "$default_port")
    prefix=$(get_value_or_default "$service" "prefix" "$default_prefix")

    paths=$(gojq --yaml-input -r --arg service "$service" '.[$service].paths // empty' < "$config_file")

    if [ -z "$paths" ]; then
        # Caso não haja paths, redirecionar todo o tráfego do serviço
        echo "Redirecionando todo o tráfego do serviço $service"
        template=$(cat "$templates_dir/template_redirect_all.yaml")
        echo "$template" | awk -v serviceName="$service" -v ns="$ns" \
                          -v host="$service" -v newHost="$newHost" -v port="$port" \
                          -v labelKey="$default_labelKey" -v labelValue="$default_labelValue" -v prefix="$prefix" \
                          '{gsub("{{serviceName}}", serviceName); gsub("{{namespace}}", ns); gsub("{{host}}", host); gsub("{{newHost}}", newHost); gsub("{{port}}", port); gsub("{{labelKey}}", labelKey); gsub("{{labelValue}}", labelValue); gsub("{{prefix}}", prefix); print}' > "$output_dir/${service}_policy.yaml"
    else
        # Redirecionar apenas os paths especificados
        echo "Redirecionando paths específicos do serviço $service"
        http_routes=""
        for path in $(echo "$paths" | gojq -r '.[]'); do
            route_item_template=$(cat "$templates_dir/template_route_item.yaml")
            route_item=$(echo "$route_item_template" | awk -v match="$path" -v newHost="$newHost" -v port="$port" -v prefix="$prefix" \
                                                     '{gsub("{{match}}", match); gsub("{{newHost}}", newHost); gsub("{{port}}", port); gsub("{{prefix}}", prefix); print}')
            http_routes="${http_routes}\n${route_item}"
        done

        template=$(cat "$templates_dir/template_redirect_paths.yaml")
        # Usar printf para escapar corretamente caracteres especiais
        printf -v escaped_http_routes "%s" "$http_routes"
        echo "$template" | awk -v serviceName="$service" -v ns="$ns" \
                          -v host="$service" -v labelKey="$default_labelKey" -v labelValue="$default_labelValue" \
                          -v http_routes="$escaped_http_routes" \
                          '{gsub("{{serviceName}}", serviceName); gsub("{{namespace}}", ns); gsub("{{host}}", host); gsub("{{labelKey}}", labelKey); gsub("{{labelValue}}", labelValue); gsub(/\{\{http_routes\}\}/, http_routes); print}' > "$output_dir/${service}_policy.yaml"
    fi
done < <(gojq --yaml-input -r 'keys[]' < "$config_file")

echo "Políticas geradas com sucesso no diretório '$output_dir'."
