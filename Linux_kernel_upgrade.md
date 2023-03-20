* [目录](#0)
  * [yum 升级内核版本](#1)
  * [红帽8 编译升级 5.10](#2)


<h3 id="1">yum 升级内核版本</h3>

ELRepo 提供yum安装kernel 的资源  
但它是跟随linux kernel 源码的发布进行更新的, 也就是 linux kernel 将版本号更新的合并进主线或是长期支持,则EPRepo也会随之更新.  
这样的结果就是, 你得到的主线 (main-line) 和长期支持 (long-tern) 都是当前的最新版本, 而如果你期望的版本号不在其中, 则无法实现.

术语解释  
kernel-ml 中的 ml 是英文mainline stable的缩写，elrepo-kernel 中列出来的是最新的稳定主线版本。  
kernel-lt 中的 lt 是英文long term support的缩写，elrepo-kernel 中列出来的长期支持版本  


ELRepo主页  
http://elrepo.org/tiki/HomePage

To install ELRepo for RHEL-9:

```
yum install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
```

To install ELRepo for RHEL-8:

```
yum install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
```

To install ELRepo for RHEL-7, SL-7 or CentOS-7:

```
yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
```

导入 ELRepo 的GPG key(如需要)
```
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
```

列出当前最新的lt长期支持版，和最新的ml主要分支

```
yum list available --disablerepo=* --enablerepo=elrepo-kernel
```

安装内核命令

```
# dnf 替换成 yum 也一样
dnf --enablerepo=elrepo-kernel install kernel-ml kernel-ml-devel kernel-ml-headers
```


#### yum 安装指定版本号的内核

这篇文章给出了正解, 主要是资源站点  
https://hicode.club/articles/2021/08/24/1629807082331.html

资源站点, 涵盖RHEL 5-9  
http://mirrors.coreix.net/elrepo-archive-archive/kernel/  
http://mirrors.coreix.net/elrepo-archive-archive/kernel/el5/x86_64/RPMS/  
http://mirrors.coreix.net/elrepo-archive-archive/kernel/el6/x86_64/RPMS/  
http://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/  
http://mirrors.coreix.net/elrepo-archive-archive/kernel/el8/x86_64/RPMS/  
http://mirrors.coreix.net/elrepo-archive-archive/kernel/el9/x86_64/RPMS/  

引用其原文

>首先从如下链接选择内核版本  
> http://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/  
> 然后通过rpm -ivh xx进行安装。

>下面通过我需要的kernel-lt-4.4.249-1.el7.elrepo.x86_64来举例

```
# https://www.cnblogs.com/erlou96/p/12904902.html
wget http://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/kernel-lt-4.4.249-1.el7.elrepo.x86_64.rpm

# 安装内核
rpm -ivh kernel-lt-4.4.249-1.el7.elrepo.x86_64.rpm --force

# 查看插入顺序，看看而已
awk -F \' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg

# 设置需要的内核最为启动项目
grub2-set-default 'CentOS Linux (4.4.249-1.el7.elrepo.x86_64) 7 (Core)'

# 然后查看启动顺序
grub2-editenv list

# 重启进入新的内核后执行下述代码可以删除老的内核
yum remove $(rpm -qa | grep kernel | grep -v $(uname -r))
```

>我的目的是为了安装 kubernetes，我发现超过 4.4版本的内核在开启 ipvs 的时候会出现问题，所以我选择的是 4.4版本的最新内核。

<h3 id="2">在 rocky 8 (红帽 8) 编译升级 5.x 6.x</h3>

绝大部分步骤参考此文档即可  
https://blog.51cto.com/u_3436241/4750925  

编译安装要用的工具集, 但 perl 可能是缺失的, 也需要确保安装

```
yum install -y ncurses-devel gcc-c++ make openssl-devel bison flex elfutils-libelf-devel perl
```

```
tar -xvf linux-5.10.90.tar.xz -C /tmp/
cd /tmp/linux-5.10.90/

# 确认当前使用的内核
uname -r
# 拷贝当前使用内核的 config文件用于节省修改配置工作
cp /boot/config-$(uname -r) ./.config
```

在.config文件中找到 ```CONFIG_SYSTEM_TRUSTED_KEYS```，```CONFIG_DEBUG_INFO_BTF```这两行，并将这两行注释。  
额外的, 如果有启用其他模块的需求, 如:  
debug 用途的 ```CONFIG_DEBUG_INFO```  
用于缓存用途的 ```CONFIG_BCACHE```  
也是通过编辑 ./config 文件来启用  
查询内核模块名称的网站  
https://www.kernelconfig.io/

接下来执行 make menuconfig  
进入UI界面，参数不用改，切换到save直接保存，尔后按两下Esc退出。  

```
make menuconfig
```

编译内核--依次执行以下步骤,注意确认是否有报错  

```
# 手动修改为自己的逻辑CPU总线程, 以获得最快完成速度
make -j$(nproc)

# nproc 为获取os逻辑cpu个数的命令, 返回值就是个数
# 以下3个make, 不可使用 -j 多线程并发

make modules
make modules_install
make install
```

使用grubby切换内核  
如果没有安装  

```
yum install -y grubby
```

```
# 查看当前系统默认启动的内核
grubby --default-kernel

# 查看当前系统有哪些可用的内核
grubby --info=ALL | grep ^kernel

通过命令 grubby --set-default=可以设置你的默认启动内核
grubby --set-default=/boot/vmlinuz-5.10.90
```
