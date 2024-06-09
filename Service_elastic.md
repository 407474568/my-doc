### 官网  




* [目录](#0)
  * [集群初始化](#1)
  * [cat API 的使用](#2)
  * [配置http层和传输层的SSL加密通信](#3)


<h3 id="1">集群初始化</h3>

- 在集群初始化时, keystore 只需要在任意一个节点上运行, 并将生成的 ```elasticsearcy.keystore``` 推送至所有节点上


- 以 docker 容器方式运行时, 通过 ```-e 'KEYSTORE_PASSWORD=xxxxxx'``` 形式传递的环境变量, 其中双引号是多数互联网上文章都提到的,将password包起来的书写方式

即 ```-e 'KEYSTORE_PASSWORD="xxxxxx"'```  
然而这在我的实测中(版本8.9.2 和 8.13.4)是会引起错误的  
报错内容为 ```Provided keystore password was incorrect```

所以, 正确的书写为以下

```-e 'KEYSTORE_PASSWORD=xxxxxx'```

错误的书写为以下

```-e 'KEYSTORE_PASSWORD="xxxxxx"'```  


#### 初始化时, 创建keystore

```
docker run --rm -it \
-v /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime \
--mount type=bind,source=/docker/elastic-master-node-01/data,destination=/usr/share/elasticsearch/data \
--mount type=bind,source=/docker/elastic-master-node-01/config,destination=/usr/share/elasticsearch/config \
-p 9200:9200 -p 9300:9300 --name=elastic-master-node-01 \
elasticsearch:8.13.4 \
bin/elasticsearch-keystore create -p
```


#### 首次初始化的 elasticsearch.yml 文件内容

```
# 集群名称
cluster.name: "elastic-cluster"

# 负责暴露http和传输流量的监听地址, 在docker iamge里也是默认配置
network.host: 0.0.0.0
network.publish_host: 172.16.0.31
http.port: 9201
transport.port: 9301

# 内存锁定, 不允许交换到swap, 官方文档推荐, 即使本身也已swapoff
bootstrap.memory_lock: true

# 节点自身名称
node.name: elastic-data-node-01

# 节点角色
node.roles: [ data ]
# node.roles: [ master ]

# 集群发现, 在生产是作为标准推荐, 本意是发现其他主机上的节点--否则只在本机的9300-9305端口上进行发现
# 只应写入具备master资格的节点, 如果是仅存放data的节点, 则不要写入
discovery.seed_hosts:
    - 172.16.0.31:9300
    - 172.16.0.32:9300
    - 172.16.0.33:9300
    - 172.16.0.34:9300
    - 172.16.0.35:9300
    - 172.16.0.36:9300
    - 172.16.0.37:9300
    - 172.16.0.38:9300
    - 172.16.0.39:9300

# 使用自签名证书方式, 所需的配置语句
# https://www.elastic.co/guide/en/elasticsearch/reference/current/security-basic-setup.html#security-basic-setup
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path: config/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: config/elastic-certificates.p12

# 集群首次搭建时需要, 在组合完成后, 该语句需要移除
cluster.initial_master_nodes: elastic-master-node-01

# 用于http通信层的SSL加密, 使用该语句的前提是已为集群生成http的SSL证书, 且分发到了对应路径下
# https://elastic.heyday.net.cn:1000/guide/en/elasticsearch/reference/current/security-basic-setup-https.html
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: http.p12
```


<h3 id="2">cat API 的使用</h3>

https://elastic.heyday.net.cn:1000/guide/en/elasticsearch/reference/current/cat.html

官网文档对URL的书写格式, 均采用了简写方式, 即你都需要自行添加上自己的单机/集群IP与端口, 例如:

```
GET _cat/master?v=true
```

实际上的请求地址为

```
GET http://<your_ip>:<your_port>/_cat/master?v=true
```

详细输出

在所有的URL后面接一个 ```?v``` 为 verbose, 即详细输出, 实际就是打印表头, 例如:

```
GET /_cat/master?v
```

使用帮助

在URL后方接 ```?help```

```
GET /_cat/master?help
```

#### cat 目录

| URL | 含义/用途                                                                                                                                                                                                                                                                                                                                                                                                    | 
|-----|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| /_cat/allocation | Provides a snapshot of the number of shards allocated to each data node and their disk space.<br>提供分配给每个数据节点的分片数及其磁盘空间的快照。                                                                                                                                                                                                                                                                               |
| /_cat/shards | The shards command is the detailed view of what nodes contain which shards. It will tell you if it’s a primary or replica, the number of docs, the bytes it takes on disk, and the node where it’s located.<br>该 shards 命令是哪些节点包含哪些分片的详细视图。它会告诉你它是主数据库还是副本数据库、文档数量、它在磁盘上占用的字节数以及它所在的节点。<br>For data streams, the API returns information about the stream’s backing indices.<br>对于数据流，API 返回有关流的支持索引的信息。 |
| /_cat/shards/{index} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/master | Returns information about the master node, including the ID, bound IP address, and name.<br>返回有关主节点的信息，包括 ID、绑定的 IP 地址和名称。                                                                                                                                                                                                                                                                               |
| /_cat/nodes | Returns information about a cluster’s nodes.<br>返回有关群集节点的信息。                                                                                                                                                                                                                                                                                                                                             |
| /_cat/tasks |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/indices | Returns high-level information about indices in a cluster, including backing indices for data streams.<br>返回有关集群中索引的高级信息，包括数据流的支持索引。                                                                                                                                                                                                                                                                     |
| /_cat/indices/{index} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/segments | Returns low-level information about the Lucene segments in index shards, similar to the indices segments API.<br>返回有关索引分片中 Lucene 段的低级信息，类似于索引段 API。<br>For data streams, the API returns information about the stream’s backing indices.<br>对于数据流，API 返回有关流的支持索引的信息。                                                                                                                                    |
| /_cat/segments/{index} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/count | Provides quick access to a document count for a data stream, an index, or an entire cluster.<br>提供对数据流、索引或整个集群的文档计数的快速访问。                                                                                                                                                                                                                                                                                |
| /_cat/count/{index} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/recovery | Returns information about ongoing and completed shard recoveries, similar to the index recovery API.<br>返回有关正在进行和已完成的分片恢复的信息，类似于索引恢复 API。<br>For data streams, the API returns information about the stream’s backing indices.<br>对于数据流，API 返回有关流的支持索引的信息。                                                                                                                                               |
| /_cat/recovery/{index} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/health | Returns the health status of a cluster, similar to the cluster health API.<br>返回集群的运行状况，类似于集群运行状况 API。                                                                                                                                                                                                                                                                                                   |
| /_cat/pending_tasks | Returns cluster-level changes that have not yet been executed, similar to the pending cluster tasks API.<br>返回尚未执行的群集级更改，类似于挂起的群集任务 API。                                                                                                                                                                                                                                                                 |
| /_cat/aliases | Retrieves the cluster’s index aliases, including filter and routing information. The API does not return data stream aliases.<br>检索群集的索引别名，包括筛选器和路由信息。API 不返回数据流别名。                                                                                                                                                                                                                                      |
| /_cat/aliases/{alias} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/thread_pool | Returns thread pool statistics for each node in a cluster. Returned information includes all built-in thread pools and custom thread pools.<br>返回群集中每个节点的线程池统计信息。返回的信息包括所有内置线程池和自定义线程池。                                                                                                                                                                                                                  |
| /_cat/thread_pool/{thread_pools} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/plugins | Returns a list of plugins running on each node of a cluster.<br>返回在群集的每个节点上运行的插件列表。                                                                                                                                                                                                                                                                                                                      |
| /_cat/fielddata | Returns the amount of heap memory currently used by the field data cache on every data node in the cluster.<br>返回群集中每个数据节点上的字段数据缓存当前使用的堆内存量。                                                                                                                                                                                                                                                             |
| /_cat/fielddata/{fields} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/nodeattrs | Returns information about custom node attributes.<br>返回有关自定义节点属性的信息。                                                                                                                                                                                                                                                                                                                                     |
| /_cat/repositories | Returns the snapshot repositories for a cluster.<br>返回集群的快照存储库。                                                                                                                                                                                                                                                                                                                                          |
| /_cat/snapshots/{repository} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/templates | Returns information about index templates in a cluster. You can use index templates to apply index settings and field mappings to new indices at creation.<br>返回有关群集中索引模板的信息。您可以使用索引模板在创建时将索引设置和字段映射应用于新索引。                                                                                                                                                                                              |
| /_cat/component_templates/_cat/ml/anomaly_detectors |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/ml/anomaly_detectors/{job_id} | Returns configuration and usage information about anomaly detection jobs.<br>返回有关异常情况检测作业的配置和使用情况信息。                                                                                                                                                                                                                                                                                                     |
| /_cat/ml/datafeeds | Returns configuration and usage information about datafeeds.<br>返回有关数据馈送的配置和使用情况信息。                                                                                                                                                                                                                                                                                                                      |
| /_cat/ml/datafeeds/{datafeed_id} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/ml/trained_models | Returns configuration and usage information about inference trained models.<br>返回有关推理训练模型的配置和使用情况信息。                                                                                                                                                                                                                                                                                                     |
| /_cat/ml/trained_models/{model_id} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/ml/data_frame/analytics | Returns configuration and usage information about data frame analytics jobs.<br>返回有关数据帧分析作业的配置和使用情况信息。                                                                                                                                                                                                                                                                                                   |
| /_cat/ml/data_frame/analytics/{id} |                                                                                                                                                                                                                                                                                                                                                                                                          |
| /_cat/transforms | Returns configuration and usage information about transforms.<br>返回有关转换的配置和使用情况信息。                                                                                                                                                                                                                                                                                                                       |
| /_cat/transforms/{transform_id} |                                                                                                                                                                                                                                                                                                                                                                                                          |



<h3 id="3">配置http层和传输层的SSL加密通信</h3>

这两个是主要依赖的文档

https://elastic.heyday.net.cn:1000/guide/en/elasticsearch/reference/current/security-basic-setup.html#security-basic-setup

https://elastic.heyday.net.cn:1000/guide/en/elasticsearch/reference/current/security-basic-setup-https.html


本次尚未弄清的问题  
- keystore 文件是否可以一个节点配置, 其他节点分发即可, 即无需每个节点单独执行
- 如果前一点不可行, 则免交互式的添加方法需要具备, 以实现自动化的配置操作, 否则工作量随节点规模线性增加, 不太能接受




用shell 脚本分发集群中所有节点的http证书

```
for num in `seq 1 9`
do
    ansible docker-cluster-node"$num" -m copy -a "src=/root/elk/elasticsearch/elastic-master-node-0$num/http.p12 dest=/docker/elastic-master-node-0$num/config/"
    ansible docker-cluster-node"$num" -m copy -a "src=/root/elk/elasticsearch/elastic-data-node-0$num/http.p12 dest=/docker/elastic-data-node-0$num/config/"
done
```

分发完成后的再次核对

```
for num in `seq 1 9`
do
    md5sum /root/elk/elasticsearch/elastic-master-node-0$num/http.p12
    ansible docker-cluster-node"$num" -m shell -a "md5sum /docker/elastic-master-node-0$num/config/http.p12"
    
    md5sum /root/elk/elasticsearch/elastic-data-node-0$num/http.p12
    ansible docker-cluster-node"$num" -m shell -a "md5sum /docker/elastic-data-node-0$num/config/http.p12"
done
```


keystore 口令不正确的提示

```
elasticsearch@elastic-master-node-01:~$ ./bin/elasticsearch-keystore add xpack.security.http.ssl.keystore.secure_password
Enter password for the elasticsearch keystore : 

ERROR: Provided keystore password was incorrect, with exit code 65
```
