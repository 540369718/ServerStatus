#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Ubuntu
#	Description: ServerStatus client
#	Version: 1.0.0
#	Author: Toyo
# Client的用法
#	/etc/init.d/status-client start|stop|restart|status
#   tail -f tmp/serverstatus_client.log
#   安装路径/usr/local/ServerStatus
#   修改信息 vim /usr/local/ServerStatus/status-client.py,修改SERVER,USER,PASSWORD三个字段，与服务器端一致
#=================================================

sh_ver="1.0.0"
file="/usr/local/ServerStatus"
jq_file="${file}/jq"
web_file="/usr/local/ServerStatus/web"
client_file="/usr/local/ServerStatus/status-client.py"
client_log_file="/tmp/serverstatus_client.log"
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
Set_client(){
	echo -e "请输入 ServerStatus 服务端的 IP/域名[server]"
	stty erase '^H' && read -p "(默认: 127.0.0.1):" server_s
	[[ -z "$server_s" ]] && server_s="127.0.0.1"	
	echo && echo "	================================================"
	echo -e "	IP/域名[server]: ${Red_background_prefix} ${server_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_username(){
	echo -e "请输入 ServerStatus 服务端中对应配置的用户名[username]（字母/数字，不可与其他账号重复）"
	stty erase '^H' && read -p "(默认: 取消):" username_s
	[[ -z "$username_s" ]] && echo "已取消..." && exit 0
	echo && echo "	================================================"
	echo -e "	账号[username]: ${Red_background_prefix} ${username_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_password(){
	echo -e "请输入 ServerStatus 服务端中对应配置的密码[password]（字母/数字）"
	stty erase '^H' && read -p "(默认: doub.io):" password_s
	[[ -z "$password_s" ]] && password_s="doub.io"
	echo && echo "	================================================"
	echo -e "	密码[password]: ${Red_background_prefix} ${password_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_config_client(){
	Set_client
	Set_username
	Set_password
}
Installation_dependency(){
	apt-get update
	apt-get install -y python vim python-pip python-dev
	sudo python -m pip install --upgrade pip
	hash -r
	sudo python -m pip install pstuil
}
Download_Server_Status_client(){
	cd "/usr/local"
	[[ ! -e ${file} ]] && mkdir "${file}"
	cd "${file}"
	[[ -e "client-linux.py" ]] rm -rf client-linux.py
	[[ -e "status-client.py" ]] rm -rf status-client.py
	wget -N --no-check-certificate "https://raw.githubusercontent.com/540369718/ServerStatus/master/clients/client-linux.py"
	[[ ! -e "client-linux.py" ]] && echo -e "${Error} ServerStatus 客户端下载失败 !" && exit 1
	mv client-linux.py status-client.py
	[[ ! -e "status-client.py" ]] && echo -e "${Error} ServerStatus 服务端文件夹重命名失败 !" && rm -rf client-linux.py && exit 1
}
Service_Server_Status_client(){	
	if ! wget --no-check-certificate "https://raw.githubusercontent.com/540369718/ServerStatus/master/shell/server_status_client_debian" -O /etc/init.d/status-client; then
		echo -e "${Error} ServerStatus 客户端服务管理脚本下载失败 !" && exit 1
	fi
	chmod +x /etc/init.d/status-client
	update-rc.d -f status-client defaults	
	echo -e "${Info} ServerStatus 客户端服务管理脚本下载完成 !"
}
Read_config_client(){
	[[ ! -e ${client_file} ]] && echo -e "${Error} ServerStatus 客户端文件不存在 !" && exit 1
	client_text="$(cat "${client_file}"|sed 's/\"//g;s/,//g;s/ //g')"
	client_server="$(echo -e "${client_text}"|grep "SERVER="|awk -F "=" '{print $2}')"
	client_port="$(echo -e "${client_text}"|grep "PORT="|awk -F "=" '{print $2}')"
	client_user="$(echo -e "${client_text}"|grep "USER="|awk -F "=" '{print $2}')"
	client_password="$(echo -e "${client_text}"|grep "PASSWORD="|awk -F "=" '{print $2}')"
}
Modify_config_client(){
	sed -i 's/SERVER = "'"${client_server}"'"/SERVER = "'"${server_s}"'"/g' ${client_file}
	sed -i 's/USER = "'"${client_user}"'"/USER = "'"${username_s}"'"/g' ${client_file}
	sed -i 's/PASSWORD = "'"${client_password}"'"/PASSWORD = "'"${password_s}"'"/g' ${client_file}
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
check_installed_client_status(){
	[[ ! -e "${client_file}" ]] && echo -e "${Error} ServerStatus 客户端没有安装，请检查 !" && exit 1
}
check_pid_client(){
	PID=`ps -ef| grep "status-client.py"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
Start_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ ! -z ${PID} ]] && echo -e "${Error} ServerStatus 正在运行，请检查 !" && exit 1
	/etc/init.d/status-client start
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
Uninstall_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ ! -z $PID ]] && kill -9 ${PID}
	Del_iptables
	if [[ -e "${client_file}" ]]; then
		rm -rf ${client_file}
	else
		rm -rf ${file}
	fi
	rm -rf /etc/init.d/status-client
	update-rc.d -f status-client remove
	echo && echo "ServerStatus 卸载完成 !" && echo
}
Install_ServerStatus_client(){
	[[ -e ${client_file} ]] && echo -e "${Error} 检测到 ServerStatus 客户端已安装 !" && Uninstall_ServerStatus_client
	echo -e "${Info} 开始设置 用户配置..."
	Set_config_client
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装..."
	Download_Server_Status_client
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_Server_Status_client
	echo -e "${Info} 开始写入 配置..."
	Read_config_client
	Modify_config_client
	echo -e "${Info} 开始设置 iptables防火墙..."
	Set_iptables
	echo -e "${Info} 开始添加 iptables防火墙规则..."
	Add_iptables
	echo -e "${Info} 开始保存 iptables防火墙规则..."
	Save_iptables
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_ServerStatus_client
}
Install_Main(){
	check_sys
	Install_ServerStatus_client
}

Install_Main
