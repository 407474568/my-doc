* [目录](#0)
  * [查看磁盘归属哪张板卡](#1)



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
