### 官网

自被 Oracle 收购以后, 手册  
https://docs.oracle.com/cd/E26926_01/html/E29115/zfs-1m.html#

openzfs 主页  
https://openzfs.org/wiki/Main_Page


* [目录](#0)
  * [因盘符变化而导致pool错误的进入DEGRADED状态的处理](#1)


<h3 id="1">因盘符变化而导致pool错误的进入DEGRADED状态的处理</h3>

https://serverfault.com/questions/854979/how-to-change-the-drive-reference-in-a-zfs-pool-from-dev-sdx-to-dev-disk-by-id
https://superuser.com/questions/1732532/zfs-disk-drive-letter-changed-how-to-reimport-by-id

实际上, ZFS的设计并不依赖Linux系统分配的盘符来标识成员硬盘.  
但从问题的现象来看, 比如此次的案例是系统添加了新的磁盘进来, 而引起盘符的变化.  
而盘符的变化又显然引起了ZFS对zpool成员盘的标识错误.  
以下是操作过程:  

```
[root@storage ~]# zpool export SATA-16T
cannot unmount '/SATA-16T': pool or dataset is busy
[root@storage ~]# zpool export -f SATA-16T
cannot unmount '/SATA-16T': pool or dataset is busy
[root@storage ~]# zpool export -h
invalid option 'h'
usage:
	export [-af] <pool> ...
[root@storage ~]# zpool export -f SATA-16T
cannot unmount '/SATA-16T': pool or dataset is busy
[root@storage ~]# zpool status
  pool: SATA-16T
 state: DEGRADED
status: One or more devices could not be used because the label is missing or
	invalid.  Sufficient replicas exist for the pool to continue
	functioning in a degraded state.
action: Replace the device using 'zpool replace'.
   see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-4J
  scan: resilvered 1.69G in 00:02:33 with 0 errors on Thu May 11 12:25:34 2023
config:

	NAME                      STATE     READ WRITE CKSUM
	SATA-16T                  DEGRADED     0     0     0
	  raidz3-0                DEGRADED     0     0     0
	    sda                   ONLINE       0     0     0
	    sdb                   ONLINE       0     0     0
	    sdc                   ONLINE       0     0     0
	    sdd                   ONLINE       0     0     0
	    sde                   ONLINE       0     0     0
	    16863869621585000276  UNAVAIL      0     0     0  was /dev/sdf1
	    10764257403669481144  UNAVAIL      0     0     0  was /dev/sdm1
	    sdk                   ONLINE       0     0     0
	    sdi                   ONLINE       0     0     0
	    sdl                   ONLINE       0     0     0
	    sdj                   ONLINE       0     0     0

errors: No known data errors
[root@storage ~]# fuse
fuse2fs         fuse-overlayfs  fuser           fusermount3     
[root@storage ~]# fuse
fuse2fs         fuse-overlayfs  fuser           fusermount3     
[root@storage ~]# fuser /SATA-16T
[root@storage ~]# zpool export SATA-16T
[root@storage ~]# zpool import SATA-16T -d /dev/disk/by-id
[root@storage ~]# zpool status
  pool: SATA-16T
 state: ONLINE
status: One or more devices has experienced an unrecoverable error.  An
	attempt was made to correct the error.  Applications are unaffected.
action: Determine if the device needs to be replaced, and clear the errors
	using 'zpool clear' or replace the device with 'zpool replace'.
   see: https://openzfs.github.io/openzfs-docs/msg/ZFS-8000-9P
  scan: resilvered 1.69G in 00:02:33 with 0 errors on Thu May 11 12:25:34 2023
config:

	NAME                        STATE     READ WRITE CKSUM
	SATA-16T                    ONLINE       0     0     0
	  raidz3-0                  ONLINE       0     0     0
	    wwn-0x5000cca2ecc29ef7  ONLINE       0     0     0
	    wwn-0x5000cca2cdcb04da  ONLINE       0     0     0
	    wwn-0x5000cca2e3c40838  ONLINE       0     0     0
	    wwn-0x5000cca295f815dc  ONLINE       0     0     0
	    wwn-0x5000cca295f725b8  ONLINE       0     0     0
	    wwn-0x5000cca2b7ccb7fc  ONLINE       0     0     1
	    wwn-0x5000cca295f6ad26  ONLINE       0     0     1
	    wwn-0x5000cca2a1f6f505  ONLINE       0     0     0
	    wwn-0x5000cca2a1f75777  ONLINE       0     0     0
	    wwn-0x5000cca2a1f54fa0  ONLINE       0     0     0
	    wwn-0x5000cca295e57e92  ONLINE       0     0     0

errors: No known data errors
[root@storage ~]# df
Filesystem                Type     1G-blocks  Used Available Use% Mounted on
/dev/mapper/rootvg-lvroot xfs             49     6        44  13% /
/dev/vda1                 xfs              1     1         1  22% /boot
SATA-16T                  zfs         118970 89609     29362  76% /SATA-16T
/dev/sdf                  xfs          14901 14802        99 100% /SATA-16T-single-01
/dev/sdh                  xfs          14901 14802        99 100% /SATA-16T-single-02
```

从以上可见:  
1) 首先, ```cannot unmount '/SATA-16T': pool or dataset is busy```一定还有服务没停止完, zpool 真的在使用中, 务必需要处理完毕.
2) 其次, ```was /dev/sdf1``` 这种就属于标记错误发生了混乱, 原本是sdf的盘符变化了, ZFS 却没有找到正确的成员盘. 然而盘却是实实在在在线的.
3) 处理办法, 并不需要去执行```zfs replace``` 替换盘的操作, 这样确实显得太笨, 因为实际上盘并不是真的丢失了. 需要的操作就是先执行```zpool export pool的名称```先导出,
   再执行```zpool import SATA-16T -d /dev/disk/by-id```导入回去.
