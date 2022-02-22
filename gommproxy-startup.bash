#!/bin/bash -x
exec 2>/tmp/startup-log
# Set routing tables for go-mmproxy
ip -4 rule add from 127.0.0.1/8 iif lo table 100
ip route add local 0.0.0.0/0 dev lo table 100
# Configure rsyslogd to write iptables messages to /var/log/messages
cp /etc/rsyslog.conf /etc/orig.rsyslog.conf
sed -i 's/\*\.info/kern\.\*\;\*\.info/' /etc/rsyslog.conf
systemctl restart rsyslog
# Only allow mm-proxy to pass through traffic from GCP's Global LB
echo 35.191.0.0/16 > /tmp/gcp-tcp-proxy-ip-range
echo 130.211.0.0/22 >> /tmp/gcp-tcp-proxy-ip-range
# Copy the proxy binary
gsutil cp gs://startup-script-proxy/go-mmproxy /tmp
setcap cap_net_admin+eip /tmp/go-mmproxy
chmod u+x /tmp/go-mmproxy
# Install iperf3 for testing
if ! command -v yum &> /dev/null
then
    dnf install -y iperf3
else
    yum install -y iperf3
fi
# Set iptables rules for logging new connections on the back-end
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -N LOGNEW
iptables -A LOGNEW -j LOG -i lo --log-prefix 'INBOUND_TCP:' --log-level 4
iptables -A LOGNEW -j ACCEPT
iptables -A INPUT -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp -s 35.191.0.0/16 -j ACCEPT # Filters out the health-check messages
iptables -A INPUT -p tcp -s 130.211.0.0/22 -j ACCEPT
iptables -A INPUT -p tcp -j LOGNEW
# Start go-mmproxy
/tmp/go-mmproxy -l 0.0.0.0:110 -4 127.0.0.1:112 --allowed-subnets /tmp/gcp-tcp-proxy-ip-range &
