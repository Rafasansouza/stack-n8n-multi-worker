# Script para gerar arquivo .env com senhas seguras - Windows
# Uso: .\scripts\generate-env.ps1

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $ProjectRoot ".env"
$EnvExample = Join-Path $ProjectRoot ".env.example"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  n8n Server - Gerador de Configuração" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se .env já existe
if (Test-Path $EnvFile) {
    Write-Host "ATENÇÃO: Arquivo .env já existe!" -ForegroundColor Yellow
    Write-Host "Localização: $EnvFile"
    Write-Host ""
    $response = Read-Host "Deseja sobrescrever? (s/N)"
    if ($response -notmatch "^[Ss]$") {
        Write-Host "Operação cancelada." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# Verificar se .env.example existe
if (-not (Test-Path $EnvExample)) {
    Write-Host "ERRO: Arquivo .env.example não encontrado!" -ForegroundColor Red
    Write-Host "Esperado em: $EnvExample"
    exit 1
}

# Função para gerar senha segura
function Generate-Password {
    param([int]$Length = 32)

    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
    $rng.GetBytes($bytes)
    $rng.Dispose()

    return [Convert]::ToBase64String($bytes).Replace("=", "").Replace("+", "").Replace("/", "").Substring(0, $Length)
}

Write-Host "Gerando valores seguros..." -ForegroundColor Green
Write-Host ""

# Gerar senhas
$N8nKey = Generate-Password -Length 43  # Base64 de 32 bytes
$PostgresPass = Generate-Password -Length 24
$RedisPass = Generate-Password -Length 24
$WahaApiKey = Generate-Password -Length 32
$WahaSwaggerPass = Generate-Password -Length 16
$OracleSha = "8d8c222d89be761c5e44baa9f6b688e11830f0a82e84b5b0f7e88ff58cff4b65"

# Copiar .env.example
Copy-Item $EnvExample $EnvFile -Force

# Ler conteúdo do arquivo
$content = Get-Content $EnvFile -Raw

# Substituir valores (multiline mode)
$content = $content -replace "(?m)^N8N_ENCRYPTION_KEY=.*$", "N8N_ENCRYPTION_KEY=$N8nKey"
$content = $content -replace "(?m)^POSTGRES_PASSWORD=.*$", "POSTGRES_PASSWORD=$PostgresPass"
$content = $content -replace "(?m)^REDIS_PASSWORD=.*$", "REDIS_PASSWORD=$RedisPass"
$content = $content -replace "(?m)^ORACLE_IC_SHA256=.*$", "ORACLE_IC_SHA256=$OracleSha"
$content = $content -replace "(?m)^WAHA_API_KEY=.*$", "WAHA_API_KEY=$WahaApiKey"
$content = $content -replace "(?m)^WAHA_SWAGGER_PASSWORD=.*$", "WAHA_SWAGGER_PASSWORD=$WahaSwaggerPass"

# Salvar arquivo
Set-Content -Path $EnvFile -Value $content -NoNewline

Write-Host "Arquivo .env criado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Valores gerados:" -ForegroundColor Cyan
Write-Host "  - N8N_ENCRYPTION_KEY: ******** ($($N8nKey.Length) chars)"
Write-Host "  - POSTGRES_PASSWORD:  ******** ($($PostgresPass.Length) chars)"
Write-Host "  - REDIS_PASSWORD:     ******** ($($RedisPass.Length) chars)"
Write-Host "  - WAHA_API_KEY:       ******** ($($WahaApiKey.Length) chars)"
Write-Host "  - WAHA_SWAGGER_PASS:  ******** ($($WahaSwaggerPass.Length) chars)"
Write-Host "  - ORACLE_IC_SHA256:   $OracleSha"
Write-Host ""
Write-Host "IMPORTANTE:" -ForegroundColor Yellow
Write-Host "  1. NUNCA commite o arquivo .env"
Write-Host "  2. Faça backup da N8N_ENCRYPTION_KEY"
Write-Host "  3. NÃO altere N8N_ENCRYPTION_KEY após criar workflows"
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "  docker-compose build"
Write-Host "  docker-compose up -d"
Write-Host ""
