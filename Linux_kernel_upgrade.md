* [目录](#0)
  * [yum 升级内核版本](#1)
  * [在 rocky 8 (红帽 8) 编译升级 5.x 6.x](#2)


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

#### 2023-06-24 重要补充说明

本节内描述的结论, 基于以下测试环境验证:
- OS发行版: Rocky 8.7
- 内核版本: 原 4.18.0-425.3.1.el8.x86_64 的内核, 经历以下升级验证  
4.18 --> 6.1.20  
4.18 --> 6.1.35  
6.1.20 --> 6.1.35  

如果编译安装期望的结果是: 内核版本得到升级, 同时kdump服务能正常工作, crash工具也能正常读取kdump生成的crash日志文件, 
则应当采取经过验证其有效性的步骤如下:

1) 解压内核源码包
2) 复制一个系统原本自带的 config 文件, 位于 /boot/config-xxx 到解压的内核源码包的根目录下.具体操作本文下方已有详细步骤.
3) 编辑 .config 文件内的内容, 需要 ```CONFIG_SYSTEM_TRUSTED_KEYS=""```, 另外需要```CONFIG_DEBUG_INFO```, 
   ```CONFIG_DEBUG_INFO_BTF```都为N (<font color=red>有关这一点还有补充说明</font>), 其余就是自己希望启用的内核模块了.
4) 执行 ```make menuconfig```
5) ```make menuconfig``` 执行后会覆盖原有对 .config 的变更, 需要重新执行步骤3的检查和修改,有关这一点,也许会显得步骤3是多余的, 但其实不尽然
6) 执行编译步骤

以上流程, 经过内核版本 6.1.20 和 6.1.35 的实践检验证明其有效性.

如果省略其中某个步骤, 可能会引起  ```make menuconfig``` 生成的 .config 文件的变化, 导致在 make 阶段, 会提出新的问题需要交互.从而有编译结果的不一致性.
这其中的原因是, 每一个新的内核版本发布都可能会包含有新的 config 参数, 而在原有的 config 文件中并不包含配置值, 需要人为的
给出明确指示,

在内核版本 6.1.20 和 6.1.35 的编译过程中发现, ```CONFIG_DEBUG_INFO```, ```CONFIG_DEBUG_INFO_BTF```, ```CONFIG_DEBUG_INFO_NONE```
如果出现在你的 config 文件中, 根据以上经验, 设置为 ```=N``` 大N, 能得出正确的结果.

不过也通过 make 过程中查看 .config 文件的变化也发现, .config 文件依然受到了 make 命令的修改, 改为了 ```=y```

如下:

```
[root@X9DR3-F 6.1.35]# grep -w CONFIG_DEBUG_INFO .config
CONFIG_DEBUG_INFO=y
[root@X9DR3-F 6.1.35]# grep -w CONFIG_DEBUG_INFO_BTF .config
# CONFIG_DEBUG_INFO_BTF is not set
[root@X9DR3-F 6.1.35]# grep -w CONFIG_DEBUG_INFO_NONE .config
# CONFIG_DEBUG_INFO_NONE is not set
```

但如果你在上述第3步中, 自行配置 ```CONFIG_DEBUG_INFO=y```, 却会引出新的 ```CONFIG_DEBUG_INFO_NONE=y```
从而在此状态编译出的内核, kdump 虽然工作正常, 但 crash 工具去读取时却会提示 ```no debugging data available```,
且尝试各种在此基础上的组合,均无法得出期望的结果.  
而你按照以上列出的步骤执行, 则可以得出期望的结果.  
这正是其吊诡之处, 与过去以往的文章告诉你, ```CONFIG_DEBUG_INFO=y``` 就是你需要的步骤, 已发生某种改变.  

附:  
<a href="files/w6kzRJaoMtnqOFJ6UHSL098YZlRvIiKM" target="_blank">被make修改后的config文件, 内核版本6.1.35</a>

该附件可用于直接执行 make 命令, 不再需要 ```make menuconfig``` 等步骤.  
但需要注意的是, 经过检验的是 6.1.35 的内核, 不同的内核版本则可能会出现新的问题.

另外其实也无需单独生成 vmlinux, ```make modules``` 和 ```make modules_install``` 会配置 crash 命令默认的 vmlinux 文件
位置, 即内核源码的解压缩位置

#### 基本步骤

绝大部分步骤参考此文档即可  
https://blog.51cto.com/u_3436241/4750925  

编译安装要用的工具集, 但 perl 可能是缺失的, 也需要确保安装

```
yum install -y ncurses-devel gcc-c++ make openssl-devel bison flex elfutils-libelf-devel perl
```

<font color=red>有关 linux 内核源码的存放位置, 建议: </font>

```
/usr/src/kernels/<内核版本号>
```


并且, 编译安装完成, 应当予以保留, 因为其中包含的工具链在系统需要 debug 时会依赖.  
如果是希望精简体积, 则应当只选择性的删除 drivers 目录下的驱动为主.


<br>

以下是必要的基本步骤

```
# --strip-components 1  不包含tar包里的第一级目录
kernel_version=6.1.35
mkdir /usr/src/kernels/"$kernel_version"
tar -xvf linux-"$kernel_version".tar.xz --strip-components 1 -C /usr/src/kernels/"$kernel_version"
cd /usr/src/kernels/"$kernel_version"

# 确认当前使用的内核
uname -r
# 拷贝当前使用内核的 config文件用于节省修改配置工作
cp /boot/config-$(uname -r) ./.config
```

在.config文件中找到 ```CONFIG_SYSTEM_TRUSTED_KEYS```，将这行置空, 但不能注释, 否则依然会要你提供证书keys的位置。  
即```CONFIG_SYSTEM_TRUSTED_KEYS=""```, 因为```CONFIG_SYSTEM_TRUSTED_KEYRING=y``` 且改为 N 也依然要你提供key

额外的, 如果有启用其他模块的需求, 如:  
~~debug 用途的 ```CONFIG_DEBUG_INFO```, ```CONFIG_DEBUG_INFO_BTF```, 而 ```CONFIG_DEBUG_INFO_NONE=n``` 需要显式的等于n~~  
用于缓存用途的 ```CONFIG_BCACHE```  
也是通过编辑 ./config 文件来启用  
查询内核模块名称的网站  
https://www.kernelconfig.io/

https://cateee.net/lkddb/web-lkddb/DEBUG_INFO_NONE.html

接下来执行 make menuconfig  
进入UI界面，参数不用改，切换到save直接保存，尔后按两下Esc退出。  

```
make menuconfig
```

执行以上这一步的原因是, 还有大量的参数没有指定, 如果不适用```make menuconfig```为你自动配置, 则会在```make```阶段
以大量的交互式问题的形式需要你进行回答.  
使用 ```make menuconfig``` 向导自动完成之后, 仍有必要再次确认, 是否被修改覆盖掉你原本打算启用/禁用的内容.  
例如:  

```
grep -w CONFIG_SYSTEM_TRUSTED_KEYS .config
grep -w CONFIG_DEBUG_INFO .config
grep -w CONFIG_DEBUG_INFO_BTF .config
grep -w CONFIG_BCACHE .config
```

编译内核--依次执行以下步骤,注意确认是否有报错  

```
# 手动修改为自己的逻辑CPU总线程, 以获得最快完成速度
make -j$(nproc)

# nproc 为获取os逻辑cpu个数的命令, 返回值就是个数
# 以下4个make, 不要使用 -j 多线程并发

make modules
make bzImage
make vmlinux
make modules_install
make install
```

补充说明:  
- vmlinux 是与之配套的调试内核, 在需要crash 分析 vmcore 时, 需要用到.应当执行, 并且保留生成的文件  
- 实际上, 当执行了```make modules``` 和 ```make modules_install``` , 如果编译参数文件 ```.config``` 有启用 ```CONFIG_DEBUG_INFO=y```的话, 
  本身也会生成```vmlinux```
文件, 它位于 ```/lib/modules/<内核版本号>/build/vmlinux```
- 额外又执行了一次 ```make vmlinux```, 所以, 以建议的内核源码放置目录为例, ```/usr/src/kernels/<内核版本号>/vmlinux```
也有一个vmlinux, 是相同的作用, 都是用于 crash 工具使用的 ```namelist```

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


#### 执行 make 阶段的错误

```
  LD [M]  arch/x86/kvm/kvm.o
  AS [M]  arch/x86/kvm/vmx/vmenter.o
  AS [M]  arch/x86/kvm/svm/vmenter.o
  LD [M]  arch/x86/kvm/kvm-intel.o
  LD [M]  arch/x86/kvm/kvm-amd.o
  CC [M]  kernel/kheaders.o
make: *** [Makefile:2012: .] Error 2
```

此错误需要检查前文中提到的 ```CONFIG_SYSTEM_TRUSTED_KEYS``` 是否已被注释


#### 执行 make modules_install 阶段的错误

```
  INSTALL /lib/modules/6.1.20/kernel/virt/lib/irqbypass.ko
  SIGN    /lib/modules/6.1.20/kernel/virt/lib/irqbypass.ko
  DEPMOD  /lib/modules/6.1.20
Warning: modules_install: missing 'System.map' file. Skipping depmod.
```

https://stackoverflow.com/questions/49397856/linux-compilation-error-missing-file-arch-x86-boot-bzimage

正确答案: 少了```make bzImage```一步

> The creation of bzImage is missing in your script. Before modules_install you should type:  
> make bzImage

如下: 

```
make -j$(nproc)
make modules
make bzImage
make vmlinux
make modules_install
make install
```


关于 make vmlinux 的补充

```
[root@5950x-node1 linux-6.1.20]# make vmlinux
  CALL    scripts/checksyscalls.sh
  DESCEND objtool
  MODPOST vmlinux.symvers
[root@5950x-node1 linux-6.1.20]# ll vmlinux
-rwxr-xr-x 1 root root 886M Jun 22 23:23 vmlinux
```

根源来自执行 make 阶段, 原本该有以下

```
  BUILD   arch/x86/boot/bzImage
Kernel: arch/x86/boot/bzImage is ready  (#1)
```

但还不确定是否因为多线程编译, -j 的关系导致, 并非每次都一定能生成```bzImage```

因此, 如果没有生成, 则执行```make modules_install```必然报该错误  
需要在```make modules_install```之前就执行```make bzImage```才能得到正确结果

#### 执行 make bzImage 阶段的错误

其中有错误, 且提示你可以选择禁用 ```CONFIG_DEBUG_INFO_BTF```  
也即注释该项, 或```CONFIG_DEBUG_INFO_BTF=n```  
通过此操作, 可正确通过  
但 ```CONFIG_DEBUG_INFO_BTF``` 选择禁用, 具体损失的功能, 待核实
