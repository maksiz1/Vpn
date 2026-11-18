#!/bin/sh
set -eu

UUID="${UUID:?set UUID variable}"
PORT="${PORT:-8080}"
WS_PATH="${WS_PATH:-/v1/stream}"

# заглушка: на "/" отдаём обычную страничку (и для healthcheck, и чтобы домен выглядел как сайт)
mkdir -p /www /etc/xray
printf '<!doctype html><meta charset=utf-8><title>Status</title><h1>OK</h1>' > /www/index.html
httpd -f -p 127.0.0.1:8081 -h /www &

cat > /etc/xray/config.json <<JSON
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": ${PORT},
    "protocol": "vless",
    "settings": {
      "clients": [{ "id": "${UUID}" }],
      "decryption": "none",
      "fallbacks": [{ "dest": 8081, "xver": 0 }]
    },
    "streamSettings": {
      "network": "ws",
      "security": "none",
      "wsSettings": { "path": "${WS_PATH}" }
    },
    "sniffing": { "enabled": true, "destOverride": ["http", "tls"] }
  }],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "block" }
  ]
}
JSON

exec xray run -c /etc/xray/config.json
