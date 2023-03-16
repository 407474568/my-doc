* [目录](#0)
  * [非原始内核版本下的kdump服务](#1)
  * [配置crash工具集环境](#2)

<h3 id="1">非原始内核版本下的kdump服务</h3>  

参考资料



红帽文档: 
Why does kdump fails to start after updating to kexec-tools-2.0.20-34.el8.x86_64 with error makedumpfile parameter 
check failed?  
https://access.redhat.com/solutions/5608211

```/usr/bin/kdumpctl```是脚本文件,通过加 -x 的调试方法来查看执行过程

```
+ '[' -f /boot/initramfs-5.4.236-1.el8.elrepo.x86_64kdump.img ']'
+ check_system_modified
+ local ret
+ [[ -f /boot/initramfs-5.4.236-1.el8.elrepo.x86_64kdump.img ]]
+ return 1
```

从输出可见, 它使用 -f 探测的文件有了错误  
原本应为 ```/boot/initramfs-5.4.236-1.el8.elrepo.x86_64k.img```  
却成为 ```/boot/initramfs-5.4.236-1.el8.elrepo.x86_64kdump.img```  
知道错误所在, 则应对不难.

第335行为我新增, 直接改为正确的文件名称 ```/boot/initramfs-5.4.236-1.el8.elrepo.x86_64.img```

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



第425行, 原文为 ```return 1```, 我偷懒直接改为0

```
 422 
 423         if [ -n "$modified_files" ]; then
 424                 dinfo "Detected change(s) in the following file(s): $modified_files"
 425                 return 0
 426         fi
 427 
 428         return 0
```

此时再重启 kdump 服务得以恢复

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

不过此时用  
```echo c > /proc/sysrq-trigger```  
触发系统panic以后, 依然会kdump生成失败而转入 emergence 下的 shell.  

继而手动调试 makedumpfile 验证,发现
```
[root@localhost ~]# makedumpfile -c --message-level 7 -d 31 /boot/initramfs-5.4.236-1.el8.elrepo.x86_64.img 123
check_elf_format: Can't get valid ehdr.

makedumpfile Failed.
```

<red>此问题待解</red>


<h3 id="2">配置crash工具集环境</h3>  

#### 如果希望手动指定 crashkernel 的大小

https://access.redhat.com/solutions/916043

Configuring crashkernel on RHEL7.0 (and later) kernels
crashkernel is configured in the GRUB_CMDLINE_LINUX line in /etc/default/grub:

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
