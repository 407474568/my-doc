### 【本机性能类】  
<br/>  
https://www.ibm.com/support/knowledgecenter/zh/SSEPGG_10.5.0/com.ibm.db2.luw.qb.server.doc/doc/t0008238.html  
:  ipcs -l 可以查看以下两组参数的当前值, 各种数据库的安装程序可能会自动以公式计算并修改sysctl.conf 文件以设置下列值  
<br/>  
:  /proc/sys/kernel/shmmax  
:  该文件表示内核所允许的最大共享内存段的大小（bytes）。  
:  缺省设置：33554432  
:  建议设置：物理内存 * 50%  
:  实际可用最大共享内存段大小=shmmax * 98%，其中大约2%用于共享内存结构。  
:  可以通过设置shmmax，然后执行ipcs -l来验证。  
<br/>  
:  /proc/sys/kernel/shmall  
:  该文件表示在任何给定时刻，系统上可以使用的共享内存的总量（bytes）。  
:  缺省设置：2097152  
<br/>  
kernel.msgmnb = 65536  
kernel.msgmax = 65536  
:  设置最大内存共享段大小bytes  
kernel.shmmax = 68719476736  
kernel.shmall = 4294967296  
<br/>  
<br/>  
:  /proc/sys/fs/file-max  
:  This file defines a system-wide limit on the number of open files for all processes. (See also setrlimit(2), which can be used by a process to set the per-process limit, RLIMIT_NOFILE, on the number of files it may open.) If you get lots of error messages about running out of file handles, try increasing this value  
:  即file-max是设置 系统所有进程一共可以打开的文件数量 。同时一些程序可以通过setrlimit调用，设置每个进程的限制。如果得到大量使用完文件句柄的错误信息，是应该增加这个值。也就是说，这项参数是系统级别的。  
fs.file-max = 819200  
<br/>  
<br/>  
:  /proc/sys/net/core/netdev_max_backlog  
:  进入包的最大设备队列.默认是1000,对重负载服务器而言,该值太低,可调整到16384/32768/65535  
:  该文件表示在每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目。  
:  进入包的最大设备队列.默认是1000,对重负载服务器而言,该值太低,可调整到16384.  
net.core.netdev_max_backlog = 32768  
<br/>  
<br/>  
:  listen()的默认参数,挂起请求的最大数量.默认是128.对繁忙的服务器,增加该值有助于网络性能.可调整到8192/16384/32768  
net.core.somaxconn = 16384  
<br/>  
<br/>  
:  /proc/sys/net/core/optmem_max  
:  每个socket buffer的最大补助缓存大小,默认10K(10240),也可调整到20k(20480),但建议保留  
net.core.optmem_max = 10240  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_wmem  
:  TCP写buffer,可参考的优化值:873200/1746400/3492800/6985600  
:  该文件包含3个整数值，分别是：min，default，max  
:  Min：为TCP socket预留用于发送缓冲的内存最小值。每个TCP socket都可以使用它。  
:  Default：为TCP socket预留用于发送缓冲的内存数量，默认情况下该值会影响其它协议使用的net.core.wmem中default的 值，一般要低于net.core.wmem中default的值。  
:  Max：为TCP socket预留用于发送缓冲的内存最大值。该值不会影响net.core.wmem_max，今天选择参数SO_SNDBUF则不受该值影响。默认值为 128K。  
:  缺省设置：4096 16384 131072  
:  建议设置：873200 1746400 3492800  
net.ipv4.tcp_wmem = 873200 1746400 3492800  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_rmem  
:  TCP读buffer,可参考的优化值:873200/1746400/3492800/6985600  
:  该文件包含3个整数值，分别是：min，default，max  
:  Min：为TCP socket预留用于接收缓冲的内存数量，即使在内存出现紧张情况下TCP socket都至少会有这么多数量的内存用于接收缓冲。  
:  Default：为TCP socket预留用于接收缓冲的内存数量，默认情况下该值影响其它协议使用的 net.core.wmem中default的 值。该值决定了在tcp_adv_win_scale、tcp_app_win和tcp_app_win的默认值情况下，TCP 窗口大小为65535。  
:  Max：为TCP socket预留用于接收缓冲的内存最大值。该值不会影响 net.core.wmem中max的值，今天选择参数 SO_SNDBUF则不受该值影响。  
:  缺省设置：4096 87380 174760  
:  建议设置：873200 1746400 3492800  
net.ipv4.tcp_rmem = 873200 1746400 3492800  
<br/>  
<br/>  
:  /proc/sys/net/core/wmem_default  
:  tcp 的内存是基于系统的内存自动计算的  
:  该文件指定了发送套接字缓冲区大小的缺省值（以字节为单位）。缺省设置：110592  
:  /proc/sys/net/core/wmem_max  
:  该文件指定了发送套接字缓冲区大小的最大值（以字节为单位）。缺省设置：131071  
:  缺省socket写buffer,可参考的优化值:873200/1746400/3492800  
net.core.wmem_default = 1746400  
:  最大socket写buffer,可参考的优化值:1746400/3492800/6985600  
net.core.wmem_max = 3492800  
:  缺省socket读buffer,可参考的优化值:873200/1746400/3492800  
net.core.rmem_default = 1746400  
:  最大socket读buffer,可参考的优化值:1746400/3492800/6985600  
net.core.rmem_max = 3492800  
<br/>  
<br/>  
<br/>  
<br/>  
<br/>  
<br/>  
### 【网络协议工作机制类--不可独自拍脑袋决定】  
<br/>  
:  决定检查过期多久邻居条目  
:  内核维护的arp表过于庞大, 发生抖动, 因此导致了这种情况,几个内核ARP参数:  
:  =================================  
:  gc_stale_time  
:  决定检查一次相邻层记录的有效性的周期。当相邻层记录失效时，将在给它发送数据前，再解析一次。缺省值是60秒。  
:  gc_thresh1  
:  存在于ARP高速缓存中的最少层数，如果少于这个数，垃圾收集器将不会运行。缺省值是128。  
:  gc_thresh2  
:  保存在 ARP 高速缓存中的最多的记录软限制。垃圾收集器在开始收集前，允许记录数超过这个数字 5 秒。缺省值是 512。  
:  gc_thresh3  
:  保存在 ARP 高速缓存中的最多记录的硬限制，一旦高速缓存中的数目高于此，垃圾收集器将马上运行。缺省值是1024。  
:  =================================  
:  比如arp -an|wc -l的结果是300左右, 那么应当调高gc_thresh各项数值,防止抖动的发生:  
:  echo "net.ipv4.neigh.default.gc_thresh1 = 512" >> sysctl.conf  
:  echo "net.ipv4.neigh.default.gc_thresh2 = 2048" >> sysctl.conf  
:  echo "net.ipv4.neigh.default.gc_thresh3 = 4096" >> sysctl.conf  
net.ipv4.neigh.default.gc_stale_time=120  
<br/>  
<br/>  
:  使用arp_announce / arp_ignore解决ARP映射问题  
:  https://www.jianshu.com/p/734640384fda  
:  arp_ignore和arp_announce参数都和ARP协议相关，主要用于控制系统返回arp响应和发送arp请求时的动作。这两个参数很重要，特别是在LVS的DR场景下，它们的配置直接影响到DR转发是否正常。  
:  首先看一下Linux内核文档中对于它们的描述：  
:  arp_ignore - INTEGER  
:  Define different modes for sending replies in response to  
:  received ARP requests that resolve local target IP addresses:  
:  0 - (default): reply for any local target IP address, configured on any interface  
:  1 - reply only if the target IP address is local address configured on the incoming interface  
:  2 - reply only if the target IP address is local address configured on the incoming interface and both with the sender's IP address are part from same subnet on this interface  
:  3 - do not reply for local addresses configured with scope host, only resolutions for global and link addresses are replied  
:  4-7 - reserved  
:  8 - do not reply for all local addresses The max value from conf/{all,interface}/arp_ignore is used when ARP request is received on the {interface}  
:  arp_ignore参数的作用是控制系统在收到外部的arp请求时，是否要返回arp响应。  
:  arp_ignore参数常用的取值主要有0，1，2，3~8较少用到：  
:  0：响应任意网卡上接收到的对本机IP地址的arp请求（包括环回网卡上的地址），而不管该目的IP是否在接收网卡上。  
:  1：只响应目的IP地址为接收网卡上的本地地址的arp请求。  
:  2：只响应目的IP地址为接收网卡上的本地地址的arp请求，并且arp请求的源IP必须和接收网卡同网段。  
:  3：如果ARP请求数据包所请求的IP地址对应的本地地址其作用域（scope）为主机（host），则不回应ARP响应数据包，如果作用域为全局（global）或链路（link），则回应ARP响应数据包。  
:  4~7：保留未使用  
:  8：不回应所有的arp请求  
<br/>  
<br/>  
:  避免放大攻击,如果你ping子网的子网地址，所有的机器都应该予以回应。这可能成为非常好用的拒绝服务攻击工具。设置为1来忽略这些子网广播消息。  
net.ipv4.icmp_echo_ignore_broadcasts = 1  
:  开启恶意icmp错误消息保护  
net.ipv4.icmp_ignore_bogus_error_responses = 1  
:  /proc/sys/net/ipv4/icmp_echo_ignore_all  
:  /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts  
:  该文件表示内核是否忽略所有的ICMP ECHO请求，或忽略广播和多播请求。  
:  0， 响应请求  
:  1， 忽略请求  
:  缺省设置：０  
:  建议设置：1  
<br/>  
<br/>  
:  arp_announce的作用是控制系统在对外发送arp请求时，如何选择arp请求数据包的源IP地址。（比如系统准备通过网卡发送一个数据包a，这时数据包a的源IP和目的IP一般都是知道的，而根据目的IP查询路由表，发送网卡也是确定的，故源MAC地址也是知道的，这时就差确定目的MAC地址了。而想要获取目的IP对应的目的MAC地址，就需要发送arp请求。arp请求的目的IP自然就是想要获取其MAC地址的IP，而arp请求的源IP是什么呢？ 可能第一反应会以为肯定是数据包a的源IP地址，但是这个也不是一定的，arp请求的源IP是可以选择的，控制这个地址如何选择就是arp_announce的作用）  
:  arp_announce参数常用的取值有0，1，2。  
:  0：允许使用任意网卡上的IP地址作为arp请求的源IP，通常就是使用数据包a的源IP。  
:  1：尽量避免使用不属于该发送网卡子网的本地地址作为发送arp请求的源IP地址。  
:  2：忽略IP数据包的源IP地址，选择该发送网卡上最合适的本地地址作为arp请求的源IP地址。  
:  sysctl.conf中包含all和eth/lo（具体网卡）的arp_ignore参数，取其中较大的值生效。  
net.ipv4.conf.default.arp_announce = 2  
net.ipv4.conf.all.arp_announce=2  
net.ipv4.conf.lo.arp_announce=2  
<br/>  
<br/>  
:  表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为0，表示关闭。  
:  14) /proc/sys/net/ipv4/tcp_syncookies  
:  该文件表示是否打开TCP同步标签(syncookie)，内核必须打开了 CONFIG_SYN_COOKIES项进行编译。 同步标签(syncookie)可以防止一个套接字在有过多试图连接到达时引起过载。  
:  缺省设置：0  
net.ipv4.tcp_syncookies = 1  
<br/>  
<br/>  
net.ipv4.tcp_tw_recycle = 1  
:  表示开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭。  
:  Enable fast recycling of TIME-WAIT sockets. Enabling this option is not recommended since this causes problems when working with NAT (Network Address Translation).  
:  启用TIME-WAIT状态sockets的快速回收，这个选项不推荐启用。在NAT(Network Address Translation)网络下，会导致大量的TCP连接建立错误。  
net.ipv4.tcp_tw_reuse = 1  
:  与其功能相似的参数net.ipv4.tcp_tw_reuse，手册里稍微有点描述，如下：  
:  tcp_tw_reuse (Boolean; default: disabled; since Linux 2.4.19/2.6)  
:  Allow to reuse TIME-WAIT sockets for new connections when it is safe from protocol viewpoint. It should not be changed without advice/request of technical experts.  
:  从协议设计上来看，对于TIME-WAIT状态的sockets重用到新的TCP连接上来说，是安全的。（用于客户端时的配置）表示开启重用,允许将TIME-WAIT sockets重新用于新的TCP连接,默认为0,表示关闭  
<br/>  
<br/>  
:  表示如果套接字由本端要求关闭，这个参数决定了它保持在FIN-WAIT-2状态的时间。  
:  /proc/sys/net/ipv4/tcp_fin_timeout  
:  对于本端断开的socket连接，TCP保持在FIN-WAIT-2状态的时间。对方可能  
:  会断开连接或一直不结束连接或不可预料的进程死亡。默认值为 60 秒。过去在2.2版本的内核中是 180 秒。您可以设置该值，但需要注意，如果您的机器为负载很重的web服务器，您可能要冒内存被大量无效数据报填满的风险，FIN-WAIT-2 sockets 的危险性低于 FIN-WAIT-1，因为它们最多只吃 1.5K的内存，但是它们存在时间更长。另外参考 tcp_max_orphans。  
:  缺省设置：60（秒）  
net.ipv4.tcp_fin_timeout = 30  
<br/>  
<br/>  
:  限制仅仅是为了防止简单的DoS 攻击  
:  /proc/sys/net/ipv4/tcp_max_orphans  
:  系统所能处理不属于任何进程的TCP sockets最大数量。假如超过这个数量，那么不属于任何进程的连接会被立即reset，并同时显示警告信息。之所以要设定这个限制，纯粹为了抵御那些简单的 DoS 攻击，千万不要依赖这个或是人为的降低这个限制。  
:  缺省设置：8192  
net.ipv4.tcp_max_orphans = 3276800  
<br/>  
<br/>  
:  表示用于向外连接的端口范围。缺省情况下过窄：32768到61000  
:  /proc/sys/net/ipv4/ip_local_port_range  
net.ipv4.ip_local_port_range = 10000 65535  
<br/>  
<br/>  
:  表示SYN队列的长度，RHEL 7.7 默认为128，加大队列长度为8192，可以容纳更多等待连接的网络连接数。  
:  /proc/sys/net/ipv4/tcp_max_syn_backlog  
:  进入SYN包的最大请求队列.默认1024.对重负载服务器,增加该值显然有好处.可调整到16384.  
:  对于那些依然还未获得客户端确认的连接请求，需要保存在队列中最大数目。对于超过 128Mb 内存的系统，默认值是 1024，低于 128Mb 的则为 128。如果服务器经常出现过载，可以尝试增加这个数字。警告！假如您将此值设为大于1024，最好修改 include/net/tcp.h 里面的 TCP_SYNQ_HSIZE，以保持  
:  TCP_SYNQ_HSIZE*16 0)或者bytes-bytes/2^(-tcp_adv_win_scale)(如果tcp_adv_win_scale 128Mb 32768-610000)则系统将忽略所有发送给自己的ICMP ECHO请求或那些广播地址的请求。  
:  缺省设置：1024  
net.ipv4.tcp_max_syn_backlog = 16384  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_timestamps  
:  该文件表示是否启用以一种比超时重发更精确的方法（请参阅 RFC 1323）来启用对 RTT 的计算；为了实现更好的性能应该启用这个选项。  
:  缺省设置：1  
net.ipv4.tcp_timestamps = 0  
<br/>  
<br/>  
:  表示系统同时保持TIME_WAIT套接字的最大数量，如果超过这个数字，TIME_WAIT套接字将立刻被清除并打印警告信息。默认为180000，建议减小，避免TIME_WAIT状态过多消耗整个服务器的资源，但也不能太小，跟你后端的处理速度有关，如果速度快可以小，速度慢则适当加大，否则高负载会有请求无法响应或非常慢。  
:  /proc/sys/net/ipv4/tcp_max_tw_buckets系统在同时所处理的最大timewait sockets 数目。如果超过此数的话，time-wait socket 会被立即砍除并且显示警告信息。之所以要设定这个限制，纯粹为了抵御那些简单的 DoS 攻击，千万不要人为的降低这个限制，不过，如果网络条件需要比默认值更多，则可以提高它(或许还要增加内存)。  
:  RHEL 7.7 缺省设置：8192  
net.ipv4.tcp_max_tw_buckets = 8192  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_sack  
:  该文件表示是否启用有选择的应答（Selective Acknowledgment），这可以通过有选择地应答乱序接收到的报文来提高性能（这样可以让发送者只发送丢失的报文段）；（对于广域网通信来说）这 个选项应该启用，但是这会增加对 CPU 的占用。  
:  缺省设置：1  
net.ipv4.tcp_sack = 1  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_window_scaling  
:  该文件表示设置tcp/ip会话的滑动窗口大小是否可变。参数值为布尔值，为1时表示可变，为0时表示不可变。tcp/ip通常使用的窗口最大可达到 65535 字节，对于高速网络，该值可能太小，这时候如果启用了该功能，可以使tcp/ip滑动窗口大小增大数个数量级，从而提高数据传输的能力。  
:  缺省设置：1  
net.ipv4.tcp_window_scaling = 1  
<br/>  
<br/>  
:  以下3个参数与TCP KeepAlive有关.单位为秒,默认值是  
:  tcp_keepalive_time = 7200  
:  tcp_keepalive_probes = 9  
:  tcp_keepalive_intvl = 75  
:  /proc/sys/net/ipv4/tcp_keepalive_intvl  
:  该文件表示发送TCP探测的频率，乘以tcp_keepalive_probes表示断开没有相应的TCP连接的时间。  
:  缺省设置：75（秒）  
:  意思是如果某个TCP连接在idle 2个小时后,内核才发起probe.如果probe 9次(每次75秒)不成功,内核才彻底放弃,认为该连接已失效.对服务器而言,显然上述值太大.可调整到:  
net.ipv4.tcp_keepalive_time = 1200  
net.ipv4.tcp_keepalive_probes = 3  
net.ipv4.tcp_keepalive_intvl = 30  
:  表示当keepalive起用的时候，TCP发送keepalive消息的频度。缺省是2小时，改为20分钟。  
<br/>  
<br/>  
#表示开启SYN Cookies,当出现SYN等待队列溢出时,启用cookies来处理,可防范少量SYN攻击,默认为0,表示关闭  
net.ipv4.tcp_syncookies = 1  
<br/>  
<br/>  
#表示开启TCP连接中TIME-WAIT sockets的快速回收,默认为0,表示关闭  
<br/>  
<br/>  
#其它的一些设置  
net.ipv4.route.gc_timeout = 100  
<br/>  
<br/>  
:  内核放弃建立连接之前发送SYNACK 包的数量  
:  /proc/sys/net/ipv4/tcp_syn_retries  
:  该文件表示本机向外发起TCP SYN连接超时重传的次数，不应该高于255；该值仅仅针对外出的连接，对于进来的连接由tcp_retries1控制。  
:  缺省设置：5  
net.ipv4.tcp_syn_retries = 2  
net.ipv4.tcp_synack_retries = 2  
<br/>  
:  /proc/sys/net/ipv4/tcp_retries1  
:  该文件表示放弃回应一个TCP连接请求前进行重传的次数。缺省设置：3  
net.ipv4.tcp_retries1 = 3  
<br/>  
:  该文件表示放弃在已经建立通讯状态下的一个TCP数据包前进行重传的次数。TCP失败重传次数,默认值15,意味着重传15次才彻底放弃.可减少到5,以尽早释放内核资源  
:  /proc/sys/net/ipv4/tcp_retries2  
:  缺省设置：15  
net.ipv4.tcp_retries2 = 5  
<br/>  
<br/>  
<br/>  
:  core文件名中添加pid作为扩展名---RHEL 7.7 默认值已是此值  
kernel.core_uses_pid = 1  
<br/>  
<br/>  
:  rp_filter参数用于控制系统是否开启对数据包源地址的校验---RHEL 7.7 默认值已是此值  
:  https://www.jianshu.com/p/717e6cd9d2bb  
:  首先看一下Linux内核文档documentation/networking/ip-sysctl.txt中的描述：  
:  rp_filter - INTEGER  
:  0 - No source validation.  
:  1 - Strict mode as defined in RFC3704 Strict Reverse Path Each incoming packet is tested against the FIB and if the interface is not the best reverse path the packet check will fail. By default failed packets are discarded.  
:  2 - Loose mode as defined in RFC3704 Loose Reverse Path Each incoming packet's source address is also tested against the FIBand if the source address is not reachable via any interface the packet check will fail.Current recommended practice in RFC3704 is to enable strict mode to prevent IP spoofing from DDos attacks. If using asymmetric routing or other complicated routing, then loose mode is recommended.The max value from conf/{all,interface}/rp_filter is used when doing source validation on the {interface}. Default value is 0. Note that some distributions enable itin startup scripts.即rp_filter参数有三个值，0、1、2，具体含义：  
:  0：不开启源地址校验。  
:  1：开启严格的反向路径校验。对每个进来的数据包，校验其反向路径是否是最佳路径。如果反向路径不是最佳路径，则直接丢弃该数据包。  
:  2：开启松散的反向路径校验。对每个进来的数据包，校验其源地址是否可达，即反向路径是否能通（通过任意网口），如果反向路径不同，则直接丢弃该数据包。  
net.ipv4.conf.all.rp_filter = 1  
net.ipv4.conf.default.rp_filter = 1  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_mem  
:  该文件包含3个整数值，分别是：low，pressure，high  
:  Low：当TCP使用了低于该值的内存页面数时，TCP不会考虑释放内存。  
:  Pressure：当TCP使用了超过该值的内存页面数量时，TCP试图稳定其内存使用，进入pressure模式，当内存消耗低于low值时则退出 pressure状态。  
:  High：允许所有tcp sockets用于排队缓冲数据报的页面量。  
:  一般情况下这些值是在系统启动时根据系统内存数量计算得到的。  
:  缺省设置：24576 32768 49152  
:  建议设置：78643200 104857600 157286400  
net.ipv4.tcp_mem = 94500000 915000000 927000000  
<br/>  
<br/>  
<br/>  
<br/>  
<br/>  
### 【路由类】  
<br/>  
<br/>  
:  开启路由转发--取决于是否充当路由器的功能需求  
net.ipv4.ip_forward = 1  
net.ipv4.conf.all.send_redirects = 1  
net.ipv4.conf.default.send_redirects = 1  
<br/>  
<br/>  
<br/>  
:  修改防火墙表大小，默认65536  
net.netfilter.nf_conntrack_max=655350  
net.netfilter.nf_conntrack_tcp_timeout_established=1200  
<br/>  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/conf/*/accept_redirects  
:  如果主机所在的网段中有两个路由器，你将其中一个设置成了缺省网关，但是该网关在收到你的ip包时发现该ip包必须经过另外一个路由器，这时这个路由器就会给你发一个所谓的“重定向”icmp包，告诉将ip包转发到另外一个路由器。参数值为布尔值，1表示接收这类重定向icmp 信息，0表示忽略。  
:  在充当路由器的linux主机上缺省值为0  
:  在一般的linux主机上缺省值为1  
:  建议将其改为0以消除安全性隐患  
net.ipv4.conf.all.accept_redirects = 0  
net.ipv4.conf.default.accept_redirects = 0  
net.ipv4.conf.all.secure_redirects = 0  
net.ipv4.conf.default.secure_redirects = 0  
<br/>  
<br/>  
<br/>  
:  处理无源路由的包, 或许某些路由器会启动这个设定值， 不过目前的设备很少使用到这种来源路由，你可以取消这个设定值---RHEL 7.7 默认值已是此值  
net.ipv4.conf.all.accept_source_route = 0  
net.ipv4.conf.default.accept_source_route = 0  
<br/>  
<br/>  
<br/>  
<br/>  
<br/>  
***************************************************************************************  
1)   Linux Proc文件系统，通过对Proc文件系统进行调整，达到性能优化的目的。  
2)   Linux性能诊断工具，介绍如何使用Linux自带的诊断工具进行性能诊断。  
<br/>  
<br/>  
二、/proc/sys/kernel/优化  
<br/>  
:  1) /proc/sys/kernel/ctrl-alt-del  
<br/>  
:  该文件有一个二进制值，该值控制系统在接收到ctrl+alt+delete按键组合时如何反应。这两个值分别是：  
:  零（0）值，表示捕获ctrl+alt+delete，并将其送至 init 程序；这将允许系统可以安全地关闭和重启，就好象输入shutdown命令一样。  
:  壹（1）值，表示不捕获ctrl+alt+delete，将执行非正常的关闭，就好象直接关闭电源一样。  
:  缺省设置：0  
:  建议设置：1，防止意外按下ctrl+alt+delete导致系统非正常重启。  
<br/>  
<br/>  
<br/>  
2) /proc/sys/kernel/msgmax  
该文件指定了从一个进程发送到另一个进程的消息的最大长度（bytes）。进程间的消息传递是在内核的内存中进行的，不会交换到磁盘上，所以如果增加该值，则将增加操作系统所使用的内存数量。  
缺省设置：8192  
<br/>  
<br/>  
4) /proc/sys/kernel/msgmni  
该文件指定消息队列标识的最大数目，即系统范围内最大多少个消息队列。  
缺省设置：16  
<br/>  
5) /proc/sys/kernel/panic  
该文件表示如果发生“内核严重错误（kernel panic）”，则内核在重新引导之前等待的时间（以秒为单位）。零（0）秒，表示在发生内核严重错误时将禁止自动重新引导。  
缺省设置：0  
<br/>  
<br/>  
<br/>  
8) /proc/sys/kernel/shmmni  
该文件表示用于整个系统的共享内存段的最大数目（个）。  
缺省设置：4096  
<br/>  
9) /proc/sys/kernel/threads-max  
该文件表示内核所能使用的线程的最大数目。  
缺省设置：2048  
<br/>  
10) /proc/sys/kernel/sem  
该文件用于控制内核信号量，信号量是System VIPC用于进程间通讯的方法。  
建议设置：250 32000 100 128  
第一列，表示每个信号集中的最大信号量数目。  
第二列，表示系统范围内的最大信号量总数目。  
第三列，表示每个信号发生时的最大系统操作数目。  
第四列，表示系统范围内的最大信号集总数目。  
所以，（第一列）*（第四列）=（第二列）  
以上设置，可以通过执行ipcs -l来验证。  
<br/>  
<br/>  
三、/proc/sys/vm/优化  
1) /proc/sys/vm/block_dump  
该文件表示是否打开Block Debug模式，用于记录所有的读写及Dirty Block写回动作。  
缺省设置：0，禁用Block Debug模式  
<br/>  
2) /proc/sys/vm/dirty_background_ratio  
该文件表示脏数据到达系统整体内存的百分比，此时触发pdflush进程把脏数据写回磁盘。  
缺省设置：10  
<br/>  
3) /proc/sys/vm/dirty_expire_centisecs  
该文件表示如果脏数据在内存中驻留时间超过该值，pdflush进程在下一次将把这些数据写回磁盘。  
缺省设置：3000（1/100秒）  
   
4) /proc/sys/vm/dirty_ratio  
该文件表示如果进程产生的脏数据到达系统整体内存的百分比，此时进程自行把脏数据写回磁盘。  
缺省设置：40  
<br/>  
5) /proc/sys/vm/dirty_writeback_centisecs  
该文件表示pdflush进程周期性间隔多久把脏数据写回磁盘。  
缺省设置：500（1/100秒）  
   
6) /proc/sys/vm/vfs_cache_pressure  
该文件表示内核回收用于directory和inode cache内存的倾向；缺省值100表示内核将根据pagecache和swapcache，把directory和inode cache保持在一个合理的百分比；降低该值低于100，将导致内核倾向于保留directory和inode cache；增加该值超过100，将导致内核倾向于回收directory和inode cache。  
缺省设置：100  
<br/>  
7) /proc/sys/vm/min_free_kbytes  
该文件表示强制Linux VM最低保留多少空闲内存（Kbytes）。  
缺省设置：724（512M物理内存）  
<br/>  
8) /proc/sys/vm/nr_pdflush_threads  
该文件表示当前正在运行的pdflush进程数量，在I/O负载高的情况下，内核会自动增加更多的pdflush进程。  
缺省设置：2（只读）  
<br/>  
9) /proc/sys/vm/overcommit_memory  
该文件指定了内核针对内存分配的策略，其值可以是0、1、2。  
0， 表示内核将检查是否有足够的可用内存供应用进程使用；如果有足够的可用内存，内存申请允许；否则，内存申请失败，并把错误返回给应用进程。  
1， 表示内核允许分配所有的物理内存，而不管当前的内存状态如何。  
2， 表示内核允许分配超过所有物理内存和交换空间总和的内存（参照overcommit_ratio）。  
缺省设置：0  
<br/>  
10) /proc/sys/vm/overcommit_ratio  
该文件表示，如果overcommit_memory=2，可以过载内存的百分比，通过以下公式来计算系统整体可用内存。  
系统可分配内存=交换空间+物理内存*overcommit_ratio/100  
缺省设置：50（%）  
<br/>  
11) /proc/sys/vm/page-cluster  
该文件表示在写一次到swap区的时候写入的页面数量，0表示1页，1表示2页，2表示4页。  
缺省设置：3（2的3次方，8页）  
<br/>  
12) /proc/sys/vm/swapiness  
该文件表示系统进行交换行为的程度，数值（0-100）越高，越可能发生磁盘交换。  
缺省设置：60  
<br/>  
13) legacy_va_layout  
该文件表示是否使用最新的32位共享内存mmap()系统调用，Linux支持的共享内存分配方式包括mmap()，Posix，System VIPC。  
0， 使用最新32位mmap()系统调用。  
1， 使用2.4内核提供的系统调用。  
缺省设置：0  
<br/>  
14) nr_hugepages  
该文件表示系统保留的hugetlb页数。  
<br/>  
15) hugetlb_shm_group  
该文件表示允许使用hugetlb页创建System VIPC共享内存段的系统组ID。  
<br/>  
四、/proc/sys/fs/优化  
1) /proc/sys/fs/file-max  
该文件指定了可以分配的文件句柄的最大数目。如果用户得到的错误消息声明由于打开文件数已经达到了最大值，从而他们不能打开更多文件，则可能需要增加该值。  
缺省设置：4096  
建议设置：65536  
<br/>  
2) /proc/sys/fs/file-nr  
该文件与 file-max 相关，它有三个值：  
已分配文件句柄的数目  
已使用文件句柄的数目  
文件句柄的最大数目  
该文件是只读的，仅用于显示信息。  
<br/>  
<br/>  
五、/proc/sys/net/core/优化  
该目录下的配置文件主要用来控制内核和网络层之间的交互行为。  
1） /proc/sys/net/core/message_burst  
写新的警告消息所需的时间（以 1/10 秒为单位）；在这个时间内系统接收到的其它警告消息会被丢弃。这用于防止某些企图用消息“淹没”系统的人所使用的拒绝服务（Denial of Service）攻击。  
缺省设置：50（5秒）  
   
2） /proc/sys/net/core/message_cost  
该文件表示写每个警告消息相关的成本值。该值越大，越有可能忽略警告消息。  
缺省设置：5  
<br/>  
<br/>  
5） /proc/sys/net/core/rmem_default  
该文件指定了接收套接字缓冲区大小的缺省值（以字节为单位）。  
缺省设置：110592  
<br/>  
6） /proc/sys/net/core/rmem_max  
该文件指定了接收套接字缓冲区大小的最大值（以字节为单位）。  
缺省设置：131071  
<br/>  
六、/proc/sys/net/ipv4/优化  
1) /proc/sys/net/ipv4/ip_forward  
该文件表示是否打开IP转发。  
0，禁止  
1，转发  
缺省设置：0  
<br/>  
2) /proc/sys/net/ipv4/ip_default_ttl  
该文件表示一个数据报的生存周期（Time To Live），即最多经过多少路由器。  
缺省设置：64  
增加该值会降低系统性能。  
   
3) /proc/sys/net/ipv4/ip_no_pmtu_disc  
该文件表示在全局范围内关闭路径MTU探测功能。  
缺省设置：0  
<br/>  
4) /proc/sys/net/ipv4/route/min_pmtu  
该文件表示最小路径MTU的大小。  
缺省设置：552  
<br/>  
5) /proc/sys/net/ipv4/route/mtu_expires  
该文件表示PMTU信息缓存多长时间（秒）。  
缺省设置：600（秒）  
<br/>  
6) /proc/sys/net/ipv4/route/min_adv_mss  
该文件表示最小的MSS（Maximum Segment Size）大小，取决于第一跳的路由器MTU。  
缺省设置：256（bytes）  
<br/>  
6.1 IP Fragmentation  
1) /proc/sys/net/ipv4/ipfrag_low_thresh/proc/sys/net/ipv4/ipfrag_low_thresh  
两个文件分别表示用于重组IP分段的内存分配最低值和最高值，一旦达到最高内存分配值，其它分段将被丢弃，直到达到最低内存分配值。  
缺省设置：196608（ipfrag_low_thresh）  
　　　　　262144（ipfrag_high_thresh）  
<br/>  
2) /proc/sys/net/ipv4/ipfrag_time  
该文件表示一个IP分段在内存中保留多少秒。  
缺省设置：30（秒）  
<br/>  
6.2 INET Peer Storage  
1) /proc/sys/net/ipv4/inet_peer_threshold  
INET对端存储器某个合适值，当超过该阀值条目将被丢弃。该阀值同样决定生存时间以及废物收集通过的时间间隔。条目越多，存活期越低，GC 间隔越短。  
缺省设置：65664  
<br/>  
2) /proc/sys/net/ipv4/inet_peer_minttl  
条目的最低存活期。在重组端必须要有足够的碎片(fragment)存活期。这个最低存活期必须保证缓冲池容积是否少于 inet_peer_threshold。该值以 jiffies为单位测量。  
缺省设置：120  
<br/>  
3) /proc/sys/net/ipv4/inet_peer_maxttl  
条目的最大存活期。在此期限到达之后，如果缓冲池没有耗尽压力的话(例如：缓冲池中的条目数目非常少)，不使用的条目将会超时。该值以 jiffies为单位测量。  
缺省设置：600  
<br/>  
4) /proc/sys/net/ipv4/inet_peer_gc_mintime  
废物收集(GC)通过的最短间隔。这个间隔会影响到缓冲池中内存的高压力。 该值以 jiffies为单位测量。  
缺省设置：10  
<br/>  
<br/>  
5) /proc/sys/net/ipv4/inet_peer_gc_maxtime  
废物收集(GC)通过的最大间隔，这个间隔会影响到缓冲池中内存的低压力。 该值以 jiffies为单位测量。  
缺省设置：120  
<br/>  
<br/>  
3) /proc/sys/net/ipv4/tcp_keepalive_time  
该文件表示从不再传送数据到向连接上发送保持连接信号之间所需的秒数。  
缺省设置：7200（2小时）  
<br/>  
<br/>  
7) /proc/sys/net/ipv4/tcp_orphan_retries  
在近端丢弃TCP连接之前，要进行多少次重试。默认值是 7 个，相当于 50秒–16分钟，视 RTO 而定。如果您的系统是负载很大的web服务器，那么也许需  
要降低该值，这类 sockets 可能会耗费大量的资源。另外参考tcp_max_orphans。  
<br/>  
<br/>  
13) /proc/sys/net/ipv4/tcp_abort_on_overflow  
当守护进程太忙而不能接受新的连接，就向对方发送reset消息，默认值是false。这意味着当溢出的原因是因为一个偶然的猝发，那么连接将恢复状态。只有在你确信守护进程真的不能完成连接请求时才打开该选项，该选项会影响客户的使用。  
缺省设置：0  
<br/>  
<br/>  
15) /proc/sys/net/ipv4/tcp_stdurg  
使用 TCP urg pointer 字段中的主机请求解释功能。大部份的主机都使用老旧的BSD解释，因此如果您在 Linux 打开它，或会导致不能和它们正确沟通。  
缺省设置：0  
<br/>  
<br/>  
20) /proc/sys/net/ipv4/tcp_fack  
该文件表示是否打开FACK拥塞避免和快速重传功能。  
缺省设置：1  
<br/>  
<br/>  
21) /proc/sys/net/ipv4/tcp_dsack  
该文件表示是否允许TCP发送“两个完全相同”的SACK。  
缺省设置：1  
<br/>  
<br/>  
22) /proc/sys/net/ipv4/tcp_ecn  
该文件表示是否打开TCP的直接拥塞通告功能。  
缺省设置：0  
<br/>  
<br/>  
23) /proc/sys/net/ipv4/tcp_reordering  
该文件表示TCP流中重排序的数据报最大数量。  
缺省设置：3  
   
24) /proc/sys/net/ipv4/tcp_retrans_collapse  
该文件表示对于某些有bug的打印机是否提供针对其bug的兼容性。  
缺省设置：1  
<br/>  
<br/>  
28) /proc/sys/net/ipv4/tcp_app_win  
该文件表示保留max(window/2^tcp_app_win, mss)数量的窗口由于应用缓冲。当为0时表示不需要缓冲。  
缺省设置：31  
<br/>  
29) /proc/sys/net/ipv4/tcp_adv_win_scale  
该文件表示计算缓冲开销bytes/2^tcp_adv_win_scale(如果tcp_adv_win_scale >; 0)或者bytes-bytes/2^(-tcp_adv_win_scale)(如果tcp_adv_win_scale <= 0）。    
缺省设置：2    
<br/>  
2) /proc/sys/net/ipv4/ip_nonlocal_bind  
该文件表示是否允许进程邦定到非本地地址。  
缺省设置：0  
<br/>  
3) /proc/sys/net/ipv4/ip_dynaddr  
该参数通常用于使用拨号连接的情况，可以使系统动能够立即改变ip包的源地址为该ip地址，同时中断原有的tcp对话而用新地址重新发出一个syn请求 包，开始新的tcp对话。在使用ip欺骗时，该参数可以立即改变伪装地址为新的ip地址。该文件表示是否允许动态地址，如果该值非0，表示允许；如果该值 大于1，内核将通过log记录动态地址重写信息。  
缺省设置：0  
<br/>  
5) /proc/sys/net/ipv4/icmp_ratelimit  
<br/>  
6) /proc/sys/net/ipv4/icmp_ratemask  
<br/>  
7) /proc/sys/net/ipv4/icmp_ignore_bogus_error_reponses  
某些路由器违背RFC1122标准，其对广播帧发送伪造的响应来应答。这种违背行为通常会被以告警的方式记录在系统日志中。如果该选项设置为True，内核不会记录这种警告信息。  
缺省设置：0  
<br/>  
8) /proc/sys/net/ipv4/igmp_max_memberships  
该文件表示多播组中的最大成员数量。  
缺省设置：20  
   
6.5 Other Configuration  
<br/>  
<br/>  
<br/>  
2) /proc/sys/net/ipv4/*/accept_source_route  
是否接受含有源路由信息的ip包。参数值为布尔值，1表示接受，0表示不接受。在充当网关的linux主机上缺省值为1，在一般的linux主机上缺省值为0。从安全性角度出发，建议关闭该功能。  
   
3) /proc/sys/net/ipv4/*/secure_redirects  
其实所谓的“安全重定向”就是只接受来自网关的“重定向”icmp包。该参数就是用来设置“安全重定向”功能的。  
参数值为布尔值，1表示启用，0表示禁止，  
缺省值为启用。  
<br/>  
4) /proc/sys/net/ipv4/*/proxy_arp  
设置是否对网络上的arp包进行中继。参数值为布尔值，1表示中继，0表示忽略，  
缺省值为0。该参数通常只对充当路由器的linux主机有用。  
