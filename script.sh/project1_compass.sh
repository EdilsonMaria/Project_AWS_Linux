#!/bin/bash

# Configurações
SERVICE_NAME="Apache"
SERVICE_URL="http://localhost:80"
EFS_DIR="/mnt/efs/status"
ONLINE_STATUS_FILE="$EFS_DIR/online_status.txt"
OFFLINE_STATUS_FILE="$EFS_DIR/offline_status.txt"

# Cria o diretório no EFS se não existir
if [ ! -d "$EFS_DIR" ]; then
    sudo mkdir -p "$EFS_DIR"
fi

# Verifica se o serviço Apache está online
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" $SERVICE_URL)

# Pega a data e hora atual
CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")

if [ "$HTTP_STATUS" -eq 200 ]; then
    STATUS="ONLINE"
    MESSAGE="O serviço Apache está funcionando corretamente."
    echo "$CURRENT_DATETIME - Serviço: $SERVICE_NAME - Status: $STATUS - Mensagem: $MESSAGE" >> $ONLINE_STATUS_FILE
else
    STATUS="OFFLINE"
    MESSAGE="O serviço Apache está inacessível ou ocorreu um problema."
    echo "$CURRENT_DATETIME - Serviço: $SERVICE_NAME - Status: $STATUS - Mensagem: $MESSAGE" >> $OFFLINE_STATUS_FILE
fi
