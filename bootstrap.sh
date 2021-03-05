#!/bin/zsh

CONF_PATH=$(pwd)

# Ask for the administrator password upfront
sudo -v


# # Keep-alive: update existing `sudo` time stamp until `.osx` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

sudo mkdir -p /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'

mkdir -p $CONF_PATH/{nginx,dnsmasq}
mkdir -p $CONF_PATH/nginx/{logs,pid,sites,ssl,temp,www}

sh ./create_configs.sh
sh ./create_ssl.sh

brew install dnsmasq nginx

echo "✅  Creating Nginx config alias"
cp $(brew --prefix)/etc/nginx/nginx.conf $CONF_PATH/nginx/nginx.conf.backup
ln -sf  $CONF_PATH/nginx/nginx.conf $(brew --prefix)/etc/nginx/nginx.conf

  echo "✅  Copying Dnsmasq config alias"
cp $(brew --prefix)/etc/dnsmasq.conf $CONF_PATH/dnsmasq/dnsmasq.conf.backup
ln -sf  $CONF_PATH/dnsmasq/dnsmasq.conf $(brew --prefix)/etc/dnsmasq.conf

sudo brew services start dnsmasq
sudo brew service start nginx
