* [目录](#0)
  * [初始化一个3节点的ceph mon/mgr集群](#1)


<h3 id="1">初始化一个3节点的 ceph mon/mgr 集群</h3>

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