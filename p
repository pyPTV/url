#!/bin/bash

apt-get update 
apt install -y build-essential 
apt install -y libevent-dev 
apt install -y libssl-dev
echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
sysctl -p
apt-get -y install squid3
cat <<EOF > /etc/3proxy/3proxy.cfg
http_port 2358
icp_port  0
cache_mem 256 MB
memory_replacement_policy lru
maximum_object_size_in_memory 512 KB
cache_dir ufs /var/spool/squid3 2048 16 256
cache_replacement_policy lru
minimum_object_size 3 KB
maximum_object_size 10 MB
cache_swap_low 90
cache_swap_high 95
access_log /var/log/squid3/access.log squid
logfile_rotate 12
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .                 0     20%     4320

dns_nameservers 8.8.8.8 8.8.4.4
positive_dns_ttl 6 hours
negative_dns_ttl 1 minutes

auth_param basic program /usr/lib/squid3/basic_ncsa_auth /etc/squid3/password
auth_param basic children 5
auth_param basic realm ServerName
auth_param basic credentialsttl 24 hour

acl password proxy_auth REQUIRED

acl localnet src 10.0.0.0/8     # RFC 1918 possible internal network
acl localnet src 172.16.0.0/12  # RFC 1918 possible internal network
acl localnet src 192.168.0.0/16 # RFC 1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443          # https
acl SSL_ports port 22           # ssh

acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 22          # ssh
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http

acl CONNECT method CONNECT

http_access allow password
http_access allow Safe_ports
http_access allow CONNECT SSL_ports
http_access allow localnet
http_access deny all

request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Cache-Control deny all


EOF

cat <<EOF > /etc/squid3/password
alex:elcpass
user2:pas45rd

EOF
service squid3 start
