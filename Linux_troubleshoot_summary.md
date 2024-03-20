* [目录](#0)
  * [CPU stuck for XXs](#1)
  * [查看被系统缓存的文件](#2)
  * [系统内核文件丢失](#3)
  * [定位 iowait 的进程](#4)
  * [iotop 提示"CONFIG_TASK_DELAY_ACCT and ...](#5)


<h3 id="1">控制台上出现错误消息：NMI watchdog BUG soft lockup - CPU stuck for XXs</h3>

红帽和SuSE的文档  
https://access.redhat.com/solutions/1503333  
https://www.suse.com/support/kb/doc/?id=000018705  

其中都提到加大 /proc/sys/kernel/watchdog_thresh 的值  
从默认值的10秒加大到20至60  
这个值的变化只是缓解watchdog汇报CPU 软锁发生的频率  
软锁持续时间低于这个值就不做汇报  


需要找到根源原因, 可参考  
https://www.cnblogs.com/RXDXB/p/12605529.html

一些可能的原因:  
服务器电源供电不足，导致CPU电压不稳导致CPU死锁  
vcpus超过物理cpu cores  
虚机所在的宿主机的CPU太忙或磁盘IO太高  
虚机的的CPU太忙或磁盘IO太高  
VM网卡驱动存在bug，处理高水位流量时存在bug导致CPU死锁  

虚拟机建议先从宿主机的负载检查起


<h3 id="2">查看被系统缓存的文件</h3>

有两个相当有用的工具

一个叫 ```linux-ftools```, 谷歌出品  
一个是 ```pcstat```

#### linux-ftools

源码获取地址  
https://code.google.com/archive/p/linux-ftools/source/default/source

使用说明介绍  
https://blog.csdn.net/icycode/article/details/80200437  
https://www.cnblogs.com/langdashu/p/5953222.html  
https://www.dazhuanlan.com/liangqier/topics/1493493  

编译安装, 其中一篇帖子已经介绍了编译安装过程中出现的错误的解决办法.  
形成的编译安装脚本如下:

```
#!/bin/bash
# 谷歌出品
unzip linux-ftools.zip
cd linux-ftools
aclocal
autoconf
automake --add-missing
./configure
make && make install
ln -sf /usr/local/bin/linux-fadvise /usr/sbin/linux-fadvise
ln -sf /usr/local/bin/linux-fallocate /usr/sbin/linux-fallocate
ln -sf /usr/local/bin/linux-fincore /usr/sbin/linux-fincore
```

有关该工具的使用, 引用别人到位的点评

> 但是 Linux-ftools 和 pcstat 这些工具只能判断某个文件是否被缓存，如果缓存，缓存大小是多少，但是无法查找到缓存中到底缓存了哪些文件。
> 
> shanker 提供了一个办法，那就查看哪些进程使用的物理内存最多，就找到该进程打开的文件，然后用 fincore 查看这些文件的缓存使用率。

也就是说工具是好工具, 但不是直接的告诉你, 在 ```free``` 命令里所显示的 ```buffer/cache``` 一列里的大小, 分别是那些.  
它只能告诉你, 某个文件, 被系统缓存了多少个页, 总大小等信息.  
因此, 还需要自己再加工一下才能真正的发挥作用.

由前面引用点评的思路得出:  
1) ps 获取内存 (RSS) 占用前X名的PID;  
2) 由PID去执行lsof, 筛选出是"文件"类型的完整路径;  
3) 再依次执行 ```linux-fincore``` 命令去查询被缓存的文件大小;  
4) 由于上一步的文件对象可能是重复的, 所以还涉及到需要去去重的问题;

综上, 得出以下脚本:

```
待补全
```

#### pcstat

```pcstat``` 其实也是有着大同小异思路的工具

```
待补全
```


<h3 id="3">系统内核文件丢失</h3>

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-verifying_the_initial_ram_disk_image

存在有时发现系统内核文件丢失的情况, 即 ```/boot/initramfs-<xxxx>.img``` 的文件不知所踪

在当前系统还可用的前提下, 其实有补救措施.

```
dracut "initramfs-$(uname -r).img" $(uname -r)
```

<h3 id="4">定位 iowait 的进程</h3>

这篇文章是转载和翻译, 引用源链接已失效  
https://blog.csdn.net/G7N3F/article/details/52673077

这是原文  
https://bencane.com/troubleshooting-high-i-o-wait-in-linux-358080d57b69

里面介绍到的一个标准工作流程:
- 通过 ```iostat``` 定位到高IO的磁盘对象
- 通过 ```top``` 可以定位到CPU的使用率是计算任务, 还是 iowait 事件
- 通过 ```iotop``` 可以定位高IO的进程
- 最有价值的部分: iotop 也不是各路发行版默认安装的, 如果没有的情况是否还有查询的方法? 答案自然是肯定的, 因为```iotop```
也必然有数据来源, 实际通过比较 /proc/<进程PID>/io 里统计数据的差值

<h3 id="5">iotop 提示"CONFIG_TASK_DELAY_ACCT and ...</h3>

iotop 提示"CONFIG_TASK_DELAY_ACCT and kernel.task_delayacct sysctl not enabled in kernel, cannot determine 
SWAPIN and IO %"

https://superuser.com/questions/610581/iotop-complains-config-task-delay-acct-not-enabled-in-kernel-only-for-specific

检查你的内核 ```.config``` 文件, 有可能实际上是 ```CONFIG_TASK_DELAY_ACCT=y```  
如果是```CONFIG_TASK_DELAY_ACCT=n```, 则不在本节的讨论范围, 因为你需要重新编译内核才能打开此功能.  
对于已经是```CONFIG_TASK_DELAY_ACCT=y```的情形, 值得借鉴的方式是:

```
sysctl kernel.task_delayacct=1
iotop
sysctl kernel.task_delayacct=0
```

即: 只在使用```iotop```时才打开```delayacct```, 用完即关, 而不是作为默认打开的配置项.  
因为该参数有拖慢系统性能的可能性, 道理也很显而易见, 因为额外监控了进程的 swapin 和 swapout
