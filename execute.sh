#!/bin/bash
set -e

# Installing needed dependencies
sudo apt update 
sudo apt install nodejs npm curl -y 

curl -fsSL https://pkg.cloudflare.com/cloudflare.key | sudo gpg --dearmor -o /usr/share/keyrings/cloudflare-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-archive-keyring.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update
sudo apt install -y cloudflared

# Download typescript and retranspile the code just in case
yes | sudo npm i -g typescript 
bash ./buildscript.sh

# Setting up the cloudflare tunnel
## Defining the cloudflare access token from cmd arguments
for argument in "$@"; do
   case $argument in token=*)
      token="${argument#token=}"
      break;;
   esac
done

cloudflared login --token "$token"
uuid=$(basename ~/.cloudflared/*.json .json)

cat > "$HOME/.cloudflared/config.yml" << EOL
tunnel: $uuid
credentials-file: $HOME/.cloudflared/$uuid.json

ingress:
  - hostname: db1.aetheris.mallou.dev
    service: tcp://127.0.0.1:5000
  - hostname: db2.aetheris.mallou.dev
    service: tcp://127.0.0.1:6000
  - hostname: aetheris.mallou.dev
    service: http://127.0.0.1:7000
  - hostname: api.aetheris.mallou.dev
    service: http://127.0.0.1:8000
  - service: http_status:404
EOL

sudo cloudflared service install
sudo systemctl enable cloudflared

# Reboot to make all services reboot
sudo reboot