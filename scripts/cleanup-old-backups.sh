#!/bin/bash

# Script para limpar backups antigos manualmente
# Uso: docker-compose exec postgres-backup /scripts/cleanup-old-backups.sh [dias]

BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${1:-${BACKUP_RETENTION_DAYS:-7}}"

echo "Limpando backups mais antigos que ${RETENTION_DAYS} dias..."
echo "Diretório: $BACKUP_DIR"
echo ""

# Listar backups que serão removidos
echo "Backups que serão removidos:"
find "$BACKUP_DIR" -name "n8n_backup_*.sql.gz" -mtime +${RETENTION_DAYS} -ls

# Contar quantos serão removidos
COUNT=$(find "$BACKUP_DIR" -name "n8n_backup_*.sql.gz" -mtime +${RETENTION_DAYS} | wc -l)

if [ "$COUNT" -eq 0 ]; then
    echo ""
    echo "Nenhum backup antigo encontrado."
    exit 0
fi

echo ""
echo "Total de arquivos: $COUNT"
echo ""
read -p "Confirma remoção? (s/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    find "$BACKUP_DIR" -name "n8n_backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
    echo "Backups removidos com sucesso!"
else
    echo "Operação cancelada."
fi

echo ""
echo "Backups restantes:"
ls -lh "$BACKUP_DIR"/n8n_backup_*.sql.gz 2>/dev/null || echo "Nenhum backup encontrado"
