#!/bin/bash

# Script de backup do PostgreSQL para n8n
# Executado dentro do container postgres-backup

set -e

BACKUP_DIR="${BACKUP_DIR:-/backups}"
POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-n8n}"
POSTGRES_USER="${POSTGRES_USER:-n8n}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/n8n_backup_${TIMESTAMP}.sql.gz"

echo "[$(date)] Starting backup..."

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

# Executar backup com pg_dump
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -F c \
    | gzip > "$BACKUP_FILE"

# Verificar se backup foi criado
if [ -f "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] Backup completed: $BACKUP_FILE ($BACKUP_SIZE)"
else
    echo "[$(date)] ERROR: Backup failed!"
    exit 1
fi

# Limpar backups antigos
if [ "$RETENTION_DAYS" -gt 0 ]; then
    echo "[$(date)] Cleaning backups older than ${RETENTION_DAYS} days..."
    find "$BACKUP_DIR" -name "n8n_backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
    echo "[$(date)] Cleanup completed"
fi

# Listar backups atuais
echo "[$(date)] Current backups:"
ls -lh "$BACKUP_DIR"/n8n_backup_*.sql.gz 2>/dev/null || echo "No backups found"

echo "[$(date)] Backup process finished"
