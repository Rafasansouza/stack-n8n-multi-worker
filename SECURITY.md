# Segurança - n8n Server

## Visão Geral

Este documento descreve as práticas de segurança implementadas e recomendações para manter o ambiente n8n seguro.

## Configurações de Segurança Implementadas

### 1. Criptografia de Dados

**N8N_ENCRYPTION_KEY**
- Utilizada para criptografar credenciais, workflows e dados sensíveis
- Gerada automaticamente com 32 bytes de entropia (256 bits)
- **CRÍTICO**: Nunca alterar após inicialização
- Backup obrigatório para recuperação de desastres

### 2. Autenticação de Serviços

**PostgreSQL**
- Usuário: `n8n` (não-root)
- Senha: 24 caracteres aleatórios
- Não exposta externamente (apenas rede interna Docker)

**Redis**
- Autenticação obrigatória com senha
- Senha: 24 caracteres aleatórios
- Modo append-only para persistência

### 3. Isolamento de Rede

- Rede Docker privada `n8n-network`
- Apenas porta 5678 (n8n UI) exposta ao host
- PostgreSQL e Redis acessíveis apenas internamente

### 4. Validação de Integridade

- Oracle Instant Client validado via SHA256
- Build Docker falha se checksum não corresponder

## Práticas Recomendadas

### Gerenciamento de Senhas

1. **NUNCA** use valores padrão como "change-me"
2. **SEMPRE** gere senhas com ferramentas criptográficas:
   ```bash
   openssl rand -base64 32  # Para N8N_ENCRYPTION_KEY
   openssl rand -base64 24  # Para senhas de banco
   ```
3. **NUNCA** commite arquivo `.env` no Git
4. Use gerenciador de senhas para armazenar credenciais

### Backup da N8N_ENCRYPTION_KEY

```bash
# Exportar chave para arquivo seguro
echo "N8N_ENCRYPTION_KEY=$(grep N8N_ENCRYPTION_KEY .env | cut -d '=' -f2)" > .env.backup

# Armazenar em local seguro (ex: cofre de senhas)
# Criptografar arquivo se necessário
gpg -c .env.backup  # Cria .env.backup.gpg

# Remover arquivo plain text
shred -u .env.backup  # Linux
# ou
rm -P .env.backup     # macOS
```

### Backup de Dados

1. **Backups automáticos** configurados (padrão: diário às 2h)
2. **Retenção**: 7 dias (configurável)
3. **Localização**: Volume Docker `n8n-server_postgres_backups`
4. **Antes de atualizar n8n**: Sempre faça backup manual

```bash
# Backup manual
docker-compose exec postgres-backup /scripts/backup.sh

# Exportar backup para fora do Docker
docker cp n8n-postgres-backup:/backups ./backups-export
```

### Atualização Segura do n8n

```bash
# 1. Backup completo
docker-compose exec postgres-backup /scripts/backup.sh

# 2. Exportar backup
docker cp n8n-postgres-backup:/backups/n8n_backup_LATEST.sql.gz ./

# 3. Atualizar versão no .env
# N8N_VERSION=2.1.0

# 4. Rebuild
docker-compose build --no-cache

# 5. Parar containers
docker-compose down

# 6. Iniciar novamente
docker-compose up -d

# 7. Verificar logs
docker-compose logs -f n8n-main
```

## Exposição de Serviços

### Porta 5678 (n8n UI)

**Ambiente de Desenvolvimento:**
```yaml
# docker-compose.yml
ports:
  - "127.0.0.1:5678:5678"  # Apenas localhost
```

**Produção (com proxy reverso):**
```yaml
# Não expor diretamente
# Use Nginx/Traefik com HTTPS
```

### PostgreSQL/Redis

**NUNCA** exponha diretamente:
```yaml
# NÃO FAZER:
postgres:
  ports:
    - "5432:5432"  # PERIGOSO!
```

Se necessário para debug local:
```yaml
# Apenas temporário e apenas localhost
postgres:
  ports:
    - "127.0.0.1:5432:5432"
```

## Logs e Auditoria

### Sensibilizar Logs

```bash
# Evitar logar senhas
N8N_LOG_LEVEL=info  # Não usar 'debug' em produção

# Verificar logs por senhas expostas
docker-compose logs | grep -i password
```

### Rotação de Logs

```yaml
# docker-compose.yml
services:
  n8n-main:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## Hardening Adicional (Produção)

### 1. Usuário Não-Root

Já implementado no Dockerfile:
```dockerfile
USER node  # Linha 47
```

### 2. Read-Only Root Filesystem

```yaml
# docker-compose.yml
n8n-main:
  security_opt:
    - no-new-privileges:true
  read_only: true
  tmpfs:
    - /tmp
    - /home/node/.cache
```

### 3. Limitar Recursos

```yaml
n8n-main:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 2G
      reservations:
        memory: 512M
```

### 4. HTTPS com Let's Encrypt

```bash
# Usar Traefik ou Nginx como proxy reverso
# Exemplo com Nginx:

# nginx.conf
server {
    listen 443 ssl http2;
    server_name n8n.example.com;

    ssl_certificate /etc/letsencrypt/live/n8n.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/n8n.example.com/privkey.pem;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

## Recuperação de Desastres

### Cenário 1: N8N_ENCRYPTION_KEY Perdida

**Prevenção**: Backup da chave em local seguro

**Se perdida**:
1. Workflows são preservados (não criptografados)
2. **Credenciais são PERDIDAS** (não recuperáveis)
3. Opções:
   - Restaurar backup com chave original
   - Recriar credenciais manualmente com nova chave

### Cenário 2: Corrupção do Banco de Dados

```bash
# 1. Parar n8n
docker-compose stop n8n-main n8n-worker

# 2. Listar backups
docker-compose exec postgres-backup ls -lh /backups

# 3. Restaurar backup
docker-compose exec postgres pg_restore \
  -U n8n -d n8n -c \
  /backups/n8n_backup_YYYY-MM-DD_HH-MM-SS.sql.gz

# 4. Reiniciar n8n
docker-compose start n8n-main n8n-worker
```

### Cenário 3: Volume Docker Corrompido

```bash
# 1. Backup emergencial (se possível)
docker run --rm -v n8n-server_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres_data_emergency.tar.gz /data

# 2. Recriar volume
docker-compose down -v
docker volume create n8n-server_postgres_data

# 3. Restaurar de backup
docker-compose up -d postgres
# Aguardar inicialização
docker-compose exec postgres pg_restore -U n8n -d n8n /backups/latest.sql.gz
```

## Checklist de Segurança

Antes de usar em produção:

- [ ] `.env` criado com senhas únicas
- [ ] `.env` NÃO commitado no Git
- [ ] N8N_ENCRYPTION_KEY com backup seguro
- [ ] Porta 5678 protegida (localhost ou proxy HTTPS)
- [ ] PostgreSQL/Redis NÃO expostos externamente
- [ ] Backups automáticos funcionando
- [ ] Backup manual testado e verificado
- [ ] Logs sem senhas expostas
- [ ] HTTPS configurado (produção)
- [ ] Firewall configurado no host
- [ ] Atualizações de segurança aplicadas

## Contato

Para reportar vulnerabilidades:
- **NÃO** abra issue público
- Contate diretamente o administrador do sistema
