### 官网  
https://redis.io/  
http://www.redis.cn/  中文社区


### 几个手册性质的网站
https://www.kancloud.cn/thinkphp/redis-quickstart/36133  
https://www.w3cschool.cn/redis_all_about/  
http://redisdoc.com/index.html  
https://www.w3cschool.cn/redis_all_about/redis_all_about-sfc726u6.html  


* [目录](#0)
  * [只安装redis-cli](#1)
  * [redis-cli info 含义解释](#2)
  * [redis-cli cluster nodes 含义解释](#3)


<h3 id="1">只安装redis-cli</h3>

Linux平台, 编译安装

```
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make redis-cli
sudo cp src/redis-cli /usr/local/bin/
redis-cli -h 127.0.0.1 -p 6379 ping
```

<h3 id="2">redis-cli info 含义解释</h3>

手册  
https://redis.io/commands/info/

该文章介绍了相当数量的指标的含义  
https://juejin.cn/post/7014398047916883998


Redis提供了info指令，它会返回关于Redis服务器的各种信息和统计数值。在使用Redis时，时常会遇到一些疑难杂症需要我们去排查，这个时候我们可以通过info指令来获取Redis的运行状态，然后进行问题的排查。

通过给定可选的参数 section ，可以让命令只返回某一部分的信息:

- server: Redis服务器的一般信息  
- clients: 客户端的连接部分  
- memory: 内存消耗相关信息  
- persistence: RDB和AOF相关信息  
- stats: 一般统计  
- replication: 主/从复制信息  
- cpu: 统计CPU的消耗  
- commandstats: Redis命令统计  
- cluster: Redis集群信息  
- keyspace: 数据库的相关统计  

它也可以采取以下值:  
- all: 返回所有信息  
- default: 值返回默认设置的信息  

如果没有使用任何参数时，默认为default，返回所有的信息。


<h3 id="3">redis-cli cluster nodes 含义解释</h3>

https://cloud.tencent.com/developer/section/1374002

```
<id> <ip:port> <flags> <master> <ping-sent> <pong-recv> <config-epoch> <link-state> <slot> <slot> ... <slot>
```
