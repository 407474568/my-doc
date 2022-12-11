#### wget 递归下载

https://www.jianshu.com/p/ac9c6a529d3d  
https://www.cnblogs.com/pied/archive/2013/01/30/2883082.html

```
示例1
wget -c -r -np -nc -L -p ftp://ftp-trace.ncbi.nlm.nih.gov

示例2
wget -r -np --reject=html www.download.example
```

| 参数 | 含义 |
| :------| :------ |
| -r | 表示递归下载当前页面所有（子）链接 |
| -np | 表示不去遍历父目录下内容 |
| --reject=html | 不接受扩展名为html的文件 |
| --accept=iso,c,h | 表示只接受以此结尾的文件，分隔符为逗号（comma-separated） |



#### 不明的磁盘空间占用问题

通常的现象就是 ```du``` 和 ```df``` 两个命令统计得到的结果不一致

然而在排除了隐藏文件的存在后, 依然无法确定空间被什么占用

有以下几点值得核查:

1) 文件句柄被某个进程持有, 导致文件从系统上被删除, 但空间尚未释放  
   这一问题最为典型, 在互联网上的关联文章也最多, 检查方法也比较简单  
   ```lsof <某个目录> | grep delete```  
   被标记为 deleted 字样的就是被删除的文件, 但由于有进程已经打开了开, 且文件句柄未释放所以空间不会回收.  
2) 挂载点覆盖原有目录下的已有数据, 在```df```下可见, 使用```du```则统计不到  
   这一情景举例如下:  
   原本有 /test 目录, 并不是独立的挂载点, 占用的是系统盘的空间, 写入了一些文件  
   后来为 /test 目录单独使用一个块存储设备(无论是本地盘或是网络存储)进行挂载  
   挂载后, 原本写入到系统盘空间内的内容将不可见, 也就是```du```统计不到, 但```df```命令依然会表现其占用的大小, 且是归属在系统盘的挂载点下的  
3) 如果是 XFS 文件系统, 应当检查碎片化问题  
   https://developer.jdcloud.com/article/1873  
   检查命令  
   ```xfs_db -c frag -r <块存储设备, 如 /dev/sdb>```  
   碎片整理命令  
   ```xfs_fsr <块存储设备, 如 /dev/sdb>```  
4) 如果是 EXT 系列的文件系统, 有必要做文件系统逻辑错误的检查, 孤儿文件也会占用空间  
   只检查  
   ```fsck -n <块存储设备, 如 /dev/sdb>```  
   检查并修复  
   ```fsck <块存储设备, 如 /dev/sdb>```  
5) 最后, 不要忽略文件系统自身对空间的占用情况  
   一个可参考的比例值是, 在系统上可见的 745G 的块设备, 由 XFS 格式化后大小占用有 6G

#### 全局禁用IPv6

编辑文件/etc/sysctl.conf，
```
vi /etc/sysctl.conf
```

添加下面的行：

```
net.ipv6.conf.all.disable_ipv6 =1
net.ipv6.conf.default.disable_ipv6 =1
```

使之生效

```
sysctl -p
```

#### iftop 监控网卡特定流量

https://huataihuang.gitbooks.io/cloud-atlas/content/network/packet_analysis/utilities/iftop.html

iftop 可以用于监控IP到IP的流量

模式有交互和纯文本输出两种

交互模式用于实时观测变化情况

纯文本可以用于数据提取等操作


进入交互模式  
-i 指定网卡接口;
-B 以Bytes为单位而不是Bit  
在交互模式中  
按b 是开关顶部的bar, 横条用于表现流量  
按n 是开关是否将主机名转换为IP显示  

```
iftop -i ens160 -B
```

纯文本的输出模式, 同样以Bytes为单位, 显示为IP, 注意是持续输出, 如下:

```
iftop -i ens160 -B -N -t
```

在上述基础上, 收集10秒的样本之后退出, 如下:

```
[root@storage ~]# iftop -i ens160 -B -N -t -s 10
interface: ens160
IP address is: 10.0.0.1
MAC address is: 00:50:56:9a:d7:cd
Listening on ens160
   # Host name (port/service if enabled)            last 2s   last 10s   last 40s cumulative
--------------------------------------------------------------------------------------------
   1 storage                                  =>     40.0KB     48.9KB     48.9KB      196KB
     10.0.0.193                               <=         0B         0B         0B         0B
--------------------------------------------------------------------------------------------
Total send rate:                                     40.0KB     48.9KB     48.9KB
Total receive rate:                                      0B         0B         0B
Total send and receive rate:                         40.0KB     48.9KB     48.9KB
--------------------------------------------------------------------------------------------
Peak rate (sent/received/total):                     57.8KB         0B     57.8KB
Cumulative (sent/received/total):                     196KB         0B      196KB
============================================================================================
```

在上述基础上, 加上过滤器, 以筛选特定的对象, 语法与tcpdump基本相似, 可参考网上用法, 如下:

```
[root@storage ~]# iftop -i ens160 -B -N -t -f 'host 10.0.0.193' -s 10
interface: ens160
IP address is: 10.0.0.1
MAC address is: 00:50:56:9a:d7:cd
Listening on ens160
   # Host name (port/service if enabled)            last 2s   last 10s   last 40s cumulative
--------------------------------------------------------------------------------------------
   1 storage                                  =>        64B        86B        86B       688B
     10.0.0.193                               <=        44B     1.58KB     1.58KB     12.6KB
--------------------------------------------------------------------------------------------
Total send rate:                                        64B        86B        86B
Total receive rate:                                     44B     1.58KB     1.58KB
Total send and receive rate:                           108B     1.66KB     1.66KB
--------------------------------------------------------------------------------------------
Peak rate (sent/received/total):                       236B     6.19KB     6.42KB
Cumulative (sent/received/total):                      688B     12.6KB     13.3KB
============================================================================================
```

#### logrotate 的配置语法

完全引用自:  
https://wangchujiang.com/linux-command/c/logrotate.html

> logrotate命令 用于对系统日志进行轮转、压缩和删除，也可以将日志发送到指定邮箱。使用logrotate 指令，可让你轻松管理系统所产生的记录文件。每个记录文件都可被设置成每日，每周或每月处理，也能在文件太大时立即处理。您必须自行编辑，指定配置文件，预设的配置文件存放在/etc/logrotate.conf文件中。

语法

```
logrotate(选项)(参数)
```

选项

```
-?或--help：在线帮助；
-d或--debug：详细显示指令执行过程，便于排错或了解程序执行的情况；
-f或--force ：强行启动记录文件维护操作，纵使logrotate指令认为没有需要亦然；
-s<状态文件>或--state=<状态文件>：使用指定的状态文件；
-v或--version：显示指令执行过程；
-usage：显示指令基本用法。
```

参数

> 配置文件：指定lograote指令的配置文件。

实例

> crontab 会定时调用logrotate命令 在 /etc/cron.daily/logrotate 文件中配置使用  
logrotate的配置文件/etc/logrotate.conf 定义引用/etc/logrotate.d目录下的一些自定义的log配置  
在/etc/logrotate.d目录下创建任意后缀名的文件,即可使用对日志进行轮转

```
/tmp/log/log.txt
{
    copytruncate
    daily
    rotate 30
    missingok
    ifempty
    compress
    noolddir
}
```

这个配置文件代表的意思是将```/tmp/log/log.txt```文件 进行轮转压缩

```
compress                 通过gzip 压缩转储以后的日志
nocompress               不做gzip压缩处理
copytruncate             用于还在打开中的日志文件，把当前日志备份并截断；是先拷贝再清空的方式，拷贝和清空之间有一个时间差，可能会丢失部分日志数据。
nocopytruncate 备份日志文件不过不截断
create mode owner group  轮转时指定创建新文件的属性，如create 0777 nobody nobody
nocreate                 不建立新的日志文件
delaycompress            和compress 一起使用时，转储的日志文件到下一次转储时才压缩
nodelaycompress          覆盖 delaycompress 选项，转储同时压缩
missingok                如果日志丢失，不报错继续滚动下一个日志
errors address           专储时的错误信息发送到指定的Email 地址
ifempty                  即使日志文件为空文件也做轮转，这个是logrotate的缺省选项。
notifempty               当日志文件为空时，不进行轮转
mail address             把转储的日志文件发送到指定的E-mail 地址
nomail                   转储时不发送日志文件
olddir directory         转储后的日志文件放入指定的目录，必须和当前日志文件在同一个文件系统
noolddir                 转储后的日志文件和当前日志文件放在同一个目录下
sharedscripts            运行postrotate脚本，作用是在所有日志都轮转后统一执行一次脚本。如果没有配置这个，那么每个日志轮转后都会执行一次脚本
prerotate                在logrotate转储之前需要执行的指令，例如修改文件的属性等动作；必须独立成行
postrotate               在logrotate转储之后需要执行的指令，例如重新启动 (kill -HUP) 某个服务！必须独立成行
daily                    指定转储周期为每天
weekly                   指定转储周期为每周
monthly                  指定转储周期为每月
rotate count             指定日志文件删除之前转储的次数，0 指没有备份，5 指保留5 个备份
dateext                  使用当期日期作为命名格式
dateformat .%s           配合dateext使用，紧跟在下一行出现，定义文件切割后的文件名，必须配合dateext使用，只支持 %Y %m %d %s 这四个参数
size(或minsize) log-size 当日志文件到达指定的大小时才转储
```

注意事项

> 在/etc/logrotate.d目录下创建任意后缀名的文件

```
/tmp/log/log*
{
    copytruncate
    daily
    rotate 30
    missingok
    ifempty
    compress
    noolddir
}
```

> 这种情况下，会将轮转过的log再重新轮转,因为轮转过后的文件名也是已log开头的

#### autofs自动挂载
相比 /etc/fstab 在操作系统启动时挂载  
autofs 按需挂载具有更多的灵活性  
https://www.cnblogs.com/felixzh/p/9239298.html
https://blog.csdn.net/zhangym199312/article/details/78277738

挂载对象的主配置文件默认位置是  
/etc/auto.master  
autofs的工作参数配置文件默认位置是  
/etc/autofs.conf

有关autofs 相对路径和绝对路径 挂载的两钟写法, 已在上面的第2个链接有所描述  
简而言之就是, 在auto.master中如果书写为:
```
/-  附加的配置文件路径
```
则是以绝对路径的方式挂载, 并且这样不会隐藏父目录下, 与自动挂载点无关的其他文件和目录  

在RHEL/CentOS 6 和 7上配置并不存在太多问题  

<font color=red>关于设备的写法</font>  

![](/images/3Z8iKXenYTujrg7QtGcWxRfd5bTk0XFZ.png)

经测试, 在RHEL/CentOS 7上  
无论是  
/dev/sr0  
还是  
:/dev/sr0  
都是可以正常工作的

而在在RHEL/CentOS 8上  
挂载光驱等本地类设备需要上图示例中的冒号, 即:
```
:/dev/sr0
```
否则会出现挂载不上的错误情况  
此错误信息通过打开autofs.conf的日志级别可以显示
```
logging = debug
```
此后通过journalctl -u autofs 可以查看到完整的输出信息

而在RHEL/CentOS 8上  
挂载NFS等网络路径
如
```
192.168.1.2:/nfs_share
```
这样的路径则不能在前面冒号, 写成
```
:192.168.1.2:/nfs_share
```
则是错误的

<font color=red>关于autofs里的绝对路径和相对路径</font>  
绝对路径的配置方法  
在主配置文件 /etc/auto.amster 书写  
```
/-  附加的配置文件路径
```
在 附加的配置文件路径 书写
```
挂载点的绝对路径    设备类型    设备名称
```

而相对路径的写法  
以下图为例

![](/images/3Z8iKXenYTUfmjAHxPqaEF6h8NeXDbcV.png)

autofs相对路径, 挂载NFS路径的正解

remoteuser1  
写成  
/remoteuser1  
反而是错的

在auto.master里, 也不需要/结尾

![](/images/3Z8iKXenYTO6mJEPpaeIc85ZnSdtHVgl.png)

实际的文件夹 /rhome/remoteuser1
remoteuser1 存不存在都不影响

#### 内存做ramdisk
[https://blog.csdn.net/weixin_37871174/article/details/75084619](https://blog.csdn.net/weixin_37871174/article/details/75084619)

以下操作不存在侵入性, 诸如编译内核参数等.
```
#!/bin/bash
# 指定大小,单位是KB
size=$((8*1024*1024))
modprobe brd rd_nr=1 rd_size=${size} max_part=0

# 假设新增的是ram0, 如普通块设备一样格式化使用
mkfs.xfs /dev/ram0


# 开机启动RAMDISK, 示例
echo "options brd rd_nr=1 rd_size=${size} max_part=0" >> /etc/modprobe.d/ramdisk.conf
echo "mkfs.ext4 /dev/ram0" >> /etc/rc.d/rc.local
echo "mount /dev/ram0 /ramdisk" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local


# 卸载ramdisk, 先卸文件系统
umount /dev/ram0
modprobe -r brd
```

#### 查找sar -d 里面显示设备名称与熟知的设备名称的对应关系
[文章链接](https://itindex.net/detail/48792-lvm-%E7%A3%81%E7%9B%98-%E6%98%A0%E5%B0%84)

![](/images/b6be90b3gy1gj2w0mf10cj20sk05cq2x.jpg)

两个命令用来查找对应关系  
```
cat /proc/partitions
dmsetup ls
```
![](/images/b6be90b3gy1gj2w1xhe2xj20d30933yi.jpg)
  
  
#### 不能本地console / 远程ssh登录的检查项
检查/etc/pam.d/login 是否有异常项  
检查/etc/securetty 这里面的是允许登录的交互方式, 如果被注释掉,则root不能登录  
检查/etc/passwd 用户shell 是否nologin  
从/var/log/messages 和 /var/log/secure 里查找提示


#### 因机器异常关闭导致xfs文件系统损坏的不能启动
[文章链接](https://blog.csdn.net/Jaelin_Pang/article/details/77825408)  
错误大概显示如下：
```
xfs metadata I/O error(dm-0) blocked ox....
...
Entering emergence mode......
~#
~#
```  
此时需要作的就是修复dm-0, 如下：  
```xfs_repair  -L  /dev/dm-0```  


#### /etc/fstab 文件详解
[文章链接](https://www.jianshu.com/p/87bef8c24c15)  

![](/images)  

其实 /etc/fstab (filesystem table) 就是将我们利用 mount 命令进行挂载时， 将所有的选项与参数写入到这个文件中就是了。除此之外， /etc/fstab 还加入了 dump 这个备份用命令的支持！ 与启动时是否进行文件系统检验 fsck 等命令有关。

```
<file systems> 挂载设备 : 不是我们通常理解的文件系统，而是指设备（硬盘及其分区，DVD光驱等）。它告知我们设备（分区）的名字，这是你在命令行中挂载（mount）、卸载（umount）设备时要用到的。
<mountpoint> 挂载点：告诉我们设备挂载到哪里。
<type> 文件系统类型：Linux支持许多文件系统。 要得到一个完整的支持名单查找mount man-page。典型 的名字包括这些：ext2, ext3, reiserfs, xfs, jfs,iso9660, vfat, ntfs, swap和auto, 'auto' 不是一个文件系统，而是让mount命令自动判断文件类型，特别对于可移动设备，软盘，DVD驱动器，这样做是很有必要的，因为可能每次挂载的文件类型不一致。
<opts> 文件系统参数：这部分是最有用的设置！！！ 它能使你所挂载的设备在开机时自动加载、使中文显示不出现乱码、限制对挂载分区读写权限。它是与mount命令的用法相关的，要想得到一个完整的列表，参考mount manpage.
<dump> 备份命令：dump utility用来决定是否做备份的. dump会检查entry并用数字来决定是否对这个文件系统进行备份。允许的数字是0和1。如果是0，dump就会忽略这个文件系统，如果是1，dump就会作一个备份。大部分的用户是没有安装dump的，所以对他们而言<dump>这个entry应该写为0。
<pass> 是否以fsck检验扇区：启动的过程中，系统默认会以fsck检验我们的 filesystem 是否完整 (clean)。 不过，某些 filesystem 是不需要检验的，例如内存置换空间 (swap) ，或者是特殊文件系统例如 /proc 与 /sys 等等。fsck会检查这个头目下的数字来决定检查文件系统的顺序，允许的数字是0, 1, 和2。0 是不要检验， 1 表示最早检验(一般只有根目录会配置为 1)， 2 也是要检验，不过1会比较早被检验啦！一般来说,根目录配置为1,其他的要检验的filesystem都配置为 2 就好了。
<opts>常用参数：
noatime 关闭atime特性，提高性能，这是一个很老的特性，放心关闭，还能减少loadcycle
defaults 使用默认设置。等于rw,suid,dev,exec,auto,nouser,async，具体含义看下面的解释。
自动与手动挂载:
auto 在启动或在终端中输入mount -a时自动挂载
noauto 设备（分区）只能手动挂载
读写权限:
ro 挂载为只读权限
rw 挂载为读写权限
可执行:
exec 是一个默认设置项，它使在那个分区中的可执行的二进制文件能够执行
noexec 二进制文件不允许执行。千万不要在你的root分区中用这个选项！！！
I/O同步:
sync 所有的I/O将以同步方式进行
async 所有的I/O将以非同步方式进行
户挂载权限:
user 允许任何用户挂载设备。 Implies noexec,nosuid,nodev unless overridden.
nouser 只允许root用户挂载。这是默认设置。
临时文件执行权限：
suid Permit the operation of suid, and sgid bits. They are mostly used to allow users on a computer system to execute binary executables with temporarily elevated privileges in order to perform a specific task.
nosuid Blocks the operation of suid, and sgid bits.
```


#### 处理NETSTAT中获取不到PID的进程
[文章链接](http://www.debugrun.com/a/OI9oeBu.html)  
说是运行时间长(一年半载)的进程可能会遇到这种现象
在常规手段都找不到的情况下,还有可能是内核线程,所以没有PID
查看方式  
rpcinfo -p localhost

#### NFS服务对应的端口及iptables配置
[文章链接](http://www.cnblogs.com/Skyar/p/3573187.html)  
NFS主要用到的端口有：111- portmapper， 875 - rquotad，892-mountd，2049-nfs，udp：32769-nlockmgr，tcp：32803-nlockmgr，把这些端口加入到iptables规则中即可。  
配置过程如下：  
1、首先修改NFS配置文件(/etc/sysconfig/nfs)，加入以上端口：  
将#RQUOTAD_PORT=875，#LOCKD_TCPPORT=32803，#LOCKD_UDPPORT=32769，#MOUNTD_PORT=892，前面的4个#去掉，保存文件退出  
2、重启nfs服务
service nfs restart  
3、查看服务运行的相关端口情况，使用 rpcinfo -p
```
    program vers proto   port  service
    100000    4   tcp    111  portmapper
    100000    3   tcp    111  portmapper
    100000    2   tcp    111  portmapper
    100000    4   udp    111  portmapper
    100000    3   udp    111  portmapper
    100000    2   udp    111  portmapper
    100024    1   udp  35093  status
    100024    1   tcp  53692  status
    100005    1   udp    892  mountd
    100005    1   tcp    892  mountd
    100005    2   udp    892  mountd
    100005    2   tcp    892  mountd
    100005    3   udp    892  mountd
    100005    3   tcp    892  mountd
    100003    2   tcp   2049  nfs
    100003    3   tcp   2049  nfs
    100003    4   tcp   2049  nfs
    100227    2   tcp   2049  nfs_acl
    100227    3   tcp   2049  nfs_acl
    100003    2   udp   2049  nfs
    100003    3   udp   2049  nfs
    100003    4   udp   2049  nfs
    100227    2   udp   2049  nfs_acl
    100227    3   udp   2049  nfs_acl
    100021    1   udp  32769  nlockmgr
    100021    3   udp  32769  nlockmgr
    100021    4   udp  32769  nlockmgr
    100021    1   tcp  32803  nlockmgr
    100021    3   tcp  32803  nlockmgr
    100021    4   tcp  32803  nlockmgr
```

4、修改/etc/sysconfig/iptables，加入端口
```
    -A INPUT -p tcp -m tcp --dport 111 -j ACCEPT
    -A INPUT -p udp -m udp --dport 111 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 2049 -j ACCEPT
    -A INPUT -p udp -m udp --dport 2049 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 892 -j ACCEPT
    -A INPUT -p udp -m udp --dport 892 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 875 -j ACCEPT
    -A INPUT -p udp -m udp --dport 875 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 32768 -j ACCEPT
    -A INPUT -p udp -m udp --dport 32768 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 32803 -j ACCEPT
```

#### Linux查看进程运行的完整路径方法
通过ps及top命令查看进程信息时，只能查到相对路径，查不到的进程的详细信息，如绝对路径等。这时，我们需要通过以下的方法来查看进程的详细信息：  
Linux在启动一个进程时，系统会在/proc下创建一个以PID命名的文件夹，在该文件夹下会有我们的进程的信息，其中包括一个名为exe的文件即记录了绝对路径，通过ll或ls –l命令即可查看。  
ll /proc/PID  
cwd符号链接的是进程运行目录；  
exe符号连接就是执行程序的绝对路径；  
cmdline就是程序运行时输入的命令行命令；  
environ记录了进程运行时的环境变量；  
fd目录下是进程打开或使用的文件的符号连接。  


#### 修改rsyslog的时间格式
[文章链接](https://linux.cn/article-6014-1.html)  
  
默认时间格式为"Jun 28 10:07:09",年份信息无法获知  
修改rsyslog.conf中的配置,可以结合man rsyslog.conf中的信息  

以rsyslog为例:  
文件位置 /etc/rsyslog.conf  
$ActionFileDefaultTemplate 声明rsyslog使用哪个格式模板  
$template CustomFormat 创建了一个自定义格式的模板  
CustomFormat是模板的名称  
```
# Use default timestamp format
$template CustomFormat,"%timestamp:::date-rfc3339% %HOSTNAME% %syslogtag% %msg%\n"
#$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$ActionFileDefaultTemplate CustomFormat
```

#### 配置sftp
[文章链接](https://my.oschina.net/sallency/blog/784022)  

在sshd的配置文件,默认 /etc/sshd_config  
这里我们使用系统自带的 internal-sftp 服务即可满足需求  
```
#Subsystem      sftp    /usr/libexec/openssh/sftp-server
Subsystem      sftp    internal-sftp
Subsystem
```
Subsystem 是说 ssh 的子模块 这里启用的即为 sftp 模块，我们使用系统自带的 internal-sftp 来提供此服务，其实配置到这你即可以使用帐号 ssh 登录，也可以使用 ftp 客户端 sftp 登录。

#### EOF块中使变量不被引用方法
![](/images/b6be90b3gy1gj2w5jsuo5j20kk08y0tc.jpg)


#### /etc/fstab中带空格的路径问题
写入/etc/fstab中的路径,如果有空格,用引号,以及用\转义都是行不通的,会提示/etc/fstab列表中语法有错误  
```
[mntent]: line 9 in /etc/fstab is bad
[mntent]: line 10 in /etc/fstab is bad 
```
而正解是,空格用\040代替

![](/images/b6be90b3gy1gj2w73meosj20yc08tdfy.jpg)


#### wget下载目录

[文章链接](http://blog.csdn.net/tylai520/article/details/17168673)  
```
 wget -r -p -np -k -P ~/tmp/ http://Java-er.com
 
-P 表示下载到哪个目录
-r 表示递归下载
-np 表示不下载旁站连接.
-k 表示将下载的网页里的链接修改为本地链接.
-p 获得所有显示网页所需的元素

额外的
-c 断点续传
-nd 递归下载时不创建一层一层的目录，把所有的文件下载到当前目录
-L 递归时不进入其它主机，如wget -c -r www.xxx.org/
-A 指定要下载的文件样式列表，多个样式用逗号分隔
-i 后面跟一个文件，文件内指明要下载的URL
```


#### wget使用代理
[文章链接](https://www.cnblogs.com/cloud2rain/archive/2013/03/22/2976337.html)
* 方法一 在环境变量中设置代理
```export http_proxy=http://127.0.0.1:8087```

* 方法二、使用配置文件
为wget使用代理，可以直接修改/etc/wgetrc，也可以在主文件夹下新建.wgetrc，并编辑相应内容，本文采用后者。
将/etc/wgetrc中与proxy有关的几行复制到~/.wgetrc，并做如下修改：
```
# You can set the default proxies for Wget to use for http, https, and ftp.
# They will override the value in the environment.
https_proxy = http://127.0.0.1:8087/
http_proxy = http://127.0.0.1:8087/
ftp_proxy = http://127.0.0.1:8087/
# If you do not want to use proxy at all, set this to off.
use_proxy = on
```  
这里 use_proxy = on 开启了代理，如果不想使用代理，每次都修改此文件未免麻烦，我们可以在命令中使用-Y参数来临时设置：  
```-Y, --proxy=on/off  打开或关闭代理```

* 方法三 使用-e参数
wget本身没有专门设置代理的命令行参数，但是有一个"-e"参数，可以在命令行上指定一个原本出现在".wgetrc"中的设置。于是可以变相在命令行上指定代理：  
```-e, --execute=COMMAND   执行`.wgetrc'格式的命令```  
例如：  
```
wget -c -r -np -k -L -p -e "http_proxy=http://127.0.0.1:8087" http://www.subversion.org.cn/svnbook/1.4/
```
这种方式对于使用一个临时代理尤为方便。


#### SuSE和rhel添加删除磁盘不重启的方法
* SuSE：  
使用自带脚本：  
rescan-scsi-bus.sh  ： 添加磁盘以后执行该脚本可以看到添加的磁盘  
rescan-scsi-bus.sh -r ： 删除磁盘以后执行可以剔除磁盘  
以上脚本如果没有可以安装包：sg3_utils  
以上的方法可以在rhel里面使用，rpm包也是一样的，但是rescan-scsi-bus.sh -r 这个命令在rhel官方资料里面写了有bug，不建议使用  
* RHEL：  
```echo "- - -" > /sys/class/scsi_host/hostx/scan```  
hostx表示在/sys/class/scsi_host有多个host开头的文件，映射的磁盘至操作系统可能是通过host0或者其他的hostx，如果执行host0的没有继续执行其余的hostx  
```echo "1" > /sys/block/sdx/device/delete```  
sdx表示要删除的磁盘，比如sdb

* shell循环遍历
    ```
    for path in `ls -d /sys/class/scsi_host/host*`
    do
        echo "- - -" > $path/scan
    done
    ```

#### RHEL / CentOS 7 安装图形界面
安装
```
yum -y groupinstall "X Window System" "GNOME Desktop" "Graphical Administration Tools"
```
设置图形为默认启动
```
systemctl set-default graphical.target
```
设置命令行为默认启动
```
systemctl set-default multi-user.target
```


#### 用screen来保持需前台活跃的程序
类似于比如wget需长时间下载，或是一个长时间执行脚本需要等待结果，在SSH断开后重连依然能接续上的场景
用screen来实现  
如没有则 yum -y install  screen  
使用方法：  
输入screen，进入screen的会话窗口，但与shell基本相同（用户配置文件没有加载）  
此时执行需要执行的程序  
按ctrl+A之后再按D键，出现[detached]  
![](/images/b6be90b3gy1gj2w90zen2j209c01b0sh.jpg)    


此时可以断开SSH连接，screen仍在运行。
重连SSH，输入screen -r将恢复screen中的内容。
退出screen，输入exit，将显示[screen is terminating]  
![](/images/b6be90b3gy1gj2w93wyjsj20be020a9t.jpg)  


#### 命令置于前台后台
用&将执行的命令置于后台后，重新唤回前台的方法，fg或是%  
![](/images/b6be90b3gy1gj2w96ob6hj20b30bjjr7.jpg)   


#### 查询与终止当前用户会话
查看自己当前所用的会话（不需要终止的会话）  
输入tty  
显示：/dev/pts/5  
 
终止不需要的会话  
pkill -9 -t pts/1  
pkill -9 -t pts/2  
pkill -9 -t pts/3  
pkill -9 -t pts/4  
-t 参数：需要终止的会话的TTY  


#### 关于tar: Removing leading `/’ from member names 
[文章链接](https://xiaobin.net/200911/tar-removing-leading-slash-from-member-name/)  
首先应该明确：*nix系统中，使用tar对文件打包时，一般不建议使用绝对路径。  

通常是在两台环境相似的机器上进行同步复制的时候，才有需要使用绝对路径进行打包。使用绝对路径打包时如果不指定相应的参数，tar会产生一句警告信息：  
```tar: Removing leading `/’ from member names```  
并且实际产生的压缩包会将绝对路径转化为相对路径。  

比如：  
![](/images/b6be90b3gy1gj2wark9rcj20mr086gln.jpg)

这样的一个压缩包，如果我们再去解开，就会当前目录（也即此例中的“~”）下再新建出“./home/robin/” 两级目录。对于这样的压缩包，解压方法是使用参数 “-C”指解压的目录为根目录（“/”）：  
```tar -xzvf robin.tar.gz -C /```  
  
更为可靠的方法是在打包和解开的时候都使用参数 -P

#### IP反查主机名、MAC地址
用nmap对局域网扫描一遍，然后查看arp缓存表就可以知道局域内ip对应的mac了。nmap比较强大也可以直接扫描mac地址和端口。执行扫描之后就可以 ```cat /proc/net/arp```查看arp缓存表了。  

进行ping扫描，打印出对扫描做出响应的主机：  
```$ nmap -sP 192.168.1.0/24```  

仅列出指定网络上的每台主机，不发送任何报文到目标主机：  
```$ nmap -sL 192.168.1.0/24```  

探测目标主机开放的端口，可以指定一个以逗号分隔的端口列表(如-PS 22，23，25，80)：  
```$ nmap -PS 192.168.1.234```  

使用UDP ping探测主机：  
```$ nmap -PU 192.168.1.0/24```  

使用频率最高的扫描选项（SYN扫描,又称为半开放扫描），它不打开一个完全的TCP连接，执行得很快：  
```$ nmap -sS 192.168.1.0/24```  


#### 配置永久静态路由
[文章链接](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/networking_guide/sec-using_the_command_line_interface)  
使用不附带任何选项的 ip route 命令显示 IP 路由表。例如：  
```
~]$ ip route
default via 192.168.122.1 dev ens9  proto static  metric 1024
192.168.122.0/24 dev ens9  proto kernel  scope link  src 192.168.122.107
192.168.122.0/24 dev eth0  proto kernel  scope link  src 192.168.122.126
```  
要在主机地址中添加一个静态路由，即 IP 地址，请作为 root 运行以下命令：  
```
ip route add 192.0.2.1 via 10.0.0.1 [dev ifname]
```  
其中 192.0.2.1 是用点分隔的十进制符号中的 IP 地址，10.0.0.1 是下一个跃点，ifname 是进入下一个跃点的退出接口。  
要在网络中添加一个静态路由，即代表 IP 地址范围的 IP 地址，请作为 root 运行以下命令：  
```
ip route add 192.0.2.0/24 via 10.0.0.1 [dev ifname]
```
其中 192.0.2.1 是用点分隔的十进制符号中目标网络的 IP 地址，10.0.0.1 是网络前缀。网络前缀是在子网掩码中启用的位元。这个网络地址/网络前缀长度格式有时是指无类别域际路由选择（CIDR）表示法。  
可在 /etc/sysconfig/network-scripts/route-interface 文件中为每个接口保存其静态路由配置。  
例如：接口 eth0 的静态路由可保存在 /etc/sysconfig/network-scripts/route-eth0 文件中。route-interface 文件有两种格式：ip 命令参数和网络/子网掩码指令，如下所述。  
有关 ip route 命令的详情，请查看 ip-route(8) man page。  

