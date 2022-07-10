#### nmcli 方式下的静态路由

https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/configuring-static-routes_configuring-and-managing-networking

https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/configuring-a-static-route-using-an-nmcli-command_configuring-static-routes

要添加一个路由：

```
$ nmcli connection modify connection_name +ipv4.routes "..."
```

同样，要删除一个特定的路由：

```
$ nmcli connection modify connection_name -ipv4.routes "..."
```

红帽的示例:

```
$ sudo nmcli connection modify example +ipv4.routes "192.0.2.0/24 198.51.100.1"
```

我的示例:

```
[root@ansible ~]# nmcli con modify to_3700x +ipv4.routes "172.16.0.6/32 172.16.0.18"
[root@ansible ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG    100    0        0 ens160
10.0.0.0        0.0.0.0         255.255.255.0   U     101    0        0 ens192
172.16.0.0      0.0.0.0         255.255.255.0   U     102    0        0 ens224
172.16.0.0      0.0.0.0         255.255.255.0   U     103    0        0 ens256
192.168.1.0     0.0.0.0         255.255.255.0   U     100    0        0 ens160
[root@ansible ~]# nmcli con up to_3700x 
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/11)
[root@ansible ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG    100    0        0 ens160
10.0.0.0        0.0.0.0         255.255.255.0   U     101    0        0 ens192
172.16.0.0      0.0.0.0         255.255.255.0   U     102    0        0 ens224
172.16.0.0      0.0.0.0         255.255.255.0   U     103    0        0 ens256
172.16.0.6      172.16.0.18     255.255.255.255 UGH   103    0        0 ens256
192.168.1.0     0.0.0.0         255.255.255.0   U     100    0        0 ens160
```


#### bond的7种模式
https://blog.csdn.net/watermelonbig/article/details/53127165  

| 英文 | 序号 | 解释 |
| ---  | ---  | ---  |
| #define BOND_MODE_ROUNDROBIN    |  0  | （balance-rr模式）网卡的负载均衡模式 |
| #define BOND_MODE_ACTIVEBACKUP  |  1  | （active-backup模式）网卡的容错模式 |
| #define BOND_MODE_XOR           |  2  | （balance-xor模式）需要交换机支持 |
| #define BOND_MODE_BROADCAST     |  3  |  （broadcast模式） |
| #define BOND_MODE_8023AD        |  4  | （IEEE 802.3ad动态链路聚合模式）需要交换机支持 |
| #define BOND_MODE_TLB           |  5  | 自适应传输负载均衡模式 |
| #define BOND_MODE_ALB           |  6  | 网卡虚拟化方式

#### Red Hat 目前主推的nmcli 命令行方式  
[文章链接](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/networking_guide/ch-configure_network_bonding)

最终操作结果还是写入 /etc/sysconfig/network-scripts/ 下,
但红帽主导使用这个命令行工具
再一个它以各种profile的形式管理,也便于在多种类型的配置中快速切换  
[文章链接](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/networking_guide/sec-network_bonding_using_the_networkmanager_command_line_tool_nmcli)  
[文章链接](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/networking_guide/sec-network_bonding_using_the_command_line_interface)  
[文章链接](https://www.jianshu.com/p/3dd5e4ca4b7d)  
[文章链接](https://blog.51cto.com/cstsncv/2049474)  

```
# 添加bonding接口
nmcli connection add con-name bond0 type bond ifname bond0 mode active-backup

# 为bonding0接口添加从属接口
nmcli con add type bond-slave ifname ens33 master bond0
nmcli con add type bond-slave ifname ens37 master bond0

# 启动bonding网卡需要先启动从属网卡。
nmcli connection up bond-slave-ens33
nmcli connection up bond-slave-ens37

# 添加一个新配置文件:bond0, 对应接口名称:bond0
nmcli connection add con-name bond0 ifname bond0 autoconnect yes type ethernet ipv4.method manual ipv4.addresses 192.168.0.102/24 gw4 192.168.0.1

# 启动bond0网卡
nmcli con up bond0

# 修改已有的配置文件
nmcli connection modify "bond0" autoconnect yes type ethernet ipv4.method manual ipv4.addresses 192.168.0.102/24 gw4 192.168.0.1

# 启停某个接口
nmcli con down bond0
nmcli con up bond0
```

[使用 NETWORKMANAGER 命令行工具 NMCLI](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/networking_guide/sec-using_the_networkmanager_command_line_tool_nmcli)

#### nmcli 命令方式配置bond 与 team模式的bond
[文章链接](https://blog.51cto.com/13438667/2090710)  
[文章链接](https://blog.51cto.com/mengzhaofu/1851644)  
[文章链接](https://developer.rackspace.com/blog/lacp-bonding-and-linux-configuration/)  
[文章链接](https://computingforgeeks.com/how-to-configure-network-teaming-on-centos-rhel-8/)  
[文章链接](https://blog.51cto.com/cstsncv/2049474)  

nmcli 最大的理念变化是将物理网卡的配置文件与相应的IP配置分离开, 方便在各种配置中切换.
nmcli 配置bond 模式, 与传统的手工配置方式并无多少不同, 由nmcli 写出来的配置文件也一样, 唯一就是device 与 NAME 两项上的不同.
nmcli 配置team 模式最大的区别据称是 team将这个组合出来的设备当作一个对象

_team方式操作基本步骤_
```
# nmcli 查看管理对象
nmcli connection show

# 添加一个配置文件的实例对象,con-name 可以理解为别名,ifname是接口文件名称,需要与物理设备保持
nmcli connection add con-name team0 type team ifname team0 config '{"runner":{"name":"lacp"}}'

# IP设置,关于ipv4.method 可以将manual 换为不存在的如help 之类的以查看帮助
nmcli connection mod team0 ipv4.addresses 192.168.0.111/24 ipv4.gateway 192.168.0.1 ipv4.method manual

# 检查添加出来的设备信息
nmcli connection show team0 
nmcli connection show team0 | grep method

# 检查写出来的配置文件
ll /etc/sysconfig/network-scripts/ifcfg-team0 
cat /etc/sysconfig/network-scripts/ifcfg-team0 

# 添加从属的slave网卡进team组
nmcli connection add con-name team0-ens37 ifname ens37 type team-slave master team0 autoconnect yes
nmcli connection add con-name team0-ens38 ifname ens38 type team-slave master team0 autoconnect yes

# 激活配置,team对象与其slave都得手动激活
nmcli connection down team0; nmcli connection up team0
nmcli connection up team0-ens37
nmcli connection up team0-ens38

# 从teamctl 查看 team组的状态--传统方式从/proc/net/bonding/xxx 查看
teamdctl team0 state

# 必要的,否则设置autoconnect yes 依然在重启后不会自动加载
nmcli connection reload
```  


#### 简版--双网卡bond配置
红帽6系  
http://blog.51cto.com/lixin15/1769338 


红帽7系在6系基础上多一点内容

http://blog.51cto.com/12259095/1869795 
https://www.cnblogs.com/gaohong/p/4900744.html

总结归纳:
```
/etc/modprobe.conf 需要添加的内容
alias bond0 bonding
options bond0 miimon=100 mode=0

加载bond module
modprobe bonding
但模块即使加载后,重启一次依然无法避免

bond下的slave网卡的配置文件需要的字段
MASTER=bond0
SLAVE=yes

bond自身的配置文件
DEVICE=bond0
IPADDR=10.0.0.10
NETMASK=255.255.255.0
GATEWAY=10.0.0.2
# 红帽7系还多以下两条 -- 必须有此两项,否则bond配置依旧存在问题
BONDING_OPTS="miimon=100 mode=1"
BONDING_MASTER=yes
```
miimon是用来进行链路监测的。比如：miimon=100，单位是ms(毫秒)这边的100，是100ms，即是0.1秒那么系统每100ms监测一次链路连接状态，如果有一条线路不通就转入另一条线路；
mode共有七种(0~6)，这里解释两个常用的选项。

mode=0：表示load balancing (round-robin)为负载均衡方式，两块网卡都在工作。

mode=1：表示fault-tolerance (active-backup)提供冗余功能，工作方式是主备的工作方式，其中一块网卡在工作（若eth0断掉），则自动切换到另一个块网卡（eth1做备份）。 

内核里的bond状态
/proc/net/bonding/bond0 



#### bond的7种模式
1、mode=0(balance-rr)(平衡抡循环策略)
链路负载均衡，增加带宽，支持容错，一条链路故障会自动切换正常链路。交换机需要配置聚合口，思科叫port channel。
特点：传输数据包顺序是依次传输（即：第1个包走eth0，下一个包就走eth1….一直循环下去，直到最后一个传输完毕），此模式提供负载平衡和容错能力；但是我们知道如果一个连接
或者会话的数据包从不同的接口发出的话，中途再经过不同的链路，在客户端很有可能会出现数据包无序到达的问题，而无序到达的数据包需要重新要求被发送，这样网络的吞吐量就会下降

2、mode=1(active-backup)(主-备份策略)
这个是主备模式，只有一块网卡是active，另一块是备用的standby，所有流量都在active链路上处理，交换机配置的是捆绑的话将不能工作，因为交换机往两块网卡发包，有一半包是丢弃的。
特点：只有一个设备处于活动状态，当一个宕掉另一个马上由备份转换为主设备。mac地址是外部可见得，从外面看来，bond的MAC地址是唯一的，以避免switch(交换机)发生混乱。
此模式只提供了容错能力；由此可见此算法的优点是可以提供高网络连接的可用性，但是它的资源利用率较低，只有一个接口处于工作状态，在有 N 个网络接口的情况下，资源利用率为1/N

3、mode=2(balance-xor)(平衡策略)
表示XOR Hash负载分担，和交换机的聚合强制不协商方式配合。（需要xmit_hash_policy，需要交换机配置port channel）
特点：基于指定的传输HASH策略传输数据包。缺省的策略是：(源MAC地址 XOR 目标MAC地址) % slave数量。其他的传输策略可以通过xmit_hash_policy选项指定，此模式提供负载平衡和容错能力

4、mode=3(broadcast)(广播策略)
表示所有包从所有网络接口发出，这个不均衡，只有冗余机制，但过于浪费资源。此模式适用于金融行业，因为他们需要高可靠性的网络，不允许出现任何问题。需要和交换机的聚合强制不协商方式配合。
特点：在每个slave接口上传输每个数据包，此模式提供了容错能力

5、mode=4(802.3ad)(IEEE 802.3ad 动态链接聚合)
表示支持802.3ad协议，和交换机的聚合LACP方式配合（需要xmit_hash_policy）.标准要求所有设备在聚合操作时，要在同样的速率和双工模式，而且，和除了balance-rr模式外的其它bonding负载均衡模式一样，任何连接都不能使用多于一个接口的带宽。
特点：创建一个聚合组，它们共享同样的速率和双工设定。根据802.3ad规范将多个slave工作在同一个激活的聚合体下。
外出流量的slave选举是基于传输hash策略，该策略可以通过xmit_hash_policy选项从缺省的XOR策略改变到其他策略。需要注意的 是，并不是所有的传输策略都是802.3ad适应的，
尤其考虑到在802.3ad标准43.2.4章节提及的包乱序问题。不同的实现可能会有不同的适应 性。
必要条件：
条件1：ethtool支持获取每个slave的速率和双工设定
条件2：switch(交换机)支持IEEE 802.3ad Dynamic link aggregation
条件3：大多数switch(交换机)需要经过特定配置才能支持802.3ad模式

6、mode=5(balance-tlb)(适配器传输负载均衡)
是根据每个slave的负载情况选择slave进行发送，接收时使用当前轮到的slave。该模式要求slave接口的网络设备驱动有某种ethtool支持；而且ARP监控不可用。
特点：不需要任何特别的switch(交换机)支持的通道bonding。在每个slave上根据当前的负载（根据速度计算）分配外出流量。如果正在接受数据的slave出故障了，另一个slave接管失败的slave的MAC地址。
必要条件：
ethtool支持获取每个slave的速率

7、mode=6(balance-alb)(适配器适应性负载均衡)
在5的tlb基础上增加了rlb(接收负载均衡receive load balance).不需要任何switch(交换机)的支持。接收负载均衡是通过ARP协商实现的.
特点：该模式包含了balance-tlb模式，同时加上针对IPV4流量的接收负载均衡(receive load balance, rlb)，而且不需要任何switch(交换机)的支持。接收负载均衡是通过ARP协商实现的。bonding驱动截获本机发送的ARP应答，并把源硬件地址改写为bond中某个slave的唯一硬件地址，从而使得不同的对端使用不同的硬件地址进行通信。
来自服务器端的接收流量也会被均衡。当本机发送ARP请求时，bonding驱动把对端的IP信息从ARP包中复制并保存下来。当ARP应答从对端到达 时，bonding驱动把它的硬件地址提取出来，并发起一个ARP应答给bond中的某个slave。
使用ARP协商进行负载均衡的一个问题是：每次广播 ARP请求时都会使用bond的硬件地址，因此对端学习到这个硬件地址后，接收流量将会全部流向当前的slave。这个问题可以通过给所有的对端发送更新 （ARP应答）来解决，应答中包含他们独一无二的硬件地址，从而导致流量重新分布。
当新的slave加入到bond中时，或者某个未激活的slave重新 激活时，接收流量也要重新分布。接收的负载被顺序地分布（round robin）在bond中最高速的slave上
当某个链路被重新接上，或者一个新的slave加入到bond中，接收流量在所有当前激活的slave中全部重新分配，通过使用指定的MAC地址给每个 client发起ARP应答。下面介绍的updelay参数必须被设置为某个大于等于switch(交换机)转发延时的值，从而保证发往对端的ARP应答 不会被switch(交换机)阻截。
必要条件：
条件1：ethtool支持获取每个slave的速率；
条件2：底层驱动支持设置某个设备的硬件地址，从而使得总是有个slave(curr_active_slave)使用bond的硬件地址，同时保证每个bond 中的slave都有一个唯一的硬件地址。如果curr_active_slave出故障，它的硬件地址将会被新选出来的 curr_active_slave接管
其实mod=6与mod=0的区别：mod=6，先把eth0流量占满，再占eth1，….ethX；而mod=0的话，会发现2个口的流量都很稳定，基本一样的带宽。而mod=6，会发现第一个口流量很高，第2个口只占了小部分流量。

归纳
mode5和mode6不需要交换机端的设置，网卡能自动聚合。mode4需要支持802.3ad。mode0，mode2和mode3理论上需要静态聚合方式。
但实测中mode0可以通过mac地址欺骗的方式在交换机不设置的情况下不太均衡地进行接收。

