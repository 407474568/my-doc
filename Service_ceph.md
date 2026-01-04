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

