* [目录](#0)
  * [CPU stuck for XXs](#1)



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
