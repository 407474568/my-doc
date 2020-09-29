#### etcd集群初始化出现cluster ID mismatch的情况

![](/images/lcf2aAz4XQ3EH0YPoOdjrq6eGIFN1CSm.png)
初始化的情况  
https://www.cnops.xyz/archives/1658  
https://www.cnblogs.com/dukuan/p/8671345.html  
删除etcd数据文件, 在配置文件/etc/etcd/etcd.conf 的 [Member] 段的 ETCD_DATA_DIR 定义的位置,默认值 /var/lib/etcd/default.etcd  
所有节点都删除一遍  

#### etcd 集群新增节点  
https://www.centos.bz/2018/04/etcd%E9%9B%86%E7%BE%A4%E5%A2%9E%E5%8A%A0%E8%8A%82%E7%82%B9/  
先在集群已有节点上add 新节点,再在新节点上操作  

在集群已有节点上add 新节点,无论是否为Leader节点皆可  
示例:  
```
etcdctl member add etcd-node3 http://192.168.10.152:2380
```  
etcd-node3 为 etcd-name  
http://192.168.10.152:2380 为 ETCD_LISTEN_PEER_URLS  
![](/images/K3szqMlOiJynmv07W6RGPSjbra5VXZo4.png)  
&nbsp;

然后在新节点上修改etcd.conf&nbsp;  
唯一不同的是 ETCD_INITIAL_CLUSTER_STATE="existing"  
有些文档说的exist, 应是版本迭代关键字已失效.  
&nbsp;

同样的,遇到cluster ID mismatch , 删除新增节点上的/var/lib/etcd/default.etcd 重启服务尝试  
![](/images/8cRvIZs9n3ryCKYSoxLkeFWDbHfXq640.png)

#### etcd 删除节点  
https://github.com/k8sp/sextant/issues/333  
```
etcdctl cluster-health  # 查看各节点健康状态
etcdctl member remove 66b087520c48d825 # 从cluster中删除有问题节点
```

清空问题节点的etcd数据目录, 再添加回有问题节点, 操作步骤与新增节点相同.


#### etcd 集群整体的灾难恢复  
https://github.com/etcd-io/etcd/blob/master/Documentation/v2/admin_guide.md#disaster-recovery 