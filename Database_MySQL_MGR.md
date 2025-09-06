* [目录](#0)
  * [MGR集群 一主多从](#1)
  * [SSL通信问题](#2)
  * [自带的SSL证书问题](#3)
  * [集群中节点离开集群的情形](#4)


<h3 id="1">MGR集群 一主多从</h3>

MGR, MySQL group replication, 组复制, 后续都简称 ```MGR```

必要背景简介
- 在本节只描述一主多从模式下的情况
- docker部署, 并采取了网络隔离

事前采取了AI大模型的建议, 使用了网络隔离, 且使用的是```macvlan```

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

```commandline
SET GLOBAL group_replication_bootstrap_group=ON;
```  

5) 启动通道

```commandline
START GROUP_REPLICATION
  USER='repl_user', PASSWORD='*qJz0s_!bWgP?FX=';
```

<font color=red>非常重要的说明</font>  
复制通道的账号密码有且仅在此处进行配置, 在除此以外的地方配置, 应该都是  
MySQL >= 8.0.4x  
MySQL >= 8.4.x  
语法所不允许的

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

<h3 id="2">SSL通信问题</h3>

证书, 要用同一个CA来生成  
以下示例, 由 Primary 节点在 初始化过程中产生的CA来为3个节点各自生成的证书

```commandline
# 节点1
openssl genrsa 2048 > /docker/mysql-mgr1/data/mysql-mgr1-key.pem
openssl req -new -key /docker/mysql-mgr1/data/mysql-mgr1-key.pem \
  -out /docker/mysql-mgr1/data/mysql-mgr1-req.pem \
  -subj "/C=CN/ST=ChengDu/L=LongQuanYi/O=Heyday/OU=IT/CN=mysql-mgr1.heyday.net.cn"

# 节点2
openssl genrsa 2048 > /docker/mysql-mgr1/data/mysql-mgr2-key.pem
openssl req -new -key /docker/mysql-mgr1/data/mysql-mgr2-key.pem \
  -out /docker/mysql-mgr1/data/mysql-mgr2-req.pem \
  -subj "/C=CN/ST=ChengDu/L=LongQuanYi/O=Heyday/OU=IT/CN=mysql-mgr2.heyday.net.cn"

# 节点3
openssl genrsa 2048 > /docker/mysql-mgr1/data/mysql-mgr3-key.pem
openssl req -new -key /docker/mysql-mgr1/data/mysql-mgr3-key.pem \
  -out /docker/mysql-mgr1/data/mysql-mgr3-req.pem \
  -subj "/C=CN/ST=ChengDu/L=LongQuanYi/O=Heyday/OU=IT/CN=mysql-mgr3.heyday.net.cn"


# 节点1
openssl x509 -req -in /docker/mysql-mgr1/data/mysql-mgr1-req.pem \
  -CA /docker/mysql-mgr1/data/ca.pem \
  -CAkey /docker/mysql-mgr1/data/ca-key.pem \
  -CAcreateserial -out /docker/mysql-mgr1/data/mysql-mgr1-cert.pem

# 节点2
openssl x509 -req -in /docker/mysql-mgr1/data/mysql-mgr2-req.pem \
  -CA /docker/mysql-mgr1/data/ca.pem \
  -CAkey /docker/mysql-mgr1/data/ca-key.pem \
  -CAcreateserial -out /docker/mysql-mgr1/data/mysql-mgr2-cert.pem

# 节点3
openssl x509 -req -in /docker/mysql-mgr1/data/mysql-mgr3-req.pem \
  -CA /docker/mysql-mgr1/data/ca.pem \
  -CAkey /docker/mysql-mgr1/data/ca-key.pem \
  -CAcreateserial -out /docker/mysql-mgr1/data/mysql-mgr3-cert.pem
```

在```my.cnf```中的配置项

```commandline
# -----------------------------------------------------------------------------
# SSL 安全配置
# -----------------------------------------------------------------------------

# CA证书路径
ssl_ca=/var/lib/mysql/ca.pem

# 服务器证书路径
ssl_cert=/var/lib/mysql/mysql-mgr1-cert.pem

# 服务器私钥路径
ssl_key=/var/lib/mysql/mysql-mgr1-key.pem

# -----------------------------------------------------------------------------
# 组复制 SSL 配置
# -----------------------------------------------------------------------------

# 在恢复通道启用SSL加密
group_replication_recovery_use_ssl=ON

# 恢复通道CA证书
group_replication_recovery_ssl_ca='/var/lib/mysql/ca.pem'

# 恢复通道证书
group_replication_recovery_ssl_cert='/var/lib/mysql/mysql-mgr1-cert.pem'

# 恢复通道私钥
group_replication_recovery_ssl_key='/var/lib/mysql/mysql-mgr1-key.pem'
```

完整的```my.cnf```

```commandline
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/8.0/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove leading # to turn on a very important data integrity option: logging
# changes to the binary log between backups.
# log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M

# Remove leading # to revert to previous value for default_authentication_plugin,
# this will increase compatibility with older clients. For background, see:
# https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_default_authentication_plugin
# default-authentication-plugin=mysql_native_password

# -----------------------------------------------------------------------------
# 基础配置
# -----------------------------------------------------------------------------

# 禁用主机名缓存，配合skip-name-resolve提高性能
host_cache_size=0

# 禁止DNS反向解析，加快连接速度
skip-name-resolve

# 数据库文件存储路径
datadir=/var/lib/mysql

# MySQL套接字文件位置
socket=/var/run/mysqld/mysqld.sock

# 限制文件导入/导出操作的安全目录
secure-file-priv=/var/lib/mysql-files

# 运行mysqld进程的系统用户
user=mysql

# -----------------------------------------------------------------------------
# 复制与日志配置
# -----------------------------------------------------------------------------

# 服务器唯一标识符（集群中每个节点必须不同）
server-id=1

# 启用二进制日志（记录所有数据更改）
log_bin=mysql-bin

# 启用全局事务标识符
gtid_mode=ON

# 强制GTID一致性，确保事务安全
enforce_gtid_consistency=ON

# 固定中继日志文件名（确保重启后一致）
relay-log=mysql-relay-bin

# 固定中继日志索引文件名
relay-log-index=mysql-relay-bin.index

# 错误日志文件路径
log_error=/var/log/mysql/error.log

# 启用通用查询日志
general_log=1

# 通用日志文件路径
general_log_file=/var/log/mysql/general.log

# 启用慢查询日志
slow_query_log=1

# 慢查询日志路径
slow_query_log_file=/var/log/mysql/slow.log

# 慢查询阈值（单位：秒）
long_query_time=2

# 二进制日志存储路径
log_bin=/var/lib/mysql/mysql_bin

# -----------------------------------------------------------------------------
# SSL 安全配置
# -----------------------------------------------------------------------------

# CA证书路径
ssl_ca=/var/lib/mysql/ca.pem

# 服务器证书路径
ssl_cert=/var/lib/mysql/mysql-mgr1-cert.pem

# 服务器私钥路径
ssl_key=/var/lib/mysql/mysql-mgr1-key.pem

# -----------------------------------------------------------------------------
# 组复制 SSL 配置
# -----------------------------------------------------------------------------

# 在恢复通道启用SSL加密
group_replication_recovery_use_ssl=ON

# 恢复通道CA证书
group_replication_recovery_ssl_ca='/var/lib/mysql/ca.pem'

# 恢复通道证书
group_replication_recovery_ssl_cert='/var/lib/mysql/mysql-mgr1-cert.pem'

# 恢复通道私钥
group_replication_recovery_ssl_key='/var/lib/mysql/mysql-mgr1-key.pem'

# -----------------------------------------------------------------------------
# 组复制核心配置
# -----------------------------------------------------------------------------

# 向其他成员报告的IP地址（集群各节点不同）
report_host=10.10.0.11

# 加载组复制插件
plugin_load_add='group_replication.so'

# 集群UUID（所有节点相同）
group_replication_group_name="b3133c6d-5f2f-11f0-ab61-0242ac120002"

# 禁止服务启动时自动开启组复制（需手动启动）
group_replication_start_on_boot=OFF

# 当前节点组复制通信地址（各节点不同）
group_replication_local_address="10.10.0.11:33061"

# 集群成员地址列表
group_replication_group_seeds="10.10.0.11:33061,10.10.0.12:33061,10.10.0.13:33061"

# 启用单主模式（一个可写节点）
group_replication_single_primary_mode=ON

# 选主权重值（越高越优先成为主节点）
loose-group_replication_member_weight=50

# 进程ID文件位置
pid-file=/var/run/mysqld/mysqld.pid

[client]
# 客户端连接使用的套接字文件
socket=/var/run/mysqld/mysqld.sock

# 包含其他配置文件目录
!includedir /etc/mysql/conf.d/

# -----------------------------------------------------------------------------
# 注意事项
# -----------------------------------------------------------------------------

# 1. lower_case_table_names 配置（初始化时需设置）:
#    - 仅在MySQL初始化时需要
#    - MySQL 8.0.4x+ 版本需要显式配置
#    - 拼写修正为 lower_case_table_names（原文件有拼写错误）
#    - 取消注释后仅在初始化时使用，后续需注释
# lower_case_table_names  = 1
```

<h3 id="3">自带的SSL证书问题</h3>

**Q:**  
> datagrip 里 console窗口我想执行一个命令, 但提示NotAfter: Sat Sep 06 02:13:40 UTC 2025

**A:**
你提到在 **DataGrip 的 console 窗口**执行命令时出现提示：

```
NotAfter: Sat Sep 06 02:13:40 UTC 2025
```

这通常 **不是 SQL 错误**，而是 **SSL/TLS 证书过期的提示**，意思是 DataGrip 连接的数据库使用了一个证书，这个证书的有效期截止到了 `Sat Sep 06 02:13:40 UTC 2025`。

可能情况包括：

1. **数据库启用了 SSL 连接**（MySQL、PostgreSQL 等都可能），DataGrip 会验证证书有效期。
2. 你当前系统时间或者 DataGrip 的 JVM 时间可能不对（但一般是连接提示过期时间，而不是报错系统时间）。
3. 如果你是在 **尝试执行一些安全命令或连接数据库时**看到这个信息，那就是证书有效期信息，并不是阻止命令执行的错误。

解决方案：

* **检查证书有效期**：确认你的数据库 SSL 证书是否已过期或快到期。
* **忽略证书过期检查（开发环境可用）**：DataGrip 连接设置里有 SSL 模式，比如 MySQL 可以设置为 `VERIFY_CA` / `VERIFY_IDENTITY` / `REQUIRED` / `DISABLED`，把严格验证改为非严格验证可以避免报错。
* **更新证书**：如果是生产环境，建议更新数据库证书，避免到期后连接失败。

💡 补充：如果你的命令因为这个提示而无法执行，通常是 **SSL 验证阻止了连接**，调整 SSL 设置或更新证书就可以继续执行命令。

如果你愿意，我可以帮你写一个 **DataGrip MySQL/PG SSL 设置调整的方法**，直接避免这个 NotAfter 提示阻止执行。你希望我给哪个数据库的示例？

**Q:**  

```
[root@mysql-mgr-node1 ~]# tail /var/log/mysql/error.log 
2025-09-06T11:41:13.669460Z 1395 [System] [MY-010597] [Repl] 'CHANGE REPLICATION SOURCE TO FOR CHANNEL 'group_replication_recovery' executed'. Previous state source_host='10.10.0.12', source_port= 3306, source_log_file='', source_log_pos= 4, source_bind=''. New state source_host='10.10.0.12', source_port= 3306, source_log_file='', source_log_pos= 4, source_bind=''.
2025-09-06T11:41:13.712034Z 1633 [ERROR] [MY-010584] [Repl] Replica I/O for channel 'group_replication_recovery': Error connecting to source 'repl_user@10.10.0.12:3306'. This was attempt 1/1, with a delay of 60 seconds between attempts. Message: SSL connection error: error:1416F086:SSL routines:tls_process_server_certificate:certificate verify failed, Error_code: MY-002026
2025-09-06T11:41:13.719660Z 1395 [ERROR] [MY-011582] [Repl] Plugin group_replication reported: 'There was an error when connecting to the donor server. Please check that group_replication_recovery channel credentials and all MEMBER_HOST column values of performance_schema.replication_group_members table are correct and DNS resolvable.'
2025-09-06T11:41:13.719685Z 1395 [ERROR] [MY-011583] [Repl] Plugin group_replication reported: 'For details please check performance_schema.replication_connection_status table and error log messages of Replica I/O for channel group_replication_recovery.'
2025-09-06T11:41:13.719865Z 1395 [ERROR] [MY-011574] [Repl] Plugin group_replication reported: 'Maximum number of retries when trying to connect to a donor reached. Aborting group replication incremental recovery.'
2025-09-06T11:41:13.719887Z 1395 [ERROR] [MY-011620] [Repl] Plugin group_replication reported: 'Fatal error during the incremental recovery process of Group Replication. The server will leave the group.'
2025-09-06T11:41:13.719932Z 1395 [ERROR] [MY-011712] [Repl] Plugin group_replication reported: 'The server was automatically set into read only mode after an error was detected.'
2025-09-06T11:41:13.719982Z 1395 [System] [MY-011565] [Repl] Plugin group_replication reported: 'Setting super_read_only=ON.'
2025-09-06T11:41:13.720073Z 1395 [ERROR] [MY-013486] [Repl] Plugin group_replication reported: 'The server was automatically set into offline mode after an error was detected.'
2025-09-06T11:41:16.760254Z 0 [System] [MY-011504] [Repl] Plugin group_replication reported: 'Group membership changed: This member has left the group.'
```

看起node1要加回node2所在的集群, 失败的原因也是证书认证的  
然而node2的时间也与其他节点没看出什么不同来  
```
[root@mysql-mgr-node2 ~]# date "+%F %T"  
2025-09-06 19:40:46  
```

**A:**
看你贴的日志和时间信息，你的 **MySQL Group Replication** 节点无法完成恢复，报错都是 SSL/TLS 证书验证失败：

```
Replica I/O for channel 'group_replication_recovery': Error connecting to source 'repl_user@10.10.0.12:3306'. 
Message: SSL connection error: error:1416F086:SSL routines:tls_process_server_certificate:certificate verify failed
```

结合你之前在 DataGrip 里看到的 `NotAfter: Sat Sep 06 02:13:40 UTC 2025` 提示，问题可以总结为：

1. **证书有效期已过或即将到期**

   * Node1 尝试连接 Node2 时，SSL 验证失败，说明 Node2 的证书已经过期或者 MySQL 检测到证书不再有效。
   * 节点时间（Node1 和 Node2）都正常，没有明显漂移，说明不是系统时间问题。

2. **Group Replication 增量恢复被阻塞**

   * SSL 证书验证失败会阻止 I/O 线程与 donor 节点连接。
   * 因为 `group_replication_recovery` channel 无法完成，节点自动退出 group 并进入只读模式。

---

### 解决方案

**选项 1：更新 MySQL 集群的 SSL 证书**（推荐，生产环境安全）

* 生成新的 CA/Server/Client 证书，确保有效期长于当前时间。
* 替换各节点的 `server-cert.pem`、`server-key.pem`、`ca.pem` 等。
* 修改 `my.cnf` 中的 `ssl_cert`, `ssl_key`, `ssl_ca` 指向新证书。
* 重启 MySQL 节点后，再次加入 group。

**选项 2：临时忽略 SSL 验证**（仅测试/开发可用）

* 在 `my.cnf` 或者 group replication 配置中，将 SSL 校验模式设为非严格模式：

  ```ini
  group_replication_ssl_mode = REQUIRED
  ```

  改为：

  ```ini
  group_replication_ssl_mode = PREFERRED
  ```

  或者 `DISABLED`（完全不使用 SSL，仅测试）
* 重启 MySQL 后，尝试增量恢复。

**选项 3：短期 workaround**

* 如果是 Node2 证书马上过期，可以暂时把 Node1 的 `--ssl-mode=DISABLED` 或 `group_replication_ssl_mode=PREFERRED`，完成加入，然后同步数据，再更新正式证书。

💡 **总结**：

* 根本原因不是时间差，而是 **证书过期或证书验证失败**。
* 解决办法是 **更新证书或者调整 SSL 模式**。

---

如果你愿意，我可以帮你写一份 **具体操作步骤，给 Node1/Node2 更新 MySQL Group Replication SSL 证书并安全加入集群** 的完整方案。

你希望我直接写吗？

**Q**

> 替换各节点的 server-cert.pem、server-key.pem、ca.pem 等 我需要具体步骤

对 👍，你给的配置路径是放在 **`/var/lib/mysql/`** 下，不是我之前脚本默认的 `/etc/mysql/ssl/`。那就要把脚本里输出目录改成 `/var/lib/mysql/`，生成好的证书直接就能被 MySQL 用。

另外：

* MySQL 证书和 key 最好权限收紧：`server-key.pem` 必须 `600`，证书和 ca.pem 可 `644`。
* 修改完证书文件后，**必须重启 mysqld** 才会加载新证书。

---

### 修改版脚本 `gen_mysql_certs.sh`

```bash
#!/bin/bash
set -e

# 有效期设置
CA_DAYS=3650        # CA 10 年
CERT_DAYS=1825      # 节点证书 5 年

# 输出目录（和 my.cnf 配置一致）
BASE_DIR=/var/lib/mysql
cd $BASE_DIR

echo "=== 1. 生成 CA 证书 ==="
openssl genrsa 2048 > $BASE_DIR/ca-key.pem
openssl req -new -x509 -nodes -days $CA_DAYS -key $BASE_DIR/ca-key.pem -out $BASE_DIR/ca.pem \
  -subj "/CN=MySQL-Group-Replication-CA"

# 节点信息
declare -A NODES
NODES["mysql-mgr1"]="10.10.0.11"
NODES["mysql-mgr2"]="10.10.0.12"
NODES["mysql-mgr3"]="10.10.0.13"

SERIAL=1

for NODE in "${!NODES[@]}"; do
  IP=${NODES[$NODE]}
  echo "=== 2. 为 $NODE ($IP) 生成证书 ==="

  openssl genrsa 2048 > $BASE_DIR/${NODE}-key.pem

  openssl req -new -key $BASE_DIR/${NODE}-key.pem -out $BASE_DIR/${NODE}-req.pem \
    -subj "/CN=$IP"

  openssl x509 -req -in $BASE_DIR/${NODE}-req.pem -days $CERT_DAYS \
    -CA $BASE_DIR/ca.pem -CAkey $BASE_DIR/ca-key.pem -set_serial $SERIAL \
    -out $BASE_DIR/${NODE}-cert.pem

  SERIAL=$((SERIAL+1))

  chmod 600 $BASE_DIR/${NODE}-key.pem
  chmod 644 $BASE_DIR/${NODE}-cert.pem $BASE_DIR/ca.pem
done

echo "=== 证书生成完成 ==="
ls -l $BASE_DIR/*pem
```

---

### 下一步操作

1. 在 node1 执行脚本，生成：

   * `/var/lib/mysql/ca.pem`
   * `/var/lib/mysql/mysql-mgr1-cert.pem` + `/var/lib/mysql/mysql-mgr1-key.pem`
   * `/var/lib/mysql/mysql-mgr2-cert.pem` + `/var/lib/mysql/mysql-mgr2-key.pem`
   * `/var/lib/mysql/mysql-mgr3-cert.pem` + `/var/lib/mysql/mysql-mgr3-key.pem`

2. 分发到其他节点：

   ```bash
   # 给 node2
   scp /var/lib/mysql/ca.pem \
       /var/lib/mysql/mysql-mgr2-cert.pem \
       /var/lib/mysql/mysql-mgr2-key.pem \
       root@10.10.0.12:/var/lib/mysql/

   # 给 node3
   scp /var/lib/mysql/ca.pem \
       /var/lib/mysql/mysql-mgr3-cert.pem \
       /var/lib/mysql/mysql-mgr3-key.pem \
       root@10.10.0.13:/var/lib/mysql/
   ```

3. 在 node2/node3 上设置权限：

   ```bash
   chmod 600 /var/lib/mysql/mysql-mgr2-key.pem
   chmod 600 /var/lib/mysql/mysql-mgr3-key.pem
   chmod 644 /var/lib/mysql/mysql-mgr2-cert.pem /var/lib/mysql/mysql-mgr3-cert.pem /var/lib/mysql/ca.pem
   chown mysql:mysql /var/lib/mysql/*pem
   ```

4. **重启 MySQL 服务**（每个节点）：

   ```bash
   systemctl restart mysqld
   ```

5. 登录 MySQL 检查：

   ```sql
   SHOW STATUS LIKE 'Ssl_cipher';
   ```

   有值就说明 SSL 成功启用。

---

👌 现在文件权限和属主没问题了，`mysqld` 能读取证书。
但是 `SHOW STATUS LIKE 'Ssl_cipher';` 依然为空 → 说明 MySQL 并没有在 **监听端口** 上启用 SSL。

我们继续排查：

---

### 1. 检查 MySQL 是否加载了证书

在 mysql 里执行：

```sql
SHOW VARIABLES LIKE 'ssl_%';
```

正确结果应该是类似：

```
+---------------+--------------------------------------+
| Variable_name | Value                                |
+---------------+--------------------------------------+
| ssl_ca        | /var/lib/mysql/ca.pem                |
| ssl_cert      | /var/lib/mysql/mysql-mgr2-cert.pem   |
| ssl_key       | /var/lib/mysql/mysql-mgr2-key.pem    |
```

如果 `Value` 是空的，说明 `mysqld` 没有正确加载配置。

---

### 2. 确认配置文件里不要带引号

你现在 `/etc/my.cnf` 里是这样的：

```ini
group_replication_recovery_ssl_ca = '/var/lib/mysql/ca.pem'
group_replication_recovery_ssl_cert = '/var/lib/mysql/mysql-mgr2-cert.pem'
group_replication_recovery_ssl_key = '/var/lib/mysql/mysql-mgr2-key.pem'
```

⚠️ 这里路径周围的单引号 `'` 是不需要的，会导致 `mysqld` 直接忽略。
应该改成：

```ini
group_replication_recovery_ssl_ca = /var/lib/mysql/ca.pem
group_replication_recovery_ssl_cert = /var/lib/mysql/mysql-mgr2-cert.pem
group_replication_recovery_ssl_key = /var/lib/mysql/mysql-mgr2-key.pem
```

`ssl_ca / ssl_cert / ssl_key` 三个参数也是一样，保持无引号。

---

### 3. 重启并验证

修改完成后：

```bash
systemctl restart mysqld
```

再查：

```sql
SHOW VARIABLES LIKE 'ssl_%';
SHOW STATUS LIKE 'Ssl_cipher';
```

如果成功，`ssl_cipher` 应该会显示类似：

```
+---------------+-------------------------------+
| Variable_name | Value                         |
+---------------+-------------------------------+
| Ssl_cipher    | TLS_AES_256_GCM_SHA384        |
```

---

👉 建议你先去掉 `/etc/my.cnf` 里的单引号，然后 `systemctl restart mysqld`，再跑 `SHOW VARIABLES LIKE 'ssl_%';` 看看加载效果。要不要我帮你写个命令，一步帮你替换掉配置文件里的单引号？

我帮你分析一下：

从你的 `SHOW VARIABLES LIKE 'ssl_%';` 输出看：

* `ssl_ca / ssl_cert / ssl_key` 都已经正确加载了（路径显示出来了 ✅）
* 但是 `ssl_cipher` 为空，说明 **服务端支持 SSL，但当前客户端连接没有使用 SSL**

这其实和配置文件里的引号没关系 —— 引号会影响 *group\_replication\_recovery\_ssl\_xxx* 这些参数，但不会影响 `ssl_ca / ssl_cert / ssl_key`（它们已经生效了）。

---

### 为什么 `Ssl_cipher` 为空？

`Ssl_cipher` 来自 `SHOW STATUS LIKE 'Ssl_cipher';`，它表示 **当前客户端连接使用的加密算法**。
现在是空，说明你连上 MySQL 时用的还是明文连接。

---

### 验证 SSL 是否可用

在客户端执行：

```bash
mysql --ssl-mode=REQUIRED -uroot -p
```

登录进去以后再查：

```sql
SHOW STATUS LIKE 'Ssl_cipher';
```

如果 SSL 工作正常，你会看到类似：

```
+---------------+-------------------------+
| Variable_name | Value                   |
+---------------+-------------------------+
| Ssl_cipher    | TLS_AES_256_GCM_SHA384  |
+---------------+-------------------------+
```

---

### 小结

* 证书已经被 MySQL 加载成功 ✅
* `Ssl_cipher` 为空只是因为你默认用明文连接 MySQL
* 真正要验证，需要 **客户端强制 SSL**（`--ssl-mode=REQUIRED`）

---

要不要我帮你写一条命令，可以在一行里直接测试 SSL 连接，并且打印出加密算法？

对 👍，你说得完全正确。

你在本机直接跑 `mysql`，默认走的是 **Unix socket**（比如 `/var/lib/mysql/mysql.sock`），这个是本地文件通信，不会启用 SSL，所以 `Ssl_cipher` 就一直是空的。

---

### 你真正要验证的有两种情况：

1. **客户端远程连接是否走 SSL**
   从另一台机器连：

   ```bash
   mysql -h mysql-mgr-node2 -uroot -p --ssl-mode=REQUIRED
   ```

   然后：

   ```sql
   SHOW STATUS LIKE 'Ssl_cipher';
   ```

   这时候如果能显示 TLS 算法，就说明 SSL 通了。

2. **组复制内部通信是否走 SSL**
   这个不需要你手工去连，只要在 `/etc/my.cnf` 里配置了：

   ```ini
   group_replication_recovery_use_ssl = ON
   group_replication_recovery_ssl_ca = /var/lib/mysql/ca.pem
   group_replication_recovery_ssl_cert = /var/lib/mysql/mysql-mgr2-cert.pem
   group_replication_recovery_ssl_key = /var/lib/mysql/mysql-mgr2-key.pem
   ```

   然后重启 mysqld，节点间的 replication 通道就会强制走 TLS。
   如果证书有问题，你会在 `error.log` 里立刻看到报错（比如 `certificate verify failed`）。

---

👉 所以你在本地 `SHOW STATUS LIKE 'Ssl_cipher';` 看到空值是正常的，不代表服务端没启 SSL。
真正的验证方式，要么用远程客户端强制 `--ssl-mode=REQUIRED`，要么等你重新启动 Group Replication，看能否正常握手。

要不要我帮你写个 **快速验证组复制 SSL 是否启用的 SQL**，不用等报错？

👌 这就对了！

* `Ssl_cipher` 已经显示为 `TLS_AES_128_GCM_SHA256` ✅
* 说明 **服务端证书生效**，并且 **客户端和服务端之间的连接已经通过 TLS 加密**。

---

### 总结

* 你本地用 socket 连接 → 明文（`Ssl_cipher` 空）
* 你用 TCP + `--ssl-mode=REQUIRED` → 成功启用 TLS
* 现在可以确认：新证书已正确安装，MySQL 的 SSL/TLS 工作正常

接下来，只要把 **三个节点都替换为同一个 CA 签发的证书**，再启动 Group Replication，节点之间的复制流量就会自动通过 TLS。

要不要我再给你一条检查 **组复制连接是否在用 SSL** 的 SQL？这样你能确认节点间 replication 真的走了 TLS。


<h3 id="4">M集群中节点离开集群的情形</h3>

**Q**

> 很好很强大! 两个因虚拟机磁盘文件损失而还原到2天状态的mysql节点, 加回集群, 已经从recovering到了online状态了, 那么这么来说mysql 8.4.6的MGR还是没有我担心的那样脆弱? 因为我就担心从node1 node3宕机之后, node2作为唯一在集群内的master, gpid也变化了, node1 node3想加回来也会被拒绝

**A**

哈哈，恭喜 🎉 两个节点已经 **从 recovering → online**，说明新的证书 & SSL 通道完全没问题，组复制自己把数据追上来了。

你担心的点非常专业 👇

---

### 1. MGR 容错的关键机制

在 MySQL 8.4 的 Group Replication (MGR) 里：

* **写入是基于 GTID（全局事务 ID）和 Group Replication 的共识机制**。
* 即使 node2 独活（单节点存活），它继续产生的事务都会有递增的 GTID。
* 当 node1、node3 恢复并尝试加入时，MGR 会让它们通过 **incremental recovery** 从存活节点拉取缺失的事务日志，追到最新 GTID。
* 如果能追平，就可以重新 ONLINE。

所以，只要：

* 你没做 `RESET MASTER` 这种破坏 GTID continuity 的操作
* node2 没有“强制重新初始化集群”
  那 node1、node3 都是可以追上的。

---

### 2. 什么时候会“被拒绝”

你担心的情况确实可能发生，但触发条件比较苛刻：

* **GTID 集合出现不可调和冲突**（例如 node2 自己被 `RESET MASTER`，导致 GTID 丢失）
* **残存节点数量 < majority**，但你手动强行把它 `force_start` 了，等于 fork 出一个“新世代”的 GPID，这样老节点再回来就会发现自己 belong to a different group → 被拒绝，需要重建。

正常操作下，只要剩下的节点没被乱操作，MGR 会尽量保证 **自动追上**。

---

### 3. 你的恢复过程能成功的原因

* node2 作为唯一幸存节点，保存了连续的 GTID。
* node1、node3 还原后虽然“回到两天前”，但 **MGR 会识别它们缺少的事务**，然后通过 group\_replication\_recovery 机制补齐。
* 只要追平，MGR 就能让它们自动从 recovering → online。

这说明 **MGR 的设计比想象中要坚韧** 👍。

---

✅ 结论：
你担心的“node2 独活导致 GPID 变化，老节点无法加入”的情况，只有在你对 node2 做了破坏性操作（重置 GTID/强制新 group 初始化）才会发生。
在你这次场景里，MGR 的恢复能力已经证明它能处理 “部分节点回滚到旧快照再追数据” 的情况。

---


完全正确，你的理解非常精准 👍

我帮你理一下逻辑：

---

### 1️⃣ GPID 的本质

* GPID（Group Replication ID）是 MGR 用来标识 **当前组的“世代”** 的唯一 ID。
* 每次集群初始化或者出现 **全量恢复/强制重建** 时，都会生成新的 GPID。
* GPID 高于已有节点 → 新加入的节点“属于不同的世代”，MGR 会拒绝加入，避免 split-brain。

---

### 2️⃣ 正常掉线 + 恢复节点的场景

* 如果 node1/node3 只是 **掉线或快照回滚**，但 node2 继续作为在线节点保持 GTID 连续：

  * 掉线节点的 GPID 依然是老 GPID（或者和 node2 一致），**不会高于 master**
  * 加回集群时，MGR 会发现它们缺少的事务，自动执行 **incremental recovery**
  * 节点就能顺利从 `RECOVERING → ONLINE`

✅ 这正是你看到的“节点成功追上”的原因。

---

### 3️⃣ GPID 高于 master 的情况

* 只有在掉线节点被误操作（比如 `RESET MASTER`、初始化新集群）或者导入了和 master 不连续的 GTID 时，GPID 才会高于 master。
* 这种情况下，节点会被拒绝加入，因为 MGR 无法保证 GTID 的一致性。

---

### 4️⃣ 总结

* **掉线 + 恢复节点，不做破坏性操作** → GPID 不会高于 master → 自动可加入
* **破坏性操作 / 重新初始化集群** → GPID 高于 master → 被拒绝，需要手动干预

所以你之前手动修改 GPID 的经验，其实是 **规避了“高 GPID 导致拒绝”的机制**。
而你这次恢复成功，说明 MGR 的保护机制起作用了，并且集群容错能力没你想的那么脆弱。

---

完全可以，这就是 MGR 的设计思路之一，你的理解很准确 ✅

我帮你梳理一下流程和原理：

---

### 1️⃣ 触发“被拒绝”的前提

* 掉线节点被误操作，或者 GPID 高于存活 master
* MGR 会拒绝节点加入，因为它认为节点属于“不同世代”

**注意**：集群里的 master 节点仍然完整保留了 GTID 日志，数据是安全的。

---

### 2️⃣ 让被拒绝节点重新加入的思路

你描述的做法本质上是 **把节点当作新节点加入集群**：

1. **清空数据目录**

   ```bash
   systemctl stop mysqld
   rm -rf /var/lib/mysql/*    # 或者备份有用的配置文件
   ```
2. **初始化节点**

   ```bash
   mysqld --initialize-insecure --user=mysql
   ```
3. **配置 my.cnf**

   * 指向原 master 的 GPID（group\_replication\_group\_name、group\_replication\_start\_on\_boot=OFF 等）
   * 配置 SSL、复制账号等
4. **启动 mysqld 并加入集群**

   ```sql
   START GROUP_REPLICATION;
   ```

   MGR 会把这个节点当作新节点 **自动从 master 拉取缺失数据**（incremental/full copy，根据节点状态可能执行全量同步），最终追到最新。

---

### 3️⃣ 注意事项

* **备份原有配置**，不要误删 SSL 证书或用户配置
* 确保网络畅通，复制账号权限正确
* 初始加入节点时，建议先用 `group_replication_start_on_boot=OFF`，避免自动启动冲突
* MGR 会自动生成 recovery channel 并拉数据，你只需等待节点状态从 `RECOVERING → ONLINE`

---

### 4️⃣ 原理

* 这种方法实际上相当于 **rejoin from scratch**
* 数据不会丢失，因为 master 保留了完整 GTID
* 新节点的数据会覆盖为空，然后通过 group replication 追上 master 的事务

---

总结一句话：

> “被拒绝的节点，只要当作新节点重新初始化，再加入集群，就能自动从 master 拉全量/增量数据，数据安全无需担心。”

---

