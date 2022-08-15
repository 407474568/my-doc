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

在本节中简要介绍以下命令的常用场景
- netstat
- traceroute
- iostat
- vmstat
- sar

 
#### netstat  
由 net-tools 软件包提供, 通常用于查找 网络会话的地址以及端口  
例如, 现在需要查找该主机上监听22端口的程序是哪一个.

```
[root@5950X-node1 ~]# netstat -anpo | grep :22
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1258/sshd            off (0.00/0/0)
tcp        0     36 192.168.1.103:22        192.168.1.100:13774     ESTABLISHED 2663/sshd: root [pr  on (0.22/0/0)
tcp6       0      0 :::22                   :::*                    LISTEN      1258/sshd            off (0.00/0/0)
```

这一示例中,  netstat 命令用到了 ```-anpo``` 参数, 其含义分别如下:  
-a 表示显示所有协议,即 TCP 和 UDP 都显示, 如果你清楚的知道你查找的是 TCP, 则可以用 -t , UDP则用 -u  
-n 表示不将地址转换为主机名, 不加的话, 显示的不是IP地址而是主机名  
-p 表示显示出程序名称及其PID, 这对于定位是哪一个程序时有用  
-o 显示计时器的计时信息, 这对于查看具体某个会话时有用, 得知其已持续的时间  

显示结果的含义  
第1列 示例中的``tcp`` 列,表示协议, tcp 还是 udp, tcp6 表示ipv6协议  
第2,3列 示例中的 两个0 或者 36 的列, 分别表示接受队列长度和发送队列长度, 不需要死记硬背, 有需要时用 ```netstat -anpo | head``` 查看表头  
第4列 IP地址表示源端地址```Local Address```
第5列 IP地址表示目标端地址```Foreign Address```
第6列 表示会话状态, 除了示例中的 ```LISTEN``` ```ESTABLISHED``` 还有其他状态  
第7列 程序PID及名称, 示例中的 ```1258/sshd```
第8列 计时器信息

通过以上, 可以得知, 监听22端口(LISTEN) 的程序为 sshd, PID为 1258

netstat 表头示例

```
[root@5950X-node1 ~]# netstat -anpo | head
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name     Timer
```

反之, 现在只知道一个程序, 希望得知它在监听哪个端口, 如何查找?  
以```nginx```为例  
先通过 ps 命令查找到 nginx 程序的进程PID

```
[root@docker ~]# ps axu | grep nginx
root       1590  0.0  0.0  23904   916 ?        Ss   Jun12   0:00 nginx: master process /usr/local/nginx/sbin/nginx
nginx      1591  0.0  0.1  53140 28824 ?        S    Jun12   0:00 nginx: worker process
nginx      1592  0.0  0.1  53140 28848 ?        S    Jun12   0:00 nginx: worker process
nginx      1593  0.0  0.1  53140 28848 ?        S    Jun12   0:00 nginx: worker process
...
zabbix     3755  0.0  0.0   8064   124 pts/0    S    Jun12   0:00 nginx: worker process
root      45196  0.0  0.0 112816   964 pts/0    S+   16:34   0:00 grep --color nginx
```

由于 nginx 的master 才是主进程, 因此, PID为第一行的 1590

得知 PID 后, 再通过 netstat 查找这个PID  
粗略的匹配, 使用 grep 即可, 更精细的匹配需要使用 awk  

```
[root@docker ~]# netstat -anpo | grep 1590
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      1590/nginx: master   off (0.00/0/0)
tcp        0      0 0.0.0.0:1021            0.0.0.0:*               LISTEN      1590/nginx: master   off (0.00/0/0)
```

由以上示例输出可以得知, PID 为 1590 的```nginx master```进程, 同时在监听 80 和 1521 端口.  
需要注意的是, 在本示例中, grep 的关键字为 ```1590```, 在此条件下, 每一个包含 ``1590`` 的行都会被显示, 意味着你自行需要分辨, 该行的内容是否你在查找的目标.

#### traceroute

通常是系统工程师和网络工程师在排查网络问题时会用到, 不要求过多掌握, 记住基本用法即可, 在某些场景下需要非系统或网络工程师提供此信息.  

linux上的命令格式  
```traceroute 目标地址```

示例

```
[root@docker ~]# traceroute 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  gateway (192.168.1.1)  0.436 ms  0.566 ms  0.627 ms
 2  192.168.10.1 (192.168.10.1)  1.799 ms  1.852 ms  2.073 ms
 3  1.28.209.222.broad.cd.sc.dynamic.163data.com.cn (222.209.28.1)  24.354 ms  24.196 ms  24.511 ms
 4  118.112.215.1 (118.112.215.1)  24.910 ms 220.167.86.237 (220.167.86.237)  25.234 ms 49.133.210.222.broad.cd.sc.dynamic.163data.com.cn (222.210.133.49)  24.636 ms
 5  61.139.121.21 (61.139.121.21)  25.029 ms 171.208.196.9 (171.208.196.9)  30.087 ms 61.139.121.65 (61.139.121.65)  30.314 ms
 6  202.97.29.33 (202.97.29.33)  58.158 ms 202.97.29.29 (202.97.29.29)  32.396 ms 202.97.29.25 (202.97.29.25)  31.784 ms
 7  202.97.91.22 (202.97.91.22)  54.529 ms 202.97.82.58 (202.97.82.58)  37.477 ms  43.043 ms
 8  202.97.12.37 (202.97.12.37)  42.052 ms 202.97.94.94 (202.97.94.94)  52.236 ms 202.97.38.93 (202.97.38.93)  46.807 ms
 9  202.97.95.170 (202.97.95.170)  51.416 ms 202.97.17.54 (202.97.17.54)  95.838 ms 202.97.95.170 (202.97.95.170)  57.094 ms
10  72.14.194.140 (72.14.194.140)  61.285 ms  61.502 ms 72.14.211.144 (72.14.211.144)  111.627 ms
11  108.170.240.225 (108.170.240.225)  101.636 ms 108.170.241.97 (108.170.241.97)  59.360 ms 108.170.241.65 (108.170.241.65)  46.738 ms
12  72.14.232.107 (72.14.232.107)  84.290 ms  88.720 ms 172.253.72.151 (172.253.72.151)  47.488 ms
13  dns.google (8.8.8.8)  42.790 ms  48.836 ms  50.953 ms
```

#### iostat, vmstat, sar

iostat 和 sar 由 sysstat 软件包提供  
vmstat 由 procps-ng 软件包提供  

#### iostat
用于监控主机上磁盘(块设备)的使用情况, 读 / 写 请求数,队列长度,带宽(吞吐量)  

```
[root@docker ~]# iostat -x -m 1 1
Linux 3.10.0-1160.45.1.el7.x86_64 (docker) 	06/23/2022 	_x86_64_	(8 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           2.32    0.00    0.85    0.54    0.00   96.28

Device:         rrqm/s   wrqm/s     r/s     w/s    rMB/s    wMB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
sdb               0.01     0.02   29.32   65.66     3.38     1.22    99.19     0.08    0.83    1.30    0.62   0.51   4.87
sda               0.00    52.33    2.52   70.47     0.21     0.50    19.75     0.01    0.18    0.97    0.16   0.16   1.20
sdc               0.23     0.27    0.81    0.24     0.00     0.00    11.80     0.00    0.38    0.29    0.66   0.35   0.04
dm-0              0.00     0.00   31.85  188.49     3.59     1.72    49.30     0.10    0.46    1.27    0.33   0.27   5.90
dm-1              0.00     0.00    1.04    0.51     0.00     0.00     8.00     0.00    0.52    0.31    0.97   0.24   0.04
```

其中 -x 的含义是显示扩展列, 不加的情况, 会只显示更少的列.  
-m 是表示采集间隔, 其后接2个数字  
第1个数字表示采样间隔, 单位为秒  
第2个数字表示采样次数.  
如果只有一个数字, 则表示按间隔进行采样不终止, 除非用户按下 ```ctrl+c```

#### sar

sar 是一个监控主机操作系统上的全局资源使用情况的工具.  
包括 CPU, 内存, 磁盘, 网络接口 都会被统计在内.  
与iostat, vmstat 之类不同的在于, sar 主要反应的是一个更长时间周期内的资源使用情况的变化.  
而它的优势在于, 它会按照一个固定采样频率生成报告记录, 而不是实时状态.  这对于没有一个更专业的监控平台的情况下, 也能对系统资源的情况, 提供一定的分析依据.  
需要的注意是, 这里的资源使用情况, 都是系统全局的, 而无法细分到具体某个进程.    
以红帽发行版为例而言, sar 的默认采样间隔为10分钟为一个周期.  
它的记录的默认位置位于 ```/var/log/sa``` 目录下

- sar -b 磁盘IO相关, 指标不同, 侧重物理设备
- sar -d 磁盘IO相关, 块设备, 指标不同, 侧重逻辑设备
- sar -B 内存相关,内存页的统计数据
- sar -r 内存相关,内存使用情况的统计数据
- sar -C CPU相关
- sar -n DEV 网络接口相关, ```sar -n``` 后接的关键字, 除了```DEV```, 还有其他类型选择, man 有提示

#### vmstat

vmstat 是一个命令实现了 主机系统资源包括 swap空间, 内存, CPU 的粗略统计情况.  
关于它显示的每个字段的含义, 网上查看资料即可.  
不建议将此命令作为你<font color=red>唯一</font>的分析判断的依据.


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
无论中间件还是数据库技术方向, 此两项作为基本常识在自己的工作也是频繁使用的.


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
