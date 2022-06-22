* [目录](#0)
  * [系统安装](#1)
  * [主流raid级别](#2)
  * [LVM基本概念与常见操作](#3)
  * [IP地址的基本常识](#4)
  * [IP地址配置](#5)
  * [sshd服务](#6)
  * [yum的基本使用](#7)
  * [其他常用工具的介绍](#8)
  * [操作系统日志、文件类型和文件权限、用户和组](#9)
  * [shell编写与文本工具](#10)
  

<h3 id="4">IP地址的基本常识</h3>

#### 为网卡配置地址的必要信息是哪些

- IP地址
- 子网掩码
- 网关
- DNS

IP地址:  
词条解释--IP地址是IP协议提供的一种统一的地址格式，它为互联网上的每一个网络和每一台主机分配一个逻辑地址，以此来屏蔽物理地址的差异。  
在实践中, 由于地址转换技术NAT的存在, 通常更多的是局域网地址而非直接的互联网地址.

子网掩码:  
词条解释--子网掩码(subnet mask)又叫网络掩码、地址掩码、子网络遮罩，它用来指明一个IP地址的哪些位标识的是主机所在的子网，以及哪些位标识的是主机的位掩码。子网掩码不能单独存在，它必须结合IP地址一起使用。  
在实践中, 子网掩码如何划分, 通常是管理这个环境的网络岗位的人的工作, 绝大多数情况下, 按照其分配的掩码进行填写即可. 如对这方面内容感兴趣,需要学习初级网络工程师的知识.

网关:  
词条解释--网关(Gateway)又称网间连接器、协议转换器。网关在网络层以上实现网络互连，是复杂的网络互连设备，仅用于两个高层协议不同的网络互连。网关既可以用于广域网互连，也可以用于局域网互连。网关是一种充当转换重任的计算机系统或设备。使用在不同的通信协议、数据格式或语言，甚至体系结构完全不同的两种系统之间，网关是一个翻译器。与网桥只是简单地传达信息不同，网关对收到的信息要重新打包，以适应目的系统的需求。同层--应用层。  
<font color=red>网关不是配置IP地址里的必选项; </font> 在实践中, 通常会有一个默认网关, 但只配IP地址不配置默认网关的情景同样常见.

DNS:
词条解释--域名系统（英文：Domain Name System，缩写：DNS）是互联网的一项服务。它作为将域名和IP地址相互映射的一个分布式数据库，能够使人更方便地访问互联网。DNS使用UDP端口53
。当前，对于每一级域名长度的限制是63个字符，域名总长度则不能超过253个字符。  
<font color=red>DNS不是配置IP地址里的必选项;</font> 负责将域名转换成IP地址(正向解析)和IP地址转换成域名(反向解析),常见更多的是正向解析.

#### 读懂路由表告诉你的信息

无论windows还是linux, 你都可以通过命令行的方式查看系统当前的路由表内容.  
通过其中的内容, 可以得出一些信息, 以及定位一些问题原因.  

在linux上查看系统路由表的命令  

```route -n``` 和 ```netstat -rn``` 两者是等价的

在windows上查看系统路由表的命令  

```route print```

linux示例:

```
[root@docker ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG    101    0        0 ens33
10.0.0.0        0.0.0.0         255.255.255.0   U     100    0        0 ens160
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
192.168.1.0     0.0.0.0         255.255.255.0   U     101    0        0 ens33
[root@docker ~]# netstat -rn
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG        0 0          0 ens33
10.0.0.0        0.0.0.0         255.255.255.0   U         0 0          0 ens160
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 docker0
192.168.1.0     0.0.0.0         255.255.255.0   U         0 0          0 ens33
```

windows示例:

```
C:\Users\Administrator>route print
===========================================================================
接口列表
 11...7c 8a e1 82 a3 9c ......Realtek PCIe GbE Family Controller
  3...02 00 4c 4f 4f 50 ......Microsoft KM-TEST 环回适配器
 15...00 ff 77 45 b1 e1 ......TAP-Windows Adapter V9
  6...76 4c a1 d8 ed 3d ......Microsoft Wi-Fi Direct Virtual Adapter
 21...f6 4c a1 d8 ed 3d ......Microsoft Wi-Fi Direct Virtual Adapter #2
 10...00 50 56 c0 00 03 ......VMware Virtual Ethernet Adapter for VMnet3
 18...74 4c a1 d8 ed 3d ......Realtek RTL8852AE WiFi 6 802.11ax PCIe Adapter
  5...74 4c a1 d8 ed 3e ......Bluetooth Device (Personal Area Network)
  1...........................Software Loopback Interface 1
===========================================================================

IPv4 路由表
===========================================================================
活动路由:
网络目标        网络掩码          网关       接口   跃点数
          0.0.0.0          0.0.0.0     192.168.12.1    192.168.12.39     35
        127.0.0.0        255.0.0.0            在链路上         127.0.0.1    331
        127.0.0.1  255.255.255.255            在链路上         127.0.0.1    331
  127.255.255.255  255.255.255.255            在链路上         127.0.0.1    331
       172.25.0.0      255.255.0.0            在链路上      172.25.250.2    281
     172.25.250.2  255.255.255.255            在链路上      172.25.250.2    281
   172.25.254.199  255.255.255.255            在链路上      172.25.250.2    281
   172.25.255.255  255.255.255.255            在链路上      172.25.250.2    281
      192.168.0.0    255.255.255.0            在链路上      172.25.250.2    281
      192.168.0.2  255.255.255.255            在链路上      172.25.250.2    281
    192.168.0.255  255.255.255.255            在链路上      172.25.250.2    281
     192.168.12.0    255.255.255.0            在链路上     192.168.12.39    291
    192.168.12.39  255.255.255.255            在链路上     192.168.12.39    291
   192.168.12.255  255.255.255.255            在链路上     192.168.12.39    291
     192.168.80.0    255.255.255.0            在链路上      192.168.80.1    291
     192.168.80.1  255.255.255.255            在链路上      192.168.80.1    291
   192.168.80.255  255.255.255.255            在链路上      192.168.80.1    291
        224.0.0.0        240.0.0.0            在链路上         127.0.0.1    331
        224.0.0.0        240.0.0.0            在链路上      192.168.80.1    291
        224.0.0.0        240.0.0.0            在链路上      172.25.250.2    281
        224.0.0.0        240.0.0.0            在链路上     192.168.12.39    291
  255.255.255.255  255.255.255.255            在链路上         127.0.0.1    331
  255.255.255.255  255.255.255.255            在链路上      192.168.80.1    291
  255.255.255.255  255.255.255.255            在链路上      172.25.250.2    281
  255.255.255.255  255.255.255.255            在链路上     192.168.12.39    291
===========================================================================
永久路由:
  无

IPv6 路由表
===========================================================================
活动路由:
 接口跃点数网络目标                网关
  1    331 ::1/128                  在链路上
 10    291 fe80::/64                在链路上
 10    291 fe80::18cf:69a1:ca29:2cd4/128
                                    在链路上
  1    331 ff00::/8                 在链路上
 10    291 ff00::/8                 在链路上
===========================================================================
永久路由:
  无
```

在linux示例中的 ```Destination``` 和windows中的```网络目标``` 是同一个东西.所表示的都是```网络号```  

它们都要结合 子网掩码 才能限定出一个范围, 在linux示例中的 ```Genmask```和和windows中的```网络掩码```

有关 网络号 和 子网掩码 相结合,是如何计算出网络地址范围的, 如不具备相应的理论知识, 也可以通过互联网上大量工具类型的,在线计算的网页帮你计算出你要访问的地址是否在这个网络范围内.

在linux示例中的 ```Gateway``` 和 windows中的```网关``` 则表示访问此网络范围下一跳的地址

有了以上信息,操作系统可以得知,访问一个地址目标, 有哪些链路可选, 但也常见一个地址目标, 有多条路径可选的情况, 此时哪条路径更为优先, 操作系统是如何做出判断的?  
这个问题由 "跳数" 来作回答, 在linux示例中的 ```Metric``` 和 windows中的```跃点数```  
需要注意的是, <font color=red>数字越小, 优先级越高</font>

在linux示例中的 ```iface``` 和 windows中的```接口``` 则表示网络接口, 也就是我们通常所说的网卡, 但网卡不一定只限于物理网卡, 也可能是虚拟的网卡设备.

以上的信息就已构成操作系统在访问一个地址目标时, 做出选路依据的全部要素.

- 只有一条路由(路径)满足时, 选择唯一的选择;
- 有多条路由(路径)满足时, 选择优先级最高的;
- 默认网关的作用就是, 当访问的目标地址不在路由表列出时, 则通过默认网关出发.
- 操作系统事实上的默认网关只有一个, 但你可能在路由表内看见多条默认网关的路由, 这并不意味着操作系统可以有多个默认网关, 因为它们的优先级高低一定有区别.
- 默认网关是什么形式? 网络号为 0.0.0.0 子网掩码 也为0.0.0.0 那一条(或多条)

<h3 id="5">IP地址配置</h3>

在本节内容介绍linux操作系统上配置 IP地址的两种方式  

- 直接编辑配置文件
- nmcli 命令行

首先应明确这两种方式的应用范围.  
- 直接编辑配置文件:   
  红帽系( RHEL 4, RHEL 5, RHEL 6 ) , 以及衍生的CentOS Oracle-Linux  
  SuSE( SuSE 10, SuSE 11 )  
- nmcli 命令行
  红帽系( RHEL 7及以后 )  
  SuSE 15 (需确认)

有关 RHEL 6以及SuSE 通过修改network-scripts 下的文件进行IP地址配置的操作方法,互联网上已足够丰富,不在此赘述.

nmcli 命令行的使用方法  
红帽的官方文档应是一个很好的起点  

https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/networking_guide/sec-using_the_networkmanager_command_line_tool_nmcli

以及其他一些文档

https://blog.51cto.com/cstsncv/2049474  
https://www.jianshu.com/p/3dd5e4ca4b7d  

如以上资料仍不足以满足需要, 善用谷歌等搜索引擎

需要掌握的技能目标: 在提供网络信息的前提下, 进行配置并验证其连通性.

<h3 id="6">sshd服务</h3>

#### 基本概念:

> SSH（Secure Shell）建立在应用层和传输层基础上的安全协议。它使用加密验证来确认用户身份，并对两台主机之间的所有通信加密。

> SSH主要的组件有：一个服务器守护进程sshd，一个用于远程登录的ssh，还有用户主机之间复制文件的 sftp/scp。SSH其它组件：生成公钥对的 ssh-keygen 命令。

#### 服务安装

openssh 和 openssl 软件包是红帽Linux(RHEL) 及其衍生的CentOS, Oracle Linux  
以及SuSE, Ubuntu等发行厂商都会预置的软件包.    
自操作系统安装初始化以来, 即使是选择最小化安装的情形, 就已被安装, 是rpm包的形式.  
客户可能出于安全漏洞的关系,  对openssh / openssl 有版本升级的需求, 具体升级的操作细节属于操作系统工程师的技能范畴,非系统工程师可以不要求掌握.  


#### 配置文件

以红帽RHEL或是CentOS发行版为例:  
系统安装时是由rpm包安装的 openssh和openssl, openssh的配置文件的默认位置为  
/etc/ssh/sshd_config  
需要注意的是, 与之文件名称相近的还有  
/etc/ssh/ssh_config  
需要分清这两者的区别:  
服务端: /etc/ssh/sshd_config  
客户端: /etc/ssh/ssh_config  
同时要分清楚在 ssh 里服务端与客户端的角色关系  
现假设有 A和B 两台主机, 现在A要通过ssh 连接到B主机上, 那么在这个网络连接里  
A 是ssh客户端, B 是ssh服务端  
连接方向对换一下, 则它们的角色关系也随之互换.  
同时, 还需要了解, 服务端的执行程序是 sshd, 而客户端是 ssh, 两者的执行程序也不同.  
因此, 如果需要查看 openssh 的版本时, 你需要知晓以下两条命令的区别  

```
ssh -V
sshd -V
```

服务端的sshd的配置文件有几个基本配置项, 即使非系统工程师, 作为常识也应有所了解.  
在 /etc/ssh/sshd_config 中的

```
sshd 监听端口号, 初始化是注释状态, 即使注释状态也有默认值是22
#Port 22

sshd 监听的IP地址, 初始化是注释状态, 即使注释状态也有默认值是0.0.0.0, 即该主机上的所有网络接口地址
#ListenAddress 0.0.0.0

root用户是否允许通过ssh登录, 当此项为no时, 即使输入正确的root口令, 也是提示不正确
PermitRootLogin yes

ssh 是否启用dns解析, 登录验证过程会更慢, 因此作为标准配置, 我们使用的是禁用状态, 即no
需要显式配置为no, 不可因为注释项, 就认为该值一定生效, 因为软件版本的变化, 导致默认值可能会变化
#UseDNS no
```


<h3 id="7">yum的基本使用</h3>

#### repo 文件的建立

yum 命令寻找软件包, 通过它的repo 文件所定义的, 我们所谓的"源"来进行匹配.  
由于yum 会建立自身的数据索引, 所以可以从中查询是否有匹配的软件包.  
在红帽发行版中, yum的repo文件位于 /etc/yum.repos.d/ 下  
一个 repo 文件的基本格式如下  

```
[RHEL]
name=RHEL6.4
baseurl=file:///mnt/cdrom 
gpgcheck=0
enabled=1
```

以上语句是一个repo最基本的要素
- 第1行 ```[RHEL]``` 是yum源 的显示名称 
- 第2行 ```name=RHEL6.4``` 是yum源 的别名 
- 第3行 ```baseurl=file:///mnt/cdrom ``` 是yum源 的别名 
- 第2行 ```name=RHEL6.4``` 是yum源 的别名 
- 第2行 ```name=RHEL6.4``` 是yum源 的别名 

#### 我只知道命令, 但我不知道这个命令由哪个软件包提供

需要记住以下 yum 的两个参数

```
yum provides
yum whatprovides
```

这两个参数实现的结果都是查询命令由哪个软件包提供, 示例如下:

```
[root@docker ~]# yum provides iostat
Loaded plugins: fastestmirror, langpacks, priorities
Loading mirror speeds from cached hostfile
sysstat-10.1.5-19.el7.x86_64 : Collection of performance monitoring tools for Linux
Repo        : base
Matched from:
Filename    : /usr/bin/iostat



sysstat-10.1.5-19.el7.x86_64 : Collection of performance monitoring tools for Linux
Repo        : @base
Matched from:
Filename    : /bin/iostat



sysstat-10.1.5-19.el7.x86_64 : Collection of performance monitoring tools for Linux
Repo        : @base
Matched from:
Filename    : /usr/bin/iostat
```

它会从yum 的数据库中去查询是否有相匹配的结果.  
但并非每一个红帽发行版, 或者有安装yum 命令的操作系统都一定可以使用这参数.  
该功能由yum 的插件(plugins)提供, 可能会存在由于未安装无法使用的情况.

<h3 id="8">其他常用工具的介绍</h3>
netstat
route
traceroute
iostat
vmstat
sar


<h3 id="9">操作系统日志、文件类型和文件权限、用户和组</h3>

#### 操作系统日志

红帽, SuSE 都位于 /var/log 目录下, 是操作系统相关的日志约定俗成的存放位置.  

其中  
- ```/var/log/messages``` 记录了系统多种事务日志, 这是首要查看的重点  
- ```/var/log/secure```  红帽将系统sshd服务的登录日志记录在此处, SuSE将此类日志放在 /var/log/messages 中
- ```/var/log/cron```  红帽将计划任务 crond 的执行记录 记录在此处
- ```/var/log/dmesg``` 操作系统启动的事件记录,非系统工程师了解即可,不作要求

#### 文件类型和文件权限、用户和组

不作介绍, 如不具备相应知识, 自行查阅资料.  
无论中间件还是数据库技术方向, 此两项作为基本常识在自己的工作也是必然要打交道的对象.


<h3 id="10">shell编写与文本工具</h3>

在本节内不会详尽的介绍shell的各个细节, 网络上的入门类教程已经足够丰富  
只重点简要介绍shell 脚本的两个核心: 循环, 分支(判断)的基本概念

#### 循环的基本格式

for 循环

```
for 变量 in 集合
do
    执行动作
done
```

while 循环

```
集合 | while read 变量
do
    执行动作
done
```

以上2个示例, 是shell 循环的基本格式, 不难发现, 循环体的基本格式是在 ```do...done```  
如果对以上示例表达的含义不够理解, 网上也有足够多的例子帮助你理解.  

#### 分支 / 判断

if 判断

```
# 单分支
if 条件表达式;then
    执行动作
fi

# 两个分支
if 条件表达式;then
    执行动作
else
    执行动作
fi

# 多分支
if 条件表达式;then
    执行动作
elif 条件表达式;then
    执行动作
else
    执行动作
fi
```

其中多分支中, elif 可以扩展无限多个  

case in 语句的分支

```
case $num in
    1)
        echo "Monday"
        ;;
    2)
        echo "Tuesday"
        ;;
    3)
        echo "Wednesday"
        ;;
    4)
        echo "Thursday"
        ;;
    5)
        echo "Friday"
        ;;
    6)
        echo "Saturday"
        ;;
    7)
        echo "Sunday"
        ;;
    *)
        echo "error"
esac
```

由以上两种分支可以看出, shell 在分支结构中的特点就是以回文的形式作为分支结构体的结束符  
case in 语句就以 esac 结束  
if 语句就以 fi 结束  
作为基本语法, 需要牢记, 否则执行报错.

#### 思考

现假设有情景如下所示:

```
[root@docker ~]# ls
AliDDNSv3_scheduler.sh              git_sync.sh                                  openssh-8.8p1                           shrink.sh                            zabbix-agent.sysv.j2
AliDDNSv3.sh                        hardware_performance_benchmark.sh            openssh-8.8p1.tar.gz                    test.sh                              zabbix-server-mysql:6.0.3.tar
anaconda-ks.cfg                     home                                         openssh_ssl_upgrade_no_interatctive.sh  test.sh~                             zabbix-server-mysql-rebuild:6.0.3.tar
current_containers.txt              kernel-devel-3.10.0-1062.9.1.el7.x86_64.rpm  openssl-1.1.1l                          ui.zip                               zabbix-web-nginx-mysql:6.0.3.tar
denyhosts-3.0                       Linux_routing_inspection                     openssl-1.1.1l.tar.gz                   wait_to_delete
denyhosts-3.0_for_RHEL7_install.sh  list.txt                                     privoxy-3.0.33-stable-src.tar.gz        zabbix-agent-5.4.9-1.el6.x86_64.rpm
denyhosts-3.0.tar.gz                mysql80-community-release-el7-4.noarch.rpm   repair_chinese_filename_error.sh        zabbix-agent-5.4.9-1.el7.x86_64.rpm
docker_mysql_data_bak_del           nginx_install                                rsync_to_new_docker.log                 zabbix-agent.systemctl.j2
```

ls 命令(不加参数的情况下)显示了当前路径下的文件名称.  
文件具体名称不是考察重点, 在自己的练习环境中不需要完全一致.  
有以下两个问题可以作为自行练习的内容, 在遇到类似要求时, 应如何解决
- 将以上文件的数量统计出来, 不借助其他命令--考察循环的使用, 用循环遍历每个文件名, 并计数.
- 将以上文件名中包含 .sh 的, 筛选显示出来--考察判断的使用
