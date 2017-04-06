EXT="91.218.212.173"
WEB="192.168.11.9"


# clear all rules
for i in $( iptables -L -n -t nat --line-numbers | grep ^[0-9] | awk '{ print $1 }' | tac )
do
  iptables -t nat -D PREROUTING $i
done


# dpm-web

# ssh
iptables -t nat -A PREROUTING -p tcp -m tcp -d $EXT --dport 122 -j DNAT --to-destination $WEB:122

#iptables -t nat -A POSTROUTING -p tcp -m tcp -s 192.168.1.100 --sport 50111 -j SNAT --to-source 11.11.11.11:50544


# save rules
iptables-save -c

