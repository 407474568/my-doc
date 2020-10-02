#### vcenter批量克隆虚拟机

首次运行powershell, 需要执行

```
Set-ExecutionPolicy RemoteSigned
```

以配置powercli可以执行远程脚本, 否则启动时会错误提示

&nbsp;

需要用到PowerCLI, 下载地址:

https://my.vmware.com/web/vmware/downloads/details?downloadGroup=PCLI650R1&productId=614

普通注册帐号即可下载, 无需付费用户权限

安装后, 有两个快捷方式

![](/images/6WhgIz9Bdl7sKAvOrmZkciXxSRfHVE2a.jpg)

需要双击运行, 后续操作要在此窗口环境下执行, 否则会缺少必要的vmware模块

&nbsp;

PowerCLI 是在 Windows Powershell上开发的, 想用python直接操控PowerCLI似乎无法绕过

只有寻找第3方lib是否有实现

https://www.reddit.com/r/learnpython/comments/cyma26/i_prefer_python_over_powershell_but_can_i_use_it/

&nbsp;


在此环境下执行ps1脚本文件的示例
```
powershell -File "D:\临时存储\vCenter批量克隆\批量克隆 - 修改.ps1" -FileName "D:\临时存储\vCenter批量克隆\info.csv"
```

第1个 -File &emsp;&emsp;&emsp;参数是powershell 传参你的ps1脚本文件的位置

第2个 -FileName &ensp;参数是ps1脚本内部要求的传参

&nbsp;

<font color=red>PowerCLI 有哪些命令</font>

全部的命令在VMware-PowerCLI-6.5.0-上有592个

常用的有以下:

```
get-vicommand– 显示所有命令列表

Connect-VIServer– 连接虚拟化平台

get-vmhost – 显示ESXi主机列表

get-cluster –显示群集列表

get-datastore– 显示存储列表

get-resourcepool– 显示资源池

get-vm – 显示虚拟机列表

get-virtualswitch– 显示虚拟交换机列表

start-vm\stop -vm – 启动或关闭虚拟机

new -vm – 创建虚拟机

get-template– 显示模板列表

get-oscustomizationspec– 显示自定义规范列表

get-vapp – 显示vapp 应用列表

get-folder – 显示文件夹列表

```

<font color=red>创建虚拟机</font>

https://developer.aliyun.com/article/530985

PowerCLI 创建虚拟机命令New-VM, 用到的最基础的信息:

- 虚拟机名称 -- 在阿里这篇文档里变量定义为: name

- 模板名称 -- 在阿里这篇文档里变量定义为: template

- esxi主机，也就是在vcenter清单里显示的名称 -- 在阿里这篇文档里变量定义为: host

- 数据存储名称 -- 在阿里这篇文档里变量定义为: datastore

只提供以上4个信息即可完成一个虚拟机的创建

更丰富的参数选择以完成自定义的需求, 通过
```
Get-Help New-VM
```
查看内置帮助

在New-VM命令其中也有 NetworkName和Portgroup 两个参数可选

&nbsp;

<font color=red>自动配置IP和计算机名称</font>

自动配置IP和计算机名称的实现, 涉及到几个命令配合

- 虚拟机规范文件:  
New-OSCustomizationSpec 和 Set-OSCustomizationSpec  
前者创建新的, 后者设置已有的  
虚拟机规范文件用来提供虚拟机的IP和计算机名称信息  

- 创建虚拟机和设置虚拟机属性:  
New-VM 和 Set-VM  
CPU数量, 内存大小, 备注等规则

- 获取当前新建出来的虚拟机的指向  
```Get-VM -Name 虚拟机名称```

- 获取指定虚拟机的网卡指向  
```Get-NetworkAdapter```  
结合上一条就是  
```Get-VM -Name 虚拟机名称 | Get-NetworkAdapter```

- 设置虚拟机网卡属性  
Set-NetworkAdapter  
用于指定虚拟机使用vCenter上的哪个虚拟端口组(或分布式交换机, 参数不同)

完整的命令示例:

```
# 创建虚拟机规范文件
New-OSCustomizationSpec -Name 虚拟机规范文件名称 -OSType 操作系统类型(Windows / Linux) -Workgroup 工作组名称 -FullName 全名 -OrgName 组织名称

# 修改虚拟机规范文件, -ChangeSid是windows类型特有的参数
Set-OSCustomizationSpec -NamingScheme Fixed -NamingPrefix 主机名 -ChangeSid:$true

# 创建虚拟机
New-VM -Name 虚拟机名称 -VMHost Exsi主机名称 -Template 虚拟机模板名称 -Datastore 数据存储名称 -OSCustomizationspec 虚拟机规范名称
或
New-VM -Name 虚拟机名称 -ResourcePool 集群名称 -Template 虚拟机模板名称 -Datastore 数据存储名称 -OSCustomizationspec 虚拟机规范名称

# 设置虚拟机属性, 指向某个虚拟机的指针 在powershell中可以用变量存储, 如:  $vm = Get-VM -Name 虚拟机名称
Set-VM -VM 指向某个虚拟机的指针 -NumCpu CPU核心数量 -MemoryGB 内存大小(GB) -Notes 备注信息 -Confirm:$false

# 获取指定的虚拟端口组, 虚拟机所在的宿主机名称用"指向某个虚拟机的指针".VMHost 可以获得
Get-VirtualPortGroup -Name 虚拟端口组名称 -VMHost 虚拟机所在的宿主机名称

设置虚拟机网卡属性--指针类都用Get-xxx的方式获取, 再用变量存储引用
Set-NetworkAdapter -NetworkAdapter 指向虚拟机网卡指针 -Portgroup 指向虚拟端口组的指针 -Confirm:$false

Set-NetworkAdapter -NetworkAdapter 指向虚拟机网卡指针 -Type E1000 -StartConnected:$true -Confirm:$false

# 移除创建的自定义虚拟机规范
Remove-OSCustomizationSpec $osspec -Confirm:$false

# 虚拟机开机
Start-VM  -VM 指向虚拟机网卡指针 -Confirm:$false
```
