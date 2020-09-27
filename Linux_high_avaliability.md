#### LVS
概念与原理  
https://blog.csdn.net/weixin_43314056/article/details/86674517  
https://blog.csdn.net/Running_free/article/details/77981201  
https://blog.csdn.net/shudaqi2010/article/details/58594501  
https://www.imooc.com/article/21560  

LVS+keepalived的例子  
https://blog.51cto.com/renlifeng/1276234  
https://blog.51cto.com/beyondhdf/1331874  
https://blog.csdn.net/u012852986/article/details/52386306  
https://blog.csdn.net/u012852986/article/details/52412174  

有关LVS的4种模式---NAT, DR, tunnel 加上后出现的Full-NAT: 
- NAT适用于有端口转换(映射)需求的场景,NAT模式下的Director 成为real_server的网关,real_server将自己的gateway指向Director , 同时流入的请求包与从real_server应答包都由NAT模式的Director 进出.
- DR模式只处理流入的请求包,real_server应答包直接返回给来源.不可转换端口.Director 和 real_server需要在同一vlan下,且不可由一台机器同时扮演Director 和 real_server
- Tunnel 模式只处理流入的请求包,real_server应答包直接返回给来源.不可转换端口.可以跨越 lan / wan

10种算法

加权最少连接优先wlc是默认算法,其余算法介绍已足够详细

ipvsadm是LVS配置管理工具  
ipvsadm -ln 列出当前工作的条目  
ipvsadm -C 清除当前配置  
ipvsadm -S 用于列出当前配置,其内容可以重定向写入文件中,用于ipvsadm启动时的恢复设置所用  

#### keepalived
官网和手册( 实际上也就是man里的内容,比较欠缺实例结合 )  
https://www.keepalived.org/download.html  
https://www.keepalived.org/manpage.html  

适合入手的文章  
https://blog.51cto.com/xuweitao/1953167  
http://www.voidcn.com/article/p-bnfpdubt-vm.html  
https://blog.csdn.net/LL845876425/article/details/82084560  
https://my.oschina.net/hncscwc/blog/158746  
https://peiqiang.net/2014/11/21/keepalived-and-redis.html  
https://blog.csdn.net/qq_26545305/article/details/79957992  
https://blog.51cto.com/lansgg/1179636

keepalived的配置文件实际包含对LVS的配置,如果先行单独配置ipvsadm,则keepalived进程在启动时也会根据keepalived配置文件中定义的LVS配置对ipvsadm进行覆盖

关于vrrp_script  
配置vrrp_script只能用于检测vrrp_instance, 是对Director 的操作,而非real_server

keepalived对real_server的几种健康检查方式  
在帮助文档给出了以下方式  
HTTP_GET|SSL_GET|TCP_CHECK|SMTP_CHECK|DNS_CHECK|MISC_CHECK

HTTP|SSL_GET和TCP方式都给出了一定的例子, 如果可以满足需求, 则帮助文档基本够用

MISC_CHECK 则是外部检查脚本, 针对real_server的健康检查方式
其中misc_dynamic项, 在帮助文档中给出了以下说明  
exit status 0: svc check success, weight unchanged.  
exit status 1: svc check failed.  
exit status 2-255: svc check success, weight changed to 2 less than exit status.  
退出值为0: 权重不变  
退出值为1: 检查失败  
退出值为2-255: 检查成功,但权重改变为2到退出值之间的值

MISC_CHECK 除此之外还有  
warmup 可选项,进行健康检查前的延迟时间  
user USERNAME [GROUPNAME] 运行健康检查脚本的用户身份

比较繁琐的在于MISC_CHECK脚本在Director上,对后端real_server的健康检查涉及配置文件  
简化脚本文件数量---则需要传参形式定义健康检查脚本文件的调度,涉及在keepalived配置文件中的配置  
简化keepalived配置文件---则需要对健康检查脚本文件作不同对象的配置.

另外一个思路就是,详细的健康检查只在real_server自身上进行,keepalived的Director上只作简单的服务可用性检查

#### 关于LVS Nginx HAProxy 对比的文章
http://www.ha97.com/5646.html  
https://www.cnblogs.com/yangmingxianshen/p/8426847.html  
https://blog.csdn.net/u010285974/article/details/86750527  
http://www.linkedkeeper.com/135.html  
http://www.magedu.com/74265.html  
https://www.cnblogs.com/kevingrace/p/5892169.html

观点足够丰富了, 再作进一步提炼:  
LVS 分发TCP/UDP流量,决定了它可以支撑更大的负载量; 同时也决定了它无法满足应用层更精细的控制  
HAproxy 可以工作在第四/七层,可以实现更精细的控制; 承载能力弱于LVS, 但也足够优秀.高于nginx.  
Nginx 纯粹工作于第七层应用层, 对web程序员更友好, 适用于web服务内部的流转与控制.

#### HAproxy
http://www.haproxy.org/  
http://cbonte.github.io/haproxy-dconv/1.9/intro.html

质量较高的文章  
https://blog.51cto.com/leejia/1421882   有讲到统计页面的配置方法  
https://www.cnblogs.com/f-ck-need-u/p/8502593.html#1-1-  
https://segmentfault.com/a/1190000007532860

一般上手的文章  
https://blog.51cto.com/jerry12356/1858243  
https://www.howtoing.com/install-and-configure-haproxy-on-centos  
https://blog.csdn.net/a355586533/article/details/54345958  

HAproxy的8种算法与Session保持  
https://blog.csdn.net/hexieshangwang/article/details/49617273  
https://www.cnblogs.com/f-ck-need-u/p/8553190.html  

**HAproxy的ACL**  
https://www.cnblogs.com/f-ck-need-u/p/8502593.html#1-5-acl  
https://www.jianshu.com/p/cd80f5f9ec1b   
因为支持正则,所以可以实现网站应用动静分离等场景.  
关于ACL的配置语句

![](https://wx4.sinaimg.cn/large/b6be90b3gy1gj51hbdn4qj20lt0dz74f.jpg)

这一示例是其中一种语法,语法有多种
![](https://wx4.sinaimg.cn/large/b6be90b3gy1gj51kj5f94j20wq0dudht.jpg)
![](https://wx1.sinaimg.cn/large/b6be90b3gy1gj51knmmkzj20wu0ltdl1.jpg)

**HAproxy的健康检查方式**  
https://www.cnblogs.com/breezey/p/4680418.html  
有3种内置的健康检查方式,不支持外部脚本方式.  
其中:  
通过监听端口进行健康检测——粒度太粗, 实用性太低  
通过URI获取进行健康检测——检测方式, 是用过去GET后端server的的web页面. 相比上一种算是好点  
通过request获取的头部信息进行匹配进行健康检测----感觉也只能和GET页面的方式半斤八两  
除此以外, 自定义的检查方式如下:  
http://cbonte.github.io/haproxy-dconv/1.9/configuration.html#3.1-external-check  手册  
http://www.loadbalancer.org/blog/how-to-write-an-external-custom-healthcheck-for-haproxy/  
https://codeday.me/bug/20181128/413167.html  
https://www.liurongxing.com/haprox-external-check.html  
传参的问题  
https://serverfault.com/questions/889424/haproxy-external-check-with-arguments  

手册给出的操作步骤也并不是很完整, 缺乏相应示例, 脚本如何返回值等细节也没篇文章完全覆盖到, 有机会再后补

**HAproxy的当前工作状态**  
HAproxy内置一个stats的功能,通过web页面可以展示当前HAproxy的一些统计信息.
如下图:
![](https://wx1.sinaimg.cn/large/b6be90b3gy1gj51kqzoytj218o0m70yk.jpg)

在配置文件的frontend中配置--backend亦可,除配置在gloabl段启动会报错以外,实际也可以配置在listen段.也即可以分离一个虚拟服务一个监控页面
![](https://wx4.sinaimg.cn/large/b6be90b3gy1gj51kumjwbj20mv0kq0t2.jpg)

**HAproxy自身的高可用**  
HAproxy有不少使用keepalived来做防止单点故障的文章,需要明确的是,无论是keepalived还是heartbeat都是主备模型,并不存在双主一说,如VIP等资源始终都是其中一台持有.  
使用keepalived来实现HAproxy自身的高可用则与其他keepalived应用场景相比并无特殊,大多数情况下都需要将LVS+keepalived的机器放置在HAproxy机器的前端.在拓扑图上的结构就是 LVS+keepalived --> HAproxy  --> 业务应用  
使用heartbeat可以实现HAproxy与heartbeat都在同一台机器---虽然也是通过组播来进行心跳通告.满足有这一需求的场景.  

HAproxy+heartbeat的方式  
https://www.cnblogs.com/kevingrace/p/10206731.html  

heartbeat的获取方式  
1) EPEL源  
2) http://linux-ha.org/wiki/Downloads  

yum安装的heartbeat, 在 /etc/ha.d/  下有:
ha.cf：             heartbeat主配置文件
haresources： 本地资源文件
authkeys：      认证文件

在介绍HAproxy+heartbeat的文章中讲到heartbeat会监控HAproxy服务,在heartbeat接管服务时也会带起HAproxy
haresources配置文件中有如下示例配置语句:
ha-master IPaddr::172.16.60.229/24/eth0 haproxy
上面设置ha-maser为主节点, 集群VIP为172.16.60.229, haproxy为所指定需要监视的应用服务.
对HAproxy的监控与需要启动时的启动操作的具体实现方法有待进一步验证--因为haproxy只是一个名称,具体如何关联对应的执行程序,执行程序不同的人如何对应,未做验证.
核心思想仍然是主机持有服务资源(VIP等) , 主机宕机,备机接管. 主机恢复后,是否抢回资源可配置.


#### LVS+keepalived 和 heartbeat都会面临的脑裂问题
针对脑裂这一问题,要实现高可靠性, 仲裁节点 / 设备 是必不可少的,以下这两个思路都不错  

https://www.zhihu.com/question/50997425  
针对LVS,使用vrrp_script的方式简单易行,不过只对网关的检测,可靠性是否足够高存疑.

https://www.cnblogs.com/kevingrace/p/7205846.html  
前半部分提了一个自行实现争用锁来实现对服务资源的竞争方式.后半部分与前一篇内容相同.  
摘录他提的思路:  
如何防止HA集群脑裂  
一般采用2个方法  
1）仲裁  
当两个节点出现分歧时，由第3方的仲裁者决定听谁的。这个仲裁者，可能是一个锁服务，一个共享盘或者其它什么东西。

2）fencing  
当不能确定某个节点的状态时，通过fencing把对方干掉，确保共享资源被完全释放，前提是必须要有可靠的fence设备。

理想的情况下，以上两者一个都不能少。  
但是，如果节点没有使用共享资源，比如基于主从复制的数据库HA，也可以安全的省掉fence设备，只保留仲裁。而且很多时候我们的环境里也没有可用的fence设备，比如在云主机里。

那么可不可以省掉仲裁，只留fence设备呢？  
不可以。因为，当两个节点互相失去联络时会同时fencing对方。如果fencing的方式是reboot，那么两台机器就会不停的重启。如果fencing的方式是power off，那么结局有可能是2个节点同归于尽，也有可能活下来一个。但是如果两个节点互相失去联络的原因是其中一个节点的网卡故障，而活下来的正好又是那个有故障的节点，那么结局一样是悲剧。  
所以，单纯的双节点，无论如何也防止不了脑裂。

如何实现上面的策略  
可以自己完全从头开始实现一套符合上述逻辑的脚本。推荐使用基于成熟的集群软件去搭建，比如Pacemaker+Corosync+合适的资源Agent。Keepalived不太适合用于有状态服务的HA，即使把仲裁和fence那些东西都加到方案里，总觉得别扭。

使用Pacemaker+Corosync的方案也有一些注意事项  
1）了解资源Agent的功能和原理  
了解资源Agent的功能和原理，才能知道它适用的场景。比如pgsql的资源Agent是比较完善的，支持同步和异步流复制，并且可以在两者之前自动切换，并且可以保证同步复制下数据不会丢失。但目前MySQL的资源Agent就很弱了，没有使用GTID又没有日志补偿，很容易丢数据，还是不要用的好，继续用MHA吧（但是，部署MHA时务必要防范脑裂）。

2）确保法定票数(quorum)  
quorum可以认为是Pacemkaer自带的仲裁机制，集群的所有节点中的多数选出一个协调者，集群的所有指令都由这个协调者发出，可以完美的杜绝脑裂问题。为了使这套机制有效运转，集群中至少有3个节点，并且把no-quorum-policy设置成stop，这也是默认值。（很多教程为了方便演示，都把no-quorum-policy设置成ignore，生产环境如果也这么搞，又没有其它仲裁机制，是很危险的！）

但是，如果只有2个节点该怎么办？

一是拉一个机子借用一下凑足3个节点，再设置location限制，不让资源分配到那个节点上。  
二是把多个不满足quorum小集群拉到一起，组成一个大的集群，同样适用location限制控制资源的分配的位置。  
但是如果你有很多双节点集群，找不到那么多用于凑数的节点，又不想把这些双节点集群拉到一起凑成一个大的集群（比如觉得不方便管理）。那么可以考虑第三种方法。  
第三种方法是配置一个抢占资源，以及服务和这个抢占资源的colocation约束，谁抢到抢占资源谁提供服务。这个抢占资源可以是某个锁服务，比如基于zookeeper包装一个，或者干脆自己从头做一个，就像下面这个例子。这个例子是基于http协议的短连接，更细致的做法是使用长连接心跳检测，这样服务端可以及时检出连接断开而释放锁）但是，一定要同时确保这个抢占资源的高可用，可以把提供抢占资源的服务做成lingyig高可用的，也可以简单点，部署3个服务，双节点上个部署一个，第三个部署在另外一个专门的仲裁节点上，至少获取3个锁中的2个才视为取得了锁。这个仲裁节点可以为很多集群提供仲裁服务（因为一个机器只能部署一个Pacemaker实例，否则可以用部署了N个Pacemaker实例的仲裁节点做同样的事情。但是，如非迫不得已，尽量还是采用前面的方法，即满足Pacemaker法定票数，这种方法更简单，可靠。