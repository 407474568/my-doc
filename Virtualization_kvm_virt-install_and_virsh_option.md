全篇内容搬运自  
https://blog.51cto.com/u_1364952/1964774  

    
<h3 id="1">virt-install 命令可选参数</h3>
virt-install是一个命令行工具，它能够为KVM、Xen或其它支持libvrit API的hypervisor创建虚拟机并完成GuestOS安装；此外，它能够基于串行控制台、VNC或SDL支持文本或图形安装界面。安装过程可以使用本地的安装介质如CDROM，也可以通过网络方式如NFS、HTTP或FTP服务实现。对于通过网络安装的方式，virt-install可以自动加载必要的文件以启动安装过程而无须额外提供引导工具。当然，virt-install也支持PXE方式的安装过程，也能够直接使用现有的磁盘映像直接启动安装过程。 

virt-install命令有许多选项，这些选项大体可分为下面几大类，同时对每类中的常用选项也做出简单说明。  
<br>

一般选项, 指定虚拟机的名称、内存大小、VCPU个数及特性等

| 参数 | 作用 |
| ---- | ---- |
| -n NAME, --name=NAME | 虚拟机名称，需全局惟一 |
| -r MEMORY, --ram=MEMORY | 虚拟机内在大小，单位为MB |
| --vcpus=VCPUS[,maxvcpus=MAX][,sockets=#][,cores=#][,threads=#] | VCPU个数及相关配置 |
| --cpu=CPU | CPU模式及特性，如coreduo等；可以使用qemu-kvm -cpu ?来获取支持的CPU模式 |

<br>
<br>

安装方法, 指定安装方法、GuestOS类型等

| 参数                                                                  | 作用                                                                                                         |
|---------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| -c CDROM, --cdrom=CDROM                                             | 光盘安装介质                                                                                                     |
| -l LOCATION, --location=LOCATION                                    | 安装源URL，支持FTP、HTTP及NFS等，如 ftp://172.16.0.1/pub                                                              |
| --pxe                                                               | 基于PXE完成安装                                                                                                  |
| --livecd: 把光盘当作LiveCD                                               |
| --os-type=DISTRO_TYPE                                               | 操作系统类型，如linux、unix或windows等                                                                                |
| --os-variant=DISTRO_VARIANT                                         | 某类型操作系统的变体，如rhel5、fedora8等                                                                                 |
| -x EXTRA, --extra-args=EXTRA                                        | 根据--location指定的方式安装GuestOS时，用于传递给内核的额外选项，例如指定kickstart文件的位置，--extra-args "ks= http://172.16.0.1/class.cfg" |
| --boot=BOOTOPTS                                                     | 指定安装过程完成后的配置选项，如指定引导设备次序、使用指定的而非安装的kernel/initrd来引导系统启动等 ；例如                                               |   
| --boot  cdrom,hd,network                                            | 指定引导次序                                                                                                     |
| --boot kernel=KERNEL,initrd=INITRD,kernel_args=”console=/dev/ttyS0” | 指定启动系统的内核及initrd文件                                                                                         |

<br>
<br>

存储配置, 指定存储类型、位置及属性等

| 参数              | 作用                                                                                                                                                                                                                                                                                                                                                                                            |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| --disk=DISKOPTS | 指定存储设备及其属性；格式为<br>--disk /some/storage/path,opt1=val1，opt2=val2等<br>常用的选项有<br>device 设备类型，如cdrom、disk或floppy等，默认为disk<br>bus 磁盘总结类型，其值可以为ide、scsi、usb、virtio或xen<br>perms 访问权限，如rw、ro或sh（共享的可读写），默认为rw<br>size 新建磁盘映像的大小，单位为GB<br>cache 缓存模型，其值有none、writethrouth（缓存读）及writeback（缓存读写）<br>format 磁盘映像格式，如raw、qcow2、vmdk等<br>sparse 磁盘映像使用稀疏格式，即不立即分配指定大小的空间<br>--nodisks 不使用本地磁盘，在LiveCD模式中常用 |

<br>
<br>

网络配置, 指定网络接口的网络类型及接口属性如MAC地址、驱动模式等

| 参数                                                | 作用                                                     |
|---------------------------------------------------|--------------------------------------------------------|
| -w NETWORK, --network=NETWORK,opt1=val1,opt2=val2 | 将虚拟机连入宿主机的网络中，其中NETWORK可以为                             |   
| bridge=BRIDGE                                     | 连接至名为“BRIDEG”的桥设备                                      |
| network=NAME                                      | 连接至名为“NAME”的网络                                         |
| 其它常用的选项还有                                         |   
| model                                             | GuestOS中看到的网络设备型号，如e1000、rtl8139或virtio等               |
| mac                                               | 固定的MAC地址；省略此选项时将使用随机地址，但无论何种方式，对于KVM来说，其前三段必须为52:54:00 |
| --nonetworks                                      | 虚拟机不使用网络功能                                             |

<br>
<br>

图形配置, 定义虚拟机显示功能相关的配置，如VNC相关配置

| 参数                                  | 作用                                                                       |
|-------------------------------------|--------------------------------------------------------------------------|
| --graphics TYPE,opt1=val1,opt2=val2 | 指定图形显示相关的配置，此选项不会配置任何显示硬件（如显卡），而是仅指定虚拟机启动后对其进行访问的接口                      |
| TYPE                                | 指定显示类型，可以为vnc、sdl、spice或none等，默认为vnc                                     |
| port                                | TYPE为vnc或spice时其监听的端口                                                    |
| listen                              | TYPE为vnc或spice时所监听的IP地址，默认为127.0.0.1，可以通过修改/etc/libvirt/qemu.conf定义新的默认值 |
| password                            | TYPE为vnc或spice时，为远程访问监听的服务进指定认证密码                                        |
| --noautoconsole                     | 禁止自动连接至虚拟机的控制台                                                           |

<br>
<br>

设备选项, 指定文本控制台、声音设备、串行接口、并行接口、显示接口等

| 参数                | 作用                                                                                                                                                                                                     |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| --serial=CHAROPTS | 附加一个串行设备至当前虚拟机，根据设备类型的不同，可以使用不同的选项，格式为“--serial type,opt1=val1,opt2=val2,...”，例如 <br>--serial pty 创建伪终端 <br>--serial dev,path=HOSTPATH 附加主机设备至此虚拟机<br>--video=VIDEO 指定显卡设备模型，可用取值为cirrus、vga、qxl或vmvga |

<br>
<br>

虚拟化平台,虚拟化模型（hvm或paravirt）、模拟的CPU平台类型、模拟的主机类型、hypervisor类型（如kvm、xen或qemu等）以及当前虚拟机的UUID等

| 参数             | 作用                                                             |
|----------------|----------------------------------------------------------------|
| -v, --hvm      | 当物理机同时支持完全虚拟化和半虚拟化时，指定使用完全虚拟化                                  |
| -p, --paravirt | 指定使用半虚拟化                                                       |
| --virt-type    | 使用的hypervisor，如kvm、qemu、xen等；所有可用值可以使用 virsh capabilities 命令获取 |

<br>
<br>

其它

| 参数               | 作用                                                                 |
|------------------|--------------------------------------------------------------------|
| --autostart      | 指定虚拟机是否在物理启动后自动启动                                                  |
| --print-xml      | 如果虚拟机不需要安装过程(--import、--boot)，则显示生成的XML而不是创建此虚拟机；默认情况下，此选项仍会创建磁盘映像 |
| --force          | 禁止命令进入交互式模式，如果有需要回答yes或no选项，则自动回答为yes                              |
| --dry-run        | 执行创建虚拟机的整个过程，但不真正创建虚拟机、改变主机上的设备配置信息及将其创建的需求通知给libvirt              |
| -d, <br> --debug | 显示debug信息                                                          | 

尽管virt-install命令有着类似上述的众多选项，但实际使用中，其必须提供的选项仅包括--name、--ram、--disk（也可是--nodisks）及安装过程相关的选项。此外，有时还需要使用括--connect=CONNCT选项来指定连接至一个非默认的hypervisor。  

```
下面这个示例创建一个名为rhel5的虚拟机，其hypervisor为KVM，内存大小为512MB，磁盘为8G的映像文件/var/lib/libvirt/p_w_picpaths/rhel5.8.img，通过boot.iso光盘镜像来引导启动安装过程。  

# virt-install \  
  --connect qemu:///system \  
  --virt-type kvm \  
  --name rhel5 \  
  --ram 512 \  
  --disk path=/var/lib/libvirt/p_w_picpaths/rhel5.img,size=8 \  
  --graphics vnc \  
  --cdrom /tmp/boot.iso \  
  --os-variant rhel5  
 
 
下面的示例将创建一个名为rhel6的虚拟机，其有两个虚拟CPU，安装方法为FTP，并指定了ks文件的位置，磁盘映像文件为稀疏格式，连接至物理主机上的名为brnet0的桥接网络：  
 
 
# virt-install \  
   --connect qemu:///system \  
   --virt-type kvm \  
   --name rhel6 \  
   --ram 1024 \  
   --vcpus 2 \  
   --network bridge=brnet0 \  
   --disk path=/VMs/p_w_picpaths/rhel6.img,size=120,sparse \  
   --location  ftp://172.16.0.1/rhel6/dvd \  
   --extra_args “ks= http://172.16.0.1/rhel6.cfg” \  
   --os-variant rhel6 \  
   --force  
 
 
下面的示例将创建一个名为rhel5.8的虚拟机，磁盘映像文件为稀疏模式的格式为qcow2且总线类型为virtio，安装过程不启动图形界面（--nographics），但会启动一个串行终端将安装过程以字符形式显示在当前文本模式下，虚拟机显卡类型为cirrus：  
 
 
# virt-install \  
--connect qemu:///system \  
--virt-type kvm \  
--name rhel5.8 \  
--vcpus 2,maxvcpus=4 \  
--ram 512 \  
--disk path=/VMs/p_w_picpaths/rhel5.8.img,size=120,format=qcow2,bus=virtio,sparse \  
--network bridge=brnet0,model=virtio  
--nographics \  
--location  ftp://172.16.0.1/pub \  
--extra-args "ks= http://172.16.0.1/class.cfg  console=ttyS0  serial" \  
--os-variant rhel5 \  
--force  \  
--video=cirrus  
 
 
下面的示例则利用已经存在的磁盘映像文件（已经有安装好的系统）创建一个名为rhel5.8的虚拟机：  
# virt-install \  
   --name rhel5.8  
   --ram 512  
   --disk /VMs/rhel5.8.img  
   --import  
 
每个虚拟机创建后，其配置信息保存在/etc/libvirt/qemu目录中，文件名与虚拟机相同，格式为XML  

1、安装软件
# yum install -y libvirt virt-manager virt-viewer python-virtinst

virt-install使用示例1：通过网络安装cnetos系统
创建镜像文件
# qemu-img create -f qcow2 -o size=120G /p_w_picpaths/vm3/centos65.qcow2
通过网络引导安装系统

# virt-install -n "centos6.5" --vcpus 2 -r 512 -l  http://192.168.8.42/cobbler/ks_mirror/centos6.5-x86_64/ --disk path=/p_w_picpaths/vm3/centos65.qcow2,bus=virtio,size=120,sparse --network bridge=br0,model=virtio --force

通过网络引导且通过kickstart文件自动化安装系统
# virt-install -n "centos6.5" --vcpus 2 -r 512 -l  http://192.168.8.42/cobbler/ks_mirror/centos6.5-x86_64/ --extra-args "ks= http://192.168.8.42/cobbler/centos6.5-x86_64.cfg" --disk path=/p_w_picpaths/vm3/centos65.qcow2,bus=virtio,size=120,sparse --network bridge=br0,model=virtio --force


可以看到可以启动安装界面

virt-install使用示例2：用virt-install安装已经存在的镜像导出xml文件通过virsh安装系统
# mkdir /p_w_picpaths/vm4/
# cp cirros-0.3.0-x86_64-disk.img /p_w_picpaths/vm4/cirros.img
# virt-install -n "cirros" -r 512 --vcpus=2 --disk path=/p_w_picpaths/vm4/cirros.img --network bridge=br0 --import


目标系统cirros2的处理
# mkdir /p_w_picpaths/vm5

# cp cirros-0.3.0-x86_64-disk.img /p_w_picpaths/vm5/cirros2.img
# virsh dumpxml cirros > /etc/libvirt/qemu/cirros2.xml

# vim /etc/libvirt/qemu/cirros2.xml


通过存在的cirros2.xml创建虚拟机系统
# virsh create /etc/libvirt/qemu/cirros2.xml --console
```

virsh常用命令：  

| 命令                    | 作用                                                               |
|-----------------------|------------------------------------------------------------------|
| virsh start x         | 启动名字为x的非活动虚拟机                                                    |
| virsh list   --all    | 列出虚拟机                                                            |
| virsh create x.xml    | 创建虚拟机（创建后，虚拟机立即执行，成为活动主机）                                        |
| virsh suspend x       | 暂停虚拟机                                                            |
| virsh resume x        | 启动暂停的虚拟机                                                         |
| virsh shutdown x      | 正常关闭虚拟机                                                          |
| virsh destroy x       | 强制关闭虚拟机                                                          |
| virsh undefine x      | 删除虚拟机                                                            |
| virsh dominfo x       | 显示虚拟机的基本信息                                                       |
| virsh domname 2       | 显示id号为2的虚拟机名                                                     |
| virsh domid x         | 显示虚拟机id号                                                         |
| virsh domuuid x       | 显示虚拟机的uuid                                                       |
| virsh domstate x      | 显示虚拟机的当前状态                                                       |
| virsh dumpxml x       | 显示虚拟机的当前配置文件（可能和定义虚拟机时的配置不同，因为当虚拟机启动时，需要给虚拟机分配id号、uuid、vnc端口号等等） |
| virsh setmem x 512000 | 给不活动虚拟机设置内存大小                                                    |
| virsh edit x          | 编辑配置文件（一般是在刚定义完虚拟机之后）                                            |


示例1：virsh命令添加网桥：
```
# service libvirtd start
可以查看帮助
# virsh help iface-bridge
通过virsh的命令可以直接添加网桥
# virsh iface-bridge eth0 br0
Created bridge br0 with attached device eth0
Bridge interface br0 started
# ifconfig
br0       Link encap:Ethernet  HWaddr 00:0C:29:D7:3A:10  
     inet addr:192.168.8.44  Bcast:192.168.8.255  Mask:255.255.255.0
     inet6 addr: fe80::20c:29ff:fed7:3a10/64 Scope:Link
     UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
     RX packets:29 errors:0 dropped:0 overruns:0 frame:0
     TX packets:18 errors:0 dropped:0 overruns:0 carrier:0
     collisions:0 txqueuelen:0
     RX bytes:2130 (2.0 KiB)  TX bytes:1636 (1.5 KiB)


eth0      Link encap:Ethernet  HWaddr 00:0C:29:D7:3A:10  
     UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
     RX packets:22781 errors:0 dropped:0 overruns:0 frame:0
     TX packets:11657 errors:0 dropped:0 overruns:0 carrier:0
     collisions:0 txqueuelen:1000
     RX bytes:26538602 (25.3 MiB)  TX bytes:956524 (934.1 KiB)
```

查看网络设备的目录可以看到程序自动添加了ifcfg-br0
```
# ls /etc/sysconfig/network-scripts/
```

virt-manager图形化界面工具的使用：
启动图形化界面工具
```
# virt-manager &
```

通过本次的使用可以看出，同样是virt-manager工具，对kvm的支持明显比xen要好得多

