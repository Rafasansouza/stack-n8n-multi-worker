# Deploy n8n Server

Guia completo para deploy do n8n Server com Python 3.13, Oracle IC 19.19 e task runners.

---

## Stack

- **n8n**: 2.0.3 (workflow automation)
- **PostgreSQL**: 15 (database)
- **Redis**: 7 (queue manager)
- **Python**: 3.13.1 (compilado do source)
- **Oracle Instant Client**: 19.19
- **Task Runner**: n8nio/runners (execução isolada Python/JS)
- **WAHA**: WhatsApp HTTP API

---

## Deploy Local (Windows/Linux/Mac)

### Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 4GB+ RAM, 10GB+ disco

### Comandos

```bash
# 1. Clonar projeto
git clone <seu-repositorio> n8n-server
cd n8n-server

# 2. Gerar .env com senhas automáticas
./scripts/generate-env.sh      # Linux/Mac/Git Bash
# ou
.\scripts\generate-env.ps1     # Windows PowerShell

# 3. Build (10-15min primeira vez)
docker compose build

# 4. Iniciar
docker compose up -d

# 5. Verificar (aguarde ~2min)
docker compose ps
# Todos devem estar "healthy"

# 6. Acessar
http://localhost:5678
```

**Primeira execução**: Crie usuário admin na interface.

---

## Deploy Servidor Linux

### 1. Instalar Docker

**Ubuntu/Debian:**
```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER && newgrp docker
docker --version
```

**CentOS/RHEL:**
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker && sudo systemctl enable docker
sudo usermod -aG docker $USER && newgrp docker
```

### 2. Transferir Projeto

**Via Git:**
```bash
cd /opt
sudo git clone <seu-repositorio> n8n-server
sudo chown -R $USER:$USER n8n-server
cd n8n-server
```

**Via SCP (do Windows):**
```bash
# No Windows (Git Bash):
scp -r . usuario@servidor:/tmp/n8n-server

# No servidor:
sudo mv /tmp/n8n-server /opt/
cd /opt/n8n-server
```

### 3. Configurar e Iniciar

```bash
# Gerar .env
chmod +x scripts/generate-env.sh
./scripts/generate-env.sh

# Editar se necessário (domínio, HTTPS)
nano .env

# Build
docker compose build

# Iniciar
docker compose up -d

# Verificar
docker compose ps
```

### 4. Firewall

**Ubuntu/Debian:**
```bash
sudo ufw allow 5678/tcp
sudo ufw enable
```

**CentOS/RHEL:**
```bash
sudo firewall-cmd --permanent --add-port=5678/tcp
sudo firewall-cmd --reload
```

### 5. Acessar

```
http://IP_SERVIDOR:5678
```

---

## HTTPS (Produção)

### Nginx + Let's Encrypt

```bash
# Instalar
sudo apt install -y nginx certbot python3-certbot-nginx

# Configurar Nginx
sudo tee /etc/nginx/sites-available/n8n > /dev/null <<'EOF'
server {
    listen 80;
    server_name seu-dominio.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Ativar
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# SSL
sudo certbot --nginx -d seu-dominio.com --email seu@email.com --agree-tos
```

**Ajustar .env:**
```bash
N8N_HOST=seu-dominio.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://seu-dominio.com/
```

```bash
docker compose restart n8n-main
```

---

## Auto-start (Systemd)

```bash
sudo tee /etc/systemd/system/n8n-server.service > /dev/null <<'EOF'
[Unit]
Description=n8n Server
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/n8n-server
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable n8n-server
sudo systemctl start n8n-server
```

---

## Gerenciamento

### Comandos Básicos

```bash
# Status
docker compose ps

# Logs
docker compose logs -f n8n-main

# Reiniciar
docker compose restart

# Parar
docker compose down

# Iniciar
docker compose up -d

# Recursos
docker stats
```

### Backup

```bash
# Backup manual PostgreSQL
docker compose exec postgres-backup /scripts/backup.sh

# Listar backups
docker compose exec postgres-backup ls -lh /backups

# Exportar backup para host
docker cp n8n-postgres-backup:/backups/n8n_backup_YYYY-MM-DD_HH-MM-SS.sql.gz ./
```

### Restore

```bash
# Copiar backup para container
docker cp backup.sql.gz n8n-postgres-backup:/backups/

# Restaurar
docker compose exec postgres-backup sh -c "
  gunzip < /backups/backup.sql.gz | psql -U n8n -d n8n
"

# Reiniciar n8n
docker compose restart n8n-main n8n-worker
```

### Escalar Workers

```bash
# Adicionar workers (total 3)
docker compose up -d --scale n8n-worker=3

# Verificar
docker compose ps | grep worker
```

### Atualizar n8n

```bash
# 1. Backup primeiro!
docker compose exec postgres-backup /scripts/backup.sh

# 2. Editar .env
nano .env
# Alterar: N8N_VERSION=2.1.0

# 3. Rebuild
docker compose build --no-cache
docker compose up -d

# 4. Verificar
docker compose logs -f n8n-main
```

---

## Troubleshooting

### Container não fica healthy

```bash
docker compose logs <container-name>
docker compose restart <container-name>
```

### n8n não carrega

```bash
# Verificar PostgreSQL
docker compose exec postgres pg_isready -U n8n

# Verificar Redis
docker compose exec redis redis-cli ping

# Ver logs
docker compose logs -f n8n-main
```

### Task timeout errors

```bash
# Verificar task broker
docker compose logs n8n-main | grep "Task Broker"
# Deve mostrar: "ready on 0.0.0.0, port 5679"

# Reiniciar
docker compose restart n8n-main task-runner
```

### Verificar componentes

```bash
# Python 3.13
docker compose exec n8n-main python --version
# Output: Python 3.13.1

# Oracle IC
docker compose exec n8n-main sh -c 'ls -lh $ORACLE_HOME'
# Output: /opt/oracle/instantclient_19_19

# Task broker connectivity
docker compose exec task-runner wget -O- --timeout=2 http://n8n-main:5679
# Deve conectar (não "Connection refused")
```

### Limpar espaço

```bash
docker system prune -a
docker volume prune  # ⚠️ Remove volumes não usados
```

### Rebuild completo

```bash
docker compose down
docker rmi n8n-custom:2.0.3
docker compose build --no-cache
docker compose up -d
```

---

## Configurações Avançadas

### Variáveis .env Importantes

```bash
# n8n
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678/
N8N_ENCRYPTION_KEY=<gerado-automaticamente>

# PostgreSQL
POSTGRES_PASSWORD=<gerado-automaticamente>

# Redis
REDIS_PASSWORD=<gerado-automaticamente>

# Task Runner
N8N_RUNNERS_GRANT_TOKEN=<gerado-automaticamente>
N8N_RUNNERS_TASK_TIMEOUT=60                    # segundos
N8N_RUNNERS_MAX_CONCURRENCY=5                  # tasks simultâneas
N8N_RUNNERS_MAX_PAYLOAD=1073741824             # 1GB

# WAHA
WAHA_API_KEY=<gerado-automaticamente>
WAHA_SWAGGER_USERNAME=admin
WAHA_SWAGGER_PASSWORD=<gerado-automaticamente>
WAHA_DASHBOARD_USERNAME=admin
WAHA_DASHBOARD_PASSWORD=<gerado-automaticamente>

# Backup
BACKUP_RETENTION_DAYS=7
BACKUP_SCHEDULE=0 2 * * *                      # 2h da manhã

# Oracle IC
ORACLE_IC_SHA256=8d8c222d89be761c5e44baa9f6b688e11830f0a82e84b5b0f7e88ff58cff4b65
```

### Aumentar Timeout de Tasks

Editar `.env`:
```bash
N8N_RUNNERS_TASK_TIMEOUT=300        # 5 minutos
N8N_RUNNERS_MAX_CONCURRENCY=10
```

Reiniciar:
```bash
docker compose restart n8n-main task-runner
```

### Configurar Oracle TNS

```bash
mkdir -p config/oracle
cat > config/oracle/tnsnames.ora <<'EOF'
ORCL =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-host)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = orcl)
    )
  )
EOF
```

Adicionar ao `docker-compose.yml` (n8n-main e n8n-worker):
```yaml
environment:
  TNS_ADMIN: /home/node/config/oracle
volumes:
  - ./config/oracle:/home/node/config/oracle:ro
```

---

## Volumes Docker

```
n8n_data:          /home/node/.n8n (workflows, credenciais)
postgres_data:     /var/lib/postgresql/data
redis_data:        /data
postgres_backups:  /backups
waha_data:         /app/.sessions
```

### Backup de Volumes

```bash
# Parar containers
docker compose down

# Backup n8n_data
docker run --rm \
  -v n8n-server_n8n_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/n8n_data.tar.gz -C /data .

# Backup postgres_data
docker run --rm \
  -v n8n-server_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres_data.tar.gz -C /data .

# Reiniciar
docker compose up -d
```

---

## Segurança

### ✅ Implementado

- Credenciais criptografadas (AES-256)
- Senhas fortes geradas automaticamente
- PostgreSQL/Redis não expostos publicamente
- Task runner em sandbox isolado
- Validação SHA256 do Oracle IC
- Rede Docker isolada

### ⚠️ Importante

- NUNCA commite `.env` no Git
- Faça backup da `N8N_ENCRYPTION_KEY`
- NUNCA altere `N8N_ENCRYPTION_KEY` após criar workflows
- Use HTTPS em produção
- Firewall configurado corretamente

---

## Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                   Docker Network (n8n-network)          │
│                                                         │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐     │
│  │PostgreSQL│◄─────┤ n8n-main │─────►│  Redis   │     │
│  │  :5432   │      │:5678:5679│      │  :6379   │     │
│  └──────────┘      └─────┬────┘      └──────────┘     │
│                          │                              │
│                          ▼                              │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐     │
│  │n8n-worker│      │task-runner│     │   WAHA   │     │
│  │          │      │ (sandbox) │      │  :3000   │     │
│  └──────────┘      └──────────┘      └──────────┘     │
│                                                         │
│  ┌──────────────────┐                                  │
│  │ postgres-backup  │ (cron diário)                    │
│  └──────────────────┘                                  │
└─────────────────────────────────────────────────────────┘

Portas expostas:
  5678 → n8n Web UI
  5679 → Task Broker (interno)
  3000 → WAHA API
```

---

## Checklist Pós-Deploy

- [ ] Docker instalado e funcionando
- [ ] Projeto clonado/transferido
- [ ] Arquivo `.env` gerado
- [ ] Build concluído (~10-15min)
- [ ] Containers "healthy" (`docker compose ps`)
- [ ] n8n acessível via navegador
- [ ] Usuário admin criado
- [ ] Python 3.13.1 verificado
- [ ] Oracle IC verificado
- [ ] Task runner conectado (sem timeouts)
- [ ] Firewall configurado
- [ ] HTTPS configurado (produção)
- [ ] Auto-start habilitado (produção)
- [ ] Backup testado

---

## Recursos

- [n8n Docs](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)
- [WAHA Docs](https://waha.devlike.pro/)
- [Docker Docs](https://docs.docker.com/)

---

**Deploy concluído! Acesse:** `http://localhost:5678` ou `http://IP_SERVIDOR:5678`
