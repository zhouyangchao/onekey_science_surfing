#!/bin/sh

ss=sslocal
proxy=proxychains4

function ss_install()
{
	cd shadowsocks
	python setup.py install
	cd ../
}

function ss_config()
{
	ss_config=$1

	if [ -f ${ss_config} ]; then
		echo "$ss_config is exist."
		return
	fi

	mkdir -p `dirname ${ss_config}`

	echo -n "please input server ip: "
	read server
	echo -n "please input server port: "
	read server_port
	echo -n "please input password: "
	read password
	echo -n "please input method: "
	read method

	cp -f ./ss_config.json $ss_config

	sed -i "s/\"server\":.*$/\"server\":\"${server}\",/g" $ss_config
	sed -i "s/\"server_port\":.*$/\"server_port\":\"${server_port}\",/g" $ss_config
	sed -i "s/\"password\":.*$/\"password\":\"${password}\",/g" $ss_config
	sed -i "s/\"method\":.*$/\"method\":\"${method}\"/g" $ss_config
}

function ss_stop()
{
	pid=`netstat -nlp -t | egrep "1080" | awk '{print $NF}' | awk -F"/" '{print $1}'`
	if [ "X$pid" != "X" ]; then
		echo "kill exist ss pid ${pid}"
		kill -9 ${pid}
	fi
}

function ss_start()
{
	ss_config=$1
	sslocal -d start -c $ss_config --log-file=/var/log/ss.log
}

function proxychain_install()
{
	proxychain_config=$1
	mkdir -p `dirname ${proxychain_config}`
	if [ "X`which ${proxy} 2>/dev/null`" = "X" ]; then
		cd proxychains
		make && make install
		cp -f ./src/proxychains.conf ${proxychain_config}
		cd ../
	fi
}

function proxychain_config()
{
	proxychain_config=$1

	sed -i "s/^sock.*$/socks5 127.0.0.1 1080/" ${proxychain_config}
}

function onekey_status()
{
	netstat -nlp --tcp | egrep "1080"
}

git submodule update --init --remote || exit 1

ss_stop
ss_install 
ss_config /etc/shadowsocks/config.json
ss_start /etc/shadowsocks/config.json

proxychain_install /etc/proxychains.conf
proxychain_config /etc/proxychains.conf

sleep 1
onekey_status
