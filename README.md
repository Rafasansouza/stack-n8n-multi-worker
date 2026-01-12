# n8n Server - Ambiente Multi-Worker com Oracle DB

> Configuração profissional do n8n 2.0.3 em modo queue com PostgreSQL, Redis, Oracle Instant Client 19.19 e Python 3.13.1

![n8n](https://img.shields.io/badge/n8n-2.0.3-orange)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)
![Redis](https://img.shields.io/badge/Redis-7-red)
![Oracle](https://img.shields.io/badge/Oracle%20IC-19.19-red)
![Python](https://img.shields.io/badge/Python-3.13.1-blue)
![Node.js](https://img.shields.io/badge/Node.js-22-green)

---

## 🚀 Quick Start

```bash
# 1. Gerar .env com senhas seguras
./scripts/generate-env.sh      # Linux/Mac/Git Bash
# ou
.\scripts\generate-env.ps1     # Windows PowerShell

# 2. Build e iniciar (10-15min primeira vez)
docker compose build
docker compose up -d

# 3. Verificar status (aguarde ~2min)
docker compose ps

# 4. Acessar: http://localhost:5678
```

**Primeira execução**: Crie usuário administrador na interface web.

📖 **Documentação completa**: [docs/DEPLOY.md](docs/DEPLOY.md)

---

## 📦 Stack Tecnológica

| Componente | Versão | Função |
|-----------|--------|--------|
| **n8n** | 2.0.3 | Workflow automation (interface + workers) |
| **PostgreSQL** | 15 | Banco de dados principal |
| **Redis** | 7-alpine | Queue manager para modo distribuído |
| **Oracle Instant Client** | 19.19 | Conectividade com Oracle Database |
| **Python** | 3.13.1 | Execução de código Python (compilado do source) |
| **Node.js** | 22-bookworm | Runtime JavaScript |
| **Task Runner** | latest | Container isolado para Python/JS (n8nio/runners) |
| **WAHA** | latest | WhatsApp HTTP API |

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Network (n8n-network)             │
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │  PostgreSQL  │◄────────┤   n8n-main   │ :5678 (Web UI)      │
│  │   (port 5432)│         │              │ :5679 (Task Broker) │
│  └──────────────┘         └──────┬───────┘                     │
│         ▲                        │                              │
│         │                        │                              │
│         │                        ▼                              │
│  ┌──────┴──────┐         ┌──────────────┐                     │
│  │    Redis    │◄────────┤  n8n-worker  │ (Processa jobs)     │
│  │  (port 6379)│         │   (escalável)│                     │
│  └─────────────┘         └──────────────┘                     │
│         ▲                                                       │
│         │                ┌──────────────┐                     │
│         └────────────────┤ Task Runner  │ (Python/JS sandbox) │
│                          └──────────────┘                     │
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │     WAHA     │         │postgres-backup│ (Backups diários)  │
│  │  (port 3000) │         │   (cron)     │                     │
│  └──────────────┘         └──────────────┘                     │
└─────────────────────────────────────────────────────────────────┘

Portas Expostas ao Host:
  • 5678 → n8n Web UI
  • 3000 → WAHA API
```

### Componentes

- **n8n-main**: Interface web, coordenador e API REST
- **n8n-worker**: Workers para processamento em background (escalável)
- **task-runner**: Container isolado para execução segura de código Python/JavaScript
- **postgres**: Banco de dados com workflows, execuções e credenciais
- **redis**: Gerenciador de filas (Bull Queue)
- **waha**: API HTTP para integração WhatsApp
- **postgres-backup**: Backups automáticos agendados via cron

---

## ✨ Características Principais

### Componentes Instalados e Configurados

- ✅ **Oracle Instant Client 19.19.0.0.0** - Instalado e configurado com todas variáveis de ambiente
  - `ORACLE_HOME`, `LD_LIBRARY_PATH`, `TNS_ADMIN` configurados
  - Validação SHA256 durante build
  - Suporte a tnsnames.ora para configurações Oracle

- ✅ **Python 3.13.1** - Compilado do source com otimizações
  - Built com `--enable-optimizations` (PGO)
  - Pip 3.13 incluído
  - Links simbólicos para python3/pip3

- ✅ **Modo Queue Distribuído** - Processamento escalável
  - Redis como gerenciador de filas (Bull Queue)
  - Múltiplos workers simultâneos
  - Escalabilidade horizontal (`--scale n8n-worker=N`)

- ✅ **Task Runner External** - Segurança reforçada
  - Execução de código Python/JS em container isolado
  - Sandbox para prevenir acesso não autorizado
  - Suporte a bibliotecas stdlib completo

- ✅ **Backup Automático** - Proteção de dados
  - Backups diários via cron (padrão: 2h da manhã)
  - Retenção configurável (padrão: 7 dias)
  - Scripts de backup/restore incluídos

- ✅ **Healthchecks** - Monitoramento built-in
  - Todos os containers com healthcheck configurado
  - Auto-restart em caso de falha
  - Status via `docker-compose ps`

- ✅ **WhatsApp Integration** - WAHA API
  - Envio/recebimento de mensagens
  - Swagger UI em http://localhost:3000
  - Suporte a múltiplas sessões

---

## ⚡ Comandos Essenciais

```bash
# Status e logs
docker compose ps
docker compose logs -f n8n-main

# Gerenciamento
docker compose restart
docker compose down
docker compose up -d

# Backup manual
docker compose exec postgres-backup /scripts/backup.sh

# Escalar workers
docker compose up -d --scale n8n-worker=3

# Verificar componentes
docker compose exec n8n-main python --version        # Python 3.13.1
docker compose exec n8n-main sh -c 'ls $ORACLE_HOME' # Oracle IC
docker stats                                          # Recursos
```

---

## 💻 Requisitos de Sistema

| Recurso | Mínimo | Recomendado |
|---------|---------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4 GB | 8+ GB |
| **Disco** | 10 GB | 50+ GB |
| **Docker** | 20.10+ | 24.0+ |
| **Docker Compose** | 2.0+ | 2.20+ |

**Sistema Operacional**:
- Windows 10/11 com Docker Desktop
- Linux (Ubuntu 20.04+, Debian 11+)
- macOS 11+

**Portas Necessárias** (não devem estar em uso):
- `5678` - n8n Web UI
- `5679` - n8n Task Broker
- `3000` - WAHA API

---

## 🆘 Troubleshooting

```bash
# Container não fica healthy
docker compose logs <container-name>
docker compose restart <container-name>

# n8n não carrega
docker compose exec postgres pg_isready -U n8n
docker compose logs -f n8n-main

# Task timeout errors
docker compose logs n8n-main | grep "Task Broker"
docker compose restart n8n-main task-runner
```

📚 **Documentação completa**: [docs/DEPLOY.md](docs/DEPLOY.md)

---

## 📝 Estrutura do Projeto

```
n8n-server/
├── .env                      # Configuração (gerado, não commitar)
├── .env.example              # Template de configuração
├── .dockerignore             # Arquivos ignorados no build
├── .gitignore                # Git ignore
├── Dockerfile                # Imagem customizada (n8n + Oracle + Python 3.13)
├── docker-compose.yml        # Orquestração de containers
├── README.md                 # Este arquivo
├── docs/
│   └── DEPLOY.md            # Documentação completa de deploy
└── scripts/
    ├── backup.sh            # Backup PostgreSQL
    ├── cleanup-old-backups.sh
    ├── generate-env.sh      # Gera .env (Linux/Mac/Git Bash)
    └── generate-env.ps1     # Gera .env (Windows PowerShell)
```

---

## 🔐 Segurança

**Práticas Implementadas**:
- ✅ Credenciais criptografadas com AES-256 (N8N_ENCRYPTION_KEY)
- ✅ Senhas fortes geradas automaticamente
- ✅ PostgreSQL/Redis não expostos publicamente
- ✅ Containers executam como non-root user
- ✅ Rede Docker isolada
- ✅ Task runner em sandbox isolado
- ✅ Validação SHA256 do Oracle IC

**⚠️ IMPORTANTE**:
- NUNCA commite o arquivo `.env` no Git
- Faça backup da `N8N_ENCRYPTION_KEY` em local seguro
- NUNCA altere `N8N_ENCRYPTION_KEY` após criar workflows
- Use senhas únicas para produção

---

## 📜 Licença

Este projeto usa n8n 2.0.3 sob [Sustainable Use License](https://github.com/n8n-io/n8n/blob/master/LICENSE.md).

---

**Desenvolvido com** ⚡ n8n + 🐘 PostgreSQL + 🔴 Redis + 🔮 Oracle + 🐍 Python 3.13
