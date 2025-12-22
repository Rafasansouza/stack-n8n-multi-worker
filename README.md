# n8n Server - Ambiente de Desenvolvimento

Configuração Docker do n8n 2.0.3 com PostgreSQL, Redis e suporte a Oracle Database para ambiente de desenvolvimento local.

## Stack Tecnológica

- **n8n**: 2.0.3 (workflow automation)
- **PostgreSQL**: 15 (banco de dados principal)
- **Redis**: 7 (queue manager para modo multi-worker)
- **Task Runner**: n8nio/runners (Python/JavaScript nativo em modo isolado)
- **Oracle Instant Client**: 19.19 (suporte a conexões Oracle)
- **WAHA**: latest (WhatsApp HTTP API)
- **Node.js**: 22 (runtime)
- **Python**: 3.x (execução nativa de código Python)

## Arquitetura

```
┌─────────────────┐
│   PostgreSQL    │◄─────┐
│   (port 5432)   │      │
└─────────────────┘      │
                         │
┌─────────────────┐      │
│     Redis       │◄─────┼─────┐
│   (port 6379)   │      │     │
└─────────────────┘      │     │
                         │     │
┌─────────────────┐      │     │
│   n8n-main      │──────┘     │
│ (port 5678/5679)│◄───┐       │
└─────────────────┘    │       │
        │              │       │
        │ Task Broker  │       │
        │ (5679)       │       │
        ▼              │       │
┌─────────────────┐    │       │
│  Task Runner    │────┘       │
│  (Python/JS)    │            │
└─────────────────┘            │
                               │
┌─────────────────┐            │
│  n8n-worker(s)  │────────────┘
│  (background)   │
└─────────────────┘

┌─────────────────┐
│      WAHA       │
│  (port 3000)    │
│  WhatsApp API   │
└─────────────────┘
```

### Modo Queue
O n8n está configurado em **modo queue** usando Bull + Redis, permitindo:
- Execução de workflows em background
- Escalonamento horizontal (múltiplos workers)
- Melhor performance para workflows pesados

### Task Runner (Python/JavaScript Nativo)
O projeto utiliza **task runner em modo external** para execução segura de código:
- **Container separado** `n8nio/runners` para isolamento de segurança
- **Suporte a Python 3** nativo (sem Pyodide)
- **Suporte a JavaScript** nativo
- **Comunicação via Task Broker** na porta 5679
- **Bibliotecas Python permitidas**: todas stdlib por padrão (`*`)
- **Autenticação via token** (N8N_RUNNERS_GRANT_TOKEN)

## Pré-requisitos

### Windows
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) 4.x ou superior
- [Git Bash](https://git-scm.com/downloads) ou WSL2 (para geração de senhas)

### Verificar Instalação
```powershell
docker --version
docker-compose --version
```

## Setup Inicial

### 1. Clonar/Baixar o Projeto
```bash
cd C:\Users\Rafael\Documents\projetos
# Se já está no diretório n8n-server, pule esta etapa
```

### 2. Configurar Variáveis de Ambiente

#### Opção A: Geração Automática (Recomendado)
Execute o script de setup:

**Windows PowerShell:**
```powershell
.\scripts\generate-env.ps1
```

**Git Bash/WSL:**
```bash
chmod +x scripts/generate-env.sh
./scripts/generate-env.sh
```

#### Opção B: Configuração Manual
```bash
# Copiar template
cp .env.example .env

# Editar .env e gerar valores seguros:
# - N8N_ENCRYPTION_KEY (openssl rand -base64 32)
# - POSTGRES_PASSWORD (openssl rand -base64 24)
# - REDIS_PASSWORD (openssl rand -base64 24)
# - N8N_RUNNERS_GRANT_TOKEN (openssl rand -base64 32)
```

**CRÍTICO:** Nunca use valores padrão como "change-me" em produção!

### 3. Build e Inicialização

```bash
# Build da imagem customizada
docker-compose build

# Iniciar todos os serviços
docker-compose up -d

# Verificar status
docker-compose ps

# Ver logs
docker-compose logs -f n8n-main
```

### 4. Acessar n8n

Abra o navegador em: **http://localhost:5678**

Na primeira execução:
1. Crie o usuário administrador
2. Configure workflows
3. Credenciais serão criptografadas com N8N_ENCRYPTION_KEY

### 5. Testar Python Runner (Opcional)

```bash
# Verificar se task-runner está healthy
docker-compose ps task-runner

# Criar um workflow de teste no n8n:
# 1. Adicione um nó "Code"
# 2. Selecione "Python (Native)" como linguagem
# 3. Cole este código:

import datetime

result = {
    'message': 'Python nativo funcionando!',
    'timestamp': str(datetime.datetime.now()),
    'version': '3.x'
}

return result

# 4. Execute o workflow - deve funcionar sem erros
```

## Gerenciamento

### Comandos Úteis

```bash
# Parar todos os serviços
docker-compose stop

# Parar e remover containers (volumes preservados)
docker-compose down

# Reiniciar serviço específico
docker-compose restart n8n-main

# Ver logs em tempo real
docker-compose logs -f

# Ver logs do Task Runner (Python/JS)
docker-compose logs -f task-runner

# Executar backup manual
docker-compose exec postgres-backup /scripts/backup.sh

# Escalar workers (adicionar mais 2 workers)
docker-compose up -d --scale n8n-worker=3

# Acessar shell do container
docker-compose exec n8n-main sh
```

### Healthchecks

Os serviços possuem healthchecks automáticos:

```bash
# Verificar saúde dos containers
docker-compose ps

# Status detalhado
docker inspect n8n-main | grep -A 10 Health
```

Status possíveis:
- `healthy`: Serviço funcionando
- `unhealthy`: Serviço com problemas
- `starting`: Inicializando

### Backup e Restore

#### Backup Automático
Configurado via variável `BACKUP_SCHEDULE` (padrão: diariamente às 2h):

```bash
# Ver último backup
docker-compose exec postgres-backup ls -lh /backups

# Ver logs de backup
docker-compose logs postgres-backup
```

#### Backup Manual
```bash
# Executar backup agora
docker-compose exec postgres-backup /scripts/backup.sh

# Verificar arquivo gerado
docker-compose exec postgres-backup ls -lh /backups
```

#### Restore de Backup
```bash
# 1. Parar n8n temporariamente
docker-compose stop n8n-main n8n-worker

# 2. Listar backups disponíveis
docker-compose exec postgres-backup ls -lh /backups

# 3. Restaurar backup específico
docker-compose exec postgres pg_restore -U n8n -d n8n -c /backups/n8n_backup_YYYY-MM-DD_HH-MM-SS.sql.gz

# 4. Reiniciar n8n
docker-compose start n8n-main n8n-worker
```

## Manutenção

### Atualizar n8n

```bash
# 1. Backup antes de atualizar (IMPORTANTE!)
docker-compose exec postgres-backup /scripts/backup.sh

# 2. Alterar versão no .env
# N8N_VERSION=2.1.0

# 3. Rebuild e restart
docker-compose build
docker-compose up -d
```

### Limpar Dados de Desenvolvimento

**ATENÇÃO:** Isso apagará TODOS os dados!

```bash
# Parar e remover tudo (incluindo volumes)
docker-compose down -v

# Remover imagens antigas
docker image prune -f
```

### Monitorar Recursos

```bash
# Uso de CPU/RAM
docker stats

# Espaço em disco dos volumes
docker system df -v
```

## Troubleshooting

### n8n não inicia

```bash
# Verificar logs
docker-compose logs n8n-main

# Problemas comuns:
# 1. N8N_ENCRYPTION_KEY vazia ou alterada
# 2. PostgreSQL não está pronto (espere healthcheck)
# 3. Redis sem senha configurada
```

### Erro de conexão com PostgreSQL

```bash
# Verificar se PostgreSQL está healthy
docker-compose ps postgres

# Testar conexão manual
docker-compose exec postgres psql -U n8n -d n8n -c "SELECT version();"

# Verificar senha no .env (POSTGRES_PASSWORD)
```

### Erro de conexão com Redis

```bash
# Verificar se Redis está rodando
docker-compose ps redis

# Testar autenticação
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping

# Deve retornar: PONG
```

### Workers não processam jobs

```bash
# Verificar logs do worker
docker-compose logs -f n8n-worker

# Verificar conexão Redis
docker-compose exec n8n-worker sh -c 'redis-cli -h redis -a $REDIS_PASSWORD ping'

# Reiniciar workers
docker-compose restart n8n-worker
```

### Oracle Database não conecta

```bash
# Verificar Oracle Instant Client
docker-compose exec n8n-main sh -c 'ls -lh $ORACLE_HOME'

# Testar variáveis de ambiente
docker-compose exec n8n-main env | grep ORACLE

# Verificar TNS_ADMIN
docker-compose exec n8n-main cat $TNS_ADMIN/tnsnames.ora
```

### Recuperar de N8N_ENCRYPTION_KEY perdida

**IMPORTANTE:** Se você perdeu a N8N_ENCRYPTION_KEY original, NÃO É POSSÍVEL recuperar credenciais criptografadas!

Opções:
1. **Restaurar backup** com a chave original
2. **Recriar credenciais** manualmente (workflows preservados, credenciais perdidas)

```bash
# Se optar por recriar:
# 1. Backup de segurança
docker-compose exec postgres-backup /scripts/backup.sh

# 2. Limpar credenciais antigas (opcional)
docker-compose exec postgres psql -U n8n -d n8n -c "DELETE FROM credentials_entity;"

# 3. Gerar nova chave e atualizar .env
# N8N_ENCRYPTION_KEY=<nova_chave>

# 4. Restart
docker-compose up -d

# 5. Reconfiguar credenciais na UI
```

### Python Code Node não funciona

```bash
# Verificar se task-runner está rodando
docker-compose ps task-runner

# Status esperado: "healthy"
# Se estiver "unhealthy" ou "restarting":

# 1. Verificar logs do task-runner
docker-compose logs task-runner

# 2. Verificar logs do n8n-main
docker-compose logs n8n-main | grep -i "task\|runner\|broker"

# 3. Verificar variáveis de ambiente
docker-compose exec task-runner printenv | grep N8N_RUNNERS

# 4. Verificar conectividade
docker-compose exec task-runner sh -c "wget -qO- http://n8n-main:5679/health || echo 'Não conectou'"

# 5. Reiniciar task-runner
docker-compose restart task-runner

# 6. Se o erro persistir, recriar containers
docker-compose down
docker-compose up -d
```

**Erros comuns**:
- `Virtual environment is missing` → Task runner não está rodando ou configurado incorretamente
- `Failed to connect to task broker` → Verificar porta 5679 e token de autenticação
- `N8N_RUNNERS_AUTH_TOKEN missing` → Verificar N8N_RUNNERS_GRANT_TOKEN no .env

### Task Runner com problemas

```bash
# Verificar configuração completa do task runner
docker-compose exec n8n-main printenv | grep N8N_RUNNERS

# Variáveis esperadas:
# N8N_RUNNERS_ENABLED=true
# N8N_RUNNERS_MODE=external
# N8N_RUNNERS_AUTH_TOKEN=<token>
# N8N_RUNNERS_TASK_BROKER_URI=tcp://0.0.0.0:5679

# Testar Python diretamente no task runner
docker-compose exec task-runner python3 -c "print('Python OK')"

# Verificar se n8n consegue alcançar o task broker
docker-compose exec n8n-main sh -c "wget -qO- http://localhost:5679/health"
```

### Espaço em disco cheio

```bash
# Limpar logs antigos
docker-compose exec postgres-backup /scripts/cleanup-old-backups.sh

# Limpar containers parados
docker container prune -f

# Limpar imagens não usadas
docker image prune -a -f

# Limpar build cache
docker builder prune -f
```

## Segurança

### Boas Práticas

1. **NUNCA commite o arquivo `.env`** - Use `.env.example` como template
2. **NUNCA mude N8N_ENCRYPTION_KEY** após criar workflows/credenciais
3. **Backup regular** antes de qualquer atualização
4. **Senhas fortes** geradas com OpenSSL/pwgen
5. **Rede isolada** - containers comunicam via rede interna do Docker

### Arquivo .env
```bash
# Verificar permissões (apenas leitura para owner)
icacls .env /grant:r "%USERNAME%:R"

# Adicionar ao .gitignore
echo ".env" >> .gitignore
```

### Portas Expostas

| Porta | Serviço | Descrição | Acesso |
|-------|---------|-----------|--------|
| 5678 | n8n-main | Interface Web | Externo |
| 5679 | n8n-main | Task Broker | Externo (para task-runner) |
| 3000 | WAHA | WhatsApp HTTP API | Externo |
| 5432 | PostgreSQL | Banco de dados | Apenas interno |
| 6379 | Redis | Queue manager | Apenas interno |

**Nota**: PostgreSQL e Redis são acessíveis apenas pela rede interna do Docker.

Para expor PostgreSQL/Redis (desenvolvimento):
```yaml
# Em docker-compose.yml
postgres:
  ports:
    - "5432:5432"  # Adicionar apenas se necessário
```

## Estrutura de Arquivos

```
n8n-server/
├── .env                      # Configuração (NÃO commitado)
├── .env.example              # Template de configuração
├── .dockerignore             # Arquivos ignorados no build
├── Dockerfile                # Imagem customizada n8n + Oracle
├── docker-compose.yml        # Orquestração de serviços
├── README.md                 # Esta documentação
├── SECURITY.md               # Guia de segurança
├── n8n-2.0.3.tgz            # Pacote n8n (opcional)
├── package/                  # Código n8n descompactado
├── scripts/
│   ├── generate-env.sh      # Gera .env com senhas seguras (Linux/Mac)
│   ├── generate-env.ps1     # Gera .env com senhas seguras (Windows)
│   ├── backup.sh            # Script de backup PostgreSQL
│   └── cleanup-old-backups.sh # Limpa backups antigos
└── backups/                  # Backups do PostgreSQL (volume)
```

## Volumes Docker

```bash
# Localização dos volumes
docker volume ls | grep n8n-server

# Volumes criados:
# - n8n-server_n8n_data          -> /home/node/.n8n (dados n8n)
# - n8n-server_postgres_data     -> /var/lib/postgresql/data (banco de dados)
# - n8n-server_redis_data        -> /data (cache Redis)
# - n8n-server_postgres_backups  -> /backups (backups PostgreSQL)
# - n8n-server_waha_data         -> /app/.sessions (sessões WhatsApp)
```

## Configurações Avançadas

### Adicionar Configuração Oracle (tnsnames.ora)

```bash
# Criar arquivo tnsnames.ora local
mkdir -p oracle
cat > oracle/tnsnames.ora << 'EOF'
MYDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-server.example.com)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCL)
    )
  )
EOF

# Atualizar docker-compose.yml para montar arquivo
# n8n-main:
#   volumes:
#     - ./oracle/tnsnames.ora:${TNS_ADMIN}/tnsnames.ora:ro
```

### Habilitar HTTPS (desenvolvimento)

```bash
# 1. Gerar certificado autoassinado
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/key.pem -out certs/cert.pem \
  -subj "/CN=localhost"

# 2. Atualizar .env
# N8N_PROTOCOL=https
# WEBHOOK_URL=https://localhost:5678/

# 3. Montar certificados no docker-compose.yml
```

### Configurar Bibliotecas Python Externas

Por padrão, todas as bibliotecas padrão do Python (`stdlib`) estão permitidas. Para adicionar bibliotecas externas:

```bash
# 1. Criar Dockerfile customizado para o task runner
cat > Dockerfile.task-runner << 'EOF'
FROM n8nio/runners:latest

USER root
RUN pip install --no-cache-dir \
    pandas \
    numpy \
    requests \
    beautifulsoup4 \
    pytz

USER node
EOF

# 2. Atualizar docker-compose.yml
# task-runner:
#   build:
#     context: .
#     dockerfile: Dockerfile.task-runner
#   image: n8n-task-runner-custom:latest

# 3. Adicionar bibliotecas permitidas no .env
# N8N_RUNNERS_EXTERNAL_ALLOW=pandas,numpy,requests,beautifulsoup4,pytz

# 4. Rebuild e restart
docker-compose build task-runner
docker-compose up -d task-runner
```

**Segurança**: O task runner bloqueia importações não autorizadas por padrão. Use `N8N_RUNNERS_EXTERNAL_ALLOW` para permitir bibliotecas específicas.

### Múltiplos Workers

```bash
# Escalar para 3 workers
docker-compose up -d --scale n8n-worker=3

# Verificar
docker-compose ps n8n-worker
```

## Recursos Adicionais

### Documentação n8n
- [Documentação Oficial n8n](https://docs.n8n.io)
- [n8n Docker Setup](https://docs.n8n.io/hosting/installation/docker/)
- [n8n Queue Mode](https://docs.n8n.io/hosting/scaling/queue-mode/)
- [Task Runners](https://docs.n8n.io/hosting/configuration/task-runners/)
- [Task Runner Environment Variables](https://docs.n8n.io/hosting/configuration/environment-variables/task-runners/)
- [Code Node Documentation](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.code/)
- [n8n 2.0 Breaking Changes](https://docs.n8n.io/2-0-breaking-changes/)

### Comunidade
- [Community Forum](https://community.n8n.io)
- [n8n GitHub Issues](https://github.com/n8n-io/n8n/issues)

## Suporte

Para problemas:
1. Verificar logs: `docker-compose logs`
2. Consultar seção Troubleshooting acima
3. Verificar [issues do n8n no GitHub](https://github.com/n8n-io/n8n/issues)
4. Perguntar no [community forum](https://community.n8n.io)

## Licença

Este projeto usa n8n 2.0.3 sob [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md).

Para mais informações sobre licenciamento: [docs.n8n.io/sustainable-use-license](https://docs.n8n.io/sustainable-use-license/)
