### 官网

自被 Oracle 收购以后, 手册  
https://docs.oracle.com/cd/E26926_01/html/E29115/zfs-1m.html#

openzfs 主页  
https://openzfs.org/wiki/Main_Page


* [目录](#0)
  * [两种安装方式](#1)
  * [因盘符变化而导致pool错误的进入DEGRADED状态的处理](#2)
  * [池特性升级](#3)
  * [如果开机没有自动导入池](#4)
  * [限制ARC对内存的消耗大小](#5)
  * [基础命令](#6)


<h3 id="6">基础命令</h3>

#### 创建池

https://docs.oracle.com/cd/E19253-01/819-5461/gaynr/index.html

```
zpool create <池名> <容错基本> <成员设备1> <成员设备2> <成员设备3>...
```

#### 添加cache设备

```
zpool add <池名> <设备类别: cache或log> <成员设备1> <成员设备2>...
```

```
[root@X9DRi-LN4F ~]# zpool status
  pool: SAS-4T-group01
 state: ONLINE
config:

	NAME            STATE     READ WRITE CKSUM
	SAS-4T-group01  ONLINE       0     0     0
	  raidz1-0      ONLINE       0     0     0
	    bcache3     ONLINE       0     0     0
	    bcache1     ONLINE       0     0     0
	    bcache4     ONLINE       0     0     0
	    bcache2     ONLINE       0     0     0
	    bcache0     ONLINE       0     0     0

errors: No known data errors
[root@X9DRi-LN4F ~]# zpool add SAS-4T-group01 cache /dev/sdc
[root@X9DRi-LN4F ~]# zpool status
  pool: SAS-4T-group01
 state: ONLINE
config:

	NAME            STATE     READ WRITE CKSUM
	SAS-4T-group01  ONLINE       0     0     0
	  raidz1-0      ONLINE       0     0     0
	    bcache3     ONLINE       0     0     0
	    bcache1     ONLINE       0     0     0
	    bcache4     ONLINE       0     0     0
	    bcache2     ONLINE       0     0     0
	    bcache0     ONLINE       0     0     0
	cache
	  sdc           ONLINE       0     0     0

errors: No known data errors
```

<h3 id="1">两种安装方式</h3>

- yum 安装

https://www.linuxprobe.com/centos7-install-use-zfs.html

参照此文档, 根据自己的OS版本修改相应url

```
# 获取repo文件
yum localinstall --nogpgcheck http://epel.mirror.net.in/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum localinstall --nogpgcheck http://archive.zfsonlinux.org/epel/zfs-release.el7.noarch.rpm

# 安装zfs包
yum install kernel-devel zfs
```

- 编译安装

安装手册, 官方文档  
https://openzfs.github.io/openzfs-docs/Developer%20Resources/Building%20ZFS.html


安装依赖, RHEL/CentOS 7:

```
sudo yum install epel-release gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel libuuid-devel libudev-devel openssl-devel zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-devel-$(uname -r) python python2-devel python-setuptools python-cffi libffi-devel git ncompress libcurl-devel
sudo yum install --enablerepo=epel python-packaging dkms 
```

安装依赖, RHEL/CentOS 8, Fedora:

```
sudo dnf install --skip-broken epel-release gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel libuuid-devel libudev-devel openssl-devel zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-devel-$(uname -r) python3 python3-devel python3-setuptools python3-cffi libffi-devel git ncompress libcurl-devel
sudo dnf install --skip-broken --enablerepo=epel --enablerepo=powertools python3-packaging dkms
```

以及, kernel-devel 也需要确保安装  
如果内核是自行编译安装, 还需要注意内核编译时, 也生成了kernel-devel  
参见本站文档  ```如何从内核源码中提取kernel-devel```

https://docs.heyday.net.cn:1000/Linux_kernel_upgrade.html#2  


以及, zfs源码包的编译安装过程依赖python解释器, 而不同版本的zfs源码包, 对python解释器版本的识别正确与否表现不同.

例如:  
当我使用 zfs-2.1.11 的源码包时, python 解释器的版本是自行编译安装的 3.10.11.  
在尝试让它正确识别后, 依然有错误的问题.  
服软的解决办法就是 yum 安装随便安装一个满足它要求的版本, 然后在编译完成后, 恢复我原本的 python 3.10.11 的执行程序在 PATH
下的链接指向

执行步骤

```
tar -xvzf <zfs源码包版本>
cd <zfs源码包版本>
sh autogen.sh
./configure
make -s -j$(nproc)
```

最后安装

```
sudo make install
sudo ldconfig
sudo depmod
```

重启后核实模块加载情况

```
[root@storage-archive ~]# uname -r
6.1.35
[root@storage-archive ~]# lsmod | grep -i bcache
bcache                339968  0
crc64                  20480  2 crc64_rocksoft,bcache
[root@storage-archive ~]# lsmod | grep -i zfs
zfs                  3969024  0
zunicode              335872  1 zfs
zzstd                 528384  1 zfs
zlua                  184320  1 zfs
zavl                   20480  1 zfs
icp                   331776  1 zfs
zcommon               114688  2 zfs,icp
znvpair               110592  2 zfs,zcommon
spl                   122880  6 zfs,icp,zzstd,znvpair,zcommon,zavl
```




<h3 id="2">因盘符变化而导致pool错误的进入DEGRADED状态的处理</h3>

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


<h3 id="3">池特性升级</h3>

旧版 zfs 创建的池, 当在新版 zfs 中运行时, 有升级提示

注意分辨清, zfs 在许多命令组合上都采用此逻辑:  
- 如果输入是的 ```zpool <动作>```, 通常这意味着只是查看  
- 如果你是真的希望被执行, 则是 ```zpool <动作> <对象>```  

因此, 在此问题中, 应当执行 ```zpool upgrade <池名>```

```
[root@storage-archive ~]# zpool list
no pools available
[root@storage-archive ~]# zpool import
   pool: SAS-4T-group01
     id: 8055163225617679732
  state: ONLINE
status: Some supported features are not enabled on the pool.
	(Note that they may be intentionally disabled if the
	'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
	some features will not be available without an explicit 'zpool upgrade'.
 config:

	SAS-4T-group01                                ONLINE
	  raidz3-0                                    ONLINE
	    ata-WDC_WD40EZRZ-00GXCB0_WD-WCC7K2DN7X0E  ONLINE
	    scsi-35000cca03b49d970                    ONLINE
	    scsi-35000cca03b8c2c20                    ONLINE
	    scsi-35000cca05c1e5180                    ONLINE
	    scsi-35000cca05c2302a4                    ONLINE
	    scsi-35000cca05c218680                    ONLINE
	    scsi-35000cca05c203418                    ONLINE
	    scsi-35000cca05c22d4d0                    ONLINE
	    scsi-35000cca05c2302a8                    ONLINE
	    scsi-35000cca05c0f6d24                    ONLINE
	    scsi-35000cca05c1e5200                    ONLINE
	    ata-ST4000DM004-2CV104_ZFN0238P           ONLINE
	    ata-WDC_WD40EZAZ-19SF3B0_WD-WX42DA1PHC31  ONLINE
[root@storage-archive ~]# zpool import SAS-4T-group01
[root@storage-archive ~]#  zpool upgrade
This system supports ZFS pool feature flags.

All pools are formatted using feature flags.


Some supported features are not enabled on the following pools. Once a
feature is enabled the pool may become incompatible with software
that does not support the feature. See zpool-features(7) for details.

Note that the pool 'compatibility' feature can be used to inhibit
feature upgrades.

POOL  FEATURE
---------------
SAS-4T-group01
      encryption
      project_quota
      device_removal
      obsolete_counts
      zpool_checkpoint
      spacemap_v2
      allocation_classes
      resilver_defer
      bookmark_v2
      redaction_bookmarks
      redacted_datasets
      bookmark_written
      log_spacemap
      livelist
      device_rebuild
      zstd_compress
      draid


[root@storage-archive ~]# zpool import SAS-4T-group01
[root@storage-archive ~]# zpool upgrade SAS-4T-group01
This system supports ZFS pool feature flags.

Enabled the following features on 'SAS-4T-group01':
  encryption
  project_quota
  device_removal
  obsolete_counts
  zpool_checkpoint
  spacemap_v2
  allocation_classes
  resilver_defer
  bookmark_v2
  redaction_bookmarks
  redacted_datasets
  bookmark_written
  log_spacemap
  livelist
  device_rebuild
  zstd_compress
  draid
```

<h3 id="4">如果开机没有自动导入池</h3>

https://github.com/openzfs/zfs/issues/8831

第一步, 这些服务应被启用, 源码包编译安装的, 它也会自动创建

```
systemctl enable zfs.target --now
systemctl enable zfs-import.target --now
systemctl enable zfs-import-cache --now
systemctl enable zfs-mount --now
```

第二步, ```zfs-import-cache``` 服务极可能是未能启动的状态

```
[root@storage-archive ~]# systemctl status zfs-import-cache.service
● zfs-import-cache.service - Import ZFS pools by cache file
   Loaded: loaded (/usr/lib/systemd/system/zfs-import-cache.service; enabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:zpool(8)


[root@storage-archive ~]# systemctl status zfs-import-cache.service 
● zfs-import-cache.service - Import ZFS pools by cache file
   Loaded: loaded (/usr/lib/systemd/system/zfs-import-cache.service; enabled; vendor preset: enabled)
   Active: inactive (dead)
Condition: start condition failed at Sun 2023-08-06 11:04:45 CST; 9min ago
           └─ ConditionFileNotEmpty=/usr/local/etc/zfs/zpool.cache was not met
     Docs: man:zpool(8)
```

前者应是第一步的四个服务未全部开机自启  
后者是 zpool 的 cache 文件的问题, 在我的情景下它根本未被创建

处置办法:  
- 先导入池  
zpool import <池名>  

- 再重置 zpool 的 cache文件  
zpool set cachefile=none <池名>  
zpool set cachefile=```cache文件位置, 如:/usr/local/etc/zfs/zpool.cache``` <池名>

在我的情景下问题得到解决


<h3 id="5">限制ARC对内存的消耗大小</h3>

https://www.emengweb.com/p/PVE%E8%AE%BE%E7%BD%AEZFS-RAM-Cache-%E5%A4%A7%E5%B0%8F

此设置在/etc/modprobe.d/zfs.conf文件中完成

```
[root@X9DR3-F ~]# cat /etc/modprobe.d/zfs.conf
options zfs zfs_arc_min=137438953472
options zfs zfs_arc_max=274877906944
```

分别对应上限和下限
