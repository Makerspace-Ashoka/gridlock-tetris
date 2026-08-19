FROM caddy:2-alpine
COPY deploy/Caddyfile.app /etc/caddy/Caddyfile
COPY index.html /srv/index.html
