#!/bin/bash

apt-get update 
echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
sysctl -p
apt-get install -y squid3 apache2-utils



echo '' > /etc/squid/squid.conf

cat <<EOF > /etc/squid/squid.conf
http_port 2358

dns_nameservers 8.8.8.8 8.8.4.4
positive_dns_ttl 6 hours
negative_dns_ttl 1 minutes

refresh_pattern . 0 100% 0
cache deny all

auth_param basic program /usr/lib/squid/basic_ncsa_auth  /etc/squid/pass
auth_param basic children 5
auth_param basic realm SquidProxy
auth_param basic credentialsttl 1 hour

acl localhost src 127.0.0.1/32
acl ncsa_users proxy_auth REQUIRED


http_access allow all
http_access allow ncsa_users
http_access allow Safe_ports
http_access allow CONNECT SSL_ports
http_access deny all



request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
request_header_access All deny all
via off
forwarded_for off
follow_x_forwarded_for deny all
debug_options ALL,5

EOF

echo 'user1:$apr1$FZeV00GX$avazDffp6clww.2Y5Abn11' > /etc/squid/pass
chmod 775 /etc/squid/pass
/etc/init.d/squid start



