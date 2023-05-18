#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

PROJECT_NAME='***********'
APP_NAME='*********'
APP_USER='********'
GIT_URL='https://github.com/bgelov/*******'
VENV_DIR="/var/venv/${PROJECT_NAME}"

echo "Run deploy script in $SCRIPT_DIR"
echo "Project: $GIT_URL"

echo "Select environment (prod, pre, dev)"
read env

if [ "$env" = "prod" ]
then
        echo "Deploy on production environment..."
        PROJECT_FOLDER="${SCRIPT_DIR}/${env}"
elif [ "$env" = "pre" ]
then
        echo "Deploy on preproduction environment..."
        PROJECT_FOLDER="${SCRIPT_DIR}/${env}"
elif [ "$env" = "dev" ]
then
        echo "Deploy on development environment..."
        PROJECT_FOLDER="${SCRIPT_DIR}/${env}"
else
        echo "Not prod, pre or dev."
        exit
fi

echo "Recreate project folder from git $GIT_URL"
rm -rf "$PROJECT_FOLDER"
cd "$SCRIPT_DIR" && git clone "$GIT_URL" "$env"

echo "Copying dotenv file..."
cp "/var/www/********/.env/${env}/.env" "$PROJECT_FOLDER"


echo "Creating virtual environment..."
if ! [ -d "$VENV_DIR" ]
then
        echo "Creating directory $VENV_DIR"
        mkdir "$VENV_DIR"
fi

echo "Recreate venv for ${env} environment..."
cd "$VENV_DIR" && rm -rf "${env}_venv"
cd "$VENV_DIR" && python3 -m venv "${env}_venv"
echo "Activate ${env} venv"
source "${VENV_DIR}/${env}_venv/bin/activate"
python -m pip install --upgrade pip
pip install -r "${PROJECT_FOLDER}/requirements.txt" --no-input


cd "$PROJECT_FOLDER" && python ./manage.py collectstatic --noinput
cd "$PROJECT_FOLDER" && python ./manage.py makemigrations
cd "$PROJECT_FOLDER" && python ./manage.py migrate


echo "Creating gunicorn socket..."
SOCKET_FILE="/etc/systemd/system/${PROJECT_NAME}_${env}.socket"
rm -rf "$SOCKET_FILE"
touch "$SOCKET_FILE"
echo "[Unit]" >> "$SOCKET_FILE"
echo "Description=${PROJECT_NAME}_${env} gunicorn socket" >> "$SOCKET_FILE"
echo "" >> "$SOCKET_FILE"
echo "[Socket]" >> "$SOCKET_FILE"
echo "ListenStream=/run/${PROJECT_NAME}_${env}.sock" >> "$SOCKET_FILE"
echo "" >> "$SOCKET_FILE"
echo "[Install]" >> "$SOCKET_FILE"
echo "WantedBy=sockets.target" >> "$SOCKET_FILE"


echo "Creating service..."
SERVICE_FILE="/etc/systemd/system/${PROJECT_NAME}_${env}.service"
rm -rf "$SERVICE_FILE"
touch "$SERVICE_FILE"
echo "[Unit]" >> "$SERVICE_FILE"
echo "Description=${PROJECT_NAME}_${env} gunicorn daemon" >> "$SERVICE_FILE"
echo "Requires=${PROJECT_NAME}_${env}.socket" >> "$SERVICE_FILE"
echo "After=network.target" >> "$SERVICE_FILE"
echo "" >> "$SERVICE_FILE"
echo "[Service]" >> "$SERVICE_FILE"
echo "User=${APP_USER}" >> "$SERVICE_FILE"
echo "Group=www-data" >> "$SERVICE_FILE"
echo "WorkingDirectory=${PROJECT_FOLDER}" >> "$SERVICE_FILE"
echo "ExecStart=${VENV_DIR}/${env}_venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/${PROJECT_NAME}_${env}.sock ${APP_NAME}.wsgi:application" >> "$SERVICE_FILE"
echo "" >> "$SERVICE_FILE"
echo "[Install]" >> "$SERVICE_FILE"
echo "WantedBy=multi-user.target" >> "$SERVICE_FILE"

systemctl daemon-reload
systemctl enable "${PROJECT_NAME}_${env}.socket"
systemctl restart "${PROJECT_NAME}_${env}"

echo "Creating nginx config..."
NGINX_CONFIG="/etc/nginx/sites-available/${PROJECT_NAME}_${env}"
rm -rf "/etc/nginx/sites-enabled/${PROJECT_NAME}_${env}"
rm -rf "$NGINX_CONFIG"
touch "$NGINX_CONFIG"
echo "server {" >> "$NGINX_CONFIG"
echo "    listen 80;" >> "$NGINX_CONFIG"
echo "    server_name test.ip03.ru;" >> "$NGINX_CONFIG"
echo "    location = /favicon.ico { access_log off; log_not_found off; }" >> "$NGINX_CONFIG"
echo "    location /static/ {" >> "$NGINX_CONFIG"
echo "        root ${PROJECT_FOLDER};" >> "$NGINX_CONFIG"
echo "    }" >> "$NGINX_CONFIG"
echo "" >> "$NGINX_CONFIG"
echo "    location / {" >> "$NGINX_CONFIG"
echo "        include proxy_params;" >> "$NGINX_CONFIG"
echo "        proxy_pass http://unix:/run/${PROJECT_NAME}_${env}.sock;" >> "$NGINX_CONFIG"
echo "    }" >> "$NGINX_CONFIG"
echo "}" >> "$NGINX_CONFIG"

ln -s "$NGINX_CONFIG" "/etc/nginx/sites-enabled"
nginx -t
nginx -s reload

echo "Reinstall SSL certificate..."
certbot --nginx -d upakovka.avantapack.ru -d avantapack.ip03.ru --reinstall
nginx -t
nginx -s reload

systemctl status "${PROJECT_NAME}_${env}"


echo "Done! Please check."
