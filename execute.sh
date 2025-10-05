#!/bin/bash
set -e

# Installing needed dependencies
sudo apt update 
sudo apt install nodejs npm curl -y 

ARCH="$(dpkg --print-architecture)"
curl -L -o /tmp/cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb"
sudo dpkg -i /tmp/cloudflared.deb || sudo apt-get -f install -y
rm -f /tmp/cloudflared.deb

# Download typescript and retranspile the code just in case
yes | sudo npm i -g typescript pm2
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

for argument in "$@"; do
   case $argument in vps=*)
      vps="${argument#vps=}"
      break;;
   esac
done

cat > "$HOME/.cloudflared/config.yml" << EOL
tunnel: $uuid
credentials-file: $HOME/.cloudflared/$uuid.json

ingress:
  - hostname: db$vps.aetheris.mallou.dev
    service: tcp://127.0.0.1:5432
  - hostname: vps$vps.aetheris.mallou.dev
    service: ssh://127.0.0.1:22
  - hostname: aetheris.mallou.dev
    service: http://127.0.0.1:8000
  - hostname: api.aetheris.mallou.dev
    service: http://127.0.0.1:9000
  - service: http_status:404
EOL

sudo cloudflared service install
sudo systemctl enable cloudflared

# Configure PM2 to always run the javascript code
sudo pm2 start ./dist/commonjs/index.js --name main
sudo pm2 save
sudo pm2 startup systemd -u $USER --hp $HOME

# Reboot to make all services reboot
sudo reboot