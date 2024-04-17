FROM httpd:latest

# Remover os arquivos padrão do Apache, se necessário
RUN rm -r /usr/local/apache2/htdocs/*

# Copiar os arquivos HTML do diretório local para o contêiner
COPY . /usr/local/apache2/htdocs/

# Certificar-se de que o Apache pode acessar os arquivos
RUN chown -R www-data:www-data /usr/local/apache2/htdocs/
