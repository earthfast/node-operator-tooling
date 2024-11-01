#!/bin/sh
set -e

# Validate SERVER_NAME
if [ -z "$SERVER_NAME" ]; then
    echo "Error: SERVER_NAME environment variable is required"
    exit 1
fi

# Clean server name
CLEAN_NAME=$(echo "$SERVER_NAME" | sed 's/\/\+$//')
echo "Using server name: $CLEAN_NAME"

# Create nginx config
cat >/etc/nginx/conf.d/default.conf <<EOF
server_names_hash_bucket_size 128;

server {
    listen 80;
    listen [::]:80;
    server_name $CLEAN_NAME;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
EOF

if [ "$SETUP_SSL" = "true" ]; then
    cat >>/etc/nginx/conf.d/default.conf <<'EOF'
    location / {
        return 301 https://$host$request_uri;
    }
}
EOF

    if [ -f "/etc/letsencrypt/live/$CLEAN_NAME/fullchain.pem" ]; then
        cat >>/etc/nginx/conf.d/default.conf <<EOF
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $CLEAN_NAME;

    ssl_certificate /etc/letsencrypt/live/$CLEAN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$CLEAN_NAME/privkey.pem;

    location / {
        proxy_pass http://content-node:5000;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header Host \$http_host;
    }
}
EOF
    fi
else
    cat >>/etc/nginx/conf.d/default.conf <<'EOF'
    location / {
        proxy_pass http://content-node:5000;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Host $http_host;
    }
}
EOF
fi

echo "Generated nginx configuration:"
cat /etc/nginx/conf.d/default.conf
