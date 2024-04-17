#!/bin/sh

# Copiar arquivos HTML para o diretório de documentos do Nginx
cp -R /usr/share/nginx/html/* /mnt/shared_folder/Projects/GerenciamentoFutebol/

# Iniciar o Nginx
nginx -g "daemon off;"
