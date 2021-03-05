CONF_PATH=$(pwd)

cat << EOF > $CONF_PATH/nginx/nginx.conf
worker_processes  1;

error_log  $CONF_PATH/nginx/logs/error.log;
error_log  $CONF_PATH/nginx/logs/error.log  notice;
error_log  $CONF_PATH/nginx/logs/error.log  info;

events {
  worker_connections  1024;
}

http {
  include       /usr/local/etc/nginx/mime.types;
  default_type  application/octet-stream;

  sendfile            off;
  tcp_nopush          on;
  tcp_nodelay         off;
  keepalive_timeout   65;

  gzip              on;
  gzip_static       on;
  gzip_http_version 1.0;
  gzip_comp_level   2;
  gzip_proxied      any;

  server_names_hash_bucket_size 128;
  server_names_hash_max_size 20000;

  proxy_headers_hash_bucket_size 128;
  proxy_headers_hash_max_size 20000;

    server {
    listen       80;
    server_name  localhost;

    location / {
      root  $CONF_PATH/nginx/www;
      try_files  $uri  $uri/  /index.html?$args ;
      index  index.html;
    }
  }

  map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
  }

  include /usr/local/etc/nginx/fastcgi.conf;
  include $CONF_PATH/nginx/sites/*.conf;
}
EOF

cat << EOF > $CONF_PATH/nginx/sites/node.conf
upstream node {
  server 127.0.0.1:5000;
  keepalive 64;
}

# proxy_cache_path  /opt/pongstr/config/nginx/cache levels=1:2 keys_zone=one:8m max_size=1000m inactive=600m;
# proxy_temp_path   /opt/pongstr/config/nginx/temp;

server {
  listen                                80;
  listen                                [::]:80;
  server_name                           node.test;
  return                                301 https://$server_name$request_uri;
}

server {
  listen                                443 ssl http2;
  listen                                [::]:443 ssl http2;
  server_name                           node.test;

  ssl_ciphers                           HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
  ssl_protocols                         TLSv1 TLSv1.1 TLSv1.2;
  ssl_session_cache                     builtin:1000  shared:SSL:10m;
  ssl_certificate                       $CONF_PATH/nginx/ssl/node.test.crt;
  ssl_certificate_key                   $CONF_PATH/nginx/ssl/node.test.key;
  ssl_prefer_server_ciphers             on;

  location / {
    proxy_pass                          http://node$request_uri;
    proxy_redirect                      off;
    proxy_set_header                    X-Real-IP $remote_addr;
    proxy_set_header                    X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header                    X-Forwarded-Proto $scheme;
    proxy_set_header                    Host $http_host;
    proxy_set_header                    X-NginX-Proxy true;
    proxy_set_header                    Connection "Upgrade";
    proxy_set_header                    Upgrade $http_upgrade;
    proxy_http_version                  1.1;
    proxy_next_upstream                 error timeout invalid_header http_500 http_502 http_503 http_504;
    proxy_buffering                     off;
    proxy_cookie_path                   / "/; secure; HttpOnly; SameSite=lax";

    # Cache Controls
    # This section sets response expiration which prevents 304 not modified
    expires                             0;
    add_header                          Pragma public;
    add_header                          Cache-Control "public";
    access_log                          off;

    add_header X-XSS-Protection         "1; mode=block";
    add_header X-Frame-Options          "sameorigin";
    add_header X-Content-Type-Options   "nosniff";
    add_header Access-Control-Allow-Origin "*";
  }

  access_log    /opt/pongstr/config/nginx/logs/access.node.log;
  error_log     /opt/pongstr/config/nginx/logs/error.node.log warn;
}
EOF

## Create custom test config
cat << EOF > $CONF_PATH/dnsmasq/dnsmasq.conf
bind-interfaces
keep-in-foreground
no-resolv

address=/dev/127.0.0.1
listen-address=127.0.0.1
EOF
