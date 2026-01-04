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

```shell
# 1. 创建一个临时的密钥环文件，并为 mon. 生成随机密钥
ceph-authtool --create-keyring /etc/ceph/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
```

- --create-keyring: 指定文件路径。  
- --gen-key -n mon.: 生成名为 mon. 的实体密钥。  
- --cap mon 'allow *': 赋予该密钥管理 Monitor 的所有权限。

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