#### tcpdump参数介绍:

http://www.ha97.com/4550.html

https://blog.51cto.com/victor1980/701764

示例  
```
tcpdump -i any src host 192.168.10.2 and dst host 192.168.10.3 and dst port 22  -e -v -tttt -n -nn -c 10 -S
```

选用的参数含义介绍:
-c     在收到指定的数量的分组后，tcpdump就会停止。  
-e     在输出行打印出数据链路层的头部信息。  
-i      指定监听的网络接口。  
-n     不把网络地址转换成名字。  
-nn   不进行端口名称的转换。  
-v     输出一个稍微详细的信息，例如在ip包中可以包括ttl和服务类型的信息  
-tttt   在每一行中输出由date处理的默认格式的时间戳。  
-S     输出tcp窗口序号的绝对值而不是相对值 (man手册: Print absolute, rather than relative, TCP sequence numbers.)  

其中:  
tcpdump中的 源 / 目标 地址, 源 / 目标 端口, 协议 使用与 / 或 / 非 关键词连接, 关于tcpdump的表达式介绍如下

##### 排除特定地址

当我可能需要排除某个地址时

```
[root@CQ-KVM-01 ~]# tcpdump -i any dst host 192.168.2.63 and src host \!192.168.2.60 and dst port 22  -e -v -tttt -n -nn -S
dropped privs to tcpdump
tcpdump: listening on any, link-type LINUX_SLL (Linux cooked v1), capture size 262144 bytes
2024-07-26 10:34:50.935994  In 50:0f:f5:6f:02:90 ethertype IPv4 (0x0800), length 68: (tos 0x68, ttl 120, id 59161, offset 0, flags [DF], proto TCP (6), length 52)
    123.147.247.146.49520 > 192.168.2.63.22: Flags [S], cksum 0xf352 (correct), seq 394818068, win 64240, options [mss 1360,nop,wscale 8,nop,nop,sackOK], length 0
2024-07-26 10:34:51.938026  In 50:0f:f5:6f:02:90 ethertype IPv4 (0x0800), length 68: (tos 0x68, ttl 120, id 59166, offset 0, flags [DF], proto TCP (6), length 52)
    123.147.247.146.49520 > 192.168.2.63.22: Flags [S], cksum 0xf352 (correct), seq 394818068, win 64240, options [mss 1360,nop,wscale 8,nop,nop,sackOK], length 0
2024-07-26 10:34:53.955759  In 50:0f:f5:6f:02:90 ethertype IPv4 (0x0800), length 68: (tos 0x68, ttl 120, id 59204, offset 0, flags [DF], proto TCP (6), length 52)
    123.147.247.146.49520 > 192.168.2.63.22: Flags [S], cksum 0xf352 (correct), seq 394818068, win 64240, options [mss 1360,nop,wscale 8,nop,nop,sackOK], length 0
^C
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

排除的语法, 在 ```tcpdump``` 里是 ```!```  
由于 ```!``` 在shell里是内置变量, 另有含义  
所以在 shell 环境下执行还需要加上转义符, 即 ```\!```

#### tcpdump的表达式介绍  

表达式是一个正则表达式，tcpdump利用它作为过滤报文的条件，如果一个报文满足表 达式的条件，则这个报文将会被捕获。如果没有给出任何条件，则网络上所有的信息包 将会被截获。  
在表达式中一般如下几种类型的关键字：  
第一种是关于类型的关键字，主要包括host，net，port，例如 host 210.27.48.2， 指明 210.27.48.2是一台主机，net 202.0.0.0指明202.0.0.0是一个网络地址，port 23 指明端口号是23。如果没有指定类型，缺省的类型是host。  
第二种是确定传输方向的关键字，主要包括src，dst，dst or src，dst and src， 这些关键字指明了传输的方向。举例说明，src 210.27.48.2 ，指明ip包中源地址是 210.27.48.2 ， dst net 202.0.0.0 指明目的网络地址是202.0.0.0。如果没有指明 方向关键字，则缺省是src or dst关键字。  
第三种是协议的关键字，主要包括fddi，ip，arp，rarp，tcp，udp等类型。Fddi指明是在FDDI (分布式光纤数据接口网络)上的特定的网络协议，实际上它是”ether”的别名，fddi和ether 具有类似的源地址和目的地址，所以可以将fddi协议包当作ether的包进行处理和分析。 其他的几个关键字就是指明了监听的包的协议内容。如果没有指定任何协议，则tcpdump 将会 监听所有协议的信息包。  
除了这三种类型的关键字之外，其他重要的关键字如下：gateway， broadcast，less， greater， 还有三种逻辑运算，取非运算是 ‘not ‘ ‘! ‘， 与运算是’and’，’&&’;或运算是’or’ ，’&#124;&#124;’； 这些关键字可以组合起来构成强大的组合条件来满足人们的需要。

#### tcpdump的输出  

将tcpdump输出到文件(输出到文件时，不会同时输出到屏幕)：  
有两种选择：输出为二进制文件，输出为文本文件。

二进制文件：tcpdump -w <binaryfilename>  
    例如：tcpdump -w dump1.bin

文本文件：  tcpdump > <textfilename>  
    例如：tcpdump >dump1.txt

查看tcpdump生成的文件，加上-r参数：  
    tcpdump -r <filename>    
    例如：tcpdump -r dump1.bin  
 
应用实例  
https://blog.csdn.net/cbbbc/article/details/48897367  例子不错,字小得发指  
https://arthurchiao.github.io/blog/tcpdump-practice-zh/ 

#### Wireshark

下载地址和UserGuide  
https://www.wireshark.org/download.html  
https://www.wireshark.org/docs/wsug_html/#ChUseFileMenuSection  

另外比较有意思的应用  
https://blog.csdn.net/lvshaorong/article/details/51382911  
https://4hou.win/wordpress/?p=14421  

Wireshark更改时间显示格式
将显示时间更改为"年-月-日 时:分:秒.微秒"---absoulute date ,它称之为绝对时间. 另外还可以选择UTC标准时间

![](/images/b6be90b3gy1gj527oy4wmj210b0mjtb2.jpg)

![](/images/b6be90b3gy1gj527rzy96j20v308ywhm.jpg)

将显示时间更改为相对时间, 时间值是从第1个被捕获的包算起的间隔时间

![](/images/b6be90b3gy1gj527ximhmj210b0mjwgc.jpg)

![](/images/b6be90b3gy1gj52806u52j20t409e40h.jpg)

#### 过滤显示
https://blog.csdn.net/lixiangminghate/article/details/81663628 

与在tcpdump中等价的过滤 源 /目标 主机地址和端口的使用  
同样使用 与 / 或 / 非 运算符  
以下示例包含 非 运算符的使用---成对小括号  
![](/images/b6be90b3gy1gj52832u1uj212g0660ua.jpg)

#### 不等于的用法示例

https://www.cnblogs.com/jiujuan/p/9017495.html

示例: 查看目标端口为22, 但IP地址不为XXX的数据包

```
tcpdump -i any ip host \!192.168.2.64 and dst port 22 -e -v -tttt -n -nn -S
```

在```tcpdump```中是用```!```表示"非", 不过又因为是在shell环境下, ```!```有其自身表达的含义, 所以需要反斜杠转义
