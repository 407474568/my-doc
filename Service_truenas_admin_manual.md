### 官网
前身就是freeNAS, 底层技术是ZFS, 如果了解ZFS, 上手就应该比较轻松  
https://www.truenas.com/truenas-scale/

### 官方手册
https://www.truenas.com/docs/ 

### 入门手册  
https://post.smzdm.com/p/a6d8m6vg/


* [目录](#0)
  * [NFS客户端不能chmod的问题](#1)


<h3 id="1">NFS客户端不能chmod的问题</h3>

https://www.truenas.com/community/threads/cannot-chmod-nfs-operation-not-permitted.97247/

回复里面的这句

> Set the zfs aclmode on the dataset in question to "passthrough".

原因也就是 TrueNAS 默认启用的ACL 是 POSIX

改成如下,是可行的选择

下图是在"存储", "数据集"的"编辑选项" 中  
如果是有子数据集的情形, 父数据集虽然做了该设置, 但不会递归传递给子数据集, 在UI上有提示.

![](/images/mwtRAUI4x7S8YvLBZaJf6kqNn7RXAtdw.png)

另外, 如果NFS共享, 希望暴露root权限给客户端, 则在NFS共享上还需设置mapuser  
该数据集的所有者是TrueNAS系统的root用户

![](/images/mwtRAUI4x77HwarEcfupLICogNT49sXO.png)

此处涉及NFS的基本概念, 需要对NFS本身有足够了解.  
NFS本身不提供用户认证, 由操作系统完成.
