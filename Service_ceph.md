* [目录](#0)
  * [Ceph 常用命令](#1)
  * [初始化一个3节点的ceph mon/mgr集群](#2)
  * [使用cephadm(容器方式)部署reef(v18)环境](#3)
  * [yaml方式创建OSD](#4)


<h3 id="1">Ceph 常用命令</h3>

查看节点 host  
```ceph orch host ls```

```shell
[ceph: root@ceph-mon-mgr-node1 /]# ceph orch host ls
HOST                ADDR             LABELS  STATUS   
X9DR3-F-node1       192.168.100.101  osd     Offline  
X9DR3-F-node2       192.168.100.102  osd              
ceph-mon-mgr-node1  192.168.100.131  _admin           
ceph-mon-mgr-node2  192.168.100.132  _admin           
ceph-mon-mgr-node3  192.168.100.133  _admin           
5 hosts in cluster
[ceph: root@ceph-mon-mgr-node1 /]# 
```

查看一个节点上的磁盘设备  

```ceph orch device ls <节点名称>```  
```ceph orch device ls X9DR3-F-node2```

```shell
[ceph: root@ceph-mon-mgr-node1 /]# ceph orch device ls X9DR3-F-node2
HOST           PATH        TYPE  DEVICE ID                                     SIZE  AVAILABLE  REFRESHED  REJECT REASONS    
X9DR3-F-node2  /dev/md123  hdd                                                7451G  Yes        8m ago                       
X9DR3-F-node2  /dev/md124  ssd                                                 372G  No         8m ago     Has a FileSystem  
X9DR3-F-node2  /dev/md125  ssd                                                 372G  Yes        8m ago                       
X9DR3-F-node2  /dev/sdc    hdd   HGST_HUS724040ALS640_PCGJNWSX                3726G  No         8m ago     Has a FileSystem  
X9DR3-F-node2  /dev/sdd    hdd   ATA_WDC_WD40EZAZ-19SF3B0_WD-WX42DA1PHC31     3726G  No         8m ago     Has a FileSystem  
X9DR3-F-node2  /dev/sde    hdd   HGST_HUS724040ALS640_PCGM7WKX                3726G  No         8m ago     Has a FileSystem  
X9DR3-F-node2  /dev/sdf    hdd   ATA_ST4000DM004-2CV104_ZFN0238P              3726G  No         8m ago     Has a FileSystem  
X9DR3-F-node2  /dev/sdg    ssd   ATA_INTEL_SSDSC2BA400G4_BTHC67210561400HGN    372G  No         8m ago     Has a FileSystem  
X9DR3-F-node2  /dev/sdh    ssd   ATA_INTEL_SSDSC2BA400G4R_BTHV711409JM400NGN   372G  No         8m ago     Has a FileSystem  
X9DR3-F-node2  /dev/sdi    ssd   ATA_INTEL_SSDSC2BA400G4_BTHC67210551400HGN    372G  No         8m ago     Has a FileSystem  
X9DR3-F-node2  /dev/sdj    ssd   ATA_INTEL_SSDSC2BA400G4R_BTHV713001RZ400NGN   372G  No         8m ago     Has a FileSystem  
X9DR3-F-node2  /dev/sdk    ssd   ATA_SSD_1TB_AA210512000000000098              953G  Yes        8m ago                       
X9DR3-F-node2  /dev/sdl    hdd   SEAGATE_ST6000NM0034_Z4D35JLZ                5589G  Yes        8m ago                       
X9DR3-F-node2  /dev/sdm    hdd   SEAGATE_ST6000NM0034_Z4D35PW60000R607QZJD    5589G  Yes        8m ago                       
X9DR3-F-node2  /dev/sdn    hdd   SEAGATE_ST6000NM0034_S4D0J045                5589G  Yes        8m ago                       
X9DR3-F-node2  /dev/sdo    hdd   HGST_HUS726060ALS640_1EGX44GC                5589G  Yes        8m ago                       
X9DR3-F-node2  /dev/sdp    hdd   HGST_H7240AS60SUN4.0T_001416EH2TBX_PBJH2TBX  3726G  Yes        8m ago                       
X9DR3-F-node2  /dev/sdq    hdd   HGST_H7240AS60SUN4.0T_001403E9M1LX_PBH9M1LX  3726G  Yes        8m ago                       
X9DR3-F-node2  /dev/sdr    ssd   ATA_INTEL_SSDSC2BA400G4R_BTHV713001QS400NGN   372G  Yes        8m ago        
```

查看节点健康状态详情

```ceph health detail```

```shell
[ceph: root@ceph-mon-mgr-node1 /]# ceph health detail 
HEALTH_WARN 1 hosts fail cephadm check; OSD count 0 < osd_pool_default_size 3
[WRN] CEPHADM_HOST_CHECK_FAILED: 1 hosts fail cephadm check
    host X9DR3-F-node1 (192.168.100.101) failed check: Can't communicate with remote host `192.168.100.101`, possibly because the host is not reachable or python3 is not installed on the host. [Errno 113] Connect call failed ('192.168.100.101', 22)
[WRN] TOO_FEW_OSDS: OSD count 0 < osd_pool_default_size 3
[ceph: root@ceph-mon-mgr-node1 /]# 
```

ceph 集群整体日志  
```ceph -w```

查看实时后台  
```ceph log last cephadm```

查看 OSD 列表  
```ceph osd tree```

添加 label 标签  
```ceph orch host label add <节点名称> <标签>```  
```ceph orch host label add X9DR3-F-node1 osd```

添加一个节点 host  
```ceph orch host add <节点名称> <IP地址>```
```shell
[root@ceph-mon-mgr-node1 ~]# ceph orch host add X9DR3-F-node2 192.168.100.102
Added host 'X9DR3-F-node2' with addr '192.168.100.102'
```

删除某个 OSD, <font color=red>慎重</font>

```shell
# 1. 移除这个手动创建的空壳 OSD,  0是它的ID
ceph osd purge 0 --yes-i-really-mean-it

# 2. 删除之前的服务定义，确保重头开始
ceph orch rm osd.custom_node1_osds
```

<h3 id="2">初始化一个3节点的 ceph mon/mgr 集群</h3>

- 入坑的一个小结, 内容可能遗漏
- 记录时使用的仍是传统部署方式, 但官方从v15版本开始早已主推cephadm, 也就是容器化方式

在此轮测试中, 用到的ceph的相关包的版本情况

```shell
[root@ceph-mon-mgr-node1 ~]# rpm -qa | grep -i ceph
ceph-release-1-1.el9.noarch
libcephfs2-18.2.7-0.el9.x86_64
python3-ceph-argparse-18.2.7-0.el9.x86_64
python3-cephfs-18.2.7-0.el9.x86_64
libcephsqlite-18.2.7-0.el9.x86_64
cephadm-18.2.7-0.el9.noarch
ceph-prometheus-alerts-18.2.7-0.el9.noarch
ceph-grafana-dashboards-18.2.7-0.el9.noarch
python3-ceph-common-18.2.7-0.el9.x86_64
ceph-common-18.2.7-0.el9.x86_64
ceph-base-18.2.7-0.el9.x86_64
ceph-selinux-18.2.7-0.el9.x86_64
ceph-mgr-cephadm-18.2.7-0.el9.noarch
ceph-mgr-dashboard-18.2.7-0.el9.noarch
ceph-mgr-diskprediction-local-18.2.7-0.el9.noarch
ceph-mgr-k8sevents-18.2.7-0.el9.noarch
ceph-mgr-modules-core-18.2.7-0.el9.noarch
ceph-mgr-18.2.7-0.el9.x86_64
ceph-mgr-rook-18.2.7-0.el9.noarch
ceph-mon-18.2.7-0.el9.x86_64
```

| 命令                                                                                                                                                             | 目的与作用                                                                                                                               |
|:---------------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------| 
| /etc/ceph/ceph.conf                                                                                                                                            | 全局控制中心。至少需包含 fsid（集群唯一标识）、mon_host（入口地址）、auth（认证开关）。它告诉所有进程“我是谁、我在哪、我信谁”。                                                           |
| /etc/ceph/ceph.mon.keyring                                                                                                                                     | MON 节点的身份证。它是 MON 守护进程之间互相认证的共享密钥。没有它，MON 无法加入选举，也无法在 RocksDB 中建立最初的安全信任。                                                           |
| monmaptool --create ...                                                                                                                                        | 创建空白蓝图。初始化一个空的二进制 monmap 文件，并绑定这个集群唯一的 fsid。这是集群“创世纪”的第一步。                                                                          |
| monmaptool --addv mon1 '[v2:...] '                                                                                                                             | 注入节点 DNA。将具体的节点名称、IP 地址、以及 多协议端口（3300+6789） 写入二进制蓝图。这决定了 MON 启动后“听”哪个端口，以及“找”谁去投票。                                                  |
| monmaptool --print                                                                                                                                             | 将二进制的 monmap 转换为人类可读文本，用于确认 min_mon_release（版本兼容性）和地址向量是否正确。                                                                        |
| sudo -u ceph ceph-mon ... --mkfs                                                                                                                               | 数据目录初始化。这是物理落地的关键。它读取 monmap 和 keyring，在 /var/lib/ceph/mon/ 下创建 RocksDB 数据库并写入初始状态信息。使用 sudo -u ceph 是为了确保生成的数据库文件从第一秒起就属于 ceph 用户。 |

1) /etc/ceph/ceph.conf 的最小化示例

```shell
[root@ceph-mon-mgr-node1 ~]# cat /etc/ceph/ceph.conf 
[global]
fsid = 49bf88d1-b9b4-48f4-a008-c302ce92d0e7

mon initial members = mon1,mon2,mon3
mon_host = [v2:192.168.100.131:3300,v1:192.168.100.131:6789],[v2:192.168.100.132:3300,v1:192.168.100.132:6789],[v2:192.168.100.133:3300,v1:192.168.100.133:6789]

public network = 192.168.100.0/19

auth cluster required = cephx
auth service required = cephx
auth client required = cephx

osd pool default size = 3
osd pool default min size = 2

mon allow pool delete = false

ms_bind_msgr2 = true
ms_bind_msgr1 = true
```

2) /etc/ceph/ceph.mon.keyring 内容创建

在手动部署 Ceph 时，创建 `ceph.mon.keyring` 是最关键的步骤之一，因为它包含了 Monitor 节点之间通信所需的共享密钥。如果密钥权限或内容不对，MON 节点将无法达成共识（Quorum）。

以下是创建该文件的标准流程及命令详解：

---

##### 1. 创建 Monitor 密钥环的步骤

通常我们在 **Node1** 上生成，然后分发到其他节点。

###### 第一步：生成临时密钥环并生成密钥

```bash
# 1. 创建一个临时的密钥环文件，并为 mon. 生成随机密钥
ceph-authtool --create-keyring /etc/ceph/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'

```

* **`--create-keyring`**: 指定文件路径。
* **`--gen-key -n mon.`**: 生成名为 `mon.` 的实体密钥。
* **`--cap mon 'allow *'`**: 赋予该密钥管理 Monitor 的所有权限。

###### 第二步：导入管理员（Admin）密钥（可选但推荐）

为了方便后续操作，通常会将 `client.admin` 的密钥也放进去，这样 MON 在初始化时就知道了管理员是谁。

```bash
# 生成管理员密钥并存入 client.admin.keyring
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'

# 将管理员密钥导入到 mon.keyring 中
ceph-authtool /etc/ceph/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring

```

###### 第三步：设置权限（极其重要）

Ceph 守护进程以 `ceph` 用户运行，如果不修改权限，`mkfs` 或服务启动时会因为读不到密钥而 **Core Dump**。

```bash
chown ceph:ceph /etc/ceph/ceph.mon.keyring
chmod 600 /etc/ceph/ceph.mon.keyring

```

---

##### 2. 文档补充：这些命令究竟在做什么？

| 命令/动作 | 文档描述（作用） |
| --- | --- |
| **`ceph-authtool --create-keyring`** | **创建保险库**：初始化一个符合 Ceph 认证格式的二进制文件。 |
| **`--gen-key -n mon.`** | **刻录印章**：产生一个唯一的、不可逆的 Base64 字符串作为身份凭证，用于 MON 节点间的身份识别。 |
| **`--cap mon 'allow *'`** | **授权范围**：在密钥环中定义该密钥的权限（Capability）。`allow *` 意味着拥有该密钥的进程可以完全控制 Monitor 存储库。 |
| **`--import-keyring`** | **信任传递**：将其他实体的密钥（如 admin）合并进来，使得 MON 在 mkfs 落地时，其 RocksDB 数据库里就已经预存了这些信任关系。 |

---

##### 3. Keyring 的内容格式预览

虽然它是二进制或特定格式，但你可以用 `cat` 查看其文本表现形式，大概长这样：

```ini
[mon.]
    key = AQB... (一串加密字符)
    caps mon = "allow *"
[client.admin]
    key = AQC... (一串加密字符)
    auid = 0
    caps mds = "allow *"
    caps mgr = "allow *"
    caps mon = "allow *"
    caps osd = "allow *"
```

---

##### 4. 手动部署 vs Cephadm

* **手动部署**：你必须先有这个文件，才能执行 `ceph-mon --mkfs`。它是先于数据库存在的。
* **Cephadm**：当你执行 `bootstrap` 时，`cephadm` 会在容器内自动跑完上述所有 `ceph-authtool` 命令，并将结果提取到宿主机的 `/etc/ceph` 目录下。

3) monmaptool 的几个命令

- fsid 是由 uuidgen 生成, 用作这个集群的唯一标识
- 用数组 [v2:xxxx] 的形式写入, 这才是让 monmaptool 写入v2地址的正解, 而shell环境下还有单引号''转义的细节需要注意
- 默认使用 v2 地址（3300 端口） 作为首选通信协议是从 Ceph v15 (Octopus) 版本正式开始的

```shell
monmaptool --create --fsid 49bf88d1-b9b4-48f4-a008-c302ce92d0e7 /tmp/monmap.v2

# 分次添加，并对地址向量加单引号
monmaptool --addv mon1 '[v2:192.168.100.131:3300,v1:192.168.100.131:6789]' /tmp/monmap.v2
monmaptool --addv mon2 '[v2:192.168.100.132:3300,v1:192.168.100.132:6789]' /tmp/monmap.v2
monmaptool --addv mon3 '[v2:192.168.100.133:3300,v1:192.168.100.133:6789]' /tmp/monmap.v2

# 启用 msgr2 并检查
monmaptool --enable-msgr2 /tmp/monmap.v2
monmaptool --print /tmp/monmap.v2
```

4) ceph 的 mkfs 补充示例

```shell
# --- 1. 物理环境清理与目录预设 ---
# 确保目录存在且为空
rm -rf /var/lib/ceph/mon/ceph-mon1/*
mkdir -p /var/lib/ceph/mon/ceph-mon1

# --- 2. 权限预设（这是防止 Core Dump 的关键） ---
# 必须先让 ceph 用户拥有该目录，后续 mkfs 才能以 ceph 身份写入 RocksDB
chown -R ceph:ceph /var/lib/ceph/mon/ceph-mon1
chown ceph:ceph /etc/ceph/ceph.mon.keyring

# --- 3. 执行 mkfs 初始化 ---
# 使用 sudo -u ceph 确保生成的所有数据库文件（RocksDB）物理所有权属于 ceph 用户
sudo -u ceph ceph-mon --mkfs \
    --cluster ceph \
    --id mon1 \
    --monmap /tmp/monmap.v2 \
    --keyring /etc/ceph/ceph.mon.keyring

# --- 4. 验证初始化结果 ---
# 检查后端是否正确识别为 rocksdb
cat /var/lib/ceph/mon/ceph-mon1/kv_backend
# 检查是否生成了策略文件
ls -l /var/lib/ceph/mon/ceph-mon1/store.db
```

额外的  
如果配置确认修改无误,但 systemctl restart 之后再 status ceph-mon@mon1.service 服务存在启动失败

```shell
[root@ceph-mon-mgr-node1 ~]# systemctl status ceph-mon@mon1.service
× ceph-mon@mon1.service - Ceph cluster monitor daemon
     Loaded: loaded (/usr/lib/systemd/system/ceph-mon@.service; enabled; preset: disabled)
     Active: failed (Result: core-dump) since Sun 2026-01-04 14:34:54 CST; 15min ago
   Duration: 194ms
    Process: 3137230 ExecStart=/usr/bin/ceph-mon -f --cluster ${CLUSTER} --id mon1 --setuser ceph --setgroup ceph (code=dumped, signal=ABRT)
   Main PID: 3137230 (code=dumped, signal=ABRT)
        CPU: 50ms

Jan 04 14:34:54 ceph-mon-mgr-node1 systemd[1]: ceph-mon@mon1.service: Scheduled restart job, restart counter is at 5.
Jan 04 14:34:54 ceph-mon-mgr-node1 systemd[1]: Stopped Ceph cluster monitor daemon.
Jan 04 14:34:54 ceph-mon-mgr-node1 systemd[1]: ceph-mon@mon1.service: Start request repeated too quickly.
Jan 04 14:34:54 ceph-mon-mgr-node1 systemd[1]: ceph-mon@mon1.service: Failed with result 'core-dump'.
Jan 04 14:34:54 ceph-mon-mgr-node1 systemd[1]: Failed to start Ceph cluster monitor daemon.
Jan 04 14:35:52 ceph-mon-mgr-node1 systemd[1]: ceph-mon@mon1.service: Start request repeated too quickly.
Jan 04 14:35:52 ceph-mon-mgr-node1 systemd[1]: ceph-mon@mon1.service: Failed with result 'core-dump'.
Jan 04 14:35:52 ceph-mon-mgr-node1 systemd[1]: Failed to start Ceph cluster monitor daemon.
[root@ceph-mon-mgr-node1 ~]# systemctl start ceph-mon@mon1.service 
Job for ceph-mon@mon1.service failed because a fatal signal was delivered causing the control process to dump core.
See "systemctl status ceph-mon@mon1.service" and "journalctl -xeu ceph-mon@mon1.service" for details.
[root@ceph-mon-mgr-node1 ~]#
```

则正解可能是重置systemd 的失败计数和状态

```shell
# 1. 重置 systemd 的失败计数和状态
systemctl reset-failed ceph-mon@mon1.service

# 2. 确保权限万无一失（特别是 mkfs 之后）
chown -R ceph:ceph /var/lib/ceph/mon/ceph-mon1

# 3. 再次尝试启动
systemctl start ceph-mon@mon1.service

# 4. 查看最新状态
systemctl status ceph-mon@mon1.service
```

<h3 id="3">使用cephadm(容器方式)部署环境</h3>

行文时的```reef```版本为v18.2.7

```shell
# 在所有节点执行
ansible ceph -m shell -a 'dnf install -y rocky-release-storage-reef'
ansible ceph -m shell -a 'dnf makecache'
ansible ceph -m shell -a 'dnf install -y cephadm ceph-common podman lvm2'
```

其中第一步的 ```ceph``` 的软件仓库, 可以用阿里的

```shell
[root@ceph-mon-mgr-node1 ~]# cat /Code/private/dev/linux_common_lib/ceph/ceph-reef-aliyun.repo
# 写入 /etc/yum.repos.d/ceph.repo
[ceph]
name=Ceph packages for x86_64
baseurl=https://mirrors.aliyun.com/ceph/rpm-reef/el9/x86_64/
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://mirrors.aliyun.com/ceph/rpm-reef/el9/noarch/
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
```

被安装的软件列表

```shell
ceph-mon-mgr-node3 | CHANGED | rc=0 >>
Last metadata expiration check: 0:00:21 ago on Mon 05 Jan 2026 03:11:58 PM CST.
Package podman-6:5.6.0-9.el9_7.x86_64 is already installed.
Package lvm2-9:2.03.32-2.el9_7.1.x86_64 is already installed.
Dependencies resolved.
================================================================================
 Package                  Arch      Version                Repository      Size
================================================================================
Installing:
 ceph-common              x86_64    2:18.2.7-0.el9         ceph            18 M
 cephadm                  noarch    2:18.2.7-0.el9         ceph-noarch    226 k
Installing dependencies:
 boost-program-options    x86_64    1.75.0-13.el9_7        appstream      104 k
 daxctl-libs              x86_64    78-2.el9               baseos          41 k
 gperftools-libs          x86_64    2.9.1-3.el9            epel           308 k
 libarrow                 x86_64    9.0.0-14.el9           epel           4.4 M
 libarrow-doc             noarch    9.0.0-14.el9           epel            25 k
 libcephfs2               x86_64    2:18.2.7-0.el9         ceph           710 k
 liboath                  x86_64    2.6.12-1.el9           epel            49 k
 libpmem                  x86_64    1.12.1-1.el9           appstream      111 k
 libpmemobj               x86_64    1.12.1-1.el9           appstream      159 k
 librabbitmq              x86_64    0.11.0-7.el9           appstream       44 k
 librados2                x86_64    2:18.2.7-0.el9         ceph           3.3 M
 libradosstriper1         x86_64    2:18.2.7-0.el9         ceph           475 k
 librbd1                  x86_64    2:18.2.7-0.el9         ceph           3.0 M
 librdkafka               x86_64    1.6.1-102.el9          appstream      662 k
 librdmacm                x86_64    57.0-2.el9             baseos          70 k
 librgw2                  x86_64    2:18.2.7-0.el9         ceph           4.5 M
 libunwind                x86_64    1.6.2-1.el9            epel            67 k
 lttng-ust                x86_64    2.12.0-6.el9           appstream      282 k
 ndctl-libs               x86_64    78-2.el9               baseos          89 k
 parquet-libs             x86_64    9.0.0-14.el9           epel           838 k
 python3-ceph-argparse    x86_64    2:18.2.7-0.el9         ceph            45 k
 python3-ceph-common      x86_64    2:18.2.7-0.el9         ceph           130 k
 python3-cephfs           x86_64    2:18.2.7-0.el9         ceph           162 k
 python3-prettytable      noarch    0.7.2-27.el9.0.1       appstream       41 k
 python3-rados            x86_64    2:18.2.7-0.el9         ceph           322 k
 python3-rbd              x86_64    2:18.2.7-0.el9         ceph           302 k
 python3-rgw              x86_64    2:18.2.7-0.el9         ceph           100 k
 re2                      x86_64    1:20211101-20.el9      epel           191 k
 thrift                   x86_64    0.15.0-4.el9           epel           1.6 M

Transaction Summary
================================================================================
Install  31 Packages

Total download size: 41 M
Installed size: 151 M
```

为 ```podman``` 配置代理--在RHEL家族发行版, ```podman```会替代```docker```作为默认runtime

```shell
[root@ceph-mon-mgr-node1 ~]# cat /Code/private/dev/linux_common_lib/ceph/podman_config_image_pull_use_proxy.sh 
# 创建 Podman 服务配置目录
proxy_ip_port="192.168.100.40:8000"
mkdir -p /etc/systemd/system/podman.service.d/
cat <<EOF > /etc/systemd/system/podman.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://$proxy_ip_port"
Environment="HTTPS_PROXY=http://$proxy_ip_port"
EOF
systemctl daemon-reload
systemctl restart podman
[root@ceph-mon-mgr-node1 ~]# 
```

提前 pull 好 ceph 的 image

```shell
# 1. 核心镜像 (这是重头戏)
podman pull quay.io/ceph/ceph:v18.2.7

# 2. 辅助组件 (Cephadm 会自动调用这些)
podman pull quay.io/ceph/ceph-grafana:9.4.7
podman pull quay.io/prometheus/prometheus:v2.43.0
podman pull quay.io/prometheus/node-exporter:v1.5.0
podman pull quay.io/prometheus/alertmanager:v0.25.0
```

执行结果

```shell
[root@docker-node1 ~]# ansible ceph -m shell -a 'podman image ls '
ceph-mon-mgr-node3 | CHANGED | rc=0 >>
REPOSITORY                        TAG         IMAGE ID      CREATED       SIZE
quay.io/ceph/ceph                 v18.2.7     0f5473a1e726  8 months ago  1.27 GB
quay.io/ceph/ceph-grafana         9.4.7       954c08fa6188  2 years ago   647 MB
quay.io/prometheus/prometheus     v2.43.0     a07b618ecd1d  2 years ago   235 MB
quay.io/prometheus/node-exporter  v1.5.0      0da6a335fe13  3 years ago   23.9 MB
ceph-mon-mgr-node2 | CHANGED | rc=0 >>
REPOSITORY                        TAG         IMAGE ID      CREATED       SIZE
quay.io/ceph/ceph                 v18.2.7     0f5473a1e726  8 months ago  1.27 GB
quay.io/ceph/ceph-grafana         9.4.7       954c08fa6188  2 years ago   647 MB
quay.io/prometheus/prometheus     v2.43.0     a07b618ecd1d  2 years ago   235 MB
quay.io/prometheus/node-exporter  v1.5.0      0da6a335fe13  3 years ago   23.9 MB
ceph-mon-mgr-node1 | CHANGED | rc=0 >>
REPOSITORY                        TAG         IMAGE ID      CREATED       SIZE
quay.io/ceph/ceph                 v18.2.7     0f5473a1e726  8 months ago  1.27 GB
quay.io/ceph/ceph-grafana         9.4.7       954c08fa6188  2 years ago   647 MB
quay.io/prometheus/prometheus     v2.43.0     a07b618ecd1d  2 years ago   235 MB
quay.io/prometheus/node-exporter  v1.5.0      0da6a335fe13  3 years ago   23.9 MB
[root@docker-node1 ~]# ansible ceph -m shell -a 'cephadm version;ceph --version'
ceph-mon-mgr-node1 | CHANGED | rc=0 >>
cephadm version 18.2.7 (6b0e988052ec84cf2d4a54ff9bbbc5e720b621ad) reef (stable)
ceph version 18.2.7 (6b0e988052ec84cf2d4a54ff9bbbc5e720b621ad) reef (stable)
ceph-mon-mgr-node3 | CHANGED | rc=0 >>
cephadm version 18.2.7 (6b0e988052ec84cf2d4a54ff9bbbc5e720b621ad) reef (stable)
ceph version 18.2.7 (6b0e988052ec84cf2d4a54ff9bbbc5e720b621ad) reef (stable)
ceph-mon-mgr-node2 | CHANGED | rc=0 >>
cephadm version 18.2.7 (6b0e988052ec84cf2d4a54ff9bbbc5e720b621ad) reef (stable)
ceph version 18.2.7 (6b0e988052ec84cf2d4a54ff9bbbc5e720b621ad) reef (stable)
[root@docker-node1 ~]# 
```

cephadm bootstrap 的执行记录

```shell
[root@ceph-mon-mgr-node1 ~]# cephadm bootstrap --mon-ip 192.168.100.131 \
    --initial-dashboard-user admin \
    --initial-dashboard-password admin \
    --skip-pull
Verifying podman|docker is present...
Verifying lvm2 is present...
Verifying time synchronization is in place...
Unit chronyd.service is enabled and running
Repeating the final host check...
podman (/usr/bin/podman) version 5.6.0 is present
systemctl is present
lvcreate is present
Unit chronyd.service is enabled and running
Host looks OK
Cluster fsid: eb07238a-ea0f-11f0-97ea-52540083ebf9
Verifying IP 192.168.100.131 port 3300 ...
Verifying IP 192.168.100.131 port 6789 ...
Mon IP `192.168.100.131` is in CIDR network `192.168.96.0/19`
Mon IP `192.168.100.131` is in CIDR network `192.168.96.0/19`
Internal network (--cluster-network) has not been provided, OSD replication will default to the public_network
Ceph version: ceph version 18.2.7 (6b0e988052ec84cf2d4a54ff9bbbc5e720b621ad) reef (stable)
Extracting ceph user uid/gid from container image...
Creating initial keys...
Creating initial monmap...
Creating mon...
Waiting for mon to start...
Waiting for mon...
mon is available
Assimilating anything we can from ceph.conf...
Generating new minimal ceph.conf...
Restarting the monitor...
Setting public_network to 192.168.96.0/19 in global config section
Wrote config to /etc/ceph/ceph.conf
Wrote keyring to /etc/ceph/ceph.client.admin.keyring
Creating mgr...
Verifying port 0.0.0.0:9283 ...
Verifying port 0.0.0.0:8765 ...
Verifying port 0.0.0.0:8443 ...
Waiting for mgr to start...
Waiting for mgr...
mgr not available, waiting (1/15)...
mgr not available, waiting (2/15)...
mgr not available, waiting (3/15)...
mgr not available, waiting (4/15)...
mgr not available, waiting (5/15)...
mgr not available, waiting (6/15)...
mgr is available
Enabling cephadm module...
Waiting for the mgr to restart...
Waiting for mgr epoch 5...
mgr epoch 5 is available
Setting orchestrator backend to cephadm...
Generating ssh key...
Wrote public SSH key to /etc/ceph/ceph.pub
Adding key to root@localhost authorized_keys...
Adding host ceph-mon-mgr-node1...
Deploying mon service with default placement...
Deploying mgr service with default placement...
Deploying crash service with default placement...
Deploying ceph-exporter service with default placement...
Deploying prometheus service with default placement...
Deploying grafana service with default placement...
Deploying node-exporter service with default placement...
Deploying alertmanager service with default placement...
Enabling the dashboard module...
Waiting for the mgr to restart...
Waiting for mgr epoch 9...
mgr epoch 9 is available
Generating a dashboard self-signed certificate...
Creating initial admin user...
Fetching dashboard port number...
Ceph Dashboard is now available at:

	     URL: https://ceph-mon-mgr-node1:8443/
	    User: admin
	Password: admin

Enabling client.admin keyring and conf on hosts with "admin" label
Saving cluster configuration to /var/lib/ceph/eb07238a-ea0f-11f0-97ea-52540083ebf9/config directory
Enabling autotune for osd_memory_target
You can access the Ceph CLI as following in case of multi-cluster or non-default config:

	sudo /usr/sbin/cephadm shell --fsid eb07238a-ea0f-11f0-97ea-52540083ebf9 -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

Or, if you are only running a single cluster on this host:

	sudo /usr/sbin/cephadm shell 

Please consider enabling telemetry to help improve Ceph:

	ceph telemetry on

For more information see:

	https://docs.ceph.com/en/latest/mgr/telemetry/

Bootstrap complete.
[root@ceph-mon-mgr-node1 ~]# podman ps
CONTAINER ID  IMAGE                                                                                      COMMAND               CREATED         STATUS         PORTS       NAMES
66123e661b59  quay.io/ceph/ceph:v18                                                                      -n mon.ceph-mon-m...  4 minutes ago   Up 4 minutes               ceph-eb07238a-ea0f-11f0-97ea-52540083ebf9-mon-ceph-mon-mgr-node1
6e21f52dcad1  quay.io/ceph/ceph:v18                                                                      -n mgr.ceph-mon-m...  4 minutes ago   Up 4 minutes               ceph-eb07238a-ea0f-11f0-97ea-52540083ebf9-mgr-ceph-mon-mgr-node1-bbbyzc
4c4ac4edeeb0  quay.io/ceph/ceph@sha256:1b9158ce28975f95def6a0ad459fa19f1336506074267a4b47c1bd914a00fec0  -n client.ceph-ex...  3 minutes ago   Up 3 minutes               ceph-eb07238a-ea0f-11f0-97ea-52540083ebf9-ceph-exporter-ceph-mon-mgr-node1
c705c52f9621  quay.io/ceph/ceph@sha256:1b9158ce28975f95def6a0ad459fa19f1336506074267a4b47c1bd914a00fec0  -n client.crash.c...  3 minutes ago   Up 3 minutes               ceph-eb07238a-ea0f-11f0-97ea-52540083ebf9-crash-ceph-mon-mgr-node1
e869a071243a  quay.io/prometheus/node-exporter:v1.5.0                                                    --no-collector.ti...  3 minutes ago   Up 3 minutes   9100/tcp    ceph-eb07238a-ea0f-11f0-97ea-52540083ebf9-node-exporter-ceph-mon-mgr-node1
09461489a7ba  quay.io/prometheus/prometheus:v2.43.0                                                      --config.file=/et...  51 seconds ago  Up 51 seconds  9090/tcp    ceph-eb07238a-ea0f-11f0-97ea-52540083ebf9-prometheus-ceph-mon-mgr-node1
d951443c6cd2  quay.io/prometheus/alertmanager:v0.25.0                                                    --cluster.listen-...  30 seconds ago  Up 31 seconds  9093/tcp    ceph-eb07238a-ea0f-11f0-97ea-52540083ebf9-alertmanager-ceph-mon-mgr-node1
a12469b3ff09  quay.io/ceph/ceph-grafana:9.4.7                                                            /bin/bash             28 seconds ago  Up 29 seconds  3000/tcp    ceph-eb07238a-ea0f-11f0-97ea-52540083ebf9-grafana-ceph-mon-mgr-node1
[root@ceph-mon-mgr-node1 ~]# 
```

此时的 Web UI 可用  
继续添加另两个计划中的 mon/mgr 节点  

让第一个节点, 也就是我这里的node1, 免密登录另外两个节点--实际上原本我也有此配置, 实际上是多添加了一个密钥

```shell
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.132
ssh-copy-id -f -i /etc/ceph/ceph.pub root@192.168.100.133
```

让 node1 在 ceph 集群里添加这两个主机

```shell
ceph orch host add ceph-mon-mgr-node2 192.168.100.132
ceph orch host add ceph-mon-mgr-node3 192.168.100.133

# 让 MON 跑在这三个指定的节点上
ceph orch apply mon --placement="3 ceph-mon-mgr-node1 ceph-mon-mgr-node2 ceph-mon-mgr-node3"

# 在 131, 132, 133 上各跑一个 MGR，共 3 个，系统会自动选一个 Active
ceph orch apply mgr --placement="3 ceph-mon-mgr-node1 ceph-mon-mgr-node2 ceph-mon-mgr-node3"
```

如何验证部署结果？

```shell
[ceph: root@ceph-mon-mgr-node1 /]# ceph mgr stat
# 你会看到类似：{ "active_name": "ceph-mon-mgr-node1...", "standbys": ["node2...", "node3..."] }

[ceph: root@ceph-mon-mgr-node1 /]# ceph orch ps --daemon_type mgr
# 你会看到三个节点上各有一个 mgr 守护进程正在运行 (running)
```

实际如下

```shell
ceph orch apply mon --placement="3 ceph-mon-mgr-node1 ceph-mon-mgr-node2 ceph-mon-mgr-node3"
Scheduled mon update...
[ceph: root@ceph-mon-mgr-node1 /]# # 在 131, 132, 133 上各跑一个 MGR，共 3 个，系统会自动选一个 Active
ceph orch apply mgr --placement="3 ceph-mon-mgr-node1 ceph-mon-mgr-node2 ceph-mon-mgr-node3"
Scheduled mgr update...
[ceph: root@ceph-mon-mgr-node1 /]# ceph mgr stat
{
    "epoch": 18,
    "available": true,
    "active_name": "ceph-mon-mgr-node1.bbbyzc",
    "num_standby": 1
}
[ceph: root@ceph-mon-mgr-node1 /]# ceph mgr stat
{
    "epoch": 19,
    "available": true,
    "active_name": "ceph-mon-mgr-node1.bbbyzc",
    "num_standby": 2
}
[ceph: root@ceph-mon-mgr-node1 /]# ceph orch ps --daemon_type mgr
NAME                           HOST                PORTS             STATUS         REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID  
mgr.ceph-mon-mgr-node1.bbbyzc  ceph-mon-mgr-node1  *:9283,8765,8443  running (4h)     33s ago   4h     567M        -  18.2.7   0f5473a1e726  6e21f52dcad1  
mgr.ceph-mon-mgr-node2.zerdtl  ceph-mon-mgr-node2  *:8443,9283,8765  running (3m)    111s ago   3m     494M        -  18.2.7   0f5473a1e726  a9e82c0a24d2  
mgr.ceph-mon-mgr-node3.ivvyde  ceph-mon-mgr-node3  *:8443,9283,8765  running (37s)    36s ago  37s    40.9M        -  18.2.7   0f5473a1e726  77dd96fb90ad  
[ceph: root@ceph-mon-mgr-node1 /]# ceph orch ps --daemon_type mgr
NAME                           HOST                PORTS             STATUS         REFRESHED  AGE  MEM USE  MEM LIM  VERSION  IMAGE ID      CONTAINER ID  
mgr.ceph-mon-mgr-node1.bbbyzc  ceph-mon-mgr-node1  *:9283,8765,8443  running (4h)     11s ago   4h     572M        -  18.2.7   0f5473a1e726  6e21f52dcad1  
mgr.ceph-mon-mgr-node2.zerdtl  ceph-mon-mgr-node2  *:8443,9283,8765  running (23m)    73s ago  23m     501M        -  18.2.7   0f5473a1e726  a9e82c0a24d2  
mgr.ceph-mon-mgr-node3.ivvyde  ceph-mon-mgr-node3  *:8443,9283,8765  running (20m)    11s ago  20m     502M        -  18.2.7   0f5473a1e726  77dd96fb90ad  
[ceph: root@ceph-mon-mgr-node1 /]# 
```


### 在集群构建后的网络调整修改

```shell
# 进入 cephadm shell
cephadm shell

# 设置公共网段（通常是你 bootstrap 所在的网段）
ceph config set global public_network 192.168.96.0/19

# 设置集群网段（假设你为 OSD 准备的内网是 10.10.10.0/24）
ceph config set global cluster_network 10.10.10.0/24
```

<h3 id="4">yaml方式创建OSD</h3>

流程简要概述: 
1) 先建好LV(不应有任何文件系统) 
2) yaml 文件编辑 
3) apply 应用 yaml

补充说明: 为什么先建好LV?  
适用于的场景:  
HDD是OSD, SSD用作WAL/DB   
同时, SSD又是划分成了X份, 而非全部空间用所做一个WAL/DB  
故此, 一个块设备划分成多个LV, 是首选方式

同时, ceph 也并不接受分区  

```shell
/usr/bin/podman: stderr ceph-volume lvm batch: error: /dev/sdo3 is a partition, please pass LVs or raw block devices
```


yaml 文件案例, OSD + db 一同创建

```shell
[ceph: root@ceph-mon-mgr-node1 /]# cat osd_spec.yaml 
service_type: osd
service_id: node1_14t_osd
placement:
  hosts:
    - X9DR3-F-node1
spec:
  data_devices:
    paths:
      - /dev/sdp
  db_devices:
    paths:
      - /dev/vg_osd_db_14t/lv_db_14t
---
service_type: osd
service_id: node1_hdd_cluster
placement:
  hosts:
    - X9DR3-F-node1
spec:
  data_devices:
    paths:
      - /dev/sde
      - /dev/sdf
      - /dev/sdg
      - /dev/sdm
      - /dev/sdq
  db_devices:
    paths:
      - /dev/vg_osd_db_4t/lv_db_hdd_1
      - /dev/vg_osd_db_4t/lv_db_hdd_2
      - /dev/vg_osd_db_4t/lv_db_hdd_3
      - /dev/vg_osd_db_4t/lv_db_hdd_4
      - /dev/vg_osd_db_4t/lv_db_hdd_5
```

应用 yaml 文件

```shell
ceph orch apply osd -i osd_spec.yaml
```

核对 OSD 与 db 设备的对应关系, 注意:  
```ceph-volume lvm list``` 是在OSD的物理机上执行的

```shell
[root@X9DR3-F-node1 ~]# ceph-volume lvm list


====== osd.0 =======

  [block]       /dev/ceph-52cc5018-4941-4e99-8d37-5ab14c12a4e4/osd-block-8ebee487-4f0e-48bb-99ca-bee74d125854

      block device              /dev/ceph-52cc5018-4941-4e99-8d37-5ab14c12a4e4/osd-block-8ebee487-4f0e-48bb-99ca-bee74d125854
      block uuid                lYTDVt-bcV9-7Epb-gir5-TH0L-1QLd-07TCwm
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_14t/lv_db_14t
      db uuid                   gmt4vE-YHoj-GQBc-svK2-togs-LB2i-c2j9lv
      encrypted                 0
      osd fsid                  8ebee487-4f0e-48bb-99ca-bee74d125854
      osd id                    0
      osdspec affinity          node1_14t_osd
      type                      block
      vdo                       0
      devices                   /dev/sdp

  [db]          /dev/vg_osd_db_14t/lv_db_14t

      block device              /dev/ceph-52cc5018-4941-4e99-8d37-5ab14c12a4e4/osd-block-8ebee487-4f0e-48bb-99ca-bee74d125854
      block uuid                lYTDVt-bcV9-7Epb-gir5-TH0L-1QLd-07TCwm
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_14t/lv_db_14t
      db uuid                   gmt4vE-YHoj-GQBc-svK2-togs-LB2i-c2j9lv
      encrypted                 0
      osd fsid                  8ebee487-4f0e-48bb-99ca-bee74d125854
      osd id                    0
      osdspec affinity          node1_14t_osd
      type                      db
      vdo                       0
      devices                   /dev/md125

====== osd.1 =======

  [block]       /dev/ceph-86a420d7-3a0c-469d-a96b-bb249d86c0b1/osd-block-3a5587b6-b0d6-4311-992c-7dde0daee0dd

      block device              /dev/ceph-86a420d7-3a0c-469d-a96b-bb249d86c0b1/osd-block-3a5587b6-b0d6-4311-992c-7dde0daee0dd
      block uuid                q0vSTs-G3a1-6hS2-tPIo-36sB-u29j-87UlrK
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_5
      db uuid                   FezrvC-OZet-MC1a-yl0a-zTeG-F91v-vE9Vy7
      encrypted                 0
      osd fsid                  3a5587b6-b0d6-4311-992c-7dde0daee0dd
      osd id                    1
      osdspec affinity          node1_hdd_cluster
      type                      block
      vdo                       0
      devices                   /dev/sde

  [db]          /dev/vg_osd_db_4t/lv_db_hdd_5

      block device              /dev/ceph-86a420d7-3a0c-469d-a96b-bb249d86c0b1/osd-block-3a5587b6-b0d6-4311-992c-7dde0daee0dd
      block uuid                q0vSTs-G3a1-6hS2-tPIo-36sB-u29j-87UlrK
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_5
      db uuid                   FezrvC-OZet-MC1a-yl0a-zTeG-F91v-vE9Vy7
      encrypted                 0
      osd fsid                  3a5587b6-b0d6-4311-992c-7dde0daee0dd
      osd id                    1
      osdspec affinity          node1_hdd_cluster
      type                      db
      vdo                       0
      devices                   /dev/md124

====== osd.2 =======

  [block]       /dev/ceph-3654bcea-eba9-479d-b935-18fba19950d8/osd-block-ad5f7f5a-b3c2-4076-8082-91d8612803fa

      block device              /dev/ceph-3654bcea-eba9-479d-b935-18fba19950d8/osd-block-ad5f7f5a-b3c2-4076-8082-91d8612803fa
      block uuid                0APteH-ICZq-IADp-QWB5-6cfe-hzak-3KdlEB
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_4
      db uuid                   oIJBMP-Rf81-Kktf-0kRD-udHf-ATP1-RdSQ3Z
      encrypted                 0
      osd fsid                  ad5f7f5a-b3c2-4076-8082-91d8612803fa
      osd id                    2
      osdspec affinity          node1_hdd_cluster
      type                      block
      vdo                       0
      devices                   /dev/sdf

  [db]          /dev/vg_osd_db_4t/lv_db_hdd_4

      block device              /dev/ceph-3654bcea-eba9-479d-b935-18fba19950d8/osd-block-ad5f7f5a-b3c2-4076-8082-91d8612803fa
      block uuid                0APteH-ICZq-IADp-QWB5-6cfe-hzak-3KdlEB
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_4
      db uuid                   oIJBMP-Rf81-Kktf-0kRD-udHf-ATP1-RdSQ3Z
      encrypted                 0
      osd fsid                  ad5f7f5a-b3c2-4076-8082-91d8612803fa
      osd id                    2
      osdspec affinity          node1_hdd_cluster
      type                      db
      vdo                       0
      devices                   /dev/md124

====== osd.3 =======

  [block]       /dev/ceph-7a827d24-6777-497c-8b79-0461d765aed9/osd-block-d347816f-4739-447b-a397-514becac6a15

      block device              /dev/ceph-7a827d24-6777-497c-8b79-0461d765aed9/osd-block-d347816f-4739-447b-a397-514becac6a15
      block uuid                l0qZ06-X2tV-Cfgs-1HtX-120P-Wg7E-qrNYG2
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_3
      db uuid                   jvzYbm-HloO-gPp9-Cr38-wjJr-79sP-fkD0ZY
      encrypted                 0
      osd fsid                  d347816f-4739-447b-a397-514becac6a15
      osd id                    3
      osdspec affinity          node1_hdd_cluster
      type                      block
      vdo                       0
      devices                   /dev/sdg

  [db]          /dev/vg_osd_db_4t/lv_db_hdd_3

      block device              /dev/ceph-7a827d24-6777-497c-8b79-0461d765aed9/osd-block-d347816f-4739-447b-a397-514becac6a15
      block uuid                l0qZ06-X2tV-Cfgs-1HtX-120P-Wg7E-qrNYG2
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_3
      db uuid                   jvzYbm-HloO-gPp9-Cr38-wjJr-79sP-fkD0ZY
      encrypted                 0
      osd fsid                  d347816f-4739-447b-a397-514becac6a15
      osd id                    3
      osdspec affinity          node1_hdd_cluster
      type                      db
      vdo                       0
      devices                   /dev/md124

====== osd.4 =======

  [block]       /dev/ceph-d6e58dc4-7fb8-47ac-977f-8aa5de7fec77/osd-block-bb402e14-92a9-4e5e-aa9b-e90b0c6474af

      block device              /dev/ceph-d6e58dc4-7fb8-47ac-977f-8aa5de7fec77/osd-block-bb402e14-92a9-4e5e-aa9b-e90b0c6474af
      block uuid                8JNcI4-ss33-Vf4U-1WRN-cH25-1uhr-g0n6Fl
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_2
      db uuid                   WbKOhZ-n9d1-1WmK-akrK-eZOZ-I3Q9-nASH6i
      encrypted                 0
      osd fsid                  bb402e14-92a9-4e5e-aa9b-e90b0c6474af
      osd id                    4
      osdspec affinity          node1_hdd_cluster
      type                      block
      vdo                       0
      devices                   /dev/sdm

  [db]          /dev/vg_osd_db_4t/lv_db_hdd_2

      block device              /dev/ceph-d6e58dc4-7fb8-47ac-977f-8aa5de7fec77/osd-block-bb402e14-92a9-4e5e-aa9b-e90b0c6474af
      block uuid                8JNcI4-ss33-Vf4U-1WRN-cH25-1uhr-g0n6Fl
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_2
      db uuid                   WbKOhZ-n9d1-1WmK-akrK-eZOZ-I3Q9-nASH6i
      encrypted                 0
      osd fsid                  bb402e14-92a9-4e5e-aa9b-e90b0c6474af
      osd id                    4
      osdspec affinity          node1_hdd_cluster
      type                      db
      vdo                       0
      devices                   /dev/md124

====== osd.5 =======

  [block]       /dev/ceph-901d9bc7-417d-4b7c-a40b-1f5c2dc9ae50/osd-block-608bf527-d06d-46d9-9dfe-361eaab17b3e

      block device              /dev/ceph-901d9bc7-417d-4b7c-a40b-1f5c2dc9ae50/osd-block-608bf527-d06d-46d9-9dfe-361eaab17b3e
      block uuid                cFSn46-ikvV-zich-kMTQ-EdQe-D8dv-6hr9KJ
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_1
      db uuid                   LxXjvC-dBoF-cqkb-s5mn-hndT-sZvS-iUlt3O
      encrypted                 0
      osd fsid                  608bf527-d06d-46d9-9dfe-361eaab17b3e
      osd id                    5
      osdspec affinity          node1_hdd_cluster
      type                      block
      vdo                       0
      devices                   /dev/sdq

  [db]          /dev/vg_osd_db_4t/lv_db_hdd_1

      block device              /dev/ceph-901d9bc7-417d-4b7c-a40b-1f5c2dc9ae50/osd-block-608bf527-d06d-46d9-9dfe-361eaab17b3e
      block uuid                cFSn46-ikvV-zich-kMTQ-EdQe-D8dv-6hr9KJ
      cephx lockbox secret      
      cluster fsid              eb07238a-ea0f-11f0-97ea-52540083ebf9
      cluster name              ceph
      crush device class        
      db device                 /dev/vg_osd_db_4t/lv_db_hdd_1
      db uuid                   LxXjvC-dBoF-cqkb-s5mn-hndT-sZvS-iUlt3O
      encrypted                 0
      osd fsid                  608bf527-d06d-46d9-9dfe-361eaab17b3e
      osd id                    5
      osdspec affinity          node1_hdd_cluster
      type                      db
      vdo                       0
      devices                   /dev/md124
[root@X9DR3-F-node1 ~]# 
```