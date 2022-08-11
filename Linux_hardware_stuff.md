* [目录](#0)
  * [查看磁盘归属哪张板卡](#1)
  * [smartctl 里的 Background scan](#2)


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


<h3 id="2">smartctl 里的 Background scan</h3>

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
