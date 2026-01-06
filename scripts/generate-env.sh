#!/bin/bash

# Script para gerar arquivo .env com senhas seguras
# Uso: ./scripts/generate-env.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"
ENV_EXAMPLE="${PROJECT_ROOT}/.env.example"

echo "========================================="
echo "  n8n Server - Gerador de Configuração"
echo "========================================="
echo ""

# Verificar se .env já existe
if [ -f "$ENV_FILE" ]; then
    echo "ATENÇÃO: Arquivo .env já existe!"
    echo "Localização: $ENV_FILE"
    echo ""
    read -p "Deseja sobrescrever? (s/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Operação cancelada."
        exit 0
    fi
    echo ""
fi

# Verificar se .env.example existe
if [ ! -f "$ENV_EXAMPLE" ]; then
    echo "ERRO: Arquivo .env.example não encontrado!"
    echo "Esperado em: $ENV_EXAMPLE"
    exit 1
fi

# Função para gerar senha segura
generate_password() {
    local length=$1
    if command -v openssl &> /dev/null; then
        openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
    elif command -v pwgen &> /dev/null; then
        pwgen -s $length 1
    else
        echo "ERRO: openssl ou pwgen não encontrado!"
        echo "Instale com: sudo apt-get install openssl"
        exit 1
    fi
}

echo "Gerando valores seguros..."
echo ""

# Gerar senhas
N8N_KEY=$(openssl rand -base64 32)
POSTGRES_PASS=$(generate_password 24)
REDIS_PASS=$(generate_password 24)
RUNNERS_TOKEN=$(openssl rand -base64 32)
WAHA_API_KEY=$(generate_password 32)
WAHA_SWAGGER_PASS=$(generate_password 16)
WAHA_DASHBOARD_PASS=$(generate_password 16)
ORACLE_SHA="8d8c222d89be761c5e44baa9f6b688e11830f0a82e84b5b0f7e88ff58cff4b65"

# Copiar .env.example e substituir valores
cp "$ENV_EXAMPLE" "$ENV_FILE"

# Substituir valores no .env (compatível com macOS e Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|^N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=${N8N_KEY}|" "$ENV_FILE"
    sed -i '' "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${POSTGRES_PASS}|" "$ENV_FILE"
    sed -i '' "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASS}|" "$ENV_FILE"
    sed -i '' "s|^N8N_RUNNERS_GRANT_TOKEN=.*|N8N_RUNNERS_GRANT_TOKEN=${RUNNERS_TOKEN}|" "$ENV_FILE"
    sed -i '' "s|^ORACLE_IC_SHA256=.*|ORACLE_IC_SHA256=${ORACLE_SHA}|" "$ENV_FILE"
    sed -i '' "s|^WAHA_API_KEY=.*|WAHA_API_KEY=${WAHA_API_KEY}|" "$ENV_FILE"
    sed -i '' "s|^WAHA_SWAGGER_PASSWORD=.*|WAHA_SWAGGER_PASSWORD=${WAHA_SWAGGER_PASS}|" "$ENV_FILE"
    sed -i '' "s|^WAHA_DASHBOARD_PASSWORD=.*|WAHA_DASHBOARD_PASSWORD=${WAHA_DASHBOARD_PASS}|" "$ENV_FILE"
else
    # Linux/Git Bash
    sed -i "s|^N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=${N8N_KEY}|" "$ENV_FILE"
    sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${POSTGRES_PASS}|" "$ENV_FILE"
    sed -i "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASS}|" "$ENV_FILE"
    sed -i "s|^N8N_RUNNERS_GRANT_TOKEN=.*|N8N_RUNNERS_GRANT_TOKEN=${RUNNERS_TOKEN}|" "$ENV_FILE"
    sed -i "s|^ORACLE_IC_SHA256=.*|ORACLE_IC_SHA256=${ORACLE_SHA}|" "$ENV_FILE"
    sed -i "s|^WAHA_API_KEY=.*|WAHA_API_KEY=${WAHA_API_KEY}|" "$ENV_FILE"
    sed -i "s|^WAHA_SWAGGER_PASSWORD=.*|WAHA_SWAGGER_PASSWORD=${WAHA_SWAGGER_PASS}|" "$ENV_FILE"
    sed -i "s|^WAHA_DASHBOARD_PASSWORD=.*|WAHA_DASHBOARD_PASSWORD=${WAHA_DASHBOARD_PASS}|" "$ENV_FILE"
fi

echo "✓ Arquivo .env criado com sucesso!"
echo ""
echo "Valores gerados:"
echo "  - N8N_ENCRYPTION_KEY:     ******** (${#N8N_KEY} caracteres)"
echo "  - POSTGRES_PASSWORD:      ******** (${#POSTGRES_PASS} caracteres)"
echo "  - REDIS_PASSWORD:         ******** (${#REDIS_PASS} caracteres)"
echo "  - N8N_RUNNERS_GRANT_TOKEN: ******** (${#RUNNERS_TOKEN} caracteres)"
echo "  - WAHA_API_KEY:           ******** (${#WAHA_API_KEY} caracteres)"
echo "  - WAHA_SWAGGER_PASSWORD:  ******** (${#WAHA_SWAGGER_PASS} caracteres)"
echo "  - WAHA_DASHBOARD_PASSWORD: ******** (${#WAHA_DASHBOARD_PASS} caracteres)"
echo "  - ORACLE_IC_SHA256:       ${ORACLE_SHA}"
echo ""
echo "IMPORTANTE:"
echo "  1. NUNCA commite o arquivo .env no Git"
echo "  2. Faça backup da N8N_ENCRYPTION_KEY em local seguro"
echo "  3. NÃO altere N8N_ENCRYPTION_KEY após criar workflows"
echo "  4. Arquivo .env criado em: $ENV_FILE"
echo ""
echo "Próximos passos:"
echo "  docker compose build"
echo "  docker compose up -d"
echo ""
