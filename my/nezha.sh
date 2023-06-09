#!/usr/bin/env bash

# 哪吒的4个参数
NEZHA_SERVER="data.tcguangda.eu.org"
NEZHA_PORT="443"
NEZHA_KEY="kiuxKLni6UKP48KU7O"
NEZHA_TLS="1"

# 检测是否已运行
check_run() {
  [[ $(pgrep -laf nezha-agent) ]] && echo "哪吒客户端正在运行中!" && exit
}

# 运行客户端
run() {
  TLS=${NEZHA_TLS:+'--tls'}
  [[ ! $PROCESS =~ nezha-agent && -e nezha-agent ]] && ./nezha-agent -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${TLS} --disable-auto-update 2>&1 &
}

check_run
run
wait

