* [目录](#0)
  * [IPSec实现防火墙功能](#1)
  * [注册Windows服务项](#2)
  * [mstsc 指定显示器](#3)
  * [清理arp条目](#4)
  * [Windows上设置应用程序的CPU亲缘性](#5)


<h3 id="1">IPSec实现防火墙功能</h3>

#### 图形化的操作  

https://blog.51cto.com/yttitan/1571117 

#### 命令行操作

```
rem 创建策略名称
netsh ipsec static add policy name="限制3389访问来源"

rem 创建动作名称,指定动作
netsh ipsec static add filteraction name="阻止" action=block
netsh ipsec static add filteraction name="允许" action=permit

rem 创建IP筛选列表
netsh ipsec static add filterlist name="所有IP"
netsh ipsec static add filterlist name="白名单IP"

rem 添加IP源地址,目的地址,目的端口,协议到IP筛选列表
netsh ipsec static add filter filterlist="所有IP" srcaddr=any dstaddr=me dstport=3389 description="所有IP的3389端口访问控制" protocol=TCP mirrored=yes
netsh ipsec static add filter filterlist="白名单IP" srcaddr=192.168.10.2 dstaddr=me dstport=3389 description="白名单IP允许3389端口访问" protocol=TCP mirrored=yes

rem 定义IP筛选列表与动作的对应关联
netsh ipsec static add rule name="所有IP的3389端口访问控制" policy="限制3389访问来源" filterlist="所有IP" filteraction="阻止"
netsh ipsec static add rule name="白名单IP允许3389端口访问" policy="限制3389访问来源" filterlist="白名单IP" filteraction="允许"

rem 激活该策略
netsh ipsec static set policy name="限制3389访问来源" assign=y

rem 确保IPSec服务是启动状态与开机自启动
sc start PolicyAgent
sc config PolicyAgent start= auto
```


<h3 id="2">注册Windows服务项</h3>

#### 使用 nssm 程序辅助注册的方法  
https://blog.csdn.net/weixin_37348409/article/details/112304560  

其中程序下载地址  
http://www.nssm.cc/release/nssm-2.24.zip  
可能需要wget 之类的来辅助下载, 浏览器直接点击未必响应  

备用地址  
<a href="files/nssm-2.24.zip" target="_blank">nssm-2.24.zip</a>  


注册

```
:: 如果nssm的目录在path里就不用这句话了
cd /d "D:\Program Files\nssm-2.24\win64"
set serviceName=my_watchdog
:: python解释器目录
set pathonExe="D:\Program Files\Python310\python.exe"
:: 项目路径
set executePath="D:\Code\private\dev"
:: 脚本以及脚本的参数
set executeScript="my_watchdog_for_windows_pc.py"
:: 注册服务
nssm.exe install %serviceName% %pathonExe%  %executeScript%
nssm.exe set %serviceName% Application %pathonExe%
nssm.exe set %serviceName% AppDirectory %executePath%
nssm.exe set %serviceName% AppParameters %executeScript%
:: 启动服务
nssm.exe start %serviceName%
pause
```

卸载  

```
cd C:\Users\wang_\Downloads\nssm-2.24\win64
set serviceName=testService1
nssm.exe stop %serviceName%
nssm.exe remove %serviceName%
pause
```

#### 使用 instsrv+srvany 的方式

https://zhuanlan.zhihu.com/p/93808282  

https://blog.csdn.net/liujiayu2/article/details/47722423

工具下载  

<a href="files/Windows服务创建工具_instsrv+srvany.rar" target="_blank">Windows服务创建工具_instsrv+srvany.rar</a>

instsrv+srvany 看起来有更广泛的普适性, 使用sc创建的服务, 后端有一些类型的exe程序在启动服务时会报错

~~64位的Windows, 将包内2个文件 ```instsrv.exe``` 和 ```srvany.exe``` 释放到 ```C:\WINDOWS\SysWOW64```~~  
~~32位的位置为 ```C:\WINDOWS\system32```~~

更正:  
64位的Windows, 将包内2个文件 ```instsrv.exe``` 和 ```srvany.exe``` 释放到 ```C:\WINDOWS\system32```  
32位的位置为 ```C:\WINDOWS\SysWOW64```  
这是Windows的历史遗留问题


创建服务

```
C:\WINDOWS\SysWOW64\instsrv.exe <自定义的服务名称> C:\WINDOWS\SysWOW64\srvany.exe
```

删除服务

```
C:\WINDOWS\SysWOW64\instsrv.exe <自定义的服务名称> remove
```

其后在注册表的服务项下添加 ```parameters```, 其位置位于 

```
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services
```


> 名称 Application 值：你要作为服务运行的程序地址。  
> 名称 AppDirectory 值：你要作为服务运行的程序所在文件夹路径。  
> 名称 AppParameters 值：你要作为服务运行的程序启动所需要的参数。

一个完整的注册表项的导出

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\trojan-cli_Hawkhost]
"Type"=dword:00000010
"Start"=dword:00000002
"ErrorControl"=dword:00000001
"ImagePath"=hex(2):43,00,3a,00,5c,00,57,00,49,00,4e,00,44,00,4f,00,57,00,53,00,\
  5c,00,53,00,79,00,73,00,57,00,4f,00,57,00,36,00,34,00,5c,00,73,00,72,00,76,\
  00,61,00,6e,00,79,00,2e,00,65,00,78,00,65,00,00,00
"DisplayName"="trojan-cli_Hawkhost"
"WOW64"=dword:0000014c
"ObjectName"="LocalSystem"

[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\trojan-cli_Hawkhost\Parameters]
"Application"="D:\\Program Files\\trojan-cli - Hawkhost\\trojan.exe"
"AppDirectory"="D:\\Program Files\\trojan-cli - Hawkhost"
"AppParameters"=""
```


<h3 id="3">mstsc 指定显示器</h3>

当终端是多个显示器时, 希望指定mstsc的显示窗口运行在哪个显示器上

https://www.cnblogs.com/wuhailong/p/16420263.html

从 mstsc 编辑会话框上另存出一个会话来, ```.rdp``` 的文件

![](images/FyG1lejZrq8CONtLkYfHdyuXFmTA5gjR.png)

用文本编辑器编辑该rdp文件

增加一个语句行

```
表示第1,2个显示器
selectedmonitors:s:1,2

表示第1个显示器
selectedmonitors:s:1
```

以此类推

![](images/FyG1lejZrqxUhPJAM2oeIOQlZWG5FmYb.png)


<h3 id="4">清理arp条目</h3>

https://www.yundongfang.com/Yun68558.html

Windows上arp命令的几个相关用法

```
查看arp缓存
arp -a
也可以
arp -a <IP地址>

清理全部arp缓存
netsh interface IP delete arpcache

删除特定arp条目
arp -d <IP地址>
```


<h3 id="5">Windows上设置应用程序的CPU亲缘性</h3>

https://blog.csdn.net/WhoisPo/article/details/52078469
https://blog.csdn.net/kongxx/article/details/79252866

图形化设置CPU亲缘性, 没有太多值得赘述的, 网上文章也足够多  
通过任务管理器对进程进行设置, Windows的术语叫"设置相关性"  
缺点就是进程结束后需要重设  

命令行设置的方法

在 cmd 下执行,或是写成批处理文件

```
start /WAIT /affinity <标志位> <应用程序>
```

如:

```
start /WAIT /affinity 0xf notepad.exe
start /WAIT /affinity 0xff notepad.exe
start /affinity 0xf notepad.exe
```

其中  
```0xf``` 是16进制, 然后会被windows转换成2进制为```1111```, 即掩码标识CPU核心数的位置  

```
start /WAIT /affinity 0x1 app.exe （只使用第一个CPU）(二进制: 0001)
start /WAIT /affinity 0x2 app.exe （只使用第二个CPU）(二进制: 0010)
start /WAIT /affinity 0x4 app.exe （只使用第三个CPU）(二进制: 0100)
start /WAIT /affinity 0x8 app.exe （只使用第四个CPU）(二进制: 1000)
start /WAIT /affinity 0x3 app.exe （只使用第1，2个CPU）(二进制: 0011)
start /WAIT /affinity 0x7 app.exe （只使用第1，2，3个CPU）(二进制: 0111)
start /WAIT /affinity 0xf app.exe （只使用第1，2，3，4个CPU）(二进制: 1111)
```

以上是4个核心的表示方式  
网上的文章大都只提到了4个以内的表示方式, 那4个以上如何表示?  
简单实验一下可知, 继续叠加即可, 即:  
前8个核心为 ```0xff```  
前12个核心为 ```0xfff```  
以此类推

至于 ```start /WAIT``` 参数的含义, 加与不加的区别是:  
- 有 ```/WAIT```, CMD窗口是阻塞状态, 适用于批处理文件的执行方式 
- 没有 ```/WAIT```, CMD窗口是非阻塞状态, 目标应用有可能因此结束运行, 根据实际情况选择 

有关 ```/affinity``` 参数, 帮助文档的提示

```
    AFFINITY    将处理器关联掩码指定为十六进制数字。
                进程被限制在这些处理器上运行。

                将 /AFFINITY 和 /NODE 结合使用时，会对关联掩码
                进行不同的解释。指定关联掩码，以便将零位作为起始位置(就如将 NUMA
                节点的处理器掩码向右移位一样)。
                进程被限制在指定关联掩码和 NUMA 节点之间的
                那些通用处理器上运行。
                如果没有通用处理器，则进程被限制在
                指定的 NUMA 节点上运行。
```
