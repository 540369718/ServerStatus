#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Ubuntu
#	Description: ServerStatus server
#	Version: 1.0.0
#	Author: Toyo
# Server的用法
#	/etc/init.d/status-server start|stop|restart|status
#   tail -f /tmp/serverstatus_server.log
#   修改配置 vim /usr/local/ServerStatus/server/config.json
#   安装路径/usr/local/ServerStatus
#   网页文件/usr/local/ServerStatus/web
# Caddy的用法
#   /etc/init.d/caddy start|stop|restart|status
#   service caddy start|stop|restart|status
#   /usr/local/caddy/Caddyfile
#=================================================

sh_ver="1.0.0"
file="/usr/local/ServerStatus"
jq_file="${file}/jq"
web_file="/usr/local/ServerStatus/web"
server_file="/usr/local/ServerStatus/server"
server_conf="/usr/local/ServerStatus/server/config.json"
server_log_file="/tmp/serverstatus_server.log"
port="35601"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"


#检查系统版本和位数
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
Set_server(){
	echo -e "请输入 ServerStatus 服务端中网站要设置的 域名[server]
默认为本机IP为域名，例如输入: toyoo.ml，如果要使用本机IP，请留空直接回车"
	stty erase '^H' && read -p "(默认: 本机IP):" server_s
	[[ -z "$server_s" ]] && server_s=""			
	echo && echo "	================================================"
	echo -e "	IP/域名[server]: ${Red_background_prefix} ${server_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_server_port(){
	while true
		do
		echo -e "请输入 ServerStatus 服务端中网站要设置的 域名/IP的端口[1-65535]（如果是域名的话，一般建议用 80 端口）"
		stty erase '^H' && read -p "(默认: 8888):" server_port_s
		[[ -z "$server_port_s" ]] && server_port_s="8888"
		expr ${server_port_s} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${server_port_s} -ge 1 ]] && [[ ${server_port_s} -le 65535 ]]; then
				echo && echo "	================================================"
				echo -e "	IP/域名[server]: ${Red_background_prefix} ${server_port_s} ${Font_color_suffix}"
				echo "	================================================" && echo
				break
			else
				echo "输入错误, 请输入正确的端口。"
			fi
		else
			echo "输入错误, 请输入正确的端口。"
		fi
	done
}
Install_caddy(){			
	wget -N --no-check-certificate https://raw.githubusercontent.com/540369718/ServerStatus/master/shell/caddy_install.sh
	chmod +x caddy_install.sh
	bash caddy_install.sh
	[[ ! -e "/usr/local/caddy/caddy" ]] && echo -e "${Error} Caddy安装失败，请手动部署，Web网页文件位置：${Web_file}" && exit 0
	if [[ -s "/usr/local/caddy/Caddyfile" ]]; then
		echo -e "${Info} 发现 Caddy 配置文件非空，开始追加 ServerStatus 网站配置内容到文件最后..."	
	fi	
	cat > "/usr/local/caddy/Caddyfile"<<-EOF
http://${server_s}:${server_port_s} {
root ${web_file}
timeouts none
gzip
}
EOF
	/etc/init.d/caddy restart
}
Download_Server_Status_server(){
	cd "/usr/local"
	wget -N --no-check-certificate "https://github.com/540369718/ServerStatus/archive/master.zip"
	[[ ! -e "master.zip" ]] && echo -e "${Error} ServerStatus 服务端下载失败 !" && exit 1
	unzip master.zip && rm -rf master.zip
	[[ ! -e "ServerStatus-Toyo-master" ]] && echo -e "${Error} ServerStatus 服务端已经存在 !" && rm -rf ServerStatus-Toyo-master
	if [[ ! -e "${file}" ]]; then
		mv ServerStatus-Toyo-master ServerStatus
	else
		mv ServerStatus-Toyo-master/* "${file}"
		rm -rf ServerStatus-Toyo-master
	fi
	[[ ! -e "${server_file}" ]] && echo -e "${Error} ServerStatus 服务端文件夹重命名失败 !" && rm -rf ServerStatus-Toyo-master && exit 1
	cd "${server_file}"
	make
	[[ ! -e "sergate" ]] && echo -e "${Error} ServerStatus 服务端安装失败 !" && exit 1
}
Install_jq(){
	if [[ ! -e ${jq_file} ]]; then
		if [[ ${bit} = "x86_64" ]]; then
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" -O ${jq_file}
		else
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux32" -O ${jq_file}
		fi
		[[ ! -e ${jq_file} ]] && echo -e "${Error} JQ解析器 下载失败，请检查 !" && exit 1
		chmod +x ${jq_file}
		echo -e "${Info} JQ解析器 安装完成，继续..." 
	else
		echo -e "${Info} JQ解析器 已安装，继续..."
	fi
}
Service_Server_Status_server(){	
	if ! wget --no-check-certificate "https://raw.githubusercontent.com/540369718/ServerStatus/master/shell/server_status_server_debian" -O /etc/init.d/status-server; then
		echo -e "${Error} ServerStatus 服务端服务管理脚本下载失败 !" && exit 1
	fi
	chmod +x /etc/init.d/status-server
	update-rc.d -f status-server defaults	
	echo -e "${Info} ServerStatus 服务端服务管理脚本下载完成 !"
}
Write_server_config(){
	cat > ${server_conf}<<-EOF
{"servers":
 [
  {
   "username": "username01",
   "password": "password",
   "name": "Server 01",
   "type": "KVM",
   "host": "MineCloud",
   "location": "RU KHB",
   "disabled": false
  }
 ]
}
EOF
}
Set_iptables(){	
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables	
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
Save_iptables(){
	iptables-save > /etc/iptables.up.rules
}
check_installed_server_status(){
	[[ ! -e "${server_file}" ]] && echo -e "${Error} ServerStatus 服务端没有安装，请检查 !" && exit 1
}
check_pid_server(){
	PID=`ps -ef| grep "sergate"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
Start_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	[[ ! -z ${PID} ]] && echo -e "${Error} ServerStatus 正在运行，请检查 !" && exit 1
	/etc/init.d/status-server start
}
Installation_dependency(){	
	[[ ${release} != "ubuntu" ]] && exit 1
	apt-get update
	apt-get install -y python unzip vim build-essential make	
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
Uninstall_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	[[ ! -z $PID ]] && kill -9 ${PID}
	Del_iptables
	if [[ -e "${client_file}" ]]; then
		mv "${client_file}" "/usr/local/status-client.py"
		rm -rf "${file}"
		mkdir "${file}"
		mv "/usr/local/status-client.py" "${client_file}"
	else
		rm -rf "${file}"
	fi
	rm -rf "/etc/init.d/status-server"
	/etc/init.d/caddy stop
	update-rc.d -f status-server remove
	echo && echo "ServerStatus 卸载完成 !" && echo	
}
Install_ServerStatus_server(){
	[[ -e "${server_file}" ]] && echo -e "${Error} 检测到 ServerStatus 服务端已安装 !" && Uninstall_ServerStatus_server
	Set_server
	Set_server_port
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	Install_caddy
	echo -e "${Info} 开始下载/安装..."
	Download_Server_Status_server
	Install_jq
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_Server_Status_server
	echo -e "${Info} 开始写入 配置文件..."
	Write_server_config
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	port="${server_port_s}"
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_ServerStatus_server
}
List_ServerStatus_server(){
	conf_text=$(${jq_file} '.servers' ${server_conf}|${jq_file} ".[]|.username"|sed 's/\"//g')
	conf_text_total=$(echo -e "${conf_text}"|wc -l)
	[[ ${conf_text_total} = "0" ]] && echo -e "${Error} 没有发现 一个节点配置，请检查 !" && exit 1
	conf_text_total_a=$(expr $conf_text_total - 1)
	conf_list_all=""
	for((integer = 0; integer <= ${conf_text_total_a}; integer++))
	do
		now_text=$(${jq_file} '.servers' ${server_conf}|${jq_file} ".[${integer}]"|sed 's/\"//g;s/,//g'|sed '$d;1d')
		now_text_username=$(echo -e "${now_text}"|grep "username"|awk -F ": " '{print $2}')
		now_text_password=$(echo -e "${now_text}"|grep "password"|awk -F ": " '{print $2}')
		now_text_name=$(echo -e "${now_text}"|grep "name"|grep -v "username"|awk -F ": " '{print $2}')
		now_text_type=$(echo -e "${now_text}"|grep "type"|awk -F ": " '{print $2}')
		now_text_location=$(echo -e "${now_text}"|grep "location"|awk -F ": " '{print $2}')
		now_text_disabled=$(echo -e "${now_text}"|grep "disabled"|awk -F ": " '{print $2}')
		if [[ ${now_text_disabled} == "false" ]]; then
			now_text_disabled_status="${Green_font_prefix}启用${Font_color_suffix}"
		else
			now_text_disabled_status="${Red_font_prefix}禁用${Font_color_suffix}"
		fi
		conf_list_all=${conf_list_all}"用户名: ${Green_font_prefix}"${now_text_username}"${Font_color_suffix} 密码: ${Green_font_prefix}"${now_text_password}"${Font_color_suffix} 节点名: ${Green_font_prefix}"${now_text_name}"${Font_color_suffix} 类型: ${Green_font_prefix}"${now_text_type}"${Font_color_suffix} 位置: ${Green_font_prefix}"${now_text_location}"${Font_color_suffix} 状态: ${Green_font_prefix}"${now_text_disabled_status}"${Font_color_suffix}\n"
	done
	echo && echo -e "节点总数 ${Green_font_prefix}"${conf_text_total}"${Font_color_suffix}"
	echo -e ${conf_list_all}
}
Install_Main(){
	check_sys
	Install_ServerStatus_server
}

Install_Main
