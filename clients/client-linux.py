#!/usr/bin/python
# -*- coding=utf-8 -*-

SERVER = "127.0.0.1"
PORT = 35601
USER = "USER"
PASSWORD = "USER_PASSWORD"
INTERVAL = 1 #更新间隔

import json
import os
import socket
import time
import psutil
import collections
import io

local_path = "/etc/shadowsocks.json"

class Traffic:
    def __init__(self):
        self.recv = collections.deque(maxlen=10)
        self.sent = collections.deque(maxlen=10)
    # 下载速度 上传速度
    def get(self):
        net_io = psutil.net_io_counters()
        self.recv.append(net_io.bytes_recv)
        self.sent.append(net_io.bytes_sent)
        net_recv = 0; net_sent = 0
        l = len(self.recv)
        for x in range(l - 1):
            net_recv += self.recv[x+1] - self.recv[x]
            net_sent += self.sent[x+1] - self.sent[x]
        net_recv = int(net_recv / l / INTERVAL)
        net_sent = int(net_sent / l / INTERVAL)
        return net_recv, net_sent

def netstat(port_list):
    IP_dict = {}
    net_connections = psutil.net_connections()
    for key in net_connections:
        if key.status == "ESTABLISHED":
            if key.laddr[1] in port_list:
                if not IP_dict.has_key(key.laddr.port):
                    IP_dict[key.laddr.port] = set()
                    IP_dict[key.laddr.port].add(key.raddr[0])
                IP_dict[key.laddr.port].add(key.raddr[0])
    return IP_dict

def get_TCP4_num():
    port_list = []
    with open(local_path, 'r+') as f:
        contents = json.load(f)
        for port in contents['port_password']:
            port_list.append(int (port))
        f.close()
    IP_dict =  netstat(port_list)
    return len(IP_dict)

def dataflow():
    # 下载流量,上传流量
    net_io = psutil.net_io_counters()
    return net_io.bytes_recv, net_io.bytes_sent

def get_hdd_info():
    # 硬盘空间总量, 硬盘使用量
    disk = psutil.disk_usage('/')
    return disk.total, disk.used

def get_mem_info():
    # 内存总量, 使用的内存
    virtual_memory = psutil.virtual_memory()
    #print u"内存使用率", virtual_memory.percent
    return virtual_memory.total, virtual_memory.used

def get_swap_info():
    # 交换内存总量, 剩余的交换内存
    swap_memory = psutil.swap_memory()
    return swap_memory.total, swap_memory.free

def ip_status():
    object_check = ['www.10010.com', 'www.189.cn', 'www.10086.cn']
    ip_check = 0
    for ip in object_check:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1)
        try:
            s.connect((ip, 80))
        except:
            ip_check += 1
        s.close()
        del s
    if ip_check >= 2:
        return False
    else:
        return True


def get_load():
    return os.getloadavg()[0]

# 自定义字段
def get_custom_msg():
    file_path = "customMsg.txt"
    if not os.path.exists(file_path):
        open(file_path, 'w').close()  # 文件不存在则创建
    try:
        custom_file = io.open(file_path, "r", encoding="utf-8")  # 用io.open设置encoding来兼容python2和python3
        custom_file.readlines()  # 读取一行测试能否成功，失败则以windows的gbk编码读取
        custom_file.seek(0, 0)  # 重新设置文件读取指针到开头
    except:
        custom_file = io.open(file_path, "r", encoding="gbk")

    result = ""
    for line in custom_file.readlines():  # 依次读取每行
        line = line.strip()  # 去掉每行头尾空白
        if not len(line):  # 判断是否是空行
            continue  # 是的话，跳过不处理
        result += (line + " ")
    custom_file.close()
    return result

def get_network(ip_version):
    HOST = "ipv4.google.com"
    if(ip_version == 6):
        HOST = "ipv6.google.com"
    try:
        s = socket.create_connection((HOST, 80), 2)
        return True
    except:
        pass
    return False

if __name__ == "__main__":
    socket.setdefaulttimeout(30)
    while 1:
        try:
            print("Connecting...")
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((SERVER, PORT))
            data = s.recv(1024)
            if data.find("Authentication required") > -1:
                s.send(USER + ':' + PASSWORD + '\n')
                data = s.recv(1024)
                if data.find("Authentication successful") < 0:
                    print(data)
                    raise socket.error
            else:
                print(data)
                raise socket.error

            data = s.recv(1024)

            timer = 0
            check_ip = 0
            if data.find("IPv4") > -1:
                check_ip = 6
            elif data.find("IPv6") > -1:
                check_ip = 4
            else:
                print(data)
                raise socket.error
            traffic = Traffic()
            traffic.get()
            while 1:

                Net_RECV, Net_SENT = traffic.get()  # 下载速度 上传速度
                DATA_RECV, DATA_SENT = dataflow()  # 下载流量,上传流量
                Uptime = int(time.time() - psutil.boot_time())  # 在线时间
                Load = get_load()  # CPU负载
                Tcp4Num = get_TCP4_num()  # TCP4连接数
                CustomMsg = get_custom_msg()  # 自定义字段
                HDDTotal, HDDUsed = get_hdd_info()  # 硬盘
                MemoryTotal, MemoryUsed = get_mem_info()  # 内存
                SwapTotal, SwapFree = get_swap_info()  # 交换空间
                IP_STATUS = ip_status()  # IP状态
                CPU_PERCENT = psutil.cpu_percent(interval=None, percpu=False)  # CPU使用率

                array = {}
                if not timer:
                    array['online' + str(check_ip)] = get_network(check_ip)
                    timer = 10
                else:
                    timer -= 1 * INTERVAL
                
                array['custom'] = CustomMsg  # 自定义字段
                array['uptime'] = Uptime  # 在线时间
                array['load'] = Load  # 负载
                array['memory_total'] = MemoryTotal  # 内存总量
                array['memory_used'] = MemoryUsed  # 使用的内存
                array['swap_total'] = SwapTotal  # 交换空间
                array['swap_used'] = SwapTotal - SwapFree  # 剩余交换空间
                array['hdd_total'] = HDDTotal  # 硬盘空间总量
                array['hdd_used'] = HDDUsed  # 硬盘使用量
                array['cpu'] = CPU_PERCENT  # CPU使用率
                array['network_rx'] = Net_RECV  # 下载速度
                array['network_tx'] = Net_SENT  # 上传速度
                array['network_in'] = DATA_RECV  # 下载流量
                array['network_out'] = DATA_SENT  # 上传流量
				array['ip_status'] = IP_STATUS  # IP状态
				array['tcp4_num'] = Tcp4Num  # 在线人数
				
                s.send("update " + json.dumps(array) + "\n")
        except KeyboardInterrupt:
            raise
        except socket.error:
            print("Disconnected...")
            # keep on trying after a disconnect
            s.close()
            time.sleep(3)
        except Exception as e:
            print("Caught Exception:", e)
            s.close()
            time.sleep(3)