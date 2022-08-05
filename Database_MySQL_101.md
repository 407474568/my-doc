* [目录](#0)
  * [初始化数据库](#1)

### 没有特别说明的情况下, 本文中的MySQL版本均为8.0

<h3 id="1">初始化数据库</h3>

新装的mysql, 初始化的流程

```
# 执行mysql的初始化命令, root的初始化密码会在终端中打印
# docker镜像的mysql, 数据目录位置 /var/lib/mysql
mysqld --initialize --console

# 执行mysql 的登录操作
mysql -u root -p

# 8.0开始需要先修改密码, 否则其他操作无法完成
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_psd_123';

# 如果没有修改则是如下情况
# mysql> CREATE USER 'itop'@'%' IDENTIFIED BY 'itop';
# ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement.

# 建用户的示例
mysql> CREATE USER 'itop'@'%' IDENTIFIED BY 'itop';
Query OK, 0 rows affected (0.01 sec)

# 建库的示例
mysql> CREATE DATABASE `rkitop` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
Query OK, 1 row affected (0.00 sec)

# 授权用户对某个库的示例
mysql> GRANT ALL ON rkitop.* TO 'itop'@'%';
Query OK, 0 rows affected (0.01 sec)

# 刷新权限
mysql> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)
```


