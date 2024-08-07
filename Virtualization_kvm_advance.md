* [目录](#0)
  * [去除虚拟机特征](#1)
  * [GPU直通](#2)
  * [磁盘设备直通](#3)
  * [PCI设备直通](#4)
  * [USB设备直通](#5)
  * [网卡和硬盘类型改 virtio](#6)
  * [x86模拟ARM环境](#7)
  * [内存膨胀](#8)
  * [禁用不需要的启动项](#9)
  * [非典型网络拓扑架构下的通信/静态路由问题](#10)
  * [为虚拟机添加一个虚拟声卡](#11)
  * [绑定CPU核心](#12)
  

<h3 id="1">去除虚拟机特征</h3>

这篇文章 qlf2012 的回答从原理层面作了解释  
https://www.zhihu.com/question/359121561  
实操层面给了一些示例,但偏少  

##### 让虚拟机的CPU型号与宿主机一致  
https://blog.51cto.com/molewan/1926131  
具体我的做法是:  
原本  

```
  <cpu mode='host-passthrough' check='none'/>
```

改为了

```
  <cpu mode='host-passthrough' check='none'>
    <feature policy='disable' name='hypervisor'/>
  </cpu>

```

#### 核心数受限的问题

https://blog.51cto.com/iyull/1864357?spm=a2c6h.12873639.article-detail.4.40e537d5a2GIqa  

实际原因是 guestOS 的类型, 例如 win7 只支持2颗CPU  
而KVM 默认情况下 一个每个CPU模拟一个socket，必须修改虚拟机CPU的topology，才能使用超过一个CPU。  

语句如下  

```
  <cpu>
    <topology sockets='2' cores='2' threads='2'/>
  </cpu>
```

如果是在前面同时配置了CPU型号直通给虚拟机, 实际情况就类似如下:  

```
  <cpu mode='host-passthrough' check='none'>
    <topology sockets='2' dies='1' cores='2' threads='2'/>
    <feature policy='disable' name='hypervisor'/>
  </cpu>
```

除此之外

```
  <vcpu placement='static'>32</vcpu>
```

也同步做修改.

不过依然要注意的是, 在有反虚拟化技术的情况下, 不正确的核心数等相关CPU信息, 依然也是被反虚拟化技术捕获的特征之一.

##### 隐藏KVM Hypervisor信息
在```<features>``` 段落中插入以下内容  

```
<hyperv>
  <vendor_id state="on" value="random"/>
</hyperv>
<kvm>
  <hidden state="on"/>
</kvm>
```

原本的示例

```
  <features>
    <acpi/>
    <apic/>
    <hyperv>
      <relaxed state='on'/>
      <vapic state='on'/>
      <spinlocks state='on' retries='8191'/>
    </hyperv>
  </features>
```

修改后的示例

```
  <features>
    <acpi/>
    <apic/>
    <hyperv>
      <relaxed state='on'/>
      <vapic state='on'/>
      <spinlocks state='on' retries='8191'/>
      <vendor_id state='on' value='random'/>
    </hyperv>
    <kvm>
      <hidden state='on'/>
    </kvm>
  </features>
```


另一种方法:  
为虚拟机添加 ```<features>``` 段落定义
```
$ virsh edit windows
<domain>
  <features> # 在features中添加vendor_id, kvm, ioapic项目
    <hyperv>
      <vendor_id state='on' value='0123456789ab'/> # value可以是任意值
    </hyperv>
    <kvm>
      <hidden state='on'/>
    </kvm>
    <ioapic driver='kvm'/>
  </features>
</domain>
```





<h3 id="2">GPU直通</h3>

另一个前期整理的笔记  
<a href="files/KVM直通相关.sh" target="_blank">KVM直通相关.sh</a>

https://blog.csdn.net/u010099177/article/details/120709515    
https://blog.acesheep.com/index.php/archives/720/  
https://blog.csdn.net/hbuxiaofei/article/details/106566348  
https://doowzs.com/posts/2021/04/rtx-vfio-passthrough/  
https://www.jianshu.com/p/52cc99a9befd  

KVM配置GPU直通有 pci-stub 和 vfio 两种模式  
根据早一点的文档反应, vfio 配置过程遇到问题, 实际上我的配置一路通畅  
pci-stub 属于更"传统"的方式  
vfio 属于KVM后来版本迭代中出现的更新的一种方法, 技术原理上有更多优势.  

流程:  
1) 宿主机开启IOMMU  
2) 禁用nouveau 驱动  
3) 加载vfio-pci 内核模块  
4) 为虚拟机配置直通GPU  




#### 1) 宿主机开启IOMMU

以下是grub2的操作步骤  

修改/etc/default/grub，在GRUB_CMDLINE_LINUX_DEFAULT中添加内核启动参数

Intel CPU添加 intel_iommu=on  
AMD CPU添加 amd_iommu=on iommu=pt  

![](images/RSiM0HtZIo0lcFCMg31nuBwHx9DKoJE8.png)

更新grub2启动参数

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```

重启系统后验证

```
grep intel_iommu=on /proc/cmdline 

dmesg | grep -E "DMAR|IOMMU"
```

#### 2) 禁用nouveau 驱动

先通过lspci 命令, 在第一列的信息即为该设备的PCI-E设备的序号

```
lspci -nnk | grep -i nvidia
```

示例输出如下

```
[root@3700X vm]# lspci -nnk | grep -i nvidia
27:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA106 [GeForce RTX 3060] [10de:2503] (rev a1)
27:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:228e] (rev a1)
```

即  
27:00.0  
27:00.1  
则为同组设备的两个子类(显卡可能还包括USB控制器等其他设备,也可能有4个)  
将这两个序号再进行查询使用到的驱动
```
lspci -vv -s 27:00.0 | grep driver
lspci -vv -s 27:00.1 | grep driver
```

<br>

查到的驱动就是需要纳入屏蔽清单的内容  

```
[root@3700X vm]# cat /etc/modprobe.d/blacklist.conf
blacklist nouveau
blacklist snd_hda_intel
```

<br>

vim /usr/lib/modprobe.d/dist-blacklist.conf  
加上一行options nouveau modeset=0  

```
[root@3700X vm]# tail /usr/lib/modprobe.d/dist-blacklist.conf
# ISDN - see bugs 154799, 159068
blacklist hisax
blacklist hisax_fcpcipnp

# sound drivers
blacklist snd-pcsp

# I/O dynamic configuration support for s390x (bz #563228)
blacklist chsc_sch
options nouveau modeset=0
```

<br>

#### 3) 加载vfio-pci 内核模块
```
# 显示显卡的PCI认证数字和[供应商ID:设备ID]
$ lspci -nn | grep -i nvidia
3b:00.0 3D controller [0302]: NVIDIA Corporation GP104GL [Tesla P4] [10de:1bb3] (rev a1)
86:00.0 3D controller [0302]: NVIDIA Corporation GP104GL [Tesla P4] [10de:1bb3] (rev a1)

# 编辑vfio配置文件
$ vim /etc/modprobe.d/vfio.conf
# 创建一个新行，指定ids=供应商ID:设备ID
options vfio-pci ids=10de:1bb3,10de:1bb3

# 创建一个新文件，写入 vfio-pci
$ echo 'vfio-pci' > /etc/modules-load.d/vfio-pci.conf

$ reboot  # 重启
```

重启后验证
```
dmesg -T | grep -i vfio
```
有类似以下输出, 标志vfio方式加载成功
```
[root@3700X ~]# dmesg -T | grep -i vfio
[Wed Mar 23 00:55:50 2022] VFIO - User Level meta-driver version: 0.3
[Wed Mar 23 00:55:50 2022] vfio_pci: add [10de:1180[ffffffff:ffffffff]] class 0x000000/00000000
[Wed Mar 23 00:55:50 2022] vfio_pci: add [10de:0e0a[ffffffff:ffffffff]] class 0x000000/00000000
[Wed Mar 23 00:57:39 2022] vfio-pci 0000:27:00.0: vgaarb: changed VGA decodes: olddecodes=io+mem,decodes=none:owns=io+mem
[Wed Mar 23 00:57:39 2022] vfio-pci 0000:27:00.1: vfio_ecap_init: hiding ecap 0x25@0x160
[Wed Mar 23 00:57:39 2022] vfio-pci 0000:27:00.0: vfio_ecap_init: hiding ecap 0x1e@0x258
[Wed Mar 23 00:57:39 2022] vfio-pci 0000:27:00.0: vfio_ecap_init: hiding ecap 0x19@0x900
[Wed Mar 23 00:57:39 2022] vfio-pci 0000:27:00.0: vfio_ecap_init: hiding ecap 0x26@0xc1c
[Wed Mar 23 00:57:39 2022] vfio-pci 0000:27:00.0: vfio_ecap_init: hiding ecap 0x27@0xd00
[Wed Mar 23 00:57:39 2022] vfio-pci 0000:27:00.0: vfio_ecap_init: hiding ecap 0x25@0xe00
[Wed Mar 23 00:57:39 2022] vfio-pci 0000:27:00.0: No more image in the PCI ROM
```

#### 4) 为虚拟机配置直通GPU
在kvm虚拟机里添加直通的GPU设备有两种方式可选
- 手动修改配置定义xml文件里添加配置项
- 单独为新增的设备信息创建xml, 用 virsh attach-device的方式导入
两者实际上也都是编辑xml文件, 并要求语法的正确性, 所以也不存在太大区别,任选一种即可.

##### 手动修改配置定义xml文件里添加
这里先引用  
https://blog.acesheep.com/index.php/archives/720/  
内的讲解

```
lspci -nn | grep -i nvidia
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation TU102 [GeForce RTX 2080 Ti Rev. A] [10de:1e07] (rev a1)
01:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:10f7] (rev a1)
01:00.2 USB controller [0c03]: NVIDIA Corporation Device [10de:1ad6] (rev a1)
01:00.3 Serial bus controller [0c80]: NVIDIA Corporation Device [10de:1ad7] (rev a1)
```
```
这里列出的PCI 设备序号 01:00.0 01:00.1 01:00.2 01:00.3
01:00.0 这里需要对应配置文件的 <source> 节点里面 
<address domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
<hostdev> 里面是直通一个PCI 设备, 例如我这里有4个需要穿透到里面,就要有4个<hostdev>
```

这里可以看见示例里是一张2080Ti的显卡
01:00.0  
01:00.1  
01:00.2  
01:00.3  
是同一个设备下的4个子设备
格式参照如下  
bus号:slot号.function号  

一个 hostdev 定义项的示例
```
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <driver name='vfio'/>
      <source>
        <address domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
      </source>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </hostdev>
```
其中 <source> </source> 之间定义的是宿主机上的设备信息  
对应填入在 lspci -nn | grep -i nvidia 看到的通道号信息  
```</source>``` 下一行的```<address ```则是虚拟机上的位置信息, 是可选的, 即使不填入, 在完成编辑后的虚拟机首次启动也会自动生成.


在我自己设备上的实例
```
[root@3700X ~]# lspci -nn | grep -i nvidia
27:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA106 [GeForce RTX 3060] [10de:2503] (rev a1)
27:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:228e] (rev a1)

[root@3700X ~]# virsh dumpxml miner-09 | less
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <driver name='vfio'/>
      <source>
        <address domain='0x0000' bus='0x27' slot='0x00' function='0x1'/>
      </source>
      <alias name='hostdev0'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
    </hostdev>
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <driver name='vfio'/>
      <source>
        <address domain='0x0000' bus='0x27' slot='0x00' function='0x0'/>
      </source>
      <alias name='hostdev1'/>
      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </hostdev>
```


2022-05-26 增补

"BAR 1: can't reserve [mem ....."  错误的处理

报错内容如下

```
[root@5950X vm]# dmesg -T | grep -i vfio | tail
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
[Thu May 26 17:04:45 2022] vfio-pci 0000:0d:00.0: BAR 1: can't reserve [mem 0xd0000000-0xdfffffff 64bit pref]
```

起因是显卡硬件设备发生变化, 最初的排错是修改  

/etc/modprobe.d/vfio.conf 里的 供应商ID:设备ID

但重启后发现虚拟机启动依然报错, 此时查看dmesg 发现有上述报错内容  

解决办法在此处找到  

https://forum.proxmox.com/threads/problem-with-gpu-passthrough.55918/

以更新grub 参数的方式,屏蔽 efi 对GPU的使用

```
GRUB_CMDLINE_LINUX="textonly video=astdrmfb video=efifb:off"
```

于是我的 grub 更新为了

```
[root@5950X ~]# cat /proc/cmdline 
BOOT_IMAGE=(hd1,msdos2)/vmlinuz-5.10.90 root=/dev/mapper/rootvg-lvroot ro crashkernel=auto rd.lvm.lv=rootvg/lvroot rhgb quiet amd_iommu=on iommu=pt textonly video=astdrmfb video=efifb:off
```

问题的确得到了解决, 虚拟机启动不再hang住最后蓝屏

~~然而这个方案也并不完美, 因为有一个代价是:~~

~~VNC连接, 即用作虚拟机显示器用途的, 不再能正常显示图像~~

2022-07-05 更正  
上述问题并非必然结果, 应是特定bug, KVM宿主机重启后有可能故障解决.

<h3 id="3">磁盘设备直通</h3>

- 以块设备的方式提供虚拟机使用, 但不使用KVM提供的缓存层

#### 2022-08-17 增补  

综合来看这应该是最灵活的方式

https://www.zywvvd.com/notes/system/linux/kvm/kmv-sata-through/kmv-sata-through/

关键点, KVM虚拟机的配置文件, ```driver``` 一行要多出这两个参数

```
cache='none' io='native'
```

当然 io 除了```native``` 还有别的选择,  需要另查

在我的例子中, 如下

```
    <disk type='block' device='disk'>
      <driver name='qemu' type='raw' cache='none' io='native'/>
      <source dev='/dev/sda' index='2'/>
      <backingStore/>
      <target dev='vdb' bus='virtio'/>
      <alias name='virtio-disk1'/>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </disk>
```

其中  
```address``` 行 依然是KVM自动生成的, 可以不填.  
```source```  行 的 ```index='2'``` 也是不需要填的.  
```<backingStore/>``` 行, 自动生成的.  
```alias``` 行, 自动生成的.  


作为对比测试, 分别使用fio进行 物理机直测, virtio 模式的KVM虚拟机测试, 不使用缓存层的KVM虚拟机测试


物理机直测, 如下

![](images/wT1roUFlKm8TREw2MhLdkQ3C6yYJulGD.jpg)


virtio 模式的KVM虚拟机测试, 如下

![](images/wT1roUFlKmpAtMgDBS6VKd4cOfo7kyLC.jpg)

不使用缓存层的KVM虚拟机测试, 如下

![](images/wT1roUFlKmIbv6Y3mFEV45KtU7w0fpin.jpg)

可见  
virtio 模式的KVM虚拟机测试, 跑出了非常离谱的数据, 实际是内存作为缓存的性能的影响  
不使用缓存层的KVM虚拟机测试, 就与存储本体在物理机上直测的结果非常吻合了.

- 以块设备的方式提供虚拟机使用

这应该只是 kvm 直通磁盘方式的其中一种选择
  
https://www.cnblogs.com/EasonJim/p/11629211.html  
https://chubuntu.com/questions/15902/add-physical-disk-to-kvm-virtual-machine.html  
  
```
    <disk type='block' device='disk'>
      <driver name='qemu' type='raw'/>
      <source dev='/dev/nvme1n1' index='3'/>
      <target dev='sdb' bus='virtio'/>
      <alias name='virtio-disk1'/>
    </disk>
    <disk type='block' device='disk'>
      <driver name='qemu' type='raw'/>
      <source dev='/dev/sda' index='2'/>
      <target dev='sdc' bus='virtio'/>
      <alias name='virtio-disk2'/>
    </disk>
```
  
这种方法确实有够简便, SATA 和 NVMe M.2 两种接口形式的SSD都得到了添加.

bus 类型除了 ```virtio``` 还有 ```scsi``` 和 ```ide```

很可惜, 实测下来, 除了连续大块IO, ```scsi``` 比 ```virtio``` 有更大的缓存效果以外,
无论 ```scsi``` 还是 ```virtio``` 在各种类型的小块IO 上均造成了瓶颈限制, 限制了SSD的性能发挥.   
也就是说, 这种方式仅限于并不怎么计较IO性能损失的情景.

一样的文章还有  

https://blog.acesheep.com/index.php/archives/720/  

引用它的原文

>本段文章  
2012/10/14: Adding a Physical Disk to a Guest with Libvirt / KVM 
http://ronaldevers.nl/2012/10/14/adding-a-physical-disk-kvm-libvirt.html  
使用virt-manager无法做到这一点。据我所知，virt-manager适用于存储池。您可以将磁盘设置为存储池，但不能将现有磁盘直接添加到VM。  
幸运的是：手动将磁盘添加到域的xml配置文件中。/etc/libvirt/qemu/<your-vm>.xml 在编辑器中打开并在```<devices>```部分添加 ```<disk>```

```
<disk type='block' device='disk'>
  <driver name='qemu' type='raw'/>
  <source dev='/dev/md/storage'/>
  <target dev='vdb' bus='virtio'/>
  <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/> #我的配置文件加入了这部分
</disk>
```


- PCI-E的SSD使用与显卡相同的透传方式

走PCI-E通道的SSD, 例如M.2 / U.2 接口形式或是本身就是PCI-E插卡式的SSD, 那么自然也同样具有PCI-E插槽的通道号等

光查看通道号不难, ```lspci``` 即可

```
[root@5950X-node1 ~]# lspci | grep -i samsung
01:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller SM981/PM981/PM983
04:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller SM981/PM981/PM983
```

但需要知道它和 ```/dev``` 下的盘符是如何对应的.  

绝大多数文章引用了它  
https://blog.weixiaoline.com/956.html  

但实际上, ```/sys/class/block/``` 下的编号很容易让人困惑, 究竟哪一个是bus号?  

```
[root@5950X-node1 ~]# ll /sys/class/block/
total 0
lrwxrwxrwx 1 root root 0 Jul  4 23:05 dm-0 -> ../../devices/virtual/block/dm-0
lrwxrwxrwx 1 root root 0 Jul  4 23:05 nvme0n1 -> ../../devices/pci0000:00/0000:00:01.1/0000:01:00.0/nvme/nvme0/nvme0n1
lrwxrwxrwx 1 root root 0 Jul  4 23:05 nvme0n1p1 -> ../../devices/pci0000:00/0000:00:01.1/0000:01:00.0/nvme/nvme0/nvme0n1/nvme0n1p1
lrwxrwxrwx 1 root root 0 Jul  4 23:05 nvme0n1p2 -> ../../devices/pci0000:00/0000:00:01.1/0000:01:00.0/nvme/nvme0/nvme0n1/nvme0n1p2
lrwxrwxrwx 1 root root 0 Jul  4 23:05 nvme0n1p3 -> ../../devices/pci0000:00/0000:00:01.1/0000:01:00.0/nvme/nvme0/nvme0n1/nvme0n1p3
lrwxrwxrwx 1 root root 0 Jul  4 23:05 nvme1n1 -> ../../devices/pci0000:00/0000:00:01.2/0000:02:00.0/0000:03:01.0/0000:04:00.0/nvme/nvme1/nvme1n1
lrwxrwxrwx 1 root root 0 Jul  4 23:05 nvme1n1p1 -> ../../devices/pci0000:00/0000:00:01.2/0000:02:00.0/0000:03:01.0/0000:04:00.0/nvme/nvme1/nvme1n1/nvme1n1p1
lrwxrwxrwx 1 root root 0 Jul  4 23:05 sda -> ../../devices/pci0000:00/0000:00:01.2/0000:02:00.0/0000:03:09.0/0000:0b:00.0/ata2/host1/target1:0:0/1:0:0:0/block/sda
lrwxrwxrwx 1 root root 0 Jul  4 23:05 sda1 -> ../../devices/pci0000:00/0000:00:01.2/0000:02:00.0/0000:03:09.0/0000:0b:00.0/ata2/host1/target1:0:0/1:0:0:0/block/sda/sda1
```

华3的这篇文档给出了正解  
https://www.h3c.com/cn/Service/Document_Software/Document_Center/Home/Server/00-Public/Installation/Installation_Manual/H3C_NVMe-789/

它指出, 以下位置的是bus号

![](images/inhN89sry5D7J10zQdWKrIoNufwU5Oxj.png)

但如果只给结论, 没法证明, 那也有理由可以怀疑前面的 ```0000:00:01```, ```0000:02:00.0```, ```0000:03:01.0``` 中的任何一个都可能是bus号.

验证的方法就是 ```lspci -vvs <bus号>```

```
[root@5950X-node1 ~]# lspci -vvs 0000:04:00.0
04:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller SM981/PM981/PM983 (prog-if 02 [NVM Express])
	Subsystem: Samsung Electronics Co Ltd Device a801
<更多无关输出省略>
```

由此可得以对照

<font color=red>2022-07-05 实测结果</font>   

将PCI-E SSD当成 GPU直通 处理, 因为需要更新grub选项且使用 stub语句 排除掉该SSD的通道号,最后   
```grub2-mkconfig -o /boot/grub2/grub.cfg```  
然后, 重启无法引导  
待解  


<h3 id="4">PCI设备直通</h3>

https://blog.csdn.net/hbuxiaofei/article/details/106589170

两种典型的做法:

- pci passthrough
- vfio

pci passthrough 的做法

1) 预先配置:  

a. 打开bios中的VT-d设置  

b. kernel引导配置iommu (iommu 的开启方法见GPU直通部分)

2) 识别设备

```
# virsh nodedev-list --tree |grep pci
```

3) 获取设备xml

```
# virsh nodedev-dumpxml pci_8086_3a6
```

4) detach设备

```
# virsh nodedev-dettach pci_8086_3a6c
```

5) 改动虚拟机xml文件 将dumpxml查询到的bus,slot,function填入

```
<devices>
......
<hostdev mode='subsystem' type='pci' managed='yes'>
 <source>
   <address domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
 </source>
</hostdev>
......
</devices>
```

VFIO 的做法  

在已打开 iommu 的前提下, vfio 具体操作更为简便, 无需变更宿主机层面.  

只需要在虚拟机中加入配置语句  

原作者的示例  

```
<devices>
......
<hostdev mode='subsystem' type='pci' managed='yes'>
 <driver name='vfio'/> 
 <source>
   <address domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
 </source>
 <rom bar='off'/>
</hostdev>
......
</devices>
```

我的示例, 这里是一张HBA卡  

```
[root@3700X vm]# lspci | grep 2308
28:00.0 Serial Attached SCSI controller: Broadcom / LSI SAS2308 PCI-Express Fusion-MPT SAS-2 (rev 05)
```

```
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <driver name='vfio'/>
      <source>
        <address domain='0x0000' bus='0x27' slot='0x00' function='0x0'/>
      </source>
      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </hostdev>
```

并且实践下来发现, vfio 的模式与 vmware 有着相近的行为模式.  

HBA卡上的 SAS 硬盘在没有虚拟机占用时, 会被宿主机系统发现并分配盘符.  
指定分配给给虚拟机, 且虚拟机开机后, 直通给虚拟机, 宿主机系统取消盘符.  
虚拟机关机后, 盘符再次回归.  
具有相同的热插拔效果.  


<font color=red>另外</font>  

这也的确是更为精确的获得你设备的通道号的办法, 配置语句都为你已经生成好.

```
# virsh nodedev-list --tree |grep pci
# virsh nodedev-dumpxml pci_8086_3a6
```


<h3 id="5">USB设备直通</h3>

https://www.modb.pro/db/402347

首先是 ```lsusb``` 命令, 从中找出需要直通的对象

```
[root@5950X-node1 vm]# lsusb
Bus 006 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 005 Device 005: ID 0bda:b711 Realtek Semiconductor Corp. RTL8188GU 802.11n WLAN Adapter (After Modeswitch)
Bus 005 Device 007: ID 0001:0000 Fry's Electronics 
Bus 005 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 003 Device 002: ID 0b05:18f3 ASUSTek Computer, Inc. 
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 003: ID 0e8d:0608 MediaTek Inc. 
Bus 001 Device 002: ID 05e3:0610 Genesys Logic, Inc. Hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

在我的示例中, 我的对象是它

```
Bus 005 Device 007: ID 0001:0000 Fry's Electronics 
```

在不能确定是哪个的情况下, 也只好通过反复插拔usb设备来确定.

在上面的信息也包括了需要配置到KVM虚拟机配置文件里的内容.

KVM配置文件的示例

```
    <hostdev mode='subsystem' type='usb' managed='yes'>
      <source>
        <vendor id='0x0001'/>
        <product id='0x0000'/>
        <address bus='5' device='7'/>
      </source>
      <alias name='hostdev0'/>
      <address type='usb' bus='0' port='2'/>
    </hostdev>
```

其中  
```Bus 005 Device 007``` 对应KVM里的 ```<address bus='5' device='7'/>```  
```ID 0001:0000``` 对应KVM里的 ```<vendor id='0x0001'/>``` 和 ```<product id='0x0000'/>```

<h3 id="6">网卡和硬盘类型改 virtio</h3>


宿主机上是 三星970 EVO plus 512G 的 NVMe 固态  
在启用 virtio 前后的虚拟机 使用 Crystaldiskmark 6 测的基准情况对比如下  
磁盘IO-启用前  

![](images/aYdg0j1LAkTdVipBP3rOQ1sq2u7GZIU6.png)

磁盘IO-启用后  

![](images/aYdg0j1LAkiV9s5tcdZS1mBbOaXrKH2u.png)

千兆网卡启用前后并无明显差异  

![](images/aYdg0j1LAkULcPJgkHrM72RdXwFuBp6i.png)

![](images/aYdg0j1LAkFdPpXLRMftz6x0U5GZYE4o.png)

操作方法  
https://blog.51cto.com/u_15329153/4598066  
这篇文档给出2种方式  
1) 虚拟机已装好了系统, IDE改virtio  
2) 虚拟机使用 virtio 全新安装windows操作系统

第1种方式先装出系统, 然后分别多添加一块 virtio 类型的网卡和磁盘, 再安装 virtio 的windows驱动, 使windows有能力识别  
第2种方式是通过有集成 virtio 驱动的第三方 Win PE 在 PE使用系统安装助手的第三方工具辅助 windows 原版ISO的安装

<font color=red>注意:  </font>  

系统安装时, 是 qemu 的硬盘, 则即使Windows 虚拟机安装了 virtio-win , 如果直接修改磁盘类型为 virtio, 则系统启动时依然会蓝屏.  
依然需要额外添加一块 virtio 类型的硬盘, 待windows识别以后, 再将系统盘改为 virtio 类型,才可以正常使用


具体到修改虚拟机配置  
https://blog.51cto.com/u_15329153/4589606  


在我的实例上  
磁盘的修改前后  

```
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/vm/games_mu_02.qcow2'/>
      <target dev='sda' bus='sata'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
```

```
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/vm/games_mu_01.qcow2'/>
      <target dev='sda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </disk>
```

重点在```<address>```标签内, slot要注意不要与已有的冲突  
bus 可以参照已有的硬盘内容, 如没有则可以从 0x00 开始尝试  


网卡的修改前后

```
    <interface type='bridge'>
      <mac address='52:54:00:91:65:22'/>
      <source bridge='br0'/>
      <model type='e1000e'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
```

```
    <interface type='bridge'>
      <mac address='52:54:00:db:52:a3'/>
      <source bridge='br0'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </interface>
```


<h3 id="7">x86模拟ARM环境</h3>

- 目标是创建受 libvirt 管理的模拟 aarch64 的环境
- 在已有libvirt, virt-install, virt-manager的前提下
- 宿主机只使用命令行, 不使用图形界面

在参考此文档之后,走通流程  
https://blog.csdn.net/c5113620/article/details/115434366  

其他文档  
https://www.codetd.com/en/article/6422338  
https://blog.csdn.net/chenxiangneu/article/details/78955462?utm_source=blogxgwz3  
2篇相同, 只是对英文的翻译  


流程如下

- 编译安装Python 3 
  (由于我选择了当前最新的qemu稳定版(6.2), 因此对python解释器的版本要求大于3.6)
- 编译安装qemu
- 下载安装edk2-aarch64 (aarch64的uefi BIOS文件)
- virsh 建立虚拟机


1) 编译安装python3.10.4  
   略


2) 编译安装qemu  
https://download.qemu.org/  
参考文档作者的原文
```
yum groupinstall 'Development Tools' -y
yum groupinstall "Virtualization Host" -y
yum install kvm qemu virt-viewer virt-manager libvirt libvirt-python python-virtinst
systemctl enable libvirtd
systemctl start libvirtd
usermod -aG libvirt $(whoami)
yum install virt-install virt-viewer virt-manager -y
vi /etc/libvirt/qemu.conf # 打开两个注释 user="root" 和 group="root"
reboot

# 编译qemu-system-aarch64
tar xf qemu-4.2.0.tar.xz
cd qemu-4.2.0/
yum install python2 zlib-devel glib2-devel pixman-devel -y
./configure --target-list=aarch64-softmmu --prefix=/usr
make -j8
make install  # default location /usr/local/bin/qemu-system-aarch64
```

编译安装会遇到提示没有ninja, 需要下载  
https://github.com/ninja-build/ninja/releases  
下载后放到可被执行的目录如/bin , /sbin, /usr/sbin 等, 或是配置环境变量皆可    
实际上我执行的

```
yum groupinstall 'Development Tools' -y
yum groupinstall "Virtualization Host" -y
tar -xvf qemu-6.2.0.tar.xz
cd qemu-6.2.0/
yum install python2 zlib-devel glib2-devel pixman-devel
./configure --target-list=aarch64-softmmu --prefix=/usr/local/qemu --python=/usr/bin/python3
make -j16 && make install

qemu_path=/usr/local/qemu/bin
for i in `ls $qemu_path`
do
    echo $qemu_path/$i
    ln -s $qemu_path/$i /bin/
done
```

3) 下载uefi bios文件  
没有找到git等地址  
https://rpmfind.net/linux/rpm2html/search.php?query=edk2-aarch64  
下载后用yum安装, 未发现有包依赖  
安装后需要编辑 /etc/libvirt/qemu.conf
取消原有的注释

```
770 nvram = [
771    "/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd",
772    "/usr/share/OVMF/OVMF_CODE.secboot.fd:/usr/share/OVMF/OVMF_VARS.fd",
773    "/usr/share/AAVMF/AAVMF_CODE.fd:/usr/share/AAVMF/AAVMF_VARS.fd",
774    "/usr/share/AAVMF/AAVMF32_CODE.fd:/usr/share/AAVMF/AAVMF32_VARS.fd"
775 ]
```

完成后需要重启 libvirt

```
systemctl restart libvirtd
```

4) libvirt 建立虚拟机的示例

```
virt-install \
--name kylin-aarch64 --vcpus 4 --ram 4096 --arch aarch64 --os-variant rhel7.9 \
--boot uefi \
--graphics vnc,listen=0.0.0.0,port=5903 \
--cdrom /mnt/ISO/银河麒麟_Kylin-Server-10-SP2-aarch64-Release-Build09-20210524.iso \
--disk path=/vm/kylin-aarch64.qcow2,size=20,bus=virtio,format=qcow2
```

#### 模拟的异构虚拟机在移除时报错

创建了模拟的异构虚拟机, 在移除时却遇到了报错

```
[root@5950x-node1 ~]# virsh undefine kylin-aarch64-test 
error: Failed to undefine domain 'kylin-aarch64-test'
error: Requested operation is not valid: cannot undefine domain with nvram
```

解决办法  
https://bugzilla.redhat.com/show_bug.cgi?id=1195667

我本人实测, 帖子中说到的其中一种方法, 删除 ```nvram``` 的一行, 并不有效, 因为编辑完以后竟然自动又被还原了, 此时虚拟机已是关机状态.

有效方法

```
virsh undefine --nvram <虚拟机名称>
```

帖子中说到, 为已知BUG, 但即使有人已经提供了补丁, 却未被采纳.

<h3 id="8">内存膨胀</h3>

https://github.com/yangcvo/KVM/blob/master/KVM%E8%99%9A%E6%8B%9F%E5%8C%96(%E5%85%AD)%E8%B0%83%E6%95%B4%E8%99%9A%E6%8B%9F%E6%9C%BACPU%E5%A4%A7%E5%B0%8F%2C%E6%B7%BB%E5%8A%A0memory%E5%86%85%E5%AD%98%2C%E6%B7%BB%E5%8A%A0%E8%99%9A%E6%8B%9F%E6%9C%BA%E7%A1%AC%E7%9B%98disk%2C%E8%99%9A%E6%8B%9F%E6%9C%BA%E5%86%85%E5%AD%98%E5%87%8F%E5%8D%8A%E7%8E%B0%E8%B1%A1.md  

https://cloud.tencent.com/developer/article/1087028  

一个比较有意思的细节, 关于kvm虚拟机内存容量的定义语句

```
  <memory unit='KiB'>8388608</memory>
  <currentMemory unit='KiB'>8388608</currentMemory>
```

字面含义 currentMemory 应该是当前内存, 网上的文章会说这是"最小内存"也就是 minRAM  

姑且照此理解, 但在使用 Win10 作为guestOS的虚拟机开机内存占用呈现以下趋势  

memory 8G, currentMemory 1G, Win10 guestOS 开机内存占用 7.7G  
memory 8G, currentMemory 2G, Win10 guestOS 开机内存占用 7.5G  
memory 8G, currentMemory 4G, Win10 guestOS 开机内存占用 4.xG  
memory 8G, currentMemory 6G, Win10 guestOS 开机内存占用 3.xG  
memory 8G, currentMemory 8G, Win10 guestOS 开机内存占用 1.8G (物理机的合理值)  


<h3 id="9">禁用不需要的启动项</h3>

kvm 的 ipxe 启动

https://askubuntu.com/questions/190929/how-do-i-disable-unwanted-ipxe-boot-attempt-in-libvirt-qemu-kvm

你可能并不需要它的ipxe启动, 延长vm的开机过程  
在此帖子中讨论了很多, 各种方式都有, 有宿主机层面的(全局性), 也有永久性的改变(取消libvirt对那几个rom的访问权限等)  

以下摘录的方式是对虚拟机的配置xml, 影响最小, 但缺点就是量大的时候就工作量大.

![](images/gnsDhBaVfRFmgnrO2QuZI9wC1VqpaTRv.png)

文档出处:  
https://libvirt.org/formatdomain.html#elementsNICSROM


<h3 id="10">嵌套虚拟化</h3>

https://blog.csdn.net/Linuxprobe18/article/details/78944974

实测,在 Rocky Linux 8.7 加 6.0.10 的内核下, 虚拟化嵌套的开关已打开

```
cat /sys/module/kvm_intel/parameters/nested
```

<h3 id="10">非典型网络拓扑架构下的通信/静态路由问题</h3>

严格说起来, 这并非 KVM 类型的知识, 实际还是网络通信层面

有关 Linux 做IP转发, 充当路由器角色的情形, 简单场景, 下面文章描述得已足够清晰  
https://developer.aliyun.com/article/268169  
https://cloud.tencent.com/developer/article/1177886  文章相同

以上适用于有需求用一台Linux系统,连通两个不同的网段的场景

对于我个人的环境, 用到了更复杂的网络拓扑结构  
实际上起源为了省一个万兆交换机的钱, 因为暂时没打算上  
然后在地址段规划上, 由于没踩过这个坑, 最初就全在同一个子网掩码下, 这正是一个坑点

拓扑结构如下

![](/images/我的当前拓扑.png)

- 在上图的拓扑中, "PC"和"存储归档机" 没有网络连线在物理层面直达图上最下方的"X9DR3-F", 它们需要通过中间的物理机进行转发  
- 虚线表示的运行在物理机之上的虚拟机.  
- 所有的主机的网络接口都使用了24位的子网掩码, 并且同一个地址段.  
- 引发出的问题是, 静态路由条目, 在书写方式上有讲究.   


举例说明:  
前提:   
1) 处于中间层的主机"5950X"和"X9DRi-LN4F+" 已打开Linux的内核参数, ```net.ipv4.ip_forward = 1```  
2) ```sysctl -a | grep -w arp_ignore``` 和 ```sysctl -a | grep -w arp_filter``` 的结果需要都为0

以上两条为必要条件, 原理在本文档已有引用和描述解释.

以右上方的"PC"机为例  
当它需要访问最下方的"X9DR3-F"
如果路由条目的写法, 采用 "172.16.0.0/24 172.16.0.6", 并不能达到目的, 因为直连网段, 操作系统本身就自动创建了同样的条目.这样的操作只是增加了一条优先级更低(由Metric值决定)但内容是冗余的静态路由.  
真正要解决问题, 还是需要配置明确的针对每个目标主机的静态路由条目.

Windows(即"PC")上的路由表示例

```
===========================================================================
永久路由:
  网络地址          网络掩码  网关地址  跃点数
       172.16.0.0    255.255.255.0       172.16.0.6       1
     172.16.0.101  255.255.255.255       172.16.0.6       1
       172.16.0.1  255.255.255.255       172.16.0.6       1
     172.16.0.102  255.255.255.255       172.16.0.6       1
          0.0.0.0          0.0.0.0      192.168.1.1     默认
===========================================================================
```

中间层的"5950X"的静态路由表如下

```
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG    427    0        0 br0
172.16.0.0      0.0.0.0         255.255.255.0   U     425    0        0 br1
172.16.0.0      0.0.0.0         255.255.255.0   U     426    0        0 br2
172.16.0.1      172.16.0.3      255.255.255.255 UGH   400    0        0 br1
172.16.0.9      172.16.0.4      255.255.255.255 UGH   400    0        0 br2
172.16.0.13     172.16.0.4      255.255.255.255 UGH   400    0        0 br2
172.16.0.17     172.16.0.3      255.255.255.255 UGH   400    0        0 br1
172.16.0.21     172.16.0.3      255.255.255.255 UGH   400    0        0 br1
172.16.0.30     172.16.0.3      255.255.255.255 UGH   400    0        0 br1
172.16.0.85     172.16.0.3      255.255.255.255 UGH   400    0        0 br1
172.16.0.101    172.16.0.3      255.255.255.255 UGH   400    0        0 br1
192.168.1.0     0.0.0.0         255.255.255.0   U     427    0        0 br0
192.168.122.0   0.0.0.0         255.255.255.0   U     0      0        0 virbr0
```

最下层的"X9DR3-F"的静态路由表如下

```
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG    425    0        0 br0
172.16.0.0      172.16.0.101    255.255.255.0   UG    425    0        0 br1
172.16.0.0      0.0.0.0         255.255.255.0   U     426    0        0 br1
172.16.0.0      0.0.0.0         255.255.255.0   U     427    0        0 br2
172.16.0.1      172.16.0.101    255.255.255.255 UGH   400    0        0 br1
172.16.0.2      172.16.0.102    255.255.255.255 UGH   400    0        0 br2
172.16.0.3      172.16.0.101    255.255.255.255 UGH   400    0        0 br1
172.16.0.5      172.16.0.102    255.255.255.255 UGH   400    0        0 br2
172.16.0.6      172.16.0.102    255.255.255.255 UGH   400    0        0 br2
172.16.0.13     172.16.0.3      255.255.255.255 UGH   400    0        0 br1
172.16.0.21     172.16.0.101    255.255.255.255 UGH   400    0        0 br1
172.16.0.100    172.16.0.5      255.255.255.255 UGH   400    0        0 br2
172.16.0.121    172.16.0.102    255.255.255.255 UGH   400    0        0 br2
192.168.1.0     0.0.0.0         255.255.255.0   U     425    0        0 br0
192.168.122.0   0.0.0.0         255.255.255.0   U     0      0        0 virbr0
```

有关于此现象背后的网络理论知识, 请教网络工程师对此的解释是:  
虽然IP地址段加掩码属于同一地址段, 但在此网络拓扑下, 依旧属于跨网络的3层通信模式.  
如果要想达到, 需要借道才能目标主机的客户端, 只填写网段式的静态路由就能访问的效果, 处于中间层的主机, 还需要具备"ARP代理"的能力.  
有关ARP代理  
https://blog.51cto.com/chenxinjie/1961255

因该场景的代表性相当有限, 在企业环境下大规模应用的可能性基本不存在, 因此也不打算在方向上继续深入.

在不使用ARP代理的情形下, 总结经验如下:  
1) 借道通信的客户端, 依然需要单个目标主机的静态路由条目  
2) 在静态路由条目中, 与目标主机配套的网关gateway的地址, 填写对象遵循是对端的接口地址原则.  
3) 由于在本场景中, 中间层以及最下层的物理机同时也是KVM宿主机, 它的静态路由条目并不全部服从上述第2条, 需要分情形对待.比如, 目标主机是运行在它自身上的虚拟机, 静态路由条目是决定数据包由哪个网络接口出去, 
   所以网关一项填的是自己的接口地址, 而非下一跳地址


<h3 id="11">为虚拟机添加一个虚拟声卡</h3>

https://www.cnblogs.com/System-hjf/p/10261494.html

只是为了 Windows 或播放软件等不出现找不到声卡的提示

KVM 默认不会为 KVM 虚拟机创建声卡

添加方法

```
    <sound model='ich6'>
      <alias name='sound0'/>
      <address type='pci' domain='0x0000' bus='0x08' slot='0x01' function='0x0'/>
    </sound>
    <audio id='1' type='none'/>
```

```<audio id='1' type='none'/>``` 是本身已存在的

```address``` 可以不填, KVM会自动生成

<h3 id="12">绑定CPU核心</h3>

在数据库领域, 绑定CPU核心--准确的术语是CPU亲缘性--是非常常见的操作, 目的通过规避因CPU核心的切换而带来上下文切换, 从而产生额外的无畏的开销.

在KVM领域实施虚拟机vcpu与物理机的CPU核心(逻辑CPU)的绑定  
https://www.helloworld.net/p/8012478504

分为临时性和持久化两种方式

查看当前虚拟机所运行在的CPU核心

```
virsh vcpuinfo <VM的名称,domain-name>



[root@Chia_KVM-01 ~]# virsh vcpuinfo CQ-docker-02
VCPU:           0
CPU:            N/A
State:          N/A
CPU time        N/A
CPU Affinity:   yyyyyyyy

VCPU:           1
CPU:            N/A
State:          N/A
CPU time        N/A
CPU Affinity:   yyyyyyyy

VCPU:           2
CPU:            N/A
State:          N/A
CPU time        N/A
CPU Affinity:   yyyyyyyy

VCPU:           3
CPU:            N/A
State:          N/A
CPU time        N/A
CPU Affinity:   yyyyyyyy
```

其中的```CPU Affinity```是该虚拟机可以在将其vcpu放置在哪一个逻辑CPU上运行, 一个```y```标记代表一个逻辑CPU


临时性绑定, vm 重启后失效

```
# 将vm4的两个vcpu绑定在宿主机的第4号和第6号cpu上, cpu编号从0开始计数

[root@yufu ~]# virsh vcpupin vm4 0 3

[root@yufu ~]# virsh vcpupin vm4 1 5
```

持久化配置

```
  <cputune>
    <vcpupin vcpu='0' cpuset='0'/>
    <vcpupin vcpu='1' cpuset='1'/>
    <vcpupin vcpu='2' cpuset='2'/>
    <vcpupin vcpu='3' cpuset='3'/>
  </cputune>
```

将其安插在

```
  <vcpu placement='static'>4</vcpu>
```

之后
