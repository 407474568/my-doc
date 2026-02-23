* [目录](#0)
  * [环境安装](#1)



<h3 id="1">网卡信息, 3网卡配置</h3>

为所有的虚拟机增设了第三张网卡

```shell
[root@X9DR3-F-node1 ~]# virsh list --all
 Id   Name                                                      State
--------------------------------------------------------------------------
 1    dc-1-router                                               running
 -    dc-1-kube-compute-node01                                  shut off
 -    dc-1-kube-compute-node02                                  shut off
 -    dc-1-kube-compute-node03                                  shut off
 -    dc-1-kube-compute-node04                                  shut off
 -    dc-1-kube-compute-node05                                  shut off
 -    dc-1-kube-compute-node06                                  shut off
 -    dc-1-kube-compute-node07                                  shut off
 -    dc-1-kube-compute-node08                                  shut off
 -    dc-1-kube-compute-node09                                  shut off
 -    dc-1-kube-compute-node10                                  shut off
 -    dc-1-kube-compute-node11                                  shut off
 -    dc-1-kube-compute-node12                                  shut off
 -    rocky-9.7-x86_64-system-components-upgrade-kvm-template   shut off

[root@X9DR3-F-node1 ~]# 

# 需要微调一下
for i in {01..12}; do 
  virt-xml dc-1-kube-compute-node$i --add-device --network bridge=br-k8s,model=virtio; 
done



for i in {01..12}; do 
  virt-xml dc-1-kube-compute-node$i --add-device --network bridge=br-k8s,model=virtio; 
done

for i in {01..01}; do 
  virt-xml dc-1-kube-compute-node$i --add-device --network bridge=br-k8s,model=virtio; 
done
```

dc-1-kube-compute-node 执行

```shell
nmcli con modify enp1s0 ipv4.gateway "" +ipv4.routes "192.168.96.0/19 192.168.100.1"  ipv6.method disabled
nmcli con up enp1s0


nmcli con mod enp7s0 ipv4.addresses 172.31.0.1/16 ipv4.method manual ipv6.method disabled
# 添加存储明细路由，指向 dc-1-router 的存储接口
nmcli con mod enp7s0 +ipv4.routes "172.16.0.0/24 172.31.1.254"
nmcli con up enp7s0

nmcli con add con-name enp10s0 type ethernet
nmcli con mod enp10s0 ipv4.addresses 10.100.10.1/16 ipv4.gateway 10.100.1.1 ipv4.method manual ipv6.method disabled
nmcli con up enp10s0
```

ryzen 组+存储server上执行

```shell
# DC-1
nmcli con modify br1 +ipv4.routes "172.31.0.0/16 172.16.0.251"
# DC-2
nmcli con modify br1 +ipv4.routes "172.30.0.0/16 172.16.0.252"

# DC-1 (业务段 10.100.x.x 走 1G 口 192.168.111.254)
nmcli con modify br0 +ipv4.routes "10.100.0.0/16 192.168.111.254"

# DC-2 (业务段 10.200.x.x 走 1G 口 192.168.112.254)
nmcli con modify br0 +ipv4.routes "10.200.0.0/16 192.168.112.254"

# 使其生效
nmcli con up br0;nmcli con up br1
```
