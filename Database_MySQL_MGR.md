* [目录](#0)
  * [MGR集群 一主多从](#1)

<h3 id="1">MGR集群 一主多从</h3>

MGR, MySQL group replication, 组复制, 后续都简称 ```MGR```

必要背景简介
- 在本节只描述一主多从模式下的情况
- docker部署, 并采取了网络隔离

事前采取了AI大模型的建议, 使用了网络隔离, 且使用的是```macvlan``

**零性能损失原理**：
- Macvlan L2绕过Linux网桥，容器流量直接通过物理接口进出交换机，避免软中断和复制开销。
- 实测性能对比（以10G网络为例）：

  | 网络模式       | 吞吐量 (Gbps) | 延迟 (μs) | CPU占用率 |
  |----------------|---------------|-----------|-----------|
  | Macvlan L2     | 9.98          | 15        | 2%        |
  | 传统Bridge     | 7.2           | 120       | 35%       |
  | Overlay        | 5.5           | 200       | 50%       |

为便于描述与理解, 以下是我的基础信息

| 节点名称       | 宿主机 IP     | 容器 IP (客户端访问) | 容器网络接口类型 | 同步网络 IP (10G/40G) |
|------------|----------------|------------------------|------------------|-------------------------|
| mysql-mgr1 | 192.168.2.31   | 192.168.2.37           | macvlan          | 10.10.0.11              |
| mysql-mgr2 | 192.168.2.32   | 192.168.2.38           | macvlan          | 10.10.0.12              |
| mysql-mgr3 | 192.168.2.33   | 192.168.2.39           | macvlan          | 10.10.0.13              |





错误: 试图配置 ```REPLICATION SOURCE``` 通道(channel)

```commandline
mysql> CHANGE REPLICATION SOURCE TO
    ->   SOURCE_HOST='10.10.0.11',
    ->   SOURCE_PORT=3306,
    ->   FOR CHANNEL 'group_replication_channel';
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'FOR CHANNEL 'group_replication_channel'' at line 4
mysql> SET GLOBAL group_replication_bootstrap_group=ON;
Query OK, 0 rows affected (0.00 sec)
```

错误: 试图```RESET MASTER; ``` 然而这是 MySQL 5.7 以前, 也包括 8.0.2x 以内的版本, 针对传统 master/slave 结构的命令, 在MGR里已弃用

```commandline
mysql> RESET MASTER; 
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'MASTER' at line 1
```

最核心的错误: 从节点的GTID与主节点的不一致

```commandline
mysql> SELECT @@GLOBAL.GTID_EXECUTED;
+----------------------------------------------------------------------------------+
| @@GLOBAL.GTID_EXECUTED                                                           |
+----------------------------------------------------------------------------------+
| 557d7cf6-7371-11f0-8f7d-02420a0a000c:1,
c04d6aa8-7367-11f0-87b0-02420a0a000c:1-4 |
+----------------------------------------------------------------------------------+
1 row in set (0.00 sec)

mysql>  SET GLOBAL GTID_PURGED='2abf7fe3-735f-11f0-8679-02420a0a000b:1-4, fa3fc2ee-7365-11f0-8650-02420a0a000b:1-4';
Query OK, 0 rows affected (0.01 sec)

mysql> SELECT @@GLOBAL.GTID_EXECUTED;
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| @@GLOBAL.GTID_EXECUTED                                                                                                                                               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| 2abf7fe3-735f-11f0-8679-02420a0a000b:1-4,
557d7cf6-7371-11f0-8f7d-02420a0a000c:1,
c04d6aa8-7367-11f0-87b0-02420a0a000c:1-4,
fa3fc2ee-7365-11f0-8650-02420a0a000b:1-4 |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

