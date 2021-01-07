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
