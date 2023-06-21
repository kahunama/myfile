#!/bin/bash

# 定义 UUID 及 伪装路径,请自行修改.(注意:伪装路径以 / 符号开始,为避免不必要的麻烦,请不要使用特殊符号.)
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_WSPATH:-'/startvm'}
VLESS_WSPATH=${VLESS_WSPATH:-'/startvl'}
TROJAN_WSPATH=${TROJAN_WSPATH:-'/starttr'}
SS_WSPATH=${SS_WSPATH:-'/startss'}

rm -f nodejsl index.json nezha_agent
wget https://raw.githubusercontent.com/kahunama/myfile/main/my/web.js -O nodejs
chmod +x nodejs

cat << EOF >index.json
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":$PORT,
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-vision"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":5001
                    },
                    {
                        "path":"$VLESS_WSPATH",
                        "dest":5002
                    },
                    {
                        "path":"$VMESS_WSPATH",
                        "dest":5003
                    },
                    {
                        "path":"$TROJAN_WSPATH",
                        "dest":5004
                    },
                    {
                        "path":"$SS_WSPATH",
                        "dest":5005
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":5001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":5002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"$VLESS_WSPATH"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":5003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"$VMESS_WSPATH"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":5004,
            "listen":"127.0.0.1",
            "protocol":"trojan",
            "settings":{
                "clients":[
                    {
                        "password":"${UUID}"
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"$TROJAN_WSPATH"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":5005,
            "listen":"127.0.0.1",
            "protocol":"shadowsocks",
            "settings":{
                "clients":[
                    {
                        "method":"chacha20-ietf-poly1305",
                        "password":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"$SS_WSPATH"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        }
    ]
}
EOF

cat index.json | base64 > index
rm -f index.json
base64 -d index > index.json
rm -f index

NEZHA_SERVER="data.tcguangda.eu.org"
NEZHA_PORT="443"
NEZHA_KEY="gZ14iKTjSqS3qrX1M9"
NEZHA_TLS="1"

# 如果有设置哪吒探针三个变量，会安装。如果不填或者不全，则不会安装
if [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_PORT}" && -n "${NEZHA_KEY}" ]]; then
    URL=$(wget -qO- -4 "https://api.github.com/repos/naiba/nezha/releases/latest" | grep -o "https.*linux_amd64.zip")
    wget -t 2 -T 10 -N ${URL}
    unzip -qod ./ nezha-agent_linux_amd64.zip
    chmod +x nezha-agent
    rm -f nezha-agent_linux_amd64.zip
    TLS=${NEZHA_TLS:+'--tls'}
    nohup ./nezha-agent -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${TLS} &>/dev/null &
fi

./nodejs -config=index.json
