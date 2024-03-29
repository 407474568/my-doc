* [目录](#0)
  * [非原始内核版本下的kdump服务](#1)
  * [配置crash工具集环境](#2)
  * [kdump需要保留多少内存](#3)
  * [设置了crashkernel的大小, kdump服务依然报错的情况](#4)
  * [kdump服务正常, vmcore未正常生成](#5)
  * [crash 调查内核崩溃原因](#6)

  
<h3 id="1">非原始内核版本下的kdump服务</h3>  

#### 可行的操作方法

##### kdump 的使用手册  
https://www.kernel.org/doc/Documentation/kdump/kdump.txt  

备用链接  
<a href="files/kdump.txt" target="_blank">kdump 的使用手册</a>


非原始内核版本--需要自行升级内核的情形, 又需要保持kdump的正常可用.  
已验证的可行选择: 源码编译安装 kernel 版本

其中, 在```kdump 的使用手册```中已包含了需要设置/检查的内核编译参数.  
实际上, 更为简便的途径从rocky(也许红帽系都一样)上的 ```config-xxx``` 复制来的基础上修改即可  

```
cd <kernel 源码包的解压目录>
cp /boot/config-$(uname -r) ./.config
```

在 Rocky Linux 8.7 上已确认, 所有都满足```kdump 的使用手册```的描述.  
除了以下一条:  
在 "Dump-capture kernel config options (Arch Dependent, i386 and x86_64)" 一节中的  
第2点:

> If CONFIG_SMP=y, then specify maxcpus=1 on the kernel command line
   when loading the dump-capture kernel, see section "Load the Dump-capture
   Kernel". 

此项不满足, 但实际验证, 也并未影响.  
你也可以直接将```CONFIG_SMP=y```改为```CONFIG_SMP=n``` 

换言之, 如果没有别的模块启用需求, 此 config 已可用

执行编译流程,随后即算完成

真正的关键之处在于, ```kdump 的使用手册``` 解答了两问题:  
1) 系统内核的内存映像文件, 与kdump所用到的内存映像文件, 可以是各自独立的, 也可以是共用的.  
2) 红帽(可能其他发行厂商也是如此) 通常的做法都是各自独立的, 在/boot目录下的 initramfs-xxxx,  initrd-xxxx, 通常kdump用到的,
名称带有kdump字样  
3) 如果使用共用的方式, 则内核在编译安装前需要编译参数明确指出, kdump给这一行为的术语叫```relocatable```, 在手册里已有操作介绍    
4) 使用 rocky 8 上复制得来的 config 中, 指定了"保留内存"的起始物理地址.
所以在内核启动的参数应当需要明确给出, 否则是造成kdump服务不正常工作的原因.
即原本的```crashkernel=auto```有必要变更为```crashkernel=256M@16M```

其中的 ```@16M``` 是由以下内核编译参数决定的:

```
CONFIG_PHYSICAL_START=0x1000000
```

此点在```kdump 的使用手册```已有明确解释

运行的示例

```
[root@localhost ~]# systemctl status kdump.service 
● kdump.service - Crash recovery kernel arming
   Loaded: loaded (/usr/lib/systemd/system/kdump.service; enabled; vendor preset: enabled)
   Active: active (exited) since Mon 2023-03-20 11:15:35 EDT; 11min ago
  Process: 1382 ExecStart=/usr/bin/kdumpctl start (code=exited, status=0/SUCCESS)
 Main PID: 1382 (code=exited, status=0/SUCCESS)

Mar 20 11:15:34 localhost.localdomain systemd[1]: Starting Crash recovery kernel arming...
Mar 20 11:15:35 localhost.localdomain kdumpctl[1400]: kdump: kexec: loaded kdump kernel
Mar 20 11:15:35 localhost.localdomain kdumpctl[1400]: kdump: Starting kdump: [OK]
Mar 20 11:15:35 localhost.localdomain systemd[1]: Started Crash recovery kernel arming.
[root@localhost ~]# 
[root@localhost ~]# 
[root@localhost ~]# uname -r
6.1.20
[root@localhost ~]# 
[root@localhost ~]# modprobe bcache
[root@localhost ~]# lsmod | grep -i bcache
bcache                339968  0
crc64                  20480  1 bcache
[root@localhost ~]# ll /var/crash
total 0
drwxr-xr-x 2 root root 67 Mar 20 11:15 127.0.0.1-2023-03-20-11:15:16


[root@localhost ~]# crash /lib/modules/6.1.20/build/vmlinux /var/crash/127.0.0.1-2023-03-20-11\:15\:16/vmcore

crash 7.3.2-2.el8
Copyright (C) 2002-2022  Red Hat, Inc.
Copyright (C) 2004, 2005, 2006, 2010  IBM Corporation
Copyright (C) 1999-2006  Hewlett-Packard Co
Copyright (C) 2005, 2006, 2011, 2012  Fujitsu Limited
Copyright (C) 2006, 2007  VA Linux Systems Japan K.K.
Copyright (C) 2005, 2011, 2020-2022  NEC Corporation
Copyright (C) 1999, 2002, 2007  Silicon Graphics, Inc.
Copyright (C) 1999, 2000, 2001, 2002  Mission Critical Linux, Inc.
This program is free software, covered by the GNU General Public License,
and you are welcome to change it and/or distribute copies of it under
certain conditions.  Enter "help copying" to see the conditions.
This program has absolutely no warranty.  Enter "help warranty" for details.
 
GNU gdb (GDB) 7.6
Copyright (C) 2013 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-unknown-linux-gnu"...

WARNING: kernel relocated [226MB]: patching 137180 gdb minimal_symbol values

      KERNEL: /lib/modules/6.1.20/build/vmlinux                        
    DUMPFILE: /var/crash/127.0.0.1-2023-03-20-11:15:16/vmcore  [PARTIAL DUMP]
        CPUS: 24
        DATE: Mon Mar 20 11:15:11 EDT 2023
      UPTIME: 00:01:31
LOAD AVERAGE: 0.61, 0.36, 0.14
       TASKS: 387
    NODENAME: localhost.localdomain
     RELEASE: 6.1.20
     VERSION: #1 SMP PREEMPT_DYNAMIC Mon Mar 20 04:29:28 EDT 2023
     MACHINE: x86_64  (3400 Mhz)
      MEMORY: 8 GB
       PANIC: "Kernel panic - not syncing: sysrq triggered crash"
         PID: 1660
     COMMAND: "bash"
        TASK: ffff9d8d83788000  [THREAD_INFO: ffff9d8d83788000]
         CPU: 3
       STATE: TASK_RUNNING (PANIC)

crash> 
crash> quit
```

同时, crash 读取系统 core dump 所需的全部套件也都编译安装上.  
除 crash 自行yum安装即可, 其余都无需额外安装.  
注意此时的 crash 运行所需的 vmlinux 所在的位置.如果没找到, 在crash不加参数的情况也应该会自动生成提示.  

```/lib/modules/6.1.20/build/vmlinux ```  


#### 以下内容属于路径错误, 或者也可能能实现, 但不知从何获取正确的资源

##### 参考资料

以下示例在 ```Rocky Linux 8.7``` 发行版基础上完成. 

非原始内核版本下的kdump服务无法运行,常规处理思路  
https://blog.csdn.net/realmardrid/article/details/123394122  
需注意, 文章中提到的:

```
在kexec-tools-2.0.19/kexec/arch/i386/x86-linux-setup.c 添加下列宏，不然编译报错。  
#define VIDEO_CAPABILITY_64BIT_BASE (1 << 1) /* Frame buffer base is 64-bit */
```

实测发现, 即使不定义这个宏, 也并未遇到报错


makedumpfile 编译安装的过程错误处理  
https://www.jianshu.com/p/c52c21c25dac


红帽文档:  
Why does kdump fails to start after updating to kexec-tools-2.0.20-34.el8.x86_64 with error makedumpfile parameter 
check failed?  
https://access.redhat.com/solutions/5608211

常规处理思路  
实际就是kernel的版本高了, 原本为其配套的 kexec-tools 并不适配, 需要自行手动编译一个.  
编译过程中又各种出错  

源码包涉及到两个:  
1) kexec-tools  
https://mirrors.edge.kernel.org/pub/linux/utils/kernel/kexec/


2) makedumpfile  
https://sourceforge.net/projects/makedumpfile/files/


#### 编译 makedumpfile 过程中的出错

make 一开始就会遇到错误, 但在源码包目录下README解释得非常有帮助

```
* REQUIREMENTS
  Please download the following library file and install it exactly as below;
  do NOT use "make install".
  - elfutils-0.144.tar.gz
    The "make install" of elfutils installs some commands (ld, readelf, etc.),
    and compiling problems sometimes happen due to using the installed
    commands. To install only the library & header files, use the following
    method:
     # tar -zxvf elfutils-0.144.tar.gz
     # cd elfutils-0.144
     # ./configure
     # make
     #
     # mkdir /usr/local/include/elfutils/
     # cp ./libdw/libdw.h   /usr/local/include/elfutils/libdw.h
     # cp ./libdw/dwarf.h   /usr/local/include/dwarf.h
     # cp ./libelf/libelf.h /usr/local/include/libelf.h
     # cp ./libelf/gelf.h   /usr/local/include/gelf.h
     #
     # cp ./libelf/libelf.a /usr/local/lib/libelf.a
     # cp ./libdw/libdw.a   /usr/local/lib/libdw.a
     # cp ./libasm/libasm.a /usr/local/lib/libasm.a
     # cp ./libebl/libebl.a /usr/local/lib/libebl.a
     #

* BUILD & INSTALL
  1.Get the latest makedumpfile from the following site:
    https://sourceforge.net/projects/makedumpfile/
  2.Uncompress the tar file:
    # tar -zxvf makedumpfile-x.y.z.tar.gz
  3.Enter the makedumpfile subdirectory:
    # cd makedumpfile-x.y.z
  4.Build, and install:
    # make; make install
  5.Build for a different architecture than the host :
    # make TARGET=<arch> ; make install
    where <arch> is the 'uname -m' of the target architecture. 
    The user has to set the environment variable CC to appropriate
    compiler for the target architecture.
  6.Build with lzo support:
    # make USELZO=on ; make install
    The user has to prepare lzo library.
  7.Build with snappy support:
    # make USESNAPPY=on ; make install
    The user has to prepare snappy library.
  8.Build the extension module for --eppic option.
    # make eppic_makedumpfile.so
    The user has to prepare eppic library from the following site:
    http://code.google.com/p/eppic/
```

elfutils 编译安装错误:

```
dwfl_report_elf.c:187:12: error: this statement may fall through [-Werror=implicit-fallthrough=]
       base = 0;
       ~~~~~^~~
dwfl_report_elf.c:189:5: note: here
     case ET_DYN:
     ^~~~
```

解决办法:

```
make CFLAGS='-Wno-implicit-fallthrough -Wno-nonnull-compare -Wno-unused-but-set-variable -Wno-implicit-function-declaration -Wno-sizeof-array-argument -Wno-sizeof-pointer-memaccess'
```

此时, 再次编译应该会出现以下错误:

```
i386_parse.y:1110:3: error: #error "bogus NMNES value"
 # error "bogus NMNES value"
   ^~~~~
make[2]: *** [Makefile:293: i386_parse.o] Error 1
make[2]: Leaving directory '/root/kexec-tools/elfutils-0.144/libcpu'
make[1]: *** [Makefile:347: all-recursive] Error 1
make[1]: Leaving directory '/root/kexec-tools/elfutils-0.144'
make: *** [Makefile:261: all] Error 2
```

~~改用~~

```
make CFLAGS='-Wno-implicit-fallthrough'
```

~~此时, 再次编译应该会出现以下错误:~~

```
dwarf_siblingof.c: In function ‘dwarf_siblingof’:
dwarf_siblingof.c:69:6: error: nonnull argument ‘result’ compared to NULL [-Werror=nonnull-compare]
   if (result == NULL)
      ^
cc1: all warnings being treated as errors
```

但实际上所需的库文件已生成, 可以按照 makedumpfile 源码包的 README 提示进行复制操作

```
mkdir /usr/local/include/elfutils/
\cp -f  ./libdw/libdw.h   /usr/local/include/elfutils/libdw.h
\cp -f ./libdw/dwarf.h   /usr/local/include/dwarf.h
\cp -f ./libelf/libelf.h /usr/local/include/libelf.h
\cp -f ./libelf/gelf.h   /usr/local/include/gelf.h

\cp -f ./libelf/libelf.a /usr/local/lib/libelf.a
\cp -f ./libdw/libdw.a   /usr/local/lib/libdw.a
\cp -f ./libasm/libasm.a /usr/local/lib/libasm.a
\cp -f ./libebl/libebl.a /usr/local/lib/libebl.a

\cp -f ./libdwfl/libdwfl.h /usr/local/include/elfutils/
```


makedumpfile 编译安装错误:

```
makedumpfile.h:30:10: fatal error: zlib.h: No such file or directory
 #include <zlib.h>
          ^~~~~~~~
compilation terminated.
make: *** [Makefile:90: elf_info.o] Error 1
```

解决办法:

```
yum -y install zlib-devel
```

makedumpfile 编译安装错误:

```
/usr/bin/ld: cannot find -lbz2
collect2: error: ld returned 1 exit status
make: *** [Makefile:97: makedumpfile] Error 1
```

解决办法:

```
yum -y install bzip2-devel
```

makedumpfile 编译安装错误:

```
/usr/bin/ld: cannot find -lpthread
/usr/bin/ld: cannot find -lbz2
/usr/bin/ld: cannot find -ldl
/usr/bin/ld: cannot find -lz
/usr/bin/ld: cannot find -lc
```

解决办法:

makedumpfile 里的 Makefile, 第55行的 ```-static``` 删掉, 使其从动态链接库寻找

```
     53 LIBS = -ldw -lbz2 -ldl -lelf -lz
     54 ifneq ($(LINKTYPE), dynamic)
     55 LIBS := -static $(LIBS)
     56 endif
     57 
```

改为:

```
     53 LIBS = -ldw -lbz2 -ldl -lelf -lz
     54 ifneq ($(LINKTYPE), dynamic)
     55 LIBS := $(LIBS)
     56 endif
     57 
```

#### kdump 服务启动的报错

<font color=red>以下均属错误言论</font>

~~```/usr/bin/kdumpctl```是脚本文件,通过加 -x 的调试方法来查看执行过程~~

```
+ '[' -f /boot/initramfs-5.4.236-1.el8.elrepo.x86_64kdump.img ']'
+ check_system_modified
+ local ret
+ [[ -f /boot/initramfs-5.4.236-1.el8.elrepo.x86_64kdump.img ]]
+ return 1
```


~~从输出可见, 它使用 -f 探测的文件有了错误  
原本应为 ```/boot/initramfs-5.4.236-1.el8.elrepo.x86_64k.img```  
却成为 ```/boot/initramfs-5.4.236-1.el8.elrepo.x86_64kdump.img```  
知道错误所在, 则应对不难.~~

~~第335行为我新增, 直接改为正确的文件名称 ```/boot/initramfs-5.4.236-1.el8.elrepo.x86_64.img```~~

```
    330                 # backup initrd for reference before replacing it
    331                 # with fadump aware initrd
    332                 backup_default_initrd
    333         else
    334                 TARGET_INITRD="$KDUMP_INITRD"
    335                 TARGET_INITRD=/boot/initramfs-5.4.236-1.el8.elrepo.x86_64.img
    336                 
    337                 # check if a backup of default initrd exists. If yes,
    338                 # it signifies a switch from fadump mode. So, restore
    339                 # the backed up default initrd.
    340                 restore_default_initrd
```

~~第425行, 原文为 ```return 1```, 我偷懒直接改为0~~

```
 422 
 423         if [ -n "$modified_files" ]; then
 424                 dinfo "Detected change(s) in the following file(s): $modified_files"
 425                 return 0
 426         fi
 427 
 428         return 0
```

~~此时再重启 kdump 服务得以恢复~~

```
[root@localhost ~]# systemctl start kdump
[root@localhost ~]# 
[root@localhost ~]# 
[root@localhost ~]# 
[root@localhost ~]# 
[root@localhost ~]# 
[root@localhost ~]# systemctl status kdump
● kdump.service - Crash recovery kernel arming
   Loaded: loaded (/usr/lib/systemd/system/kdump.service; enabled; vendor preset: enabled)
   Active: active (exited) since Thu 2023-03-16 09:25:54 EDT; 5s ago
  Process: 2825 ExecStart=/usr/bin/kdumpctl start (code=exited, status=0/SUCCESS)
 Main PID: 2825 (code=exited, status=0/SUCCESS)

Mar 16 09:25:53 localhost.localdomain systemd[1]: Starting Crash recovery kernel arming...
Mar 16 09:25:53 localhost.localdomain kdumpctl[2827]: kdump: Detected change(s) in the following file(s):  /usr/sbin/makedumpfile
Mar 16 09:25:54 localhost.localdomain kdumpctl[2827]: kdump: kexec: loaded kdump kernel
Mar 16 09:25:54 localhost.localdomain kdumpctl[2827]: kdump: Starting kdump: [OK]
Mar 16 09:25:54 localhost.localdomain systemd[1]: Started Crash recovery kernel arming.
```

~~不过此时用~~  
```echo c > /proc/sysrq-trigger```  
~~触发系统panic以后, 依然会kdump生成失败而转入 emergence 下的 shell.~~  

~~继而手动调试 makedumpfile 验证,发现~~

```
[root@localhost ~]# makedumpfile -c --message-level 7 -d 31 /boot/initramfs-5.4.236-1.el8.elrepo.x86_64.img 123
check_elf_format: Can't get valid ehdr.

makedumpfile Failed.
```

此处有误, 即使正确能工作的kdump主机, 使用该 makedumpfile 命令加参数, 也出现同样的报错

<h3 id="2">配置crash工具集环境</h3>  

#### 启用 kdump

红帽/CentOS/Rocky 以及再其基础上的山寨/换皮, 开启的方法在互联网上足够多了, 没有介绍必要

SuSE Linux, 虽然步骤大同小异, 留个文档链接以备不时之需

https://www.suse.com/support/kb/doc/?id=000016171

#### 如果希望手动指定 crashkernel 的大小

https://access.redhat.com/solutions/916043

Configuring crashkernel on RHEL7.0 (and later) kernels
crashkernel is configured in the GRUB_CMDLINE_LINUX line in ```/etc/default/grub```

```
GRUB_TIMEOUT=5
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=rhel00/root rd.lvm.lv=rhel00/swap
 rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
```

其中```crashkernel=auto``` 改为 128M 或 256M

After modifying /etc/default/grub, regenerate the GRUB2 configuration using the edited default file. If your system uses BIOS firmware, execute the following command:

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```

如果是启用了UEFI 的则略有区别  
On a system with UEFI firmware, execute the following instead:  

```
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
```

>Starting with RHEL7 kernels crashkernel=auto should usually be used. The kernel will automatically reserve an appropriate amount of memory for the kdump kernel.
>
>Keep in mind that it is an algorithmically calculated memory reservation and may not meet the needs of all systems 
> (Especially for configurations with many IO cards and loaded drivers). Ensure that memory reserved by crashkernel=auto is sufficient for the target machine by testing kdump. If it is insufficient, reserve more memory using syntax crashkernel= XM where X is amount of memory to be reserved in megabytes.
>
> The amount of memory reserved for the kdump kernel can be estimated with the following scheme:
> 
>base memory to be reserved = 160MB  
an additional 2 bits added for every 4 KB of physical RAM present in the system. 
So  for example if a system has 1TB of memory 224 MB is the minimum (160 + 64 MB). 
> 
> Note: It is recommended to verify that kdump is working on all systems after installation of all applications. The memory reserved by crashkernel=auto takes only typical RHEL configurations into account. If 3rd party modules are used more memory may need to be reserved. If a testdump fails, it is a good strategy to verify if it works with crashkernel=768M@0M. It is recommended that until a test dump works without failure that kdump not be considered configured properly.
>
>Note: RHEL7 with crashkernel=auto will only reserve memory on systems with 2GB or more physical memory. If the 
> system has less than 2GB of memory the memory must be reserved by explicitly requesting the reservation size, for example: crashkernel=128M.
>
>Note: Some environments still require manual configuration of the crashkernel option, for example if dumps to very 
> large local filesystems are performed. Please refer to kdump fails with large ext4 file system because fsck.ext4 gets OOM-killed for details.
>
>After adding the crashkernel parameter the system must be rebooted for the crashkernel memory to be reserved for 
> use by kdump.


<h3 id="3">kdump需要保留多少内存</h3>  

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/kernel_administration_guide/kernel_crash_dump_guide

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/kernel_administration_guide/kernel_crash_dump_guide#sect-kdump-memory-requirements

原文引用

> For example, on the x86_64 architecture, the amount of reserved memory is 160 MB + 2 bits for every 4 KB of RAM

在x86架构CPU上:  
160 MB 是基数不变  
每4KB内存需要2个bits  
因此 1TB 内存:  
1024 x 1024 x 1024 = 1,073,741,824 KiloBytes  
1,073,741,824 / 4 = 268,435,456 (个4K页)  
每个4K页 占用 2个 比特位bits 268,435,456 * 2 = 536870912  
536870912 / 1024 / 1024 = 512  
但这512还是比特位bits, 需要转换成字节Bytes, 还需要除8, 512 / 8 = 64MB  
这也就是文中 1TB 内存需要的保留内存为 160+64=224MB 的由来  
因此, 常见的如256G内存的机型等, crashkernel 都在 256MB 覆盖范围内.

另附原文中的不同架构CPU的保留内存大小表格

<table>
    <tr>
        <th>CPU architecture</th><th>Available memory</th><th>Crash memory automatically reserved</th>
    </tr>
    <tr>
        <td>AMD64 and Intel 64 (x86_64)</td><td>2 GB and more</td><td>161 MB + 64 MB per 1 TB</td>
    </tr>
    <tr>
        <td>64-bit ARM architecture (arm64)</td><td>2 GB and more</td><td>512 MB</td>
    </tr>
    <tr>
        <td rowspan="5">IBM POWER ppc64/ppc64le</td><td>2 GB to 4 GB</td><td>384 MB</td>
    </tr>
    <tr>
        <td>4 GB to 16 GB</td><td>512 MB</td>
    </tr>
    <tr>
        <td>16 GB to 64 GB</td><td>1 GB</td>
    </tr>
    <tr>
        <td>64 GB to 128 GB</td><td>2 GB</td>
    </tr>
    <tr>
        <td>128 GB and more</td><td>4 GB</td>
    </tr>
    <tr>
        <td>IBM Z (s390x)</td><td>4 GB and more</td><td>161 MB + 64 MB per 1 TB<br>[1] 160 MB on RHEL-ALT-7.6</td>
    </tr>
</table>


<h3 id="4">设置了crashkernel的大小, kdump服务依然报错的情况</h3>  

根据本文介绍的, 设置了 crashkernel=256M@16M, 然而```kdump```服务依旧告诉你你没有保留内存

```
[root@5950x-node1 ~]# systemctl status kdump.service
● kdump.service - Crash recovery kernel arming
   Loaded: loaded (/usr/lib/systemd/system/kdump.service; enabled; vendor preset: enabled)
   Active: failed (Result: exit-code) since Sun 2023-04-02 17:56:04 CST; 5s ago
  Process: 2037 ExecStart=/usr/bin/kdumpctl start (code=exited, status=1/FAILURE)
 Main PID: 2037 (code=exited, status=1/FAILURE)

Apr 02 17:56:04 5950x-node1 systemd[1]: Starting Crash recovery kernel arming...
Apr 02 17:56:04 5950x-node1 kdumpctl[2039]: kdump: No memory reserved for crash kernel
Apr 02 17:56:04 5950x-node1 kdumpctl[2039]: kdump: Starting kdump: [FAILED]
Apr 02 17:56:04 5950x-node1 systemd[1]: kdump.service: Main process exited, code=exited, status=1/FAILURE
Apr 02 17:56:04 5950x-node1 systemd[1]: kdump.service: Failed with result 'exit-code'.
Apr 02 17:56:04 5950x-node1 systemd[1]: Failed to start Crash recovery kernel arming.
```

dmesg 的报错内容

```
[root@5950x-node1 ~]# dmesg -T | grep crash
[Sun Apr  2 18:10:34 2023] Command line: BOOT_IMAGE=(mduuid/09130a4a9a5219308af89a0cd8ad0e0b)/vmlinuz-6.1.20 root=UUID=efd8306f-d3a5-4be6-b70c-273dc67f4095 ro crashkernel=256M@16M rd.md.uuid=c73334c8:9da98fe8:be443e65:43c976e2 rd.md.uuid=09130a4a:9a521930:8af89a0c:d8ad0e0b rhgb quiet
[Sun Apr  2 18:10:34 2023] crashkernel reservation failed - memory is in use.
[Sun Apr  2 18:10:34 2023] Kernel command line: BOOT_IMAGE=(mduuid/09130a4a9a5219308af89a0cd8ad0e0b)/vmlinuz-6.1.20 root=UUID=efd8306f-d3a5-4be6-b70c-273dc67f4095 ro crashkernel=256M@16M rd.md.uuid=c73334c8:9da98fe8:be443e65:43c976e2 rd.md.uuid=09130a4a:9a521930:8af89a0c:d8ad0e0b rhgb quiet
```

由以上可见, 它是试图使用自16M开始的内存地址, 却发现已在使用中.  
这一情况出现在物理机上, 与虚拟机上还有区别.  
不确定是否是与传统BIOS(legacy bios) 和 启用了UEFI 的BIOS 的区别.  
例如在我的主板上是双BIOS, 且未发现仅使用传统BIOS的选项. 但系统其实是以传统BIOS模式启动的.  
总之, 对于此类情况的处理办法:
- 取消 256M@16M 中的 @16M
- 尝试增大 16M 的大小


经过更改后的 dmesg 内容可知, 系统保留的内存是自```2784 MB```开始

```
[Sun Apr  2 18:41:55 2023] Command line: BOOT_IMAGE=(mduuid/09130a4a9a5219308af89a0cd8ad0e0b)/vmlinuz-6.1.20 root=UUID=efd8306f-d3a5-4be6-b70c-273dc67f4095 ro crashkernel=256M rd.md.uuid=c73334c8:9da98fe8:be443e65:43c976e2 rd.md.uuid=09130a4a:9a521930:8af89a0c:d8ad0e0b rhgb quiet
[Sun Apr  2 18:41:55 2023] Reserving 256MB of memory at 2784MB for crashkernel (System RAM: 130960MB)
[Sun Apr  2 18:41:55 2023] Kernel command line: BOOT_IMAGE=(mduuid/09130a4a9a5219308af89a0cd8ad0e0b)/vmlinuz-6.1.20 root=UUID=efd8306f-d3a5-4be6-b70c-273dc67f4095 ro crashkernel=256M rd.md.uuid=c73334c8:9da98fe8:be443e65:43c976e2 rd.md.uuid=09130a4a:9a521930:8af89a0c:d8ad0e0b rhgb quiet
```


<h3 id="5">kdump服务正常, vmcore未正常生成</h3>  

https://gitee.com/src-openeuler/kernel/issues/I3EAS1?_from=gitee_search

> 当前定位原因：第二个内核启动过程中会触发设备复位(reset_devices)操作，但设备复位操作后MegaRAID控制器或磁盘状态故障，导致访问MegaRAID卡下挂的磁盘报错(vmcore文件需要写入这些磁盘保存)；  
影响：带有该MegaRAID卡的机器上kdump触发启动第二个内核过程中一直报磁盘访问错误，导致第二个内核启动过程中生成vmcore失败；  
规避措施：1.linux上游社区主线版本也有同样问题；2.在物理机/etc/sysconfig/kdump文件中将第二个内核启动默认参数中的reset_devices去掉，可以成功生成vmcore，即可规避该问题；

原本以为 openeuler 社区就是正解, 因为正巧我虽然不是硬件raid卡, 但板载raid也即软raid, 怀疑也是kdump试图写文件但不成功.

然而实践检验的结果并非如此.

https://bugzilla.openanolis.cn/show_bug.cgi?id=1360

> 原因：
> crashkernel参数配置，预留内存过小导致kdump无法正常运行。
>
> 实例使用的是8G内存，crashkernel配置如下：
> crashkernel=0M-2G:0M,2G-8G:192M,8G-:256M
>
> 将该参数修改为:
> crashkernel=0M-2G:0M,2G-8G:256M,8G-:512M
>
> 如此，在预留256M内存的情况下，可以正常生成vmcore

原本是对这个说法不以为然的, 因为根据kdump手册的介绍, 256M已可支持1TB内存的物理机.

然而实践的结果确实是从256M 调大到512M解决了问题.  
物理机的内存为128G.  
修改后的 /proc/cmdline

```
[root@5950x-node1 ~]# cat /proc/cmdline 
BOOT_IMAGE=(mduuid/09130a4a9a5219308af89a0cd8ad0e0b)/vmlinuz-6.1.20 root=UUID=efd8306f-d3a5-4be6-b70c-273dc67f4095 ro crashkernel=0M-2G:0M,2G-8G:256M,8G-:512M rd.md.uuid=c73334c8:9da98fe8:be443e65:43c976e2 rd.md.uuid=09130a4a:9a521930:8af89a0c:d8ad0e0b rhgb quiet
```


<h3 id="6">crash 调查内核崩溃原因</h3>

https://www.51cto.com/article/648410.html

要能读取 ```kdump``` 生成的内核转储文件, 实际需要用到3个包

```
crash
kernel-debuginfo
kernel-debuginfo-common-<架构>
```

其中 ```kernel-debuginfo-common-<架构>``` 包名依赖于你的具体CPU架构

通过 yum 命令安装, 其实只需要给出,```crash```和```kernel-debuginfo```, yum 会附带给出```kernel-debuginfo-common-<架构>```的名称.

而自行编译安装的内核, 如按照本文档前述内容, 在编译安装阶段, 启用了 ```kdump``` 的相关工具链, 则只需要 ```crash``` 软件包被安装即可

1) crash 命令格式

```crash <namelist, 即用于读取kdump文件的环境> <内核转储文件>```

其中
- namelist , 如果按本文文档的编译安装阶段的推荐位置, 则位于 ```/lib/modules/<内核版本>/build/vmlinux```
即, crash 命令不给任何参数的情况下, "KERNEL:" 一行指向的位置

- 内核转储文件, 即 kdump 生成的文件, 默认配置没有修改的情况下是 ```/var/crash``` 会新增出目录
最终的文件是 ```vmcore``` (同样没有修改默认配置的情况下)

**如何确认一个文件是否为有效的读取 kdump 的环境?**

```
[root@X9DRi-LN4F ~]# crash -g /lib/modules/6.1.46/build/vmlinux

crash 7.3.2-4.el8_8.1
Copyright (C) 2002-2022  Red Hat, Inc.
Copyright (C) 2004, 2005, 2006, 2010  IBM Corporation
Copyright (C) 1999-2006  Hewlett-Packard Co
Copyright (C) 2005, 2006, 2011, 2012  Fujitsu Limited
Copyright (C) 2006, 2007  VA Linux Systems Japan K.K.
Copyright (C) 2005, 2011, 2020-2022  NEC Corporation
Copyright (C) 1999, 2002, 2007  Silicon Graphics, Inc.
Copyright (C) 1999, 2000, 2001, 2002  Mission Critical Linux, Inc.
This program is free software, covered by the GNU General Public License,
and you are welcome to change it and/or distribute copies of it under
certain conditions.  Enter "help copying" to see the conditions.
This program has absolutely no warranty.  Enter "help warranty" for details.
 
GNU gdb (GDB) 7.6
Copyright (C) 2013 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-unknown-linux-gnu"...

crash: /lib/modules/6.1.46/build/vmlinux: contains debugging data
```

其中  
```crash: /lib/modules/6.1.46/build/vmlinux: contains debugging data```

2) 内核崩溃的原因与进程

```
[root@X9DRi-LN4F ~]# crash /lib/modules/6.1.46/build/vmlinux /var/crash/127.0.0.1-2023-08-26-12\:08\:02/vmcore

crash 7.3.2-4.el8_8.1
Copyright (C) 2002-2022  Red Hat, Inc.
Copyright (C) 2004, 2005, 2006, 2010  IBM Corporation
Copyright (C) 1999-2006  Hewlett-Packard Co
Copyright (C) 2005, 2006, 2011, 2012  Fujitsu Limited
Copyright (C) 2006, 2007  VA Linux Systems Japan K.K.
Copyright (C) 2005, 2011, 2020-2022  NEC Corporation
Copyright (C) 1999, 2002, 2007  Silicon Graphics, Inc.
Copyright (C) 1999, 2000, 2001, 2002  Mission Critical Linux, Inc.
This program is free software, covered by the GNU General Public License,
and you are welcome to change it and/or distribute copies of it under
certain conditions.  Enter "help copying" to see the conditions.
This program has absolutely no warranty.  Enter "help warranty" for details.
 
GNU gdb (GDB) 7.6
Copyright (C) 2013 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-unknown-linux-gnu"...

WARNING: kernel relocated [912MB]: patching 139086 gdb minimal_symbol values

      KERNEL: /lib/modules/6.1.46/build/vmlinux  [TAINTED]             
    DUMPFILE: /var/crash/127.0.0.1-2023-08-26-12:08:02/vmcore  [PARTIAL DUMP]
        CPUS: 32
        DATE: Sat Aug 26 12:07:39 CST 2023
      UPTIME: 4 days, 14:05:22
LOAD AVERAGE: 6.02, 4.26, 3.50
       TASKS: 1364
    NODENAME: X9DRi-LN4F
     RELEASE: 6.1.46
     VERSION: #1 SMP PREEMPT_DYNAMIC Sun Aug 20 11:29:53 CST 2023
     MACHINE: x86_64  (3300 Mhz)
      MEMORY: 1024 GB
       PANIC: "Oops: 0000 [#1] PREEMPT SMP PTI" (check log for details)
         PID: 1882
     COMMAND: "bcache_gc"
        TASK: ffff96141b514c80  [THREAD_INFO: ffff96141b514c80]
         CPU: 26
       STATE: TASK_RUNNING (PANIC)

crash>
```

以上为例,  
```PANIC:``` 是引起内核崩溃的原因  
```PID``` ```COMMAND``` 是相关的进程/命令

3) 还想更进一步了解更多

**bt 命令查看堆栈信息**

```
crash> bt
PID: 1957     TASK: ffff8949c5ca4c80  CPU: 17   COMMAND: "bcache_gc"
 #0 [ffffa51b342778b0] machine_kexec at ffffffff8ca6a7e7
 #1 [ffffa51b34277908] __crash_kexec at ffffffff8cbbcaba
 #2 [ffffa51b342779c8] crash_kexec at ffffffff8cbbdd84
 #3 [ffffa51b342779d8] oops_end at ffffffff8ca28af9
 #4 [ffffa51b342779f8] page_fault_oops at ffffffff8ca79825
 #5 [ffffa51b34277a78] exc_page_fault at ffffffff8d558714
 #6 [ffffa51b34277aa0] asm_exc_page_fault at ffffffff8d600bb2
    [exception RIP: btree_node_free+17]
    RIP: ffffffffc0a0c921  RSP: ffffa51b34277b58  RFLAGS: 00010207
    RAX: 0000000080000000  RBX: 0000000000000000  RCX: 0000000000000001
    RDX: 0000000080000001  RSI: ffff8948d8780690  RDI: 0000000000000000
    RBP: ffffa51b34277dd8   R8: ffff8948d8780690   R9: 00000000000301c0
    R10: 0004bc434315903d  R11: 0000000000000001  R12: 0000000000000004
    R13: ffffa51b34277e00  R14: ffffa51b34277e60  R15: ffffa51b34277d10
    ORIG_RAX: ffffffffffffffff  CS: 0010  SS: 0018
 #7 [ffffa51b34277b70] btree_gc_coalesce at ffffffffc0a10ea5 [bcache]
 #8 [ffffa51b34277cf8] btree_gc_recurse at ffffffffc0a111e1 [bcache]
 #9 [ffffa51b34277de0] bch_btree_gc at ffffffffc0a11ae7 [bcache]
#10 [ffffa51b34277ec8] bch_gc_thread at ffffffffc0a11d91 [bcache]
#11 [ffffa51b34277f18] kthread at ffffffff8cb19ec9
#12 [ffffa51b34277f50] ret_from_fork at ffffffff8ca01eb2
```

有编号的最后一行:  
```#12 [ffffa51b34277f50] ret_from_fork at ffffffff8ca01eb2```  
是系统崩溃前的最后一个调用  
如果想查看与之关联的对象, 则需执行下一个命令

**dis 反编译**

通过前一步的 ```ret_from_fork at ffffffff8ca01eb2``` 其中的 ```ffffffff8ca01eb2``` 是其内存地址.

用 dis 命令来看一下该地址的反汇编结果

```
crash> dis -l ffffffff8ca01eb2
/usr/src/kernels/6.1.46/arch/x86/entry/entry_64.S: 312
0xffffffff8ca01eb2 <ret_from_fork+34>:  movq   $0x0,0x50(%rsp)
```

其中  
```/usr/src/kernels/6.1.46/arch/x86/entry/entry_64.S: 312```  
代表该代码文件及行数, 即:  
文件是: ```/usr/src/kernels/6.1.46/arch/x86/entry/entry_64.S```  
行数为: 312 行

```0xffffffff8ca01eb2 <ret_from_fork+34>:  movq   $0x0,0x50(%rsp)```  
执行的汇编指令, 当然已超出个人技能范畴  

**log 命令**

可以打印系统消息缓冲区，从而可能找到系统崩溃的线索。

** ps 命令**

ps 命令用于显示进程的状态，带 > 标识代表是活跃的进程。
