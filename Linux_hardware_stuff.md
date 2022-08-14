* [目录](#0)
  * [查看磁盘归属哪张板卡](#1)
  * [查看磁盘信息的方式](#1)
  * [smartctl 里的 Background scan](#3)
  * [by-id 查找与盘符的对应关系](#4)


<h3 id="1">查看磁盘归属哪张板卡</h3>  

http://bean-li.github.io/proc-scsi-scsi-to-dev-sdX/  
https://blog.csdn.net/yiyeguzhou100/article/details/100715930  

![](imgages/3Zs7lRNdCyUPZidBp4LVgWbsyQKDj96Y.png)

如图所示  

```
cat /proc/scsi/scsi
```

是为列出所有scsi设备的通道编号, 依次为:  
host -> channel -> id -> lun

而通过

```
ls -ld /sys/block/*/device
```

则可以查看每个盘符对应的通道编号, 两者对应上, 则可获知需要的信息  
但如果是虚拟化平台直通后的, 又会无法确定在宿主机上的对应关系, 因为通道号不同

<h3 id="2">查看磁盘信息的方式</h3> 

当磁盘处于重负载下, 使用 ```parted -l``` 命令可能会挂起一直得不到响应.  
目前尚未确认属于特定条件的个案还是普遍.  

与此同时的 ```smartctl``` ```lsblk``` 则不会有此现象

查看磁盘扇区大小的方式  

https://zdyxry.github.io/2019/06/05/%E6%9F%A5%E7%9C%8B%E7%A3%81%E7%9B%98%E6%89%87%E5%8C%BA%E5%A4%A7%E5%B0%8F/

除了 ```parted -l``` 有所显示以外, ```lsblk``` 同样也可以完成此任务

```
lsblk -d -o NAME,PHY-SEC,LOG-SEC <设备名>
```

其中  
-d 不显示 slave 节点, 也就是此磁盘之上的分区信息不显示出来  
-o 指定显示哪些列的信息, 其中 PHY-SEC,LOG-SEC 分别代表物理扇区, 逻辑扇区, -h 帮助信息有详细说明


<h3 id="3">smartctl 里的 Background scan</h3>

有关此话题的讨论  
https://www.reddit.com/r/DataHoarder/comments/e677p1/psa_if_you_have_sas_drives_check_the_background/

有关 ```Background scan```  
题主以为是希捷独有技术, 因为他没接触过其他品牌, 所以他也不能确定.  
实际上应该是企业级的机械盘, 各个厂家都有--准确的说是SAS盘, SAS盘通常都是面向企业级客户.

在我的这个例子里, 大概也是企业盘里最拉垮的一类了, 7200转的SAS, 启用了 ```Background scan``` 

![](images/m4OqhH3P5xtenPO05Db6lNUyEhj3LfcX.png)

凑巧的是帖子讨论的不少人都是ZFS 文件系统的用户, 对 ```Background scan``` 也是在 ZFS 使用场景下进行的讨论.

>As long as you’re doing regular scrubs on your pools, arguably you don’t need it with ZFS. However, counterpoint is that a scrub only reads allocated blocks, so a potential weak spot might not be discovered until you write to it and then have issues later reading it. Also, I can confirm that the BMS does not only reallocate sectors, it will first try a rewrite-in-place which will usually succeed - basically, if the scan decides a sector needed a little too much ECC, even if it read successfully, it will rewrite it to “refresh” it on the physical medium. The drive SHOULD be doing this in normal operation as well, but I can’t 100% confirm that.
>
>If a drive runs out of spare sectors it should be discarded regardless of interface and type. The secondary point of the BMS is to detect this scenario sooner.
>
>The core point is to do regular read tests to ensure all data remains readable and to catch otherwise silent errors. As long as you’re doing that regularly in some fashion it should be OK.

他的核心观点是, ```Background scan``` 在工作时对IO性能的影响有限,   
而 ```zfs scurb``` 功能只检查有数据的位置, 而没数据的位置由于 ```zfs``` 不做检查, 因此 ```Background scan``` 是个弥补.  
技术上来说两者功能并不重叠, 并且由于负面影响, 应该处于开启状态.


<h3 id="4">by-id 查找与盘符的对应关系</h3> 

在 ```zfs``` 的命令 ```zpool status``` 中, 展现的不是盘符, 而是id, 如下所示

```
NAME                                          STATE     READ WRITE CKSUM
SAS-4T-group01                                DEGRADED     0     0     0
  raidz3-0                                    DEGRADED     0     0     0
    scsi-35000cca05c22d4d0                    ONLINE       0     0     0
    scsi-35000cca05c2302a4                    ONLINE       0     0     0
    scsi-35000cca05c218680                    ONLINE       0     0     0
    scsi-35000cca03b49d970                    ONLINE       0     0     0
    scsi-35000cca05c203418                    ONLINE       0     0     0
    scsi-35000cca03b8c2c20                    ONLINE       0     0     0
    scsi-35000cca03b8e60b4                    FAULTED      2     0     0  too many errors
    scsi-35000cca05c2302a8                    ONLINE       0     0     0
    ata-ST4000DM004-2CV104_ZFN0238P           ONLINE       0     0     0
    ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K0CEHPR8  DEGRADED     0     0   108  too many errors
    scsi-35000cca05c1e5180                    ONLINE       0     0     0
    scsi-35000cca05c0f6d24                    ONLINE       0     0     0
    scsi-35000cca05c1e5200                    ONLINE       0     0     0
    ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K5EAD4EK  ONLINE       0     0     0
    ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K2DN7X0E  ONLINE       0     0     0
```

当需要知晓某块盘 对应系统上哪个盘符, 以便于后续查询其他信息时, 就需要解决这个对应关系转换的问题

https://www.diytechguru.com/2020/11/27/identify-zfs-disks-using-disk-by-id/

命令也很简单

```
ls -l /dev/disk/by-id/ 
```

多加个 ```grep``` 也就有想要的答案了

```
[root@storage-archive ~]# ls -l /dev/disk/by-id/ | grep scsi-35000cca03b8e60b4
lrwxrwxrwx 1 root root  9 Aug 13 23:13 scsi-35000cca03b8e60b4 -> ../../sdg
lrwxrwxrwx 1 root root 10 Aug 13 23:13 scsi-35000cca03b8e60b4-part1 -> ../../sdg1
lrwxrwxrwx 1 root root 10 Aug 13 23:13 scsi-35000cca03b8e60b4-part9 -> ../../sdg9
[root@storage-archive ~]# ls -l /dev/disk/by-id/ | grep ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K0CEHPR8
lrwxrwxrwx 1 root root  9 Aug 13 23:13 ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K0CEHPR8 -> ../../sdm
lrwxrwxrwx 1 root root 10 Aug 13 23:13 ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K0CEHPR8-part1 -> ../../sdm1
lrwxrwxrwx 1 root root 10 Aug 13 23:13 ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K0CEHPR8-part9 -> ../../sdm9
```

