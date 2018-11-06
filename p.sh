#!/bin/bash


#apt-get update 
apt install -y build-essential 
apt install -y libevent-dev 
apt install -y libssl-dev
apt install -y git


git clone https://github.com/z3APA3A/3proxy.git
cd 3proxy
ln -s Makefile.Linux Makefile
make
make install


cat <<EOF > /etc/3proxy/conf/3proxy.cfg
nscache 65536
nserver 8.8.8.8
nserver 8.8.4.4
timeouts 1 5 30 60 180 1800 15 60
daemon
config /conf/3proxy.cfg
monitor /conf/3proxy.cfg
log /logs/3proxy-%y%m%d.log D
rotate 60
counter /count/3proxy.3cf
include /conf/counters
include /conf/bandlimiters
auth iponly
allow * 95.141.36.180
allow * 95.27.43.24
allow * 95.141.36.99
proxy -n -p2358 -a

EOF


service 3proxy start
echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
sysctl -p
