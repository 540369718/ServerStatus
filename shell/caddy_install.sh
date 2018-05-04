#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#       System Required: Ubuntu
#       Description: Caddy Install
#       Version: 1.0.0
#       Author: Toyo
#=================================================

file="/usr/local/caddy/"
caddy_file="/usr/local/caddy/caddy"
caddy_conf_file="/usr/local/caddy/Caddyfile"
Info_font_prefix="\033[32m" && Error_font_prefix="\033[31m" && Info_background_prefix="\033[42;37m" && Error_background_prefix="\033[41;37m" && Font_suffix="\033[0m"

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
Download_caddy(){
	[[ ! -e ${file} ]] && mkdir "${file}"
	cd "${file}"
	PID=$(ps -ef |grep "caddy" |grep -v "grep" |grep -v "init.d" |grep -v "service" |grep -v "caddy_install" |awk '{print $2}')
	[[ ! -z ${PID} ]] && kill -9 ${PID}	
	wget --no-check-certificate -O "caddy_linux.tar.gz" "https://caddyserver.com/download/linux/amd64?license=personal" && caddy_bit="caddy_linux_amd64"
	[[ ! -e "caddy_linux.tar.gz" ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 下载失败 !" && exit 1
	tar zxf "caddy_linux.tar.gz"
	rm -rf "caddy_linux.tar.gz"
	[[ ! -e ${caddy_file} ]] && echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy 解压失败或压缩文件错误 !" && exit 1
	rm -rf LICENSES.txt
	rm -rf README.txt 
	rm -rf CHANGES.txt
	rm -rf "init/"
	chmod +x caddy
}
Service_caddy(){	
	if ! wget --no-check-certificate https://raw.githubusercontent.com/540369718/ServerStatus-Toyo/master/shell/caddy_debian -O /etc/init.d/caddy; then
		echo -e "${Error_font_prefix}[错误]${Font_suffix} Caddy服务 管理脚本下载失败 !" && exit 1
	fi
	chmod +x /etc/init.d/caddy
	update-rc.d -f caddy defaults
}
install_caddy(){	
	Download_caddy
	Service_caddy
	echo && echo -e " Caddy 配置文件：${caddy_conf_file}
 Caddy 日志文件：/tmp/caddy.log
 使用说明：service caddy start | stop | restart | status
 或者使用：/etc/init.d/caddy start | stop | restart | status
 ${Info_font_prefix}[信息]${Font_suffix} Caddy 安装完成！" && echo
}
Install_Main(){
	check_sys
	if [[ ${bit} != "x86_64" ]] || [[ ${release} != "ubuntu" ]]; then
		echo -e "${Error_font_prefix}[错误]${Font_suffix} 不支持!" && exit 1		
	fi
	install_caddy
}

Install_Main
