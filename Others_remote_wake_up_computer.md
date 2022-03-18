<font color=red>【2021-12-24】</font> 增补 故障处理  
archlinux对wake-on-lan的介绍  
https://wiki.archlinux.org/title/Wake-on-LAN

模块设置  
https://wiki.archlinux.org/title/Kernel_module#Setting_module_options  

问题讨论  
https://forums.centos.org/viewtopic.php?f=47&t=71861  
https://forums.linuxmint.com/viewtopic.php?t=220964

ELRepo  
http://elrepo.org/tiki/HomePage

根据网上的讨论可知, Realtek的网卡在linux出现wake-on-lan的bug是重灾区  
1) 通过ELRepo的yum源, yum安装kmod-r8168, 附带更新了linux-firmware, 不能确定是否也是解决问题的关键.  
2) 需要增加一个模块参数 ```options r8168 s5wol=1```

```
[root@localhost ~]# yum install kmod-r8168
Loaded plugins: fastestmirror, langpacks
Loading mirror speeds from cached hostfile
 * elrepo: hkg.mirror.rackspace.com
elrepo                                                                                                                                                                   | 3.0 kB  00:00:00     
elrepo/primary_db                                                                                                                                                        | 539 kB  00:00:01     
Resolving Dependencies
--> Running transaction check
---> Package kmod-r8168.x86_64 0:8.049.02-1.el7_9.elrepo will be installed
--> Processing Dependency: kernel(strscpy) = 0xdd64e639 for package: kmod-r8168-8.049.02-1.el7_9.elrepo.x86_64
--> Running transaction check
---> Package kernel.x86_64 0:3.10.0-1160.49.1.el7 will be installed
--> Processing Dependency: linux-firmware >= 20190429-72 for package: kernel-3.10.0-1160.49.1.el7.x86_64
--> Running transaction check
---> Package linux-firmware.noarch 0:20180911-69.git85c5d90.el7 will be updated
---> Package linux-firmware.noarch 0:20200421-80.git78c0348.el7_9 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

================================================================================================================================================================================================
 Package                                       Arch                                  Version                                                       Repository                              Size
================================================================================================================================================================================================
Installing:
 kernel                                        x86_64                                3.10.0-1160.49.1.el7                                          updates                                 50 M
 kmod-r8168                                    x86_64                                8.049.02-1.el7_9.elrepo                                       elrepo                                  83 k
Updating for dependencies:
 linux-firmware                                noarch                                20200421-80.git78c0348.el7_9                                  updates                                 80 M

Transaction Summary
================================================================================================================================================================================================
Install  2 Packages
Upgrade             ( 1 Dependent package)

Total download size: 131 M
Is this ok [y/d/N]: y
Downloading packages:
Delta RPMs disabled because /usr/bin/applydeltarpm not installed.
warning: /var/cache/yum/x86_64/7/elrepo/packages/kmod-r8168-8.049.02-1.el7_9.elrepo.x86_64.rpm: Header V4 DSA/SHA1 Signature, key ID baadae52: NOKEY          ]  0.0 B/s | 400 kB  --:--:-- ETA 
Public key for kmod-r8168-8.049.02-1.el7_9.elrepo.x86_64.rpm is not installed
(1/3): kmod-r8168-8.049.02-1.el7_9.elrepo.x86_64.rpm                                                                                                                     |  83 kB  00:00:00     
(2/3): kernel-3.10.0-1160.49.1.el7.x86_64.rpm                                                                                                                            |  50 MB  00:00:06     
(3/3): linux-firmware-20200421-80.git78c0348.el7_9.noarch.rpm                                                                                                            |  80 MB  00:00:08     
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                            15 MB/s | 131 MB  00:00:09     
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org
Importing GPG key 0xBAADAE52:
 Userid     : "elrepo.org (RPM Signing Key for elrepo.org) <secure@elrepo.org>"
 Fingerprint: 96c0 104f 6315 4731 1e0b b1ae 309b c305 baad ae52
 Package    : elrepo-release-7.0-5.el7.elrepo.noarch (installed)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org
Is this ok [y/N]: y
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : linux-firmware-20200421-80.git78c0348.el7_9.noarch                                                                                                                           1/4 
  Installing : kernel-3.10.0-1160.49.1.el7.x86_64                                                                                                                                           2/4 
  Installing : kmod-r8168-8.049.02-1.el7_9.elrepo.x86_64                                                                                                                                    3/4 
Working. This may take some time ...
Done.
  Cleanup    : linux-firmware-20180911-69.git85c5d90.el7.noarch                                                                                                                             4/4 
  Verifying  : kmod-r8168-8.049.02-1.el7_9.elrepo.x86_64                                                                                                                                    1/4 
  Verifying  : linux-firmware-20200421-80.git78c0348.el7_9.noarch                                                                                                                           2/4 
  Verifying  : kernel-3.10.0-1160.49.1.el7.x86_64                                                                                                                                           3/4 
  Verifying  : linux-firmware-20180911-69.git85c5d90.el7.noarch                                                                                                                             4/4 

Installed:
  kernel.x86_64 0:3.10.0-1160.49.1.el7                                                        kmod-r8168.x86_64 0:8.049.02-1.el7_9.elrepo                                                       

Dependency Updated:
  linux-firmware.noarch 0:20200421-80.git78c0348.el7_9                                                                                                                                          

Complete!

```
模块参数
```
[root@localhost ~]# cat /etc/modprobe.d/r8168.conf 
options r8168 s5wol=1
```


<font color=red>【2021-12-17】</font> 新增 故障处理  
https://github.com/Bpazy/blog/issues/124  
https://forums.centos.org/viewtopic.php?t=71861  
https://bugs.centos.org/view.php?id=16486  
RHEL / CentOS 7的 3.10.1062后的内核版本, 导致WOL失效, 3.10的内核回退到老版本即恢复该功能


### nmcli 命令开启wake-on-lan功能
```
nmcli connection modify 配置文件名 802-3-ethernet.wake-on-lan magic
```



### 分为对局域网内计算机进行唤醒和通过互联网唤醒计算机  
通过互联网唤醒计算机, 实际上就是多一步在互联网出口设备上要做端口映射,以及交换机/路由器上可能会需要进行IP与MAC的绑定问题.  
<br/>
分别需要对BIOS，操作系统，以及路由器进行设置。
<br/>
微星BIOS设置（近几年各大厂商都普及了图形化界面，以微星Z77A-G41为例），不同厂商界面不同，但基本大同小异。  
关于BIOS和操作系统的设定，youtube的这哥们给出了答案  
https://www.youtube.com/watch?v=2CGFvLgye3g  
BIOS方面，只要有wake on PCI-E都是可以的，按早年间的一些文章介绍，还以为一定要wake on lan  
实际上只需要wake on  PCI-E及禁用EuP 2013，如下图
![](/images/uA7hrF2GedyqQgnb79CsTdfUim0kEvGA.jpg)
<br/>
![](/images/uA7hrF2Ged3loFhTwjMaXHi29CekObKP.jpg)
<br/>
接下来对操作系统进行设定  
在设备管理器中找到<font color=red>接路由器的物理网卡</font>，先设置电源管理  
![](/images/uA7hrF2GedCb6YWhJIdeA4GREgBFf9jO.jpg)

接下来设置“高级”选项卡，有四项需要确认  
“魔术封包唤醒”&ensp;&ensp;&ensp;====>&ensp;&ensp;需确认处于打开状态  
“关机&ensp;网络唤醒”&ensp;&ensp;====>&ensp;&ensp;需确认处于打开状态  
<br/>
“环保节能”&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;====>&ensp;&ensp;需确认处于关闭状态  
“节能乙太网路”&ensp;&ensp;&ensp;====>&ensp;&ensp;需确认处于关闭状态  
youtube哥们用的英文操作系统  
![](/images/uA7hrF2GedpFetMrgZjovYkEGxiH3IQX.jpg)
对操作系统的设定是为了避免关闭Windows时，彻底关闭了网卡，导致无法接受唤醒信号。  
<br/>
最后对路由器进行设定——此时短时间已能进行唤醒，几分钟后会失效  
原因这两个帖子说到了  
http://www.gebi1.com/forum.php?mod=viewthread&action=printable&tid=240599  
http://blog.ashchan.com/archive/2009/08/13/wake-on-lan-over-internet/  
假如是交换机（比如需要唤醒机房局域网内的某台服务器），在不断电的情况下，此时已可以完成，因为网卡MAC的地址还在。家用路由器，非绑定的MAC-IP地址由于MAC地址时效问题，会进行清理，所以关机后几分钟就无法唤醒了。因此在路由器做一个MAC与IP的绑定，为的是始终保留此MAC的IP，便于路由器接受到唤醒信号知道该传给哪个端口。  
另外路由器上需建立端口转发（映射关系），唤醒信号（魔术封包）使用UDP的9端口（也有些用7，取决于软件） ，家用路由器也许不分TCP和UDP。  

最后，智能手机上寻找wol 或 wake on lan 关键字的软件来安装，大同小异，主要是协议。  
再一个，动态的公网IP，就借助一下动态域名解析软件来解决了，在不断线重拨的情况下，IP不会发生变化，绝大多数时候都能满足需求了。  
如果动态解析确实无法满足，向日葵的开机棒几年前也搞起来了。  

<font color=red>PS：</font>  
经过反复测试， 绑定MAC地址可以解决路由器的MAC地址失效问题，以实现唤醒。但前提务必是由操作系统关闭计算机，如电源键关机等会导致网卡处于休眠状态（即使看见指示灯闪烁），也会无法唤醒计算机。
