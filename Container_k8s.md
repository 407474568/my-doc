* [目录](#0)
  * [高频命令](#1)
  * [ConfigMap](#2)

<h3 id="1">高频命令</h3>

```shell
# 详细地看一个pod到底在搞什么飞机
kubectl describe pod calico-node-t542x -n kube-system

# 查看安装 CNI 配置的容器日志
kubectl logs calico-node-t542x -n kube-system -c install-cni

# 查看升级 IPAM 的容器日志
kubectl logs calico-node-t542x -n kube-system -c upgrade-ipam
```

<h3 id="2">ConfigMap</h3>

#### ConfigMap 的增删改查

- 问题: kube 的各计算/master节点, 开机自启动都会存在不断```crash-backoff```诸如此类的异常情况
- 起因: 前期集群初始化时, 经历过一些错误修复, 可能是有错误信息被散落在某个配置文件中, 也可能是kube的自发现, 发现了一个错误的APIServer的地址, 所以它无法与 APIServer 通信
- 解决方式: 利用 ConfigMap 高优先级特性, 创建一个 ConfigMap,指定正确的 APIServer, 并使 pod 在创建时要引用这个正确的信息 

用到的工具/命令

```shell
# 查看指定namespace下有哪些ConfigMap, kube-system 是 namespace, 后续不再赘述
kubectl get cm -n kube-system

[root@dc-1-kube-master-01 ~]# kubectl get cm -n kube-system
NAME                                                   DATA   AGE
calico-config                                          4      5d17h
coredns                                                1      5d18h
extension-apiserver-authentication                     6      5d18h
kube-apiserver-legacy-service-account-token-tracking   1      5d18h
kube-proxy                                             2      5d18h
kube-root-ca.crt                                       1      5d18h
kubeadm-config                                         1      5d18h
kubelet-config                                         1      5d18h
kubernetes-services-endpoint                           2      3m44s


# 查看某个 cm 的具体内容：
kubectl describe cm kubernetes-services-endpoint -n kube-system
# 或者看完整的 yaml 格式：
kubectl get cm kubernetes-services-endpoint -n kube-system -o yaml


```

存在错误时的问题现象, ```Unknown```只是其中之一, 也可以```CrashBackOff```

```shell
[root@dc-1-kube-master-01 ~]# watch kubectl get pods -n kube-system -o wide

Every 2.0s: kubectl get pods -n kube-system -o wide                                                                                                                     dc-1-kube-master-01: Thu Mar 19 10:14:49 2026

NAME                                          READY   STATUS    RESTARTS      AGE     IP              NODE                       NOMINATED NODE   READINESS GATES
calico-kube-controllers-66dc6f5694-69f59      1/1     Running   2 (42m ago)   3d13h   10.101.73.4     dc-1-kube-compute-node09   <none>           <none>
calico-node-49h89                             1/1     Running   3 (41m ago)   3d13h   10.100.0.5	dc-1-kube-compute-node05   <none>           <none>
calico-node-5q6rg                             1/1     Running   2 (44m ago)   3d13h   10.100.0.203    dc-1-kube-master-03        <none>           <none>
calico-node-6zm8k                             1/1     Running   2 (42m ago)   3d13h   10.100.0.9	dc-1-kube-compute-node09   <none>           <none>
calico-node-87cn5                             1/1     Running   2 (43m ago)   3d13h   10.100.0.3	dc-1-kube-compute-node03   <none>           <none>
calico-node-bzr4z                             1/1     Running   2 (44m ago)   3d13h   10.100.0.1	dc-1-kube-compute-node01   <none>           <none>
calico-node-cj8hk                             1/1     Running   2 (44m ago)   3d13h   10.100.0.201    dc-1-kube-master-01        <none>           <none>
calico-node-f8n9t                             0/1     Unknown   0             3d13h   10.100.0.8	dc-1-kube-compute-node08   <none>           <none>
calico-node-jqqs5                             1/1     Running   2 (42m ago)   3d13h   10.100.0.12     dc-1-kube-compute-node12   <none>           <none>
calico-node-kxls7                             1/1     Running   2 (44m ago)   3d13h   10.100.0.202    dc-1-kube-master-02        <none>           <none>
calico-node-n7wzx                             1/1     Running   2 (42m ago)   3d13h   10.100.0.7	dc-1-kube-compute-node07   <none>           <none>
calico-node-p9q67                             1/1     Running   2 (43m ago)   3d13h   10.100.0.6	dc-1-kube-compute-node06   <none>           <none>
calico-node-pvwj9                             1/1     Running   2 (42m ago)   3d13h   10.100.0.10     dc-1-kube-compute-node10   <none>           <none>
calico-node-r67rv                             1/1     Running   4 (42m ago)   3d13h   10.100.0.2	dc-1-kube-compute-node02   <none>           <none>
calico-node-t4j69                             1/1     Running   2 (42m ago)   3d13h   10.100.0.11     dc-1-kube-compute-node11   <none>           <none>
calico-node-znmrk                             1/1     Running   2 (43m ago)   3d13h   10.100.0.4	dc-1-kube-compute-node04   <none>           <none>
coredns-bbdc5fdf6-dvctr                       1/1     Running   2 (44m ago)   3d14h   10.101.115.7    dc-1-kube-compute-node02   <none>           <none>
coredns-bbdc5fdf6-gs7dc                       1/1     Running   2 (43m ago)   3d14h   10.101.229.67   dc-1-kube-compute-node04   <none>           <none>
kube-apiserver-dc-1-kube-master-01            1/1     Running   4 (44m ago)   5d18h   10.100.0.201    dc-1-kube-master-01        <none>           <none>
kube-apiserver-dc-1-kube-master-02            1/1     Running   2 (44m ago)   3d14h   10.100.0.202    dc-1-kube-master-02        <none>           <none>
kube-apiserver-dc-1-kube-master-03            1/1     Running   2 (44m ago)   3d14h   10.100.0.203    dc-1-kube-master-03        <none>           <none>
kube-controller-manager-dc-1-kube-master-01   1/1     Running   5 (42m ago)   5d18h   10.100.0.201    dc-1-kube-master-01        <none>           <none>
kube-controller-manager-dc-1-kube-master-02   1/1     Running   2 (44m ago)   3d14h   10.100.0.202    dc-1-kube-master-02        <none>           <none>
kube-controller-manager-dc-1-kube-master-03   1/1     Running   3 (44m ago)   5d18h   10.100.0.203    dc-1-kube-master-03        <none>           <none>
kube-proxy-4gdrr                              1/1     Running   2 (44m ago)   3d13h   10.100.0.202    dc-1-kube-master-02        <none>           <none>
kube-proxy-5t45l                              1/1     Running   2 (43m ago)   3d13h   10.100.0.3	dc-1-kube-compute-node03   <none>           <none>
kube-proxy-7gp67                              0/1     Unknown   0             3d13h   10.100.0.8	dc-1-kube-compute-node08   <none>           <none>
kube-proxy-7jbp6                              1/1     Running   2 (44m ago)   3d13h   10.100.0.2	dc-1-kube-compute-node02   <none>           <none>
kube-proxy-c2t4r                              1/1     Running   2 (43m ago)   3d13h   10.100.0.4	dc-1-kube-compute-node04   <none>           <none>
kube-proxy-hvk7s                              1/1     Running   2 (42m ago)   3d13h   10.100.0.9	dc-1-kube-compute-node09   <none>           <none>
kube-proxy-jd5pq                              1/1     Running   2 (43m ago)   3d13h   10.100.0.5	dc-1-kube-compute-node05   <none>           <none>
kube-proxy-m8k9q                              1/1     Running   2 (42m ago)   3d13h   10.100.0.12     dc-1-kube-compute-node12   <none>           <none>
kube-proxy-md2ft                              1/1     Running   2 (44m ago)   3d13h   10.100.0.1	dc-1-kube-compute-node01   <none>           <none>
kube-proxy-pjzs8                              1/1     Running   2 (43m ago)   3d13h   10.100.0.6	dc-1-kube-compute-node06   <none>           <none>
kube-proxy-v77sr                              1/1     Running   2 (42m ago)   3d13h   10.100.0.10     dc-1-kube-compute-node10   <none>           <none>
kube-proxy-vbph6                              1/1     Running   2 (42m ago)   3d13h   10.100.0.7	dc-1-kube-compute-node07   <none>           <none>
kube-proxy-vfmkq                              1/1     Running   2 (42m ago)   3d13h   10.100.0.11     dc-1-kube-compute-node11   <none>           <none>
kube-proxy-xlz7h                              1/1     Running   2 (44m ago)   3d13h   10.100.0.203    dc-1-kube-master-03        <none>           <none>
kube-proxy-zcbvf                              1/1     Running   2 (44m ago)   3d13h   10.100.0.201    dc-1-kube-master-01        <none>           <none>
kube-scheduler-dc-1-kube-master-01            1/1     Running   6 (42m ago)   5d18h   10.100.0.201    dc-1-kube-master-01        <none>           <none>
kube-scheduler-dc-1-kube-master-02            1/1     Running   3 (42m ago)   5d18h   10.100.0.202    dc-1-kube-master-02        <none>           <none>
kube-scheduler-dc-1-kube-master-03            1/1     Running   2 (44m ago)   3d14h   10.100.0.203    dc-1-kube-master-03        <none>           <none>
```