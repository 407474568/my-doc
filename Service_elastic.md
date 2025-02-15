### 官网手册  

https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html

在本文后续都不再特别强调, 如官网访问困难, 可访问我本人的镜像站点, 非实时镜像, 定期更新.

所有涉及的官网手册的链接将 `www.elastic.co` 替换 为 `elastic.heyday.net.cn:1000` 即可


* [目录](#0)
  * [集群初始化](#1)
  * [cat API 的使用](#2)
  * [配置 elastic 和 kibana 的通信加密](#3)
  * [生成配置SSL通信加密所需的证书--自动应答方式](#4)
  * [集群构建中容易出错的点](#5)
  * [elasticsearch-reset-password等相关工具的一个补充](#6)


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

另外, 企业环境下对于容器启动时设置环境, `-e xxx=xxx` 这个方式, 对于口令这种敏感信息通常是不被接受的做法.  
改进的选项之一是:  
使用 docker 启动时的 `--env-file` 的形式传递


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



<h3 id="3">配置 elastic 和 kibana 的通信加密</h3>

#### 配置 elastic 的http层和传输层的SSL加密通信

这两个是主要依赖的文档

https://elastic.heyday.net.cn:1000/guide/en/elasticsearch/reference/current/security-basic-setup.html#security-basic-setup

https://elastic.heyday.net.cn:1000/guide/en/elasticsearch/reference/current/security-basic-setup-https.html

流程概述:
- 生成自签名证书的CA(如果不是使用已有CA), 默认名elastic-stack-ca.p12
- 生成由自签名证书的CA(如果不是使用已有CA)签发传输层的密钥, 默认名elastic-certificates.p12
- 修改 elastic 的配置文件, 默认名 elasticsearch.yml, 使其加载该密钥加密传输层通信
- 生成由自签名证书的CA(如果不是使用已有CA)签发http层的密钥, 默认名 http.p12
- 修改 elastic 的配置文件, 默认名 elasticsearch.yml, 使其加载该密钥加密http层通信
- 核实 http 接口, 默认URL为 <host>:9200 , 是否只接受 https, 不再接受 http

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

启用成功的标志

- elastic 的 9200 端口不再响应 `http` 而只处理 `https` 的请求, 并且日志内也能找到相关记录, 大意为客户端发来了 `http` 不会被响应

#### 静默模式下生成自签名SSL证书  

- keystore 文件是否可以一个节点配置, 其他节点分发即可, 即无需每个节点单独执行?
- 如果前一点不可行, 则免交互式的添加方法需要具备, 以实现自动化的配置操作, 否则工作量随节点规模线性增加, 不太能接受

以下是 `通义` 的回复, ~~尚未验证~~

Q: elastic的 keystore文件, 我是否可以采取在集群中任意一个节点, 通过elasticsearch-certutil 工具生成以后, 再将keystore结果文件复制分发到每个节点上, 而不需要每个节点都运行一次 elasticsearch-certutil 工具

A: 是的，你可以采取这种方法。在Elasticsearch集群中，只要你使用的是相同的密钥材料和配置选项在其中一个节点上生成了keystore文件，理论上你可以将这个keystore
文件复制到集群的其他所有节点上，而无需在每个节点上单独运行`elasticsearch-certutil`工具。

具体步骤如下：

1. **在任一节点上生成密钥和证书**：使用`elasticsearch-certutil`命令生成所需的密钥和证书。例如，你可能使用如下命令来创建一个PKCS#12格式的密钥存储文件（keystore）：

   ```bash
   elasticsearch-certutil cert --out /path/to/my_keystore.p12 --pass <your_secure_password>
   ```

   这里，`--out`指定了输出的keystore文件路径，`--pass`指定了访问keystore的密码。

2. **复制keystore到其他节点**：将生成的`my_keystore.p12`文件以及相应的配置更新（如果有的话）复制到集群中的每一个节点上的相同路径下。确保所有节点都有访问该keystore的权限，并且都知道用于访问它的密码。

3. **更新Elasticsearch配置**：在每个节点的Elasticsearch配置文件（通常是`elasticsearch.yml`）中，配置使用新复制的keystore。这可能涉及设置`xpack.security.transport.ssl.keystore.path`、`xpack.security.transport.ssl.keystore.password`等配置项指向你复制的keystore文件及其密码。

4. **重启Elasticsearch服务**：在每个节点上重启Elasticsearch服务以应用新的SSL/TLS配置。

请注意，虽然这种方法在技术上可行且可以简化部署过程，但在处理敏感信息（如密钥和证书）时要格外小心，确保在网络传输过程中加密并保护好这些信息，避免泄露风险。此外，保持良好的密钥管理实践，定期轮换密钥和证书，并确保所有节点间的一致性。

该回答除说明"一个节点生成证书, 复制分发到其他节点通用"的可行外, 命令行的参数也表明可以实现免交互.


#### 验证

实际上, 关于 ```elasticsearch-certutil``` 的手册在此处

https://elastic.heyday.net.cn:1000/guide/en/elasticsearch/reference/current/certutil.html  



我的 yaml 文件示例

```
instances:
  - name: "elasic-master-node-01" 
    ip: 
      - "192.168.1.31"
      - "172.16.0.31"
    dns: 
      - "elasic-master-node-01"
    filename: "http"
  - name: "elasic-master-node-02" 
    ip: 
      - "192.168.1.32"
      - "172.16.0.32"
    dns: 
      - "elasic-master-node-02"
    filename: "http"
  - name: "elasic-master-node-03" 
    ip: 
      - "192.168.1.33"
      - "172.16.0.33"
    dns: 
      - "elasic-master-node-03"
    filename: "http"
  - name: "elasic-master-node-04" 
    ip: 
      - "192.168.1.34"
      - "172.16.0.34"
    dns: 
      - "elasic-master-node-04"
    filename: "http"
  - name: "elasic-master-node-05" 
    ip: 
      - "192.168.1.35"
      - "172.16.0.35"
    dns: 
      - "elasic-master-node-05"
    filename: "http"
  - name: "elasic-master-node-06" 
    ip: 
      - "192.168.1.36"
      - "172.16.0.36"
    dns: 
      - "elasic-master-node-06"
    filename: "http"
  - name: "elasic-master-node-07" 
    ip: 
      - "192.168.1.37"
      - "172.16.0.37"
    dns: 
      - "elasic-master-node-07"
    filename: "http"
  - name: "elasic-master-node-08" 
    ip: 
      - "192.168.1.38"
      - "172.16.0.38"
    dns: 
      - "elasic-master-node-08"
    filename: "http"
  - name: "elasic-master-node-09" 
    ip: 
      - "192.168.1.39"
      - "172.16.0.39"
    dns: 
      - "elasic-master-node-09"
    filename: "http"
```

执行 ```elasticsearch-certutil``` 的命令

```
bin/elasticsearch-certutil cert --silent --in /tmp/instances.yml --out /tmp/elasticsearch-ssl-http.zip --pass 63834516 --ca /tmp/elastic-stack-ca.p12
```

使用 `cert` 模式能为 elastic 的 http接口生成所需的SSL证书, 但却不知在 `http` 模式下的 kibana 证书是如何生成出来的. 此疑问待解决

有关 ```elasticsearch-certutil``` 的使用文档虽然介绍了它的参数用法, 但在其介绍中提到 ```http``` 模式有许多参数都不能使用.

这带来的问题就是, 此时需要生成 ```http``` 模式的证书就不知道该如何实现免交互--根据文档内容,~~怀疑压根儿就没为 ```http``` 模式设计免交互模式~~

`通义` 得出的结论与我的观点相符

Q:
> 它的文档在这里,
> https://www.elastic.co/guide/en/elasticsearch/reference/current/certutil.html  
> 只不过在http模式下, 原本在cert 模式下可用的参数大部分都不可用

A:
> 您提供的链接指向的是Elasticsearch官方文档中关于`elasticsearch-certutil`的部分，确实说明了在不同的操作模式下（如`ca`、`cert`、`csr`、`http`）可用的参数有所不同。`http` 模式主要用于简化为Elasticsearch HTTP接口生成证书或证书请求的过程，它通过一系列互动提示来确定用户的需要，然后生成相应的文件集，这通常包括可能的CA、CSR、以及用于Elasticsearch和Kibana的证书和密钥。与`cert`模式相比，`http`模式的设计更偏向于引导用户通过问答形式完成配置，而不是直接通过命令行参数全面控制输出。  
尽管如此，如果您希望在生成HTTP接口证书时实现类似`cert`模式下的非交互式操作，即不通过命令行问答而是直接通过参数指定所有细节，目前`elasticsearch-certutil`的`http`模式并不直接支持这种方式。`http`模式更多是为了简化新手或偶尔进行此操作的用户的体验，它通过一系列问题来确定用户需求，最终生成一个包含所需文件的zip包，每个文件夹内还包含readme指导如何使用这些文件。  
如果您的目标是在不进行任何交互的情况下为HTTP接口生成证书，您可能需要采取变通方法，比如先使用`cert`模式为HTTP接口生成证书（如果可以接受PKCS#12或PEM格式），或者利用`http` 模式生成一次证书后，根据实际需要手动调整或复制这些证书到相应位置。对于高度定制或自动化部署场景，考虑编写脚本来处理`cert`模式的证书生成可能会更加灵活和可控。  
总之，当前版本的`elasticsearch-certutil`并未提供直接在`http`模式下通过命令行参数进行全面非交互式配置的功能。您可能需要根据具体情况选择合适的模式（如`cert`）并结合适当的参数来满足自动化部署的需求。

不过, 实测得知, 可以多行提交, 也就是可以复制粘贴来节省一定的工作量

```
## Which hostnames will be used to connect to elastic-master-node-01?

These hostnames will be added as "DNS" names in the "Subject Alternative Name"
(SAN) field in your certificate.

You should list every hostname and variant that people will use to connect to
your cluster over http.
Do not list IP addresses here, you will be asked to enter them later.

If you wish to use a wildcard certificate (for example *.es.example.com) you
can enter that here.

Enter all the hostnames that you need, one per line.
When you are done, press <ENTER> once more to move on to the next step.

elastic-master-node-01
elastic-master-node-02
elastic-master-node-03
elastic-master-node-04
elastic-master-node-05
elastic-master-node-06
elastic-master-node-07
elastic-master-node-08
elastic-master-node-09
elastic-data-node-01
elastic-data-node-02
elastic-data-node-03
elastic-data-node-04
elastic-data-node-05
elastic-data-node-06
elastic-data-node-07
elastic-data-node-08
elastic-data-node-09
```

#### kibana 的加密

https://elastic.heyday.net.cn:1000/guide/en/elasticsearch/reference/current/security-basic-setup-https.html#encrypt-kibana-elasticsearch

第一步, 加密 kibana 与 elastic 主机之间的流量

以下是 `kibana.yml` 用到的配置语句

```
[root@ansible-2-9 elk]# cat kibana.yml 
server.host: "0.0.0.0"
server.shutdownTimeout: "5s"
elasticsearch.ssl.certificateAuthorities: config/elasticsearch-ca.pem
elasticsearch.hosts: [ "https://192.168.1.33:9200" ]
elasticsearch.username: "kibana_system"
elasticsearch.password: "HlqKTz=TLhNpowi7arQL"
```

其中

```
elasticsearch.username: "kibana_system"
elasticsearch.password: "HlqKTz=TLhNpowi7arQL"
```

```kibana_system``` 是 kibana 用于连接elastic的默认内置账户

该信息是 kibana 连接到 elastic 主机所必须的, 否则

在启用 SSL/TLS 以后, kibana 没有为其提供连接elastic的正确认证信息, 则会出现

```
[2024-06-16T01:32:08.557-05:00][ERROR][elasticsearch-service] Unable to retrieve version information from Elasticsearch nodes. security_exception
	Root causes:
		security_exception: missing authentication credentials for REST request [/_nodes?filter_path=nodes.*.version%2Cnodes.*.http.publish_address%2Cnodes.*.ip]
[2024-06-16T01:32:09.680-05:00][INFO ][plugins.screenshotting.chromium] Browser executable: /usr/share/kibana/node_modules/@kbn/screenshotting-plugin/chromium/headless_shell-linux_x64/headless_shell
[2024-06-16T01:51:58.546-05:00][ERROR][plugins.ruleRegistry] Error: Timeout: it took more than 1200000ms
    at Timeout._onTimeout (/usr/share/kibana/node_modules/@kbn/alerting-plugin/server/alerts_service/lib/install_with_timeout.js:43:18)
    at listOnTimeout (node:internal/timers:573:17)
    at processTimers (node:internal/timers:514:7)
[2024-06-16T01:51:58.550-05:00][ERROR][plugins.ruleRegistry] Error: Failure during installation of common resources shared between all indices. Timeout: it took more than 1200000ms
    at installWithTimeout (/usr/share/kibana/node_modules/@kbn/alerting-plugin/server/alerts_service/lib/install_with_timeout.js:59:13)
    at ResourceInstaller.installCommonResources (/usr/share/kibana/node_modules/@kbn/rule-registry-plugin/server/rule_data_plugin_service/resource_installer.js:42:5)
```

以上, 第一步, 仅解决elastic集群已启用SSL/TLS加密后的连接问题

第二步, 配置 kibana 与浏览器之间的流量加密

根据官网文档内容  
https://www.elastic.co/guide/en/elasticsearch/reference/current/security-basic-setup-https.html#encrypt-kibana-browser  
需要通过提交CSR给CA处理, 而在前期是通过 `elasticsearch-certutil` 创建的自己的CA, 应当如何处理, 文档里没提及(或者没找对地方)

但从 `通义` 这里找到了答案

Q:
> https://elastic.co/guide/en/elasticsearch/reference/current/security-basic-setup-https.html#encrypt-kibana-elasticsearch
其中提到"Send the kibana-server.csr certificate signing request to your internal CA or trusted CA for signing to obtain a signed certificate. The signed file can be in different formats, such as a .crt file like kibana-server.crt"
理解它的意图是将 csr 即签名请求发送内部CA以生成kibana的签名证书, 但它没有提到, 我是采用elasticsearch-certutil 创建的CA, 应当如何处理这个CSR签名请求, 步骤是什么

A:  
当你使用 `elasticsearch-certutil` 创建了一个 CA，并且为 Kibana 生成了 CSR（Certificate Signing Request），即 `kibana-server.csr` 文件后，下一步是让内部 CA 或受信任的外部 CA 对该 CSR 进行签名，从而获得一个有效的证书。既然你已经使用 `elasticsearch-certutil` 创建了自己的 CA，那么你可以直接使用这个 CA 来签署 CSR。以下是大致步骤：

1. **准备CA密钥对**：
   如果你还没有 CA 的私钥和证书（假设你已经通过 `elasticsearch-certutil ca` 命令创建了），确保你有这些文件，通常是一个 `.p12` 文件（如 `elastic-stack-ca.p12`）和相应的密码。

2. **使用CA签署CSR**：
   你需要使用你的 CA 私钥来签署 CSR。虽然 `elasticsearch-certutil` 直接提供的命令不包括签署 CSR 的功能，但你可以使用其他工具来完成这一步，比如 `openssl`。以下是使用 `openssl` 的基本步骤：

   - 首先，从你的 CA 密钥库（`.p12` 文件）导出 CA 的私钥和证书到 PEM 格式。如果你的 CA 密钥库是 PKCS#12 格式的（例如 `elastic-stack-ca.p12`），可以这样做：
     ```sh
     openssl pkcs12 -in elastic-stack-ca.p12 -nocerts -nodes -out ca-key.pem
     openssl pkcs12 -in elastic-stack-ca.p12 -nokeys -out ca-cert.pem
     ```

   - 使用 CA 的私钥和证书来签署 CSR：
     ```sh
     openssl x509 -req -in kibana-server.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out kibana-server.crt -days 365
     ```
     这个命令会使用你的 CA 证书和私钥来签署 CSR，并生成一个有效期为一年（`-days 365`）的证书 `kibana-server.crt`。

3. **配置Kibana使用签署后的证书**：
   签名完成后，你需要在 Kibana 的配置文件（通常是 `kibana.yml`）中指定新生成的证书和对应的私钥：
   ```yaml
   server.ssl.certificate: $KBN_PATH_CONF/kibana-server.crt
   server.ssl.key: $KBN_PATH_CONF/kibana-server.key
   ```
   确保将 `kibana-server.crt` 和 `kibana-server.key` 放置在正确的目录下，并且按照 Kibana 配置文件的路径进行指定。

4. **重启Kibana**：
   最后，重启 Kibana 以应用新的安全配置。

这样，你就完成了使用自己创建的 CA 签署 Kibana CSR 并配置 Kibana 使用签署后证书的过程。

以上是 ```通义``` 关于如何处理CSR的回答, 且经过验证, 内容无误

基于以上, 需要为 `kibana.yml` 增加以下配置语句

```
server.ssl.certificate: config/kibana.crt
server.ssl.key: config/kibana.key
server.ssl.enabled: true
```

其中 ```server.ssl.enabled: true``` 决定了在有该语句以后, kibana 将只响应 `https` 而不再响应 `http` 的请求

而示例中的 `kibana.crt` 和 `kibana.key` ,  
对于容器部署环境, 需要解决文件映射到容器内的问题  
对于传统部署环境, 需要解决文件分发问题

此外, 对比了

```
elasticsearch.hosts: [ "https://192.168.1.33:9200" ]
```

```
elasticsearch.hosts: [ "https://192.168.1.31:9200","https://192.168.1.32:9200","https://192.168.1.33:9200","https://192.168.1.34:9200","https://192.168.1.35:9200","https://192.168.1.36:9200","https://192.168.1.37:9200","https://192.168.1.38:9200","https://192.168.1.39:9200" ]
```

两种配置语句, 粗看行为是一致的, 从启动日志未发现明显差异  
前者是 kibana 指向同一个docker宿主机的 elastic 节点, 但是不同的容器, 实际上还是走的网络访问  
后者 kibana 指向了集群内全部的 elastic 节点的 web 接口, 适合批量部署而无需做修改

#### 免交互模式生成 elastic 和 kibana 的证书

`通义` 给了一个看似可行的步骤, 待核实后进行补充

Q:
> 就前面的问题, 你回答道"如果您的目标是在不进行任何交互的情况下为HTTP接口生成证书，您可能需要采取变通方法，比如先使用cert模式为HTTP接口生成证书（如果可以接受PKCS#12或PEM格式），或者利用http模式生成一次证书后，根据实际需要手动调整或复制这些证书到相应位置。对于高度定制或自动化部署场景，考虑编写脚本来处理cert模式的证书生成可能会更加灵活和可控。"  
我就此一点还想展开  
我也认同"先使用cert模式为HTTP接口生成证书" 这个做法应该才是正确的实现"在不进行任何交互的情况下为HTTP接口生成证书"的解决途径, 但该官网文档同样没解释的一个问题是, 在 http 模式下生成的kibana的证书, 那么当我选择了cert模式下的非交互模式, 又当如何为kibana创建证书

A:  
在非交互模式下使用 `elasticsearch-certutil` 的 `cert` 模式为 Kibana 生成证书，您可以按照以下步骤操作：

##### 准备工作
1. **确保已有 CA 证书和密钥**：如果您打算使用现有的证书颁发机构 (CA) 来签署 Kibana 的证书，确保您已经有了 CA 的证书（`.pem` 文件）和密钥（同样为 `.pem` 文件）。如果没有，您需要先使用 `elasticsearch-certutil` 的 `ca` 模式生成一个 CA。

##### 生成 Kibana 证书
2. **编写 YAML 配置文件**：为了在非交互模式下生成证书，您需要创建一个 YAML 文件来定义 Kibana 实例的详细信息。例如，创建一个名为 `kibana-instances.yml` 的文件，内容可能如下：

   ```yaml
   instances:
     - name: "kibana-node1"
       dns: ["kibana.example.com", "localhost"]
       ip: ["127.0.0.1", "10.0.0.1"]
   ```

   这里，`name` 是实例的标识，`dns` 是期望在证书的 Subject Alternative Names (SANs) 中包含的域名，`ip` 列出了与 Kibana 相关联的 IP 地址。

3. **生成证书**：使用 `cert` 模式并指定 YAML 文件作为输入，以及使用现有的 CA 证书和密钥来签署新证书。假设您的 CA 密钥库文件是 `elastic-stack-ca.p12`，并且您知道 CA 密码，执行以下命令：

   ```sh
   bin/elasticsearch-certutil cert \
     --ca elastic-stack-ca.p12 \
     --ca-pass <your_ca_password> \
     --in kibana-instances.yml \
     --out kibana-certificates.p12 \
     --pass <your_certificate_password> \
     --pem
   ```

   这里，`--ca` 指定 CA 的 PKCS#12 文件，`--ca-pass` 是 CA 密钥的密码，`--in` 是实例配置的 YAML 文件路径，`--out` 是输出的 PKCS#12 文件名，`--pass` 是新证书密钥的密码，`--pem` 表示输出 PEM 格式（如果您希望使用 PEM 格式而不是 PKCS#12）。

##### 部署到 Kibana
4. **配置 Kibana**：一旦证书生成完成，您需要将 Kibana 配置文件（通常是 `kibana.yml`）更新为使用新证书。如果生成的是 PKCS#12 格式的证书，您可能需要指定期望的证书和密钥文件路径。如果是 PEM 格式，您可能需要分别指定证书和密钥的路径，同时指定 CA 的证书路径：

   ```yaml
   # 对于 PKCS#12
   server.ssl.keystore.path: "path/to/kibana-certificates.p12"
   server.ssl.keystore.password: "<your_certificate_password>"
   
   # 对于 PEM
   server.ssl.certificate: "path/to/kibana-server.crt"
   server.ssl.key: "path/to/kibana-server.key"
   server.ssl.certificateAuthorities: ["path/to/elasticsearch-ca.pem"]
   ```

5. **重启 Kibana**：最后，重启 Kibana 以应用新的 SSL 配置。

通过以上步骤，您就能在非交互模式下为 Kibana 生成并部署证书了。请注意，具体命令行参数和配置细节可能需要根据您的实际情况和版本做适当调整。

<font color=red>以上是 `通义` 的回答</font>

#### 更新证书

用相同的CA

https://www.elastic.co/guide/en/elasticsearch/reference/current/update-node-certs-same.html

用不同的CA

https://www.elastic.co/guide/en/elasticsearch/reference/current/update-node-certs-different.html

待补充

<h3 id="4">生成配置SSL通信加密所需的证书--自动应答方式</h3>

https://www.elastic.co/guide/en/elasticsearch/reference/current/certutil.html

实际上官方文档还是给出了步骤, 只不过需要仔细一些

##### 生成CA的静默化/自动化

我的例子

```
[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-certutil ca \
>  --out /root/elastic-stack-ca.p12 \
>  --pass ""
This tool assists you in the generation of X.509 certificates and certificate
signing requests for use with SSL/TLS in the Elastic stack.

The 'ca' mode generates a new 'certificate authority'
This will create a new X.509 certificate and private key that can be used
to sign certificate when running in 'cert' mode.

Use the 'ca-dn' option if you wish to configure the 'distinguished name'
of the certificate authority

By default the 'ca' mode produces a single PKCS#12 output file which holds:
    * The CA certificate
    * The CA's private key

If you elect to generate PEM format certificates (the -pem option), then the output will
be a zip file containing individual files for the CA certificate and private key

[root@elk-exam ~]# ll
total 904M
-rw-------. 1 root root 1.3K Feb  5 13:26 anaconda-ks.cfg
-rw-r--r--. 1 root root 582M Feb  4 23:12 elasticsearch-8.15.5-linux-x86_64.tar.gz
-rw-------. 1 root root 2.7K Feb  6 23:05 elastic-stack-ca.p12
-rw-r--r--. 1 root root 323M Feb  4 23:12 kibana-8.15.5-linux-x86_64.tar.gz
[root@elk-exam ~]# 
```

##### 生成 elastic 使用的私钥的静默化/自动化

我的例子

```
[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-certutil cert \
>  --ca /root/elastic-stack-ca.p12 \
>  --ca-pass "" \
>  --out /root/elastic-certificates.p12 \
>  --pass ""
This tool assists you in the generation of X.509 certificates and certificate
signing requests for use with SSL/TLS in the Elastic stack.

The 'cert' mode generates X.509 certificate and private keys.
    * By default, this generates a single certificate and key for use
       on a single instance.
    * The '-multiple' option will prompt you to enter details for multiple
       instances and will generate a certificate and key for each one
    * The '-in' option allows for the certificate generation to be automated by describing
       the details of each instance in a YAML file

    * An instance is any piece of the Elastic Stack that requires an SSL certificate.
      Depending on your configuration, Elasticsearch, Logstash, Kibana, and Beats
      may all require a certificate and private key.
    * The minimum required value for each instance is a name. This can simply be the
      hostname, which will be used as the Common Name of the certificate. A full
      distinguished name may also be used.
    * A filename value may be required for each instance. This is necessary when the
      name would result in an invalid file or directory name. The name provided here
      is used as the directory name (within the zip) and the prefix for the key and
      certificate files. The filename is required if you are prompted and the name
      is not displayed in the prompt.
    * IP addresses and DNS names are optional. Multiple values can be specified as a
      comma separated string. If no IP addresses or DNS names are provided, you may
      disable hostname verification in your SSL configuration.


    * All certificates generated by this tool will be signed by a certificate authority (CA)
      unless the --self-signed command line option is specified.
      The tool can automatically generate a new CA for you, or you can provide your own with
      the --ca or --ca-cert command line options.


By default the 'cert' mode produces a single PKCS#12 output file which holds:
    * The instance certificate
    * The private key for the instance certificate
    * The CA certificate

If you specify any of the following options:
    * -pem (PEM formatted output)
    * -multiple (generate multiple certificates)
    * -in (generate certificates from an input file)
then the output will be be a zip file containing individual certificate/key files


Certificates written to /root/elastic-certificates.p12

This file should be properly secured as it contains the private key for 
your instance.
This file is a self contained file and can be copied and used 'as is'
For each Elastic product that you wish to configure, you should copy
this '.p12' file to the relevant configuration directory
and then follow the SSL configuration instructions in the product guide.

For client applications, you may only need to copy the CA certificate and
configure the client to trust this certificate.
```

##### 为每个节点签发证书的静默化/自动化

如官方文档所说, 要先行创建一个yaml语法格式的文本文件

```
instances:
  - name: "node1" 
    ip: 
      - "192.0.2.1"
    dns: 
      - "node1.mydomain.com"
  - name: "node2"
    ip:
      - "192.0.2.2"
      - "198.51.100.1"
  - name: "node3"
  - name: "node4"
    dns:
      - "node4.mydomain.com"
      - "node4.internal"
  - name: "CN=node5,OU=IT,DC=mydomain,DC=com"
    filename: "node5" 
```

我的例子

```
[root@elk-exam ~]# cat auto_answer.yml
instances:
  - name: "elasticsearch1" 
    ip: 
      - "192.168.1.231"
  - name: "elasticsearch2" 
    ip: 
      - "192.168.1.231"
  - name: "elasticsearch3" 
    ip: 
      - "192.168.1.231"
```

接下来, 提交免交互的命令行

```
[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-certutil cert \
> --silent \
> --in /root/auto_answer.yml \
> --out /root/elastic_node_certificates.zip \
> --pass "" \
> --ca /root/elastic-stack-ca.p12 \
>  --ca-pass ""
[root@elk-exam ~]# ll
total 904M
-rw-------. 1 root root 1.3K Feb  5 13:26 anaconda-ks.cfg
-rw-r--r--. 1 root root  194 Feb  7 12:03 auto_answer.yml
-rw-------. 1 root root 3.6K Feb  6 23:32 elastic-certificates.p12
-rw-------. 1 root root  12K Feb  7 12:30 elastic_node_certificates.zip
-rw-r--r--. 1 root root 582M Feb  4 23:12 elasticsearch-8.15.5-linux-x86_64.tar.gz
-rw-------. 1 root root 2.7K Feb  6 23:05 elastic-stack-ca.p12
-rw-r--r--. 1 root root 323M Feb  4 23:12 kibana-8.15.5-linux-x86_64.tar.gz
```

以上, 3组命令分别实现了创建CA, 创建```elastic```集群的私钥, 为节点签发证书一共3个部分的免交互操作  
对于有自动化部署需求的场景, 可在此基础上进一步完善脚本与相应配置文件的编辑

<font color=red>重要补充</font>

上述的自动化/免交互生成证书的操作中, 有一处细节需要注意

在我前面的示例中, 
CA, 即 ```elastic-stack-ca.p12```  
以及, 包含elastic私钥的证书 ```elastic-certificates.p12```  
使用了空密码, 即```""```  
然而这用在 ```elastic``` 启动时却始终存在报错

报错内容, 以及相关联的 elasticsearch.yml 的语句如下示例

```
[2025-02-10T23:38:50,646][ERROR][o.e.b.Elasticsearch      ] [elasticsearch1] fatal exception while booting Elasticsearchorg.elasticsearch.ElasticsearchSecurityException: failed to load SSL configuration [xpack.security.transport.ssl] - cannot read configured [PKCS12] keystore (as a truststore) [/elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12] - this is usually caused by an incorrect password; (a keystore password was provided)
	at org.elasticsearch.xcore@8.15.5/org.elasticsearch.xpack.core.ssl.SSLService.lambda$loadSslConfigurations$11(SSLService.java:620)
	at java.base/java.util.HashMap.forEach(HashMap.java:1429)
	at java.base/java.util.Collections$UnmodifiableMap.forEach(Collections.java:1708)
	at org.elasticsearch.xcore@8.15.5/org.elasticsearch.xpack.core.ssl.SSLService.loadSslConfigurations(SSLService.java:616)
	at org.elasticsearch.xcore@8.15.5/org.elasticsearch.xpack.core.ssl.SSLService.<init>(SSLService.java:160)

See logs for more details.

ERROR: Elasticsearch did not exit normally - check the logs at /elastic/elasticsearch-8.15.5/logs/cluster-exam.log

ERROR: Elasticsearch died while starting up, with exit code 1
[root@elk-exam ~]# tail -n 30 /elastic/elastics_exam_conf/elasticsearch1/elasticsearch.yml 
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12

# Enable encryption and mutual authentication between cluster nodes
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  client_authentication: required
  keystore.path: /elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12
  keystore.password: ""
  truststore.path: /elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12
  truststore.password: ""
# Create a new cluster with the current node only
# Additional nodes can still join the cluster later
cluster.initial_master_nodes: ["elk-exam"]

# Allow HTTP API connections from anywhere
# Connections are encrypted and require user authentication
http.host: 0.0.0.0

# Allow other nodes to join the cluster from anywhere
# Connections are encrypted and mutually authenticated
#transport.host: 0.0.0.0

#----------------------- END SECURITY AUTO CONFIGURATION -------------------------
node.roles: [ master ]
cluster.name: cluster-exam
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /elastic/elastics_exam_conf/elasticsearch1/elasticsearch1.p12
```

通过与AI大模型的对话, 首先是它发现了一处问题: 证书长度为0

```
[root@elk-exam ~]# keytool -list -v -keystore /elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12 -storetype PKCS12
Enter keystore password:  

*****************  WARNING WARNING WARNING  *****************
* The integrity of the information stored in your keystore  *
* has NOT been verified!  In order to verify its integrity, *
* you must provide your keystore password.                  *
*****************  WARNING WARNING WARNING  *****************

Keystore type: PKCS12
Keystore provider: SunJSSE

Your keystore contains 1 entry

Alias name: instance
Creation date: Feb 10, 2025
Entry type: PrivateKeyEntry
Certificate chain length: 0


*******************************************
*******************************************

```

```
根据您提供的信息，使用 keytool 命令验证密钥库文件 /elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12 时，虽然没有报错，但显示了以下关键内容：

证书链长度为 0 (Certificate chain length: 0)：
这表明密钥库中没有有效的证书链。通常情况下，Elasticsearch 的 SSL/TLS 配置需要一个包含私钥和证书的完整链。
密码验证：
您成功输入了密码（无论是空字符串还是其他值），并且没有出现密码错误的提示，说明密码是正确的。
文件权限：
文件权限设置为 -rw-------，并且归 elastic 用户所有，这符合 Elasticsearch 的运行要求。
```

```keytool``` 并非是系统自带的命令, 需要yum安装, 且并不属于 ```elasticsearch``` 的范畴, 估计JAVA生态内的

进而在它的提示下, 手动验证 ```/elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12``` 的有效性

用到的是 ```openssl``` 命令

```
[root@elk-exam ~]# openssl pkcs12 -in /root/elastic-certificates.p12 -nodes -passin pass:""
Bag Attributes
    friendlyName: instance
    localKeyID: 54 69 6D 65 20 31 37 33 39 32 35 35 31 33 33 32 34 32 
Key Attributes: <No Attributes>
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQChZuF6jqZ5CfXN
uJpttdpGWCJnm6YeKkYxsLfCGPIRnx0jfPx6HICe0hECVl+4ue3yTwwTbD+b5I/A
9M98mmxjlxLKEZ0uXtann2He586jpg6E3lD7BG5jc989+zDrxDO6Bn57/NnKzemQ
ldrEvJ5d+Q5snWvbo67g0iIwiPOu9y2qfMmkox29mhuABDDvInr8DMjz+0pNosWF
vYeDNgwuK4lDr4uwo4lLny5jtUY0oj493G1oTV8swOCLc2de/USTjgFLR3ilLeA8
Rk7XnomUTcsums+Q1MDEwlzKMsmjWLQKOH4OG07lC81cR3RXRK44BCNeYuMbFUEg
U5XqJZNDAgMBAAECggEAKDNrWu7X+RLphe2CjWv7q4S9QQgsNpw58pt9EZvMA2aZ
x+KUMkgSIzzYXrgrzGOHKFDXBalzKH2j7qArY/JEqAOTewArIcceeQ7CPlaHigxM
1nxXOEaQxjWwt4vu0fKDHcULUQ+YIaLrF4ezv0fpvCdSF+yX1lOtNbMxL9yUsZHa
xe86jiFWfgKfeO9+nQdNDqJ9WN0wdVYTybMzHnAu2t6CVsPOs/zLd2j5AzqHU0Xg
P0HgWJIW55qi+tFIu7jac31e40LHFLKQuFXqB9UsdJgS8DnENfb4gi6QuiUgAPXR
QTa3oSP1eLZEellzlAc1Jo/1sFFdPF+uooQ2dc0yOQKBgQDeHsKP22HqtVqVxsRW
oQ0sUytHJ39gSYQfyybZzZCr1vOTWwmWMOuTzRtY7U49PXAWCFN0OZtOhU1+QOPu
t//TrVEKcCS5CEfgO65pH+HqyHYtEEA7FyeEy4s36Hn9nkfQyqqGrhv9mEjZmSMS
neQ0gPoXeSQBvZJnMreFYO41ywKBgQC6BTkRu/UOkGHAJj8FUqf49iBXRN2RCef5
jLddVRzqK0z89DZOFEZmVFw6VPM/S1jmwSBv8y4P+Adj3jwDjkW6inrv7g/6gKq6
TRmu8Pfnr6zflQn0g4nUnOWUJA4YDpqeloZKv2EhULe8ZlbvzcSbqAtuMxA7DVdk
0BrIavwpaQKBgQCxLBH/U3toDt5Bh/mGLBJo37IuoHe+owVLouzLYGfcWamSSVR9
Q2o1S65boXX97SqhuGRw2Z5i5HtqkHH/MS9TdfSlgcwY91z1pEU7Px4h+2IgEc1a
FN8F0qGqp7nerckU5wNcSDa1cinxv2+1YtHre1GBNbSd2suTm2W9cxKvPwKBgGQM
SxVuse6TWP+vklWajx0nw10sfL51RX7CYByimlqXz2B9OHfmD7cZyEDXT7zLGZWC
aZ/Mewm7rL3Z2Q1Qh9A8isJgl9dzPF/W9+lPUQYbRi86SZBo7sibWh7DBZGKyT5i
Vvf81pDEiQ2bPUbctNHDH+K1NBWOp2JhSwZgBB+BAoGAXPodNrZqYWCfp1xhMA+I
+VTYhlt3lLfjPYGcdnPd+MkSsRxCpKNHHmsmfC6VqftTcEmAQT9In4EK5Xqg0lRm
tA55sNkZLMdp7lldEXrm4Tv7cZMHDK57tteTubVVhcbtchwI/DcfjwXgWucI4Svp
zHB/2Al20MWdrfqRVqO8Fyk=
-----END PRIVATE KEY-----
Bag Attributes
    friendlyName: instance
    localKeyID: 54 69 6D 65 20 31 37 33 39 32 35 35 31 33 33 32 34 32 
subject=CN = instance

issuer=CN = Elastic Certificate Tool Autogenerated CA

-----BEGIN CERTIFICATE-----
MIIDIzCCAgugAwIBAgIVAKfpZG7uS63o6OCA5AlLK5zp96y0MA0GCSqGSIb3DQEB
CwUAMDQxMjAwBgNVBAMTKUVsYXN0aWMgQ2VydGlmaWNhdGUgVG9vbCBBdXRvZ2Vu
ZXJhdGVkIENBMB4XDTI1MDIxMTA2MjUzM1oXDTI4MDIxMTA2MjUzM1owEzERMA8G
A1UEAxMIaW5zdGFuY2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCh
ZuF6jqZ5CfXNuJpttdpGWCJnm6YeKkYxsLfCGPIRnx0jfPx6HICe0hECVl+4ue3y
TwwTbD+b5I/A9M98mmxjlxLKEZ0uXtann2He586jpg6E3lD7BG5jc989+zDrxDO6
Bn57/NnKzemQldrEvJ5d+Q5snWvbo67g0iIwiPOu9y2qfMmkox29mhuABDDvInr8
DMjz+0pNosWFvYeDNgwuK4lDr4uwo4lLny5jtUY0oj493G1oTV8swOCLc2de/UST
jgFLR3ilLeA8Rk7XnomUTcsums+Q1MDEwlzKMsmjWLQKOH4OG07lC81cR3RXRK44
BCNeYuMbFUEgU5XqJZNDAgMBAAGjTTBLMB0GA1UdDgQWBBT998EHDasy+OaTgG5l
x9i5Amf64TAfBgNVHSMEGDAWgBSaCsYuY8ZAQ/9H4GytrFHZqNpeDzAJBgNVHRME
AjAAMA0GCSqGSIb3DQEBCwUAA4IBAQAjZJ034Qk2O51DiUWtJuiCTreupNd6UFYK
GV3lxxfVbEKtGtcshO5bQe92xp5OrGv07cSUn50Ne/0eSapaz1Olu32nF18TsRZT
gen+9krZ/VI/4C7evpsZgNC97v906bwXrGZDR/qMA7Ev1G3I/OCrKv+hempSUvhr
wIyGExjeZVVjD36JIj/VMNjTOPe7jFoDF2e8QRenby3233jJ3UkLh1gkcl5Xedl+
BDBLP8BAjlEuxxPZovAwE/jv60mN4a1pNkMaRdJG3gie22Z2ythp0zaqJvKUxIGw
gHfg2b5y/Frng3pk4f+noKhwtQygO02yIIBT4D6WfdKGuy66ZmHD
-----END CERTIFICATE-----
Bag Attributes
    friendlyName: ca
    2.16.840.1.113894.746875.1.1: <Unsupported tag 6>
subject=CN = Elastic Certificate Tool Autogenerated CA

issuer=CN = Elastic Certificate Tool Autogenerated CA

-----BEGIN CERTIFICATE-----
MIIDSTCCAjGgAwIBAgIUQ1Vz56YMzNEZGV4qc/poSLZWMlYwDQYJKoZIhvcNAQEL
BQAwNDEyMDAGA1UEAxMpRWxhc3RpYyBDZXJ0aWZpY2F0ZSBUb29sIEF1dG9nZW5l
cmF0ZWQgQ0EwHhcNMjUwMjEwMTQyMDI1WhcNMjgwMjEwMTQyMDI1WjA0MTIwMAYD
VQQDEylFbGFzdGljIENlcnRpZmljYXRlIFRvb2wgQXV0b2dlbmVyYXRlZCBDQTCC
ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALdp4JYMLhs7LejddWNx/56G
0I9vxDjEWnE1p/ZK9yU0gusCveb2n7mLJtWy4EKU15DhNaG4Tg1DFW7Hx8ejs4MG
tpa4Gbc7YYZDukbJTl7pXc2XXZUAudz0nm2AJxSJP4l521rP8NZwoxwlFT3Q9U88
IqVfBmO5IIhAurIyKE/WlNVHDjxGs1qqeYlF3z3OKw4W0toythzEtlHtxru20PWi
YEp1bMtHFBArePmu8xfC4EvgKzmnIxBE5GitR+XG8iV5uEZ/TLOEP3dzIYxL83rN
4msn70x3jm2rsHRAlA4qxfkrWwqSmBo7Lz8R7TgAdjvZC4uqzGMxGiQuzwU/bdsC
AwEAAaNTMFEwHQYDVR0OBBYEFJoKxi5jxkBD/0fgbK2sUdmo2l4PMB8GA1UdIwQY
MBaAFJoKxi5jxkBD/0fgbK2sUdmo2l4PMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZI
hvcNAQELBQADggEBAHG2YoZFmZ2S2ysxgQmpatXp6YMoAwsh/CPb2u91YvFSThRU
DMmSurOW0ZeSbInqSL4BpdAUruI7PSrmTermsLUYuP+V/qLx92vhlvlZ4N6k2aOc
XxWhi9i9U7HkoHfrCFXdu4dCZCrznLVQ2JIMAbIthpl1ftetTnA3Je5lzCmK9ZoG
1QMoY9/VJujRgdnHH9M6Lfa1z2H7xudkiGf+rNcdxDD3+EUpnnTtsUw4Houx/fUk
EG8cIr7k9pRQjhqZcwW+z1p6T6TbpLTU1Ot0SXfx4IO/HCRkYhAEEc746eXspObE
v0d9AH5ww0JDwBE+IMxECfGH2g4TiUFSk+K8RI8=
-----END CERTIFICATE-----
```

如上所示, openssl 验证内容为有效

```
是的，根据您提供的 openssl 输出结果，生成的节点证书文件 /root/elastic-certificates.p12 中确实包含了完整的证书链。以下是具体内容的分析：

证书内容分析
- 节点私钥：
输出中包含了一段以 -----BEGIN PRIVATE KEY----- 开头的内容，这是节点的私钥。
- 节点证书：
输出中包含了一段以 -----BEGIN CERTIFICATE----- 开头的内容，这是节点的证书。
证书的主题（subject）为 CN = instance，表明这是为节点实例生成的证书。
- CA 证书：
输出中还包含了一段以 -----BEGIN CERTIFICATE----- 开头的内容，这是 CA 的自签名证书。
证书的主题（subject）为 CN = Elastic Certificate Tool Autogenerated CA，表明这是用于签发节点证书的 CA 证书。
```

反复折腾几遍删除所有(CA,私钥,节点证书)重建以后, 突然意识到会不会是空密码的缘故

于是进行尝试, 果然报错有了变化, 新的报错给与以下经验总结

1) ```keystore.password``` 和 ```keystore.secure_password``` 是访问节点的 ```keystore``` 文件的两种方式. ```password``` 是明文存储,
```keystore.secure_password``` 是存储在 ```keystore```  
2) 而这个 ```keystore``` 是指的 ```elasticsearch-certutil cert``` 模式下生成的, 为集群内所有节点共有使用的,   
3) 使用 ```keystore.password``` 或 ```keystore.secure_password``` 是一个互斥的选项, 只能二选一, 否则 ```elasticsearch``` 启动时有明确的报错
查看方式是```/elastic/elasticsearch-8.15.5/bin/elasticsearch-keystore list```  
4) 使用 elastic 官方的软件包, 默认就是 ```keystore.secure_password``` 内置的 keystore 相关的几条语句需要移除  
5) 在我总结本文档这次的部署中, 为的是验证免交互模式的全流程, 并且选择了明文而不是```keystore```来存储密码.这更多的只适用于非正式环境  
6) 使用 keystore 存储密码, 而非明文的免交互方式, 待后续补充


针对 ```3) 使用 keystore.password 或 keystore.secure_password 是一个互斥的选项``` 的补充:

```
[2025-02-11T17:43:52,455][ERROR][o.e.b.Elasticsearch      ] [elasticsearch1] fatal exception while booting Elasticsearchorg.elasticsearch.ElasticsearchSecurityException: failed to load SSL configuration [xpack.security.transport.ssl] - cannot specify both [keystore.secure_password] and [keystore.password]
	at org.elasticsearch.xcore@8.15.5/org.elasticsearch.xpack.core.ssl.SSLService.lambda$getSSLConfigurations$4(SSLService.java:553)
	at java.base/java.util.HashMap.forEach(HashMap.java:1429)
	at java.base/java.util.Collections$UnmodifiableMap.forEach(Collections.java:1708)
	at org.elasticsearch.xcore@8.15.5/org.elasticsearch.xpack.core.ssl.SSLService.getSSLConfigurations(SSLService.java:545)
	at org.elasticsearch.xcore@8.15.5/org.elasticsearch.xpack.core.ssl.SSLService.getSSLConfigurations(SSLService.java:539)

See logs for more details.

ERROR: Elasticsearch did not exit normally - check the logs at /elastic/elasticsearch-8.15.5/logs/cluster-exam.log

ERROR: Elasticsearch died while starting up, with exit code 1
```


针对 ```4) 使用 elastic 官方的软件包, 内置的 keystore 相关的几条语句需要移除``` 的补充:

```
[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-keystore list
keystore.seed
xpack.security.http.ssl.keystore.secure_password
xpack.security.transport.ssl.keystore.secure_password
xpack.security.transport.ssl.truststore.secure_password
[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-keystore remove xpack.security.transport.ssl.keystore.secure_password

ERROR: will not overwrite keystore at [/elastic/elasticsearch-8.15.5/config/elasticsearch.keystore], because this incurs changing the file owner, with exit code 78
[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-keystore remove xpack.security.transport.ssl.truststore.secure_password^C
[root@elk-exam ~]# su - elastic 
[elastic@elk-exam ~]$ /elastic/elasticsearch-8.15.5/bin/elasticsearch-keystore remove xpack.security.transport.ssl.keystore.secure_password
[elastic@elk-exam ~]$ /elastic/elasticsearch-8.15.5/bin/elasticsearch-keystore remove xpack.security.transport.ssl.truststore.secure_password



[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-keystore list
keystore.seed
xpack.security.http.ssl.keystore.secure_password
[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-keystore remove xpack.security.http.ssl.keystore.secure_password

ERROR: will not overwrite keystore at [/elastic/elasticsearch-8.15.5/config/elasticsearch.keystore], because this incurs changing the file owner, with exit code 78
[root@elk-exam ~]# su - elastic -c "/elastic/elasticsearch-8.15.5/bin/elasticsearch-keystore remove xpack.security.http.ssl.keystore.secure_password"
```

如上所示, elastic 还额外做了个限制, 防止 keystore 文件的属主属性发生变化



最终的运行成功的配置文件的关联性语句如下:

```
[root@elk-exam ~]# tail -n 30 /elastic/elastics_exam_conf/elasticsearch1/elasticsearch.yml 
# Enable encryption for HTTP API client connections, such as Kibana, Logstash, and Agents
xpack.security.http.ssl:
  enabled: true
  keystore.path: /elastic/elastics_exam_conf/elasticsearch1/elasticsearch1.p12
  keystore.password: "63834516"

# Enable encryption and mutual authentication between cluster nodes
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  client_authentication: required
  keystore.path: /elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12
  keystore.password: "63834516"
  truststore.path: /elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12
  truststore.password: "63834516"
# Create a new cluster with the current node only
# Additional nodes can still join the cluster later
cluster.initial_master_nodes: ["elk-exam"]

# Allow HTTP API connections from anywhere
# Connections are encrypted and require user authentication
http.host: 0.0.0.0

# Allow other nodes to join the cluster from anywhere
# Connections are encrypted and mutually authenticated
#transport.host: 0.0.0.0

#----------------------- END SECURITY AUTO CONFIGURATION -------------------------
node.roles: [ master ]
cluster.name: cluster-exam
```

生成CA与集群keystore, 即```elastic-certificates.p12``` 的过程  
这部分文字并不重要, 作个参考, 主要是表示都用到了口令"63834516"而非空密码  
如下:

```
[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-certutil ca \
> --out /root/elastic-stack-ca.p12 \
> --pass "63834516"
This tool assists you in the generation of X.509 certificates and certificate
signing requests for use with SSL/TLS in the Elastic stack.

The 'ca' mode generates a new 'certificate authority'
This will create a new X.509 certificate and private key that can be used
to sign certificate when running in 'cert' mode.

Use the 'ca-dn' option if you wish to configure the 'distinguished name'
of the certificate authority

By default the 'ca' mode produces a single PKCS#12 output file which holds:
    * The CA certificate
    * The CA's private key

If you elect to generate PEM format certificates (the -pem option), then the output will
be a zip file containing individual files for the CA certificate and private key

[root@elk-exam ~]# 
[root@elk-exam ~]# rm -f /root/elastic-certificates.p12
[root@elk-exam ~]# /elastic/elasticsearch-8.15.5/bin/elasticsearch-certutil cert \
> --ca /root/elastic-stack-ca.p12 \
> --ca-pass "63834516" \
> --out /root/elastic-certificates.p12 \
> --pass "63834516"
This tool assists you in the generation of X.509 certificates and certificate
signing requests for use with SSL/TLS in the Elastic stack.

The 'cert' mode generates X.509 certificate and private keys.
    * By default, this generates a single certificate and key for use
       on a single instance.
    * The '-multiple' option will prompt you to enter details for multiple
       instances and will generate a certificate and key for each one
    * The '-in' option allows for the certificate generation to be automated by describing
       the details of each instance in a YAML file

    * An instance is any piece of the Elastic Stack that requires an SSL certificate.
      Depending on your configuration, Elasticsearch, Logstash, Kibana, and Beats
      may all require a certificate and private key.
    * The minimum required value for each instance is a name. This can simply be the
      hostname, which will be used as the Common Name of the certificate. A full
      distinguished name may also be used.
    * A filename value may be required for each instance. This is necessary when the
      name would result in an invalid file or directory name. The name provided here
      is used as the directory name (within the zip) and the prefix for the key and
      certificate files. The filename is required if you are prompted and the name
      is not displayed in the prompt.
    * IP addresses and DNS names are optional. Multiple values can be specified as a
      comma separated string. If no IP addresses or DNS names are provided, you may
      disable hostname verification in your SSL configuration.


    * All certificates generated by this tool will be signed by a certificate authority (CA)
      unless the --self-signed command line option is specified.
      The tool can automatically generate a new CA for you, or you can provide your own with
      the --ca or --ca-cert command line options.


By default the 'cert' mode produces a single PKCS#12 output file which holds:
    * The instance certificate
    * The private key for the instance certificate
    * The CA certificate

If you specify any of the following options:
    * -pem (PEM formatted output)
    * -multiple (generate multiple certificates)
    * -in (generate certificates from an input file)
then the output will be be a zip file containing individual certificate/key files


Certificates written to /root/elastic-certificates.p12

This file should be properly secured as it contains the private key for 
your instance.
This file is a self contained file and can be copied and used 'as is'
For each Elastic product that you wish to configure, you should copy
this '.p12' file to the relevant configuration directory
and then follow the SSL configuration instructions in the product guide.

For client applications, you may only need to copy the CA certificate and
configure the client to trust this certificate.
[root@elk-exam ~]# 
[root@elk-exam ~]#  keytool -list -v -keystore /root/elastic-certificates.p12 -storetype PKCS12
Enter keystore password:  
Keystore type: PKCS12
Keystore provider: SunJSSE

Your keystore contains 2 entries

Alias name: ca
Creation date: Feb 11, 2025
Entry type: trustedCertEntry

Owner: CN=Elastic Certificate Tool Autogenerated CA
Issuer: CN=Elastic Certificate Tool Autogenerated CA
Serial number: 34554ad835512cfdd75fe90fe22f9c148b7e8640
Valid from: Tue Feb 11 15:59:00 CST 2025 until: Fri Feb 11 15:59:00 CST 2028
Certificate fingerprints:
	 SHA1: D0:78:4C:31:91:B2:E6:FA:26:01:02:87:8E:78:71:28:FF:65:68:6D
	 SHA256: 8D:FB:EA:A2:BB:6C:8B:34:F3:66:29:F4:D4:53:DA:79:90:AA:E8:06:8D:15:F3:51:13:65:96:18:22:20:F5:16
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions: 

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: 92 3C 28 BB 3E DB 15 7D   30 CF 83 52 CA 7D 17 2F  .<(.>...0..R.../
0010: 13 90 E2 B9                                        ....
]
]

#2: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen:2147483647
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 92 3C 28 BB 3E DB 15 7D   30 CF 83 52 CA 7D 17 2F  .<(.>...0..R.../
0010: 13 90 E2 B9                                        ....
]
]



*******************************************
*******************************************


Alias name: instance
Creation date: Feb 11, 2025
Entry type: PrivateKeyEntry
Certificate chain length: 2
Certificate[1]:
Owner: CN=instance
Issuer: CN=Elastic Certificate Tool Autogenerated CA
Serial number: 308e3cf7624ee3c2c11316308d2a5009c4746f29
Valid from: Tue Feb 11 16:05:26 CST 2025 until: Fri Feb 11 16:05:26 CST 2028
Certificate fingerprints:
	 SHA1: A2:F8:CE:20:A2:CB:AD:7A:5F:66:95:2D:60:3C:22:FE:90:A2:D5:3B
	 SHA256: F1:D3:50:C3:66:31:61:FC:DD:16:34:D5:07:D2:43:81:6D:8A:7A:9E:67:23:A9:B9:6C:C9:37:A7:70:39:DE:FE
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions: 

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: 92 3C 28 BB 3E DB 15 7D   30 CF 83 52 CA 7D 17 2F  .<(.>...0..R.../
0010: 13 90 E2 B9                                        ....
]
]

#2: ObjectId: 2.5.29.19 Criticality=false
BasicConstraints:[
  CA:false
  PathLen: undefined
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 33 38 58 61 D9 B7 2C 01   4D F4 30 6A 27 02 1F A8  38Xa..,.M.0j'...
0010: F3 E6 14 C9                                        ....
]
]

Certificate[2]:
Owner: CN=Elastic Certificate Tool Autogenerated CA
Issuer: CN=Elastic Certificate Tool Autogenerated CA
Serial number: 34554ad835512cfdd75fe90fe22f9c148b7e8640
Valid from: Tue Feb 11 15:59:00 CST 2025 until: Fri Feb 11 15:59:00 CST 2028
Certificate fingerprints:
	 SHA1: D0:78:4C:31:91:B2:E6:FA:26:01:02:87:8E:78:71:28:FF:65:68:6D
	 SHA256: 8D:FB:EA:A2:BB:6C:8B:34:F3:66:29:F4:D4:53:DA:79:90:AA:E8:06:8D:15:F3:51:13:65:96:18:22:20:F5:16
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions: 

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: 92 3C 28 BB 3E DB 15 7D   30 CF 83 52 CA 7D 17 2F  .<(.>...0..R.../
0010: 13 90 E2 B9                                        ....
]
]

#2: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen:2147483647
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 92 3C 28 BB 3E DB 15 7D   30 CF 83 52 CA 7D 17 2F  .<(.>...0..R.../
0010: 13 90 E2 B9                                        ....
]
]



*******************************************
*******************************************



```


<h3 id="5">集群构建中容易出错的点</h3>

只配置了 ```discovery.seed_hosts```, 没有声明 ```network.publish_host```

```
[2025-02-12T11:51:17,212][WARN ][o.e.c.c.ClusterFormationFailureHelper] [elasticsearch3] master 
not discovered yet, this node has not previously joined a bootstrapped cluster, and this node 
must discover master-eligible nodes [elasticsearch1] to bootstrap a cluster: have discovered 
[{elasticsearch3}{k2WB06JTSYCvPws5b0kt9Q}{cz8Xr6QWQJ-qCIEg18k8YQ}{elasticsearch3}{127.0.0.1}
{127.0.0.1:9303}{dm}{8.15.5}{7000099-8512000}]; discovery will continue using 
[192.168.1.231:9301, 192.168.1.231:9302, 192.168.1.231:9303] from hosts providers and 
[{elasticsearch3}{k2WB06JTSYCvPws5b0kt9Q}{cz8Xr6QWQJ-qCIEg18k8YQ}{elasticsearch3}{127.0.0.1}
{127.0.0.1:9303}{dm}{8.15.5}{7000099-8512000}] from last-known cluster state; node term 0, 
last-accepted version 0 in term 0; for troubleshooting guidance, see 
https://www.elastic.co/guide/en/elasticsearch/reference/8.15/discovery-troubleshooting.html
```

配置文件如下:

```
[root@elk-exam ~]# grep -v -E -e "^$" -e "^#" /elastic/elastics_exam_conf/elasticsearch1/elasticsearch.yml 
node.name: elasticsearch1
path.data: /elastic/elastics_exam_data/elasticsearch1
path.logs: /elastic/elastics_exam_logs/elasticsearch1
http.port: 9201
xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl:
  enabled: true
  keystore.path: /elastic/elastics_exam_conf/elasticsearch1/elasticsearch1.p12
  keystore.password: "63834516"
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  client_authentication: required
  keystore.path: /elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12
  keystore.password: "63834516"
  truststore.path: /elastic/elastics_exam_conf/elasticsearch1/elastic-certificates.p12
  truststore.password: "63834516"
cluster.initial_master_nodes: ["elasticsearch1"]
http.host: 0.0.0.0
node.roles: [ master,data ]
cluster.name: cluster-exam
transport.port: 9301
discovery.seed_hosts:
    - 192.168.1.231:9301
    - 192.168.1.231:9302
    - 192.168.1.231:9303
```

不单是 ```network.publish_host```  
如上示例中, 还有以下参数也没有声明  

```
network.host: 0.0.0.0
network.publish_host: 0.0.0.0
```

以上两个参数在没有声明的情况下去启动 elasticsearch  
得到的结果会发现 ```transport.port``` 监听的地址 ```127.0.0.1```  
由于是集群间节点之间通信所用的端口, 那么必然也会构建不成功  
日志中也会有明确的 ```connection refused``` 的记录  
没有保留到相关文字记录, 完整能运行的正确的配置如下

```
[root@elk-exam ~]# grep -v -E -e "^$" -e "^#" /elastic/elasticsearch1/config/elasticsearch.yml 
node.name: elasticsearch1
path.data: /elastic/elasticsearch1/data
http.port: 9201
network.host: 0.0.0.0
network.publish_host: 0.0.0.0
node.roles: [ master,data ]
cluster.name: cluster-exam
transport.port: 9301
xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl:
  enabled: true
  keystore.path: /elastic/elasticsearch1/config/certs/elasticsearch1.p12
  keystore.password: "63834516"
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  client_authentication: required
  keystore.path: /elastic/elasticsearch1/config/certs/elastic-certificates.p12
  keystore.password: "63834516"
  truststore.path: /elastic/elasticsearch1/config/certs/elastic-certificates.p12
  truststore.password: "63834516"
cluster.initial_master_nodes: ["elasticsearch1"]
discovery.seed_hosts:
    - 192.168.1.231:9301
    - 192.168.1.231:9302
    - 192.168.1.231:9303
bootstrap.memory_lock: true
```

内存不足的相关报错  
其实就是 ```jvm.options``` 未设置

https://lxblog.com/qianwen/share?shareId=dfa9df5f-1ea1-4c9b-98ff-f67d1d2399b8

<h3 id="6">elasticsearch-reset-password等相关工具的一个补充</h3>

```elasticsearch-reset-password``` 以及其他管理 ```elastic```内置用户相关的工具   
如还有 ```elasticsearch-setup-passwords``` (一个已淘汰的工具, 使用会有警告提示)  
通过查看```elasticsearch-reset-password```该命令的帮助  
有参数选项 ```--url``` 作为指定你 elastic 节点的URL位置  
这个参数的应用场景是, 如果你的 elastic 软件环境运行在并非是同一个根目录下  
举例来说, 从官网下载```elasticsearch-8.15.5-linux-x86_64.tar.gz```  
那么解压将得到```elasticsearch-8.15.5```目录  
其中包括```bin```和```config```的子目录  
如果 ```elastic``` 就在此环境下启动, 配置文件也是修改的```config```子目录下的对应文件  
则 ```elasticsearch-reset-password``` 无需给额外参数已经可以修改到 ```elastic``` 的用户密码  


但我尝试了另一种配置方式, ```elastic``` 软件可执行程序是同一份  
不同的是```config```通过不同的位置以作区分和运行  
然而就遇到的问题是, 虽然日志已显示 ```elastic```集群已启动且构建成功  
并且```http.port```定义的端口也可以登录状态  
但由于你并不知晓内置用户```elastic```的密码, 需要重置一次  
而在这种配置方式下, ```elasticsearch-reset-password```则是需要通过 ```--URL``` 指定你的节点运行的所谓```endpoint```  
然而加上 ```--URL``` 也遇到了问题, 并未能成功重置到密码  
由于官网文档未找到这部分问题的对应解决办法, 即便是在与AI大模型的多轮对话也未能找到答案

https://lxblog.com/qianwen/share?shareId=92cdb579-8d69-4a52-a8d3-437c40653c1f

https://lxblog.com/qianwen/share?shareId=b6ea9863-672c-40e6-aaab-ac6951826370

https://lxblog.com/qianwen/share?shareId=6ee1710b-f6e8-49f6-88b4-d18187d9dcb8

这暴露出的问题是:  
1) ```elasticsearch-reset-password``` 成功执行后, 究竟修改的记录是位于何处, 并不清楚, 即以```elastic```的术语称之为```keystore```是文件形式还是其他  
2) 上述我所使用的另一种配置模式下, 要想实现的真正的解决办法, 有待更新
