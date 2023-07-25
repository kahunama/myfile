#!/bin/bash
if [ ! -f "xray" ]
then
	curl -L https://github.com/XTLS/Xray-core/releases/download/v1.7.5/Xray-linux-64.zip -o xray.zip
	unzip xray.zip
	chmod +x xray
else
	chmod +x xray
fi
if [ ! -f "mjj" ]
then
	curl -L https://www.baipiao.eu.org/mjj/mjj-linux-amd64 -o mjj
	chmod +x mjj
else
	chmod +x mjj
fi
kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $2}') >/dev/null 2>&1
read -p "请输入连接:" protocol
read -p "请输入本地socks5端口(默认10808):" localport
if [ -z "$localport" ]
then
	localport=10808
fi
if [ $(echo $protocol | awk -F: '{print $1}') == "vless" ]
then
	echo 当前使用vless协议
	id=$(echo $protocol | awk -F:// '{print $2}' | sed -e 's/&/\n/g' | grep ?encryption= | awk -F@ '{print $1}')
	add=$(echo $protocol | awk -F:// '{print $2}' | sed -e 's/&/\n/g' | grep ?encryption= | awk -F@ '{print $2}' | awk -F? '{print $1}' | awk -F: '{print $1}')
	port=$(echo $protocol | awk -F:// '{print $2}' | sed -e 's/&/\n/g' | grep ?encryption= | awk -F@ '{print $2}' | awk -F? '{print $1}' | awk -F: '{print $2}')
	encryption=$(echo $protocol | awk -F:// '{print $2}' | sed -e 's/&/\n/g' | grep ?encryption= | awk -F= '{print $2}')
	scy=$(echo $protocol | awk -F:// '{print $2}' | sed -e 's/&/\n/g' | grep security= | awk -F= '{print $2}')
	type=$(echo $protocol | awk -F:// '{print $2}' | sed -e 's/&/\n/g' | grep type= | awk -F= '{print $2}')
	host=$(echo $protocol | awk -F:// '{print $2}' | sed -e 's/&/\n/g' | grep host= | awk -F= '{print $2}')
	path=$(echo $protocol | awk -F:// '{print $2}' | sed -e 's/&/\n/g' | grep path= | awk -F= '{print $2}' | sed -e 's#%2F#/#g' | sed -e 's#%3F#?#g' | sed -e 's#%3D#=#g' | awk -F# '{print $1}')
	if [ "$scy" == "xtls" ]
	then
		flow=xtls-rprx-origin
	fi
	netSettings=$(echo $type Settings | awk '{print $1$2}')
	tlsSettings=$(echo $scy Settings | awk '{print $1$2}')
	if [ "$scy" == "tls" ] || [ "$scy" == "xtls" ]
	then
cat>config.json<<EOF
{
	"inbounds": [
		{
			"port": $localport,
			"listen": "127.0.0.1",
			"protocol": "socks",
			"settings": {
				"auth": "noauth",
				"udp": true,
				"allowTransparent": false
			}
		}
	],
	"outbounds": [
		{
			"protocol": "vless",
			"settings": {
				"vnext": [
					{
						"address": "$add",
						"port": $port,
						"users": [
							{
								"id": "$id",
								"security": "auto",
								"encryption": "$encryption",
								"flow": "$flow"
							}
						]
					}
				]
			},
			"streamSettings": {
				"network": "$type",
				"security": "$scy",
				"$tlsSettings": {
					"allowInsecure": false,
					"serverName": "$host",
					"fingerprint": ""
				},
				"$netSettings": {
					"path": "$path",
					"headers": {
						"Host": "$host"
					}
				}
			},
			"mux": {
				"enabled": false,
				"concurrency": -1
			}
		}
	]
}
EOF
else
cat>config.json<<EOF
{
	"inbounds": [
		{
			"port": $localport,
			"listen": "127.0.0.1",
			"protocol": "socks",
			"settings": {
				"auth": "noauth",
				"udp": true,
				"allowTransparent": false
			}
		}
	],
	"outbounds": [
		{
			"protocol": "vless",
			"settings": {
				"vnext": [
					{
						"address": "$add",
						"port": $port,
						"users": [
							{
								"id": "$id",
								"security": "auto",
								"encryption": "$encryption",
								"flow": "$flow"
							}
						]
					}
				]
			},
			"streamSettings": {
				"network": "$type",
				"$netSettings": {
					"path": "$path",
					"headers": {
						"Host": "$host"
					}
				}
			},
			"mux": {
				"enabled": false,
				"concurrency": -1
			}
		}
	]
}
EOF
fi
fi
if [ $(echo $protocol | awk -F: '{print $1}') == "vmess" ]
then
	echo 当前使用vmess协议
	add=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"add\": | awk -F\" '{print $4}')
	port=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"port\": | awk -F\" '{print $4}')
	id=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"id\": | awk -F\" '{print $4}')
	aid=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"aid\": | awk -F\" '{print $4}')
	scy=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"scy\": | awk -F\" '{print $4}')
	net=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"net\": | awk -F\" '{print $4}')
	type=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"type\": | awk -F\" '{print $4}')
	host=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"host\": | awk -F\" '{print $4}')
	path=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"path\": | awk -F\" '{print $4}')
	tls=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"tls\": | awk -F\" '{print $4}')
	sni=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"sni\": | awk -F\" '{print $4}')
	alpn=$(echo $protocol | awk -F:// '{print $2}' | base64 -d | sed -e 's/,/\n/g' | grep \"alpn\": | awk -F\" '{print $4}')
	netSettings=$(echo $net Settings | awk '{print $1$2}')
	tlsSettings=$(echo $tls Settings | awk '{print $1$2}')
	if [ "$tls" == "tls" ] || [ "$tls" == "xtls" ]
	then
cat>config.json<<EOF
{
	"inbounds": [
		{
			"port": $localport,
			"listen": "127.0.0.1",
			"protocol": "socks",
			"settings": {
				"auth": "noauth",
				"udp": true,
				"allowTransparent": false
			}
		}
	],
	"outbounds": [
		{
			"protocol": "vmess",
			"settings": {
				"vnext": [
					{
						"address": "$add",
						"port": $port,
						"users": [
							{
								"id": "$id",
								"alterId": $aid,
								"security": "$scy"
							}
						]
					}
				]
			},
			"streamSettings": {
				"network": "$net",
				"security": "$tls",
				"$tlsSettings": {
					"allowInsecure": false,
					"serverName": "$host",
					"fingerprint": ""
				},
				"$netSettings": {
					"path": "$path",
					"headers": {
						"Host": "$host"
					}
				}
			},
			"mux": {
				"enabled": false,
				"concurrency": -1
			}
		}
	]
}
EOF
else
cat>config.json<<EOF
{
	"inbounds": [
		{
			"port": $localport,
			"listen": "127.0.0.1",
			"protocol": "socks",
			"settings": {
				"auth": "noauth",
				"udp": true,
				"allowTransparent": false
			}
		}
	],
	"outbounds": [
		{
			"protocol": "vmess",
			"settings": {
				"vnext": [
					{
						"address": "$add",
						"port": $port,
						"users": [
							{
								"id": "$id",
								"alterId": $aid,
								"security": "$scy"
							}
						]
					}
				]
			},
			"streamSettings": {
				"network": "$net",
				"$netSettings": {
					"path": "$path",
					"headers": {
						"Host": "$host"
					}
				}
			},
			"mux": {
				"enabled": false,
				"concurrency": -1
			}
		}
	]
}
EOF
fi
fi
./xray run>/dev/null 2>&1 &
sleep 2
http_code=$(curl -A "" --retry 2 -x socks5://127.0.0.1:$localport -s https://www.google.com/generate_204 -w %{http_code} --connect-timeout 2 --max-time 3)
if [ "$http_code" != "204" ]
then
	echo 无效地址
	kill -9 $(ps -ef | grep xray | grep -v grep | awk '{print $2}') >/dev/null 2>&1
else
	curl -A "" --retry 2 -x socks5://127.0.0.1:$localport -s https://ipinfo.io --connect-timeout 2 --max-time 3
	./mjj -socks5=127.0.0.1:$localport
fi
