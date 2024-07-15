#!/bin/bash

# Verificar se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo "kubectl não está instalado. Por favor, instale o kubectl."
    exit 1
fi

output_dir="istio_policies"

# Verificar se o diretório de políticas existe
if [ ! -d "$output_dir" ]; then
    echo "Diretório de políticas '$output_dir' não encontrado!"
    exit 1
fi

# Aplicar todas as políticas no Kubernetes
for policy_file in "$output_dir"/*.yaml; do
    echo "Aplicando política: $policy_file"
    kubectl apply -f "$policy_file"
done

echo "Políticas aplicadas com sucesso."