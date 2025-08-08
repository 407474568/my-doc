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


**MySQL MGR 新建一个集群的流程归纳总结**

Primary 节点:

1) 清空数据目录(默认位置 /var/lib/mysql), 清空binlog(默认位置与datadir相同)
2) 初始化, 如: ```mysqld --initialize-insecure```, ```--initialize-insecure```是允许mysql root用户密码为空
3) 创建复制通道的用户名和密码
4) 主节点先设置自己为引导节点
5) 启动通道
6) 主节点关闭自己为引导节点
7) 主节点查询自己的 ```GTID_EXECUTED```, 用于从节点设置为跟自己一致

SECONDARY 节点:
1) 同主节点1
2) 同主节点2
3) 使用主节点创建的复制通道的用户名和密码进行复制通道的启动
4) 验证结果

**更详细一点的参考步骤**

Primary 节点:

1) 略, 但需要注意, 初始化时, 不应有"基本配置" 以外的配置项存在于 ```my.cnf```, 需要注释
2) 略
3) 创建复制通道的用户名和密码
```commandline
-- 创建用于组复制恢复的用户
CREATE USER 'repl_user'@'%' IDENTIFIED BY '*qJz0s_!bWgP?FX=';
-- 授予复制权限
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
-- 授予组复制所需的权限
GRANT SELECT ON performance_schema.* TO 'repl_user'@'%';
-- 刷新权限
FLUSH PRIVILEGES;
```
4) 主节点先设置自己为引导节点
```SET GLOBAL group_replication_bootstrap_group=ON;```
5) 启动通道
```commandline
START GROUP_REPLICATION
  USER='repl_user', PASSWORD='*qJz0s_!bWgP?FX=';
```
6) 主节点关闭自己为引导节点, SQL交互从阻塞状态中脱离, 可输入状态就应执行  
```SET GLOBAL group_replication_bootstrap_group=OFF;```
7) 主节点查询自己的 ```GTID_EXECUTED```, 用于从节点设置为跟自己一致  
```SELECT * FROM performance_schema.replication_group_members;```



**比较容易犯的错误的地方**

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

在上面的示例中:  
1) 第一条 ```SELECT @@GLOBAL.GTID_EXECUTED;``` 是在没有作 ```SET GLOBAL GTID_PURGED``` 修改前的值
2) 第二条 ```SET GLOBAL GTID_PURGED``` 是修改为跟主节点相同的GTID
3) 第三条 ```SELECT @@GLOBAL.GTID_EXECUTED;``` 是在发起加入节点的操作```START GROUP_REPLICATION
  USER='repl_user', PASSWORD='*qJz0s_!bWgP?FX=';``` 之后, 发现有报错, 日志中也明确记录是GTID不一致的缘故, 再次通过SQL语句确认的

而在这里我犯的最大的一个错误是:  
当我在从节点上 ```SET GLOBAL GTID_PURGED=``` 设置成跟主节点跟一样以后  
由于受错误信息的误导, 以为每个节点上都应该创建用于复制通道的账号密码  
从而引起了```GTID```的变化  
使得无论怎么重置mysql初始化的流程发现都报从节点有主节点不具备的事务, 从而无法加入集群  
历经一番周折才发现这一点:  
<span style="color:red;">从节点在加入MGR集群前, 不可有多余的动作, 从而引起```GTID```的变化</span>

成功加入集群的示例:
```commandline
mysql> SELECT * FROM performance_schema.replication_group_members;
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+----------------------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION | MEMBER_COMMUNICATION_STACK |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+----------------------------+
| group_replication_applier | 1b5f8f23-7407-11f0-87d7-02420a0a000d | 10.10.0.13  |        3306 | ONLINE       | SECONDARY   | 8.4.6          | XCom                       |
| group_replication_applier | bb237743-73a1-11f0-86c8-02420a0a000c | 10.10.0.12  |        3306 | ONLINE       | SECONDARY   | 8.4.6          | XCom                       |
| group_replication_applier | fa3fc2ee-7365-11f0-8650-02420a0a000b | 10.10.0.11  |        3306 | ONLINE       | PRIMARY     | 8.4.6          | XCom                       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+----------------------------+
3 rows in set (0.00 sec)
```

状态列 ```MEMBER_STATE``` 应当非常短的时间就变为 ```ONLINE```  
如果一直出于 ```RECOVERING```, 则是存在异常.  
稍后也会从集群中移除  
日志记录于mysql的error log

因存在错误而从MGR中被移除的日志示例:

```commandline
2025-08-07T15:06:37.077331Z 0 [System] [MY-011503] [Repl] Plugin group_replication reported: 'Group membership changed to 10.10.0.12:3306, 10.10.0.11:3306 on view 17545546673283903:16.'
2025-08-07T15:06:37.077413Z 12 [System] [MY-015046] [Repl] Plugin group_replication reported: 'This member 10.10.0.11:3306 will be the one sending the recovery metadata message.'
2025-08-07T15:06:38.076926Z 0 [Warning] [MY-011499] [Repl] Plugin group_replication reported: 'Members removed from the group: 10.10.0.12:3306'
2025-08-07T15:06:38.076997Z 0 [System] [MY-011503] [Repl] Plugin group_replication reported: 'Group membership changed to 10.10.0.11:3306 on view 17545546673283903:17.'
```

从节点存在错误的命令报错:

```commandline
mysql> START GROUP_REPLICATION
    ->   USER='repl_user', PASSWORD='*qJz0s_!bWgP?FX=';
ERROR 3092 (HY000): The server is not configured properly to be an active member of the group. Please see more details on error log.
```

从节点因存在错误而加入不了集群的 error log:

```commandline
2025-08-07T15:06:36.588491Z 11 [System] [MY-013587] [Repl] Plugin group_replication reported: 'Plugin 'group_replication' is starting.'
2025-08-07T15:06:36.589140Z 11 [System] [MY-011565] [Repl] Plugin group_replication reported: 'Setting super_read_only=ON.'
2025-08-07T15:06:36.590397Z 11 [Warning] [MY-011735] [Repl] Plugin group_replication reported: '[GCS] Automatically adding IPv4 localhost address to the allowlist. It is mandatory that it is added.'
2025-08-07T15:06:36.590424Z 11 [Warning] [MY-011735] [Repl] Plugin group_replication reported: '[GCS] Automatically adding IPv6 localhost address to the allowlist. It is mandatory that it is added.'
2025-08-07T15:06:36.618816Z 13 [System] [MY-010597] [Repl] 'CHANGE REPLICATION SOURCE TO FOR CHANNEL 'group_replication_applier' executed'. Previous state source_host='', source_port= 3306, source_log_file='', source_log_pos= 4, source_bind=''. New state source_host='<NULL>', source_port= 0, source_log_file='', source_log_pos= 4, source_bind=''.
2025-08-07T15:06:36.661692Z 14 [System] [MY-014081] [Repl] Plugin group_replication reported: 'The Group Replication certifier broadcast thread (THD_certifier_broadcast) started.'
2025-08-07T15:06:37.163564Z 0 [ERROR] [MY-011526] [Repl] Plugin group_replication reported: 'This member has more executed transactions than those present in the group. Local transactions: 2abf7fe3-735f-11f0-8679-02420a0a000b:1-4, 4b4ddfc7-739e-11f0-85c7-02420a0a000c:1-4, fa3fc2ee-7365-11f0-8650-02420a0a000b:1-4 > Group transactions: 2abf7fe3-735f-11f0-8679-02420a0a000b:1-4, fa3fc2ee-7365-11f0-8650-02420a0a000b:1-4'
2025-08-07T15:06:37.163642Z 0 [ERROR] [MY-011522] [Repl] Plugin group_replication reported: 'The member contains transactions not present in the group. The member will now exit the group.'
2025-08-07T15:06:37.163680Z 0 [System] [MY-011503] [Repl] Plugin group_replication reported: 'Group membership changed to 10.10.0.12:3306, 10.10.0.11:3306 on view 17545546673283903:16.'
2025-08-07T15:06:40.207924Z 0 [System] [MY-011504] [Repl] Plugin group_replication reported: 'Group membership changed: This member has left the group.'
2025-08-07T15:06:40.209427Z 0 [System] [MY-014082] [Repl] Plugin group_replication reported: 'The Group Replication certifier broadcast thread (THD_certifier_broadcast) stopped.'
2025-08-07T15:06:40.209532Z 11 [System] [MY-011566] [Repl] Plugin group_replication reported: 'Setting super_read_only=OFF.'
```