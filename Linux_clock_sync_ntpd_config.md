#### ntpdate等"跳变式"修正时间的负面影响
使用ntpdate命令同步,存在的问题是如果时间偏差过大,一次性修正过猛,会对应用产生不可接受的影响  
关于此问题更详细的描述  
http://www.cnblogs.com/liuyou/archive/2012/07/29/2614330.html  

#### 对NTP服务端的配置  
https://my.oschina.net/myaniu/blog/182959  
http://blog.163.com/little_yang@126/blog/static/2317559620091019104019991/  

对配置的解析也比较详细  
http://blog.csdn.net/wzyzzu/article/details/46515129  

配置样例  
![](/images/EvFZq5d9XY082ZJluBiS1Eb5UAqaXp7r.png)


#### 指定日志位置
用
```
logfile /path/to/xxx.log
```  
进行定义, 日志内容如下  
![](/images/EvFZq5d9XYiszylR4DJpQNtvLXwOKnEe.jpg)

#### 层的概念
这些问题主要涉及到NTP的层（stratum）的概念，顶层是1，值为0时表示层数不明，层的值是累加的，比如NTP授时方向是A-〉B-〉C，假设A的stratum值是3，那么B从A获取到时间，B的stratum置为4，C从B获取到时间，C的值被置为5。一般只有整个NTP系统最顶层的服务器stratum才设为1。  
NTP同步的方向是从stratum值较小的节点向较大的节点传播，如果某个NTP客户端接收到stratum比自己还要大，那么NTP客户端认为自己的时间比接受到的时间更为精确，不会进行时间的更新。  
对于大部分NTP软件系统来说，服务启动后，stratum值初始是0，一旦NTP服务获取到了时间，NTP层次就设置为上级服务器stratum+1。对于具备卫星时钟、原子钟的专业NTP设备，一般stratum值初始是1。  

#### NTPD的运行过程
NTPD启动后，stratum值初始是0，此时NTPD接收到NTP请求，回复stratum字段为0的NTP包，客户端接收后，发现stratum字段无效，拒绝更新时间，造成时间更新失败。  
几分钟后，NTPD从上级服务器获取到了更新，设置了正确的stratum，回复stratum字段为n+1的NTP包，客户端接收后，确认stratum有效，成功进行时间更新。  
在NTPD上级服务器不可用的情况下，NTPD将本机时钟服务模拟为一个上级NTP服务器，地址使用环回127.127.1.0，服务启动几分钟后，NTPD从127.127.1.0更新了时钟，设置了有效的stratum，客户端接收后，成功进行时间更新。  

#### 关于排错
http://www.tuicool.com/articles/Iv2QNf  
在使用 ntpq -p 查询的过程中，出现如下的 error log:  
```
# ntpq -p 
localhost: timed out, nothing received 
***Request timed out 
```
原因很简单，ntpd 需要有 loopback 的参与，而默认是拒绝所有，将 loopback 放行就好了: 
```
restrict 127.0.0.1
```
补充:  
同样的,ipv6的环回地址同样可能需要添加进配置文件,否则在启用了ipv6的机器上也可能ntpq -p看不到上级服务器的信息,在suse上就是如此
```
restrict -6 ::1
```

#### NTP版本升级
编译安装, 下载地址  
http://www.ntp.org/downloads.html
ntp的软件包编译安装本身不涉及太多判断要处理, 只是编译参数的选择, 以及原有配置文件的备份工作可能需要涉及

我自己所使用的编译参数
```
./configure \
--prefix=/usr/local/ntp \
--bindir=/usr/sbin \
--sysconfdir=/etc \
--enable-linuxcaps \
--with-lineeditlibs=readline \
--docdir=/usr/share/doc/${ntp_version} \
--with-openssl-incdir=/usr/local/openssl/include \
--enable-all-clocks \
--enable-parse-clocks \
--disable-ipv6 \
--without-ntpsnmpd \
--enable-clockctl

make -j 4 && make install -j 4
```

#### NTP服务的解析得较深入的文章
http://www.happyworld.net.cn/post/6.html  
以下摘抄文中部分内容,原文后面还有几种时间偏差范围的对比测试  

ntpdate就是执行该命令的时候就将客户端的时钟与服务器端的时钟做下同步，不管差异多大，都是一次调整到位。  
而ntpd服务的方式，又有两种策略，一种是平滑、缓慢的渐进式调整（adjusts the clock in small steps所谓的微调）；一种是步进式调整（跳跃式调整）。两种策略的区别就在于，微调方式在启动NTP服务时加了个“-X”的参数，而默认的是不加“-X”参数。  
假如使用了-x选项，那么ntpd只做微调，不跳跃调整时间，但是要注意，-x参数的负作用：当时钟差大的时候，同步时间将花费很长的时间。-x也有一个阈值，就是600s，当系统时钟与标准时间差距大于600s时，ntpd会使用较大“步进值”的方式来调整时间，将时钟“步进”调整到正确时间。  
假如不使用-x选项，那么ntpd在时钟差距小于128ms时，使用微调方式调整时间，当时差大于128ms时，使用“跳跃”式调整。  
这两种方式都会在本地时钟与远端的NTP服务器时钟相差大于1000s时，ntpd会停止工作。在启动NTP时加了参数“-g”就可以忽略1000S的问题。  
 
以下是man ntpd里关于加参数“-X”的描述：  
-X  
Normally, the time is slewed if the offset is less than the step threshold, which is 128 ms by default, and stepped if above the  threshold.  This option  sets the threshold to 600 s, which is well within the accuracy window to set the clock manually. Note: Since the slew rate of typical Unix kernels is limited to 0.5 ms/s, each second of adjustment requires an amortization interval of  2000 s. Thus, an adjustment as much as 600 s  will take  almost  14  days to complete. This option can be used with the -g and -q options. See the tinker command for other options. Note: The kernel time discipline is disabled with this option.

![](/images/EvFZq5d9XYtP16m50yED9s83lMO4VwcS.png)

<font color="#660000">只有对于跳跃式的校正时间，系统日志才会记录。</font><br />  


#### 同步系统时间同时同步硬件时钟
https://blog.51cto.com/xjsunjie/1895760
![](/images/JN0x4dPk9pu34jaxqbCgcl710HoUiQMB.png)  
在/etc/sysconfig/ntpd文件中，添加  
```
SYNC_HWCLOCK=yes  
OPTIONS="-x -u ntp:ntp -p /var/run/ntpd.pid -g"
```

