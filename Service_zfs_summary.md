### 官网

自被 Oracle 收购以后, 手册  
https://docs.oracle.com/cd/E26926_01/html/E29115/zfs-1m.html#

openzfs 主页  
https://openzfs.org/wiki/Main_Page


* [目录](#0)
  * [dataset数据集的recordsize大小](#7)
  * [基础命令](#6)
  * [两种安装方式](#1)
  * [因盘符变化而导致pool错误的进入DEGRADED状态的处理](#2)
  * [池特性升级](#3)
  * [如果开机没有自动导入池](#4)
  * [限制ARC对内存的消耗大小](#5)

<h3 id="7">dataset数据集的recordsize大小</h3>

以下是 ZFS 中不同 `recordsize` 配置的适用场景、性能优劣对比，结合数据库块大小（如 Oracle 的 8KB）和文件系统簇大小的特性进行分析，并汇总成表格：

---

#### **1. `recordsize` 的核心作用**
ZFS 的 `recordsize` 是逻辑块大小（默认 128KB），决定了：
- **COW（写时拷贝）的粒度**：每次修改数据时，ZFS 会复制整个 `recordsize` 大小的块。
- **存储效率**：小文件可能浪费空间（类似文件系统簇的概念）。
- **I/O 性能**：大块适合顺序读写，小块适合随机读写。

---

#### **2. 不同 `recordsize` 的适用场景与性能对比**

| **recordsize** | **适用场景** | **性能优势** | **性能劣势** | **空间效率** | **典型用途** |
|----------------|--------------|--------------|--------------|--------------|--------------|
| **4KB - 8KB** | OLTP 数据库、小文件随机读写（如日志、元数据） | 极低延迟，适合随机 I/O | 大文件顺序读写效率低，COW 次数多 | 小文件无浪费，大文件可能因碎片化浪费空间 | Oracle 数据库块（默认 8KB） |
| **16KB - 32KB** | 混合负载（中小文件 + 中等 I/O） | 平衡随机与顺序性能 | 仍可能因 COW 造成写放大 | 中等空间利用率 | 虚拟机磁盘镜像（如 QCOW2） |
| **128KB** | 默认值，通用场景 | ZFS 默认优化值，兼顾多种负载 | 对大文件非最优，碎片化较明显 | 默认空间效率 | 普通文件存储（未细分场景） |
| **256KB - 512KB** | 大文件顺序读写（如视频流、备份） | 提升吞吐量，减少元数据开销 | 随机 I/O 延迟高，内存消耗大 | 小文件浪费空间（最多 512KB/文件） | NAS 存储、视频编辑工作流 |
| **1MB - 2MB** | 超大文件（如 ISO、虚拟机模板、数据库 dump） | 极大提升顺序读写性能，降低碎片化 | 随机 I/O 性能极差，内存压力大 | 小文件空间浪费严重（1-2MB/文件） | 归档存储、静态资源库 |

---

#### **3. 详细分析**

##### **(1) 4KB - 8KB**
- **适用场景**：
  - **OLTP 数据库**（如 Oracle 默认块大小 8KB）。
  - 高频随机读写的小文件（如日志、索引、元数据）。
- **性能优势**：
  - 随机 I/O 延迟最低，适合频繁更新的小数据块。
  - 与数据库块大小对齐，避免额外 I/O 开销。
- **性能劣势**：
  - 大文件需多次 COW，写放大效应显著。
  - ARC 缓存压力大（需缓存更多小块）。
- **空间效率**：
  - 小文件无浪费，但大文件因碎片化可能浪费空间。

##### **(2) 16KB - 32KB**
- **适用场景**：
  - 混合负载（如虚拟机磁盘、中小型文件存储）。
  - 需要平衡随机与顺序性能的场景。
- **性能优势**：
  - 比 8KB 更适合中等大小文件的顺序读写。
  - 减少 COW 次数，降低写放大。
- **性能劣势**：
  - 对超大文件仍非最优，吞吐量受限。
- **空间效率**：
  - 小文件浪费空间（16KB-32KB/文件）。

##### **(3) 128KB**
- **适用场景**：
  - 通用场景（未明确负载类型时的默认值）。
- **性能优势**：
  - ZFS 默认优化值，兼容性最佳。
  - 对中等大小文件的顺序读写表现均衡。
- **性能劣势**：
  - 大文件碎片化明显，吞吐量低于更大块。
- **空间效率**：
  - 默认空间利用率适中。

##### **(4) 256KB - 512KB**
- **适用场景**：
  - 大文件顺序读写（如视频流、备份文件）。
- **性能优势**：
  - 显著提升顺序读写吞吐量（减少磁盘寻道）。
  - 降低元数据管理开销。
- **性能劣势**：
  - 随机 I/O 延迟高（需读取/写入大块数据）。
  - 内存消耗大（ARC 需缓存大块数据）。
- **空间效率**：
  - 小文件空间浪费（256KB-512KB/文件）。

##### **(5) 1MB - 2MB**
- **适用场景**：
  - 超大文件存储（如 ISO、数据库 dump、虚拟机模板）。
- **性能优势**：
  - 极大提升顺序读写性能（适合机械硬盘和 NVMe）。
  - 几乎消除碎片化，元数据开销最小。
- **性能劣势**：
  - 随机 I/O 性能极差（单次读写需处理 1-2MB 数据）。
  - 内存压力极大（需大容量 RAM 支持）。
- **空间效率**：
  - 小文件空间浪费严重（1-2MB/文件）。

---

#### **4. 与 Oracle 数据库块大小的关联**
- **Oracle 8KB 块**：
  - 与 ZFS 的 8KB `recordsize` 对齐，避免跨块读写。
  - 适合 OLTP 场景（高频随机 I/O）。
- **ZFS 的大块（如 128KB）**：
  - 若 Oracle 数据库使用大表空间（如 16KB 或 32KB 块），ZFS 可设为 128KB 以提升批量查询性能。

---

#### **5. 实际配置建议**
| **数据类型**       | **推荐 recordsize** | **原因** |
|--------------------|---------------------|----------|
| 高清电影、ISO      | 1MB - 2MB           | 大文件顺序读写，降低碎片化 |
| 数据库（OLTP）     | 8KB                 | 与 Oracle 块对齐，优化随机 I/O |
| 虚拟机磁盘（QCOW2）| 16KB - 32KB         | 平衡虚拟机 I/O 特性 |
| 日志文件、小文件   | 4KB - 8KB           | 降低随机写延迟 |
| 视频流、备份       | 256KB - 512KB       | 提升顺序吞吐量 |

---

#### **6. 总结**
| **recordsize** | **随机 I/O 性能** | **顺序 I/O 性能** | **空间效率（小文件）** | **内存消耗** | **适用负载类型** |
|----------------|------------------|-------------------|------------------------|--------------|------------------|
| 4KB - 8KB      | 极高             | 低                | 高                     | 低           | OLTP、小文件 |
| 16KB - 32KB    | 高               | 中                | 中                     | 中           | 混合负载 |
| 128KB          | 中               | 中                | 中                     | 中           | 通用 |
| 256KB - 512KB  | 低               | 高                | 低                     | 高           | 大文件顺序读写 |
| 1MB - 2MB      | 极低             | 极高              | 极低                   | 极高         | 超大文件归档 |

通过合理配置 `recordsize`，可以针对不同数据类型优化存储性能，但需权衡空间利用率和硬件资源（如内存）。

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
