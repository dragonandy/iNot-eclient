#!/bin/sh
#Created by Jman on 15/11/15.
#Copyright © 2015年 Jman. All rights reserved.

name="18998798120"
passwd="70331351"
# clientip="10.100.243.197"
# mac="20:76:93:3C:6A:D8"
nasip="61.146.20.254"
iswifi="4060"

getIP(){
  clientip=`ifconfig eth2.2|grep inet|awk '{print $2}'|tr -d "addr:"`
	mac=`ifconfig |grep -B1 $clientip|awk '/HWaddr/ { print $5 }'`
}

getData(){
  secret="Eshore!@#"
  timestamp=`date +%s`
  if [[ $1 = "challenge" ]]; then
    #statements
    buffer=$clientip$nasip$mac$timestamp$secret
    echo $buffer
    md5=`echo -n "$buffer"|md5sum|cut -d ' ' -f1| tr '[a-z]' '[A-Z]'`
    data="{\"username\":\"$name\",\"clientip\":\"$clientip\",
    \"nasip\":\"$nasip\",\"mac\":\"$mac\",\"timestamp\":\"$timestamp\",
    \"authenticator\":\"$md5\"}"
    echo $data
  elif [[ $1 = "login" ]]; then
    #statements
    buffer=$clientip$nasip$mac$timestamp$code$secret
    md5=`echo -n "$buffer"|md5sum|cut -d ' ' -f1| tr '[a-z]' '[A-Z]'`
    data="{\"username\":\"$name\",\"password\":\"$passwd\",
    \"clientip\":\"$clientip\",\"nasip\":\"$nasip\",\"mac\":\"$mac\",
    \"timestamp\":\"$timestamp\",\"authenticator\":\"$md5\",
    \"iswifi\":\"$iswifi\"}"
    echo $data
  elif [[ $1 = "logout" ]]; then
    #statements
    buffer=$clientip$nasip$mac$timestamp$secret
  	md5=`echo -n "$buffer"|md5sum|cut -d ' ' -f1| tr '[a-z]' '[A-Z]'`
  	data="{\"clientip\":\"$clientip\",\"nasip\":\"$nasip\",\"mac\":\"$mac\",
    \"secret\":\"$secret\",\"timestamp\":$timestamp,\"authenticator\":\"$md5\"}"
    echo $data
  elif [[ $1 = "keep" ]]; then
    #statements
    buffer=$clientip$nasip$mac$timestamp$secret
  	md5=`echo -n "$buffer"|md5sum|cut -d ' ' -f1| tr '[a-z]' '[A-Z]'`
  	data="username=$name&clientip=$clientip&nasip=$nasip&mac=$mac&""timestamp=$timestamp&authenticator=$md5"
    echo $data
  fi
}

getResponse(){
  challengead="http://enet.10000.gd.cn:10001/client/challenge"
  loginad="http://enet.10000.gd.cn:10001/client/login"
  keepad="http://enet.10000.gd.cn:8001/hbservice/client/active?"
  logoutad="http://enet.10000.gd.cn:10001/client/logout"

  if [[ $1 = "challenge" ]]; then
    response=`wget -O - -q --post-data="$data" "$challengead"` && code=`echo ${response:14:4}`
    echo $response
  elif [[ $1 = "login" ]]; then
    response=`wget -O - -q --post-data="$data" "$loginad"` && rescode=`echo ${response:12:1}`
    echo $response
  elif [[ $1 = "logout" ]]; then
    response=`wget -O - -q --post-data="$data" "$logoutad"`
    echo "$response"
  elif [[ $1 = "keep" ]]; then
    response=`wget -O - -q "$keepad$data"` && keepcode=`echo ${response:12:1}`
  fi

}

Login(){
  while [[ "1" ]]; do
    getIP
    getData keep
    getResponse keep
    if [[ "$keepcode" != "0" ]]; then
      logger -t "iNot-eclient" "$response"
      getData challenge
      getResponse challenge
      if [[ "$code" != "0" ]]; then
        logger -t "iNot-eclient" "$response"
        getData login
        getResponse login
        logger -t "iNot-eclient" "$response"
        sleep 3
      fi
    elif [[ "$keepcode" == "0" ]]; then
      sleep 120
    fi
  done
}

Logout(){
  getData logout
  getResponse logout
  logger -t "iNot-eclient" "$response"
}

case $1 in
  start)
    Login
    ;;
  stop)
    Logout
    ;;
  restart)
    Logout
    sleep 3
    Login
    ;;
  *)
    echo "usge: /tmp/eclient.sh {start|stop|restart}"
    exit 1
    ;;
esac