# ServerStatus：
* ServerStatus 是ServerStatus-Toyo版的自用修改版。仅支持Ubuntu。

## ServerStatus中文版：   
* ServerStatus中文版(https://github.com/tenyue/ServerStatus) 是一个酷炫高逼格的云探针、云监控、服务器云监控、多服务器探针~。
* 在线演示：https://tz.cloudcpp.com 
## ServerStatus-Toyo： 
* ServerStatus-Toyo版(https://github.com/ToyoDAdoubi/ServerStatus-Toyo) 是一个酷炫高逼格的云探针、云监控、服务器云监控、多服务器探针~，该云监控（云探针）是ServerStatus项目的优化/修改版。
* 在线演示：http://tz.toyoo.ml/

# 目录介绍：
* clients  客户端文件
* server   服务端文件
* shell    安装文件
* web      网站文件  

# 安装教程：     

执行下面的代码下载并运行脚本。

客户端(服务端也要运行客户端才能监控本机)
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/540369718/ServerStatus/master/shell/status_client.sh && chmod +x status_client.sh && bash status_client.sh
```
会要求输入服务端的IP（本机就是默认的127.0.0.1），用户名和密码（与服务端一致即可，不是SSH密码）

服务端
``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/540369718/ServerStatus/master/shell/status_server.sh && chmod +x status_server.sh && bash status_server.sh
```
会要求输入服务器端的IP或域名，以及端口。用于展示网站。

# 客户端手动修改配置
``` bash
vim /usr/local/ServerStatus/status-client.py  //修改SERVER地址，username帐号， password密码
```

# 服务端手动修改配置
``` bash
vim /usr/local/ServerStatus/server/config.json //按照JSON格式即可
/etc/init.d/status-server restart
```     
其中config.json文件的格式如下，注意username, password的值需要和客户端对应一致                 
```
{"servers":
	[
		{
			"username": "s01",
			"password": "some-hard-to-guess-copy-paste-password"
			"name": "Mainserver 1",
			"type": "Dedicated Server",
			"host": "GenericServerHost123",
			"location": "Austria",
			"disabled": false
		},
		{
			"username": "s02",
			"password": "some-hard-to-guess-copy-paste-password"
			"name": "Mainserver 2",
			"type": "Dedicated Server",
			"host": "GenericServerHost123",
			"location": "Austria",
			"disabled": false			
		}
	]
}       
```


# 其他操作

### 客户端：

service status-client start|stop|restart|status

### 服务端：

service status-server start|stop|restart|status


### Caddy（HTTP服务）：

service caddy start|stop|restart|status

Caddy配置文件：/usr/local/caddy/caddy

默认脚本只能一开始安装的时候设置配置文件，更多的Caddy使用方法，可以参考这些教程：https://doub.io/search/caddy

——————————————————————————————————————

安装目录：/usr/local/ServerStatus

网页文件：/usr/local/ServerStatus/web

配置文件：/usr/local/ServerStatus/server/config.json

客户端查看日志：tail -f tmp/serverstatus_client.log

服务端查看日志：tail -f /tmp/serverstatus_server.log

# 其他说明

网络实时流量单位为：G=GB/s，M=MB/s，K=KB/s

服务器总流量单位为：T=TB，G=GB，M=MB，K=KB
