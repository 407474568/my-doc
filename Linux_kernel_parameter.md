### �����������ࡿ  
<br/>  
https://www.ibm.com/support/knowledgecenter/zh/SSEPGG_10.5.0/com.ibm.db2.luw.qb.server.doc/doc/t0008238.html  
:  ipcs -l ���Բ鿴������������ĵ�ǰֵ, �������ݿ�İ�װ������ܻ��Զ��Թ�ʽ���㲢�޸�sysctl.conf �ļ�����������ֵ  
<br/>  
:  /proc/sys/kernel/shmmax  
:  ���ļ���ʾ�ں��������������ڴ�εĴ�С��bytes����  
:  ȱʡ���ã�33554432  
:  �������ã������ڴ� * 50%  
:  ʵ�ʿ���������ڴ�δ�С=shmmax * 98%�����д�Լ2%���ڹ����ڴ�ṹ��  
:  ����ͨ������shmmax��Ȼ��ִ��ipcs -l����֤��  
<br/>  
:  /proc/sys/kernel/shmall  
:  ���ļ���ʾ���κθ���ʱ�̣�ϵͳ�Ͽ���ʹ�õĹ����ڴ��������bytes����  
:  ȱʡ���ã�2097152  
<br/>  
kernel.msgmnb = 65536  
kernel.msgmax = 65536  
:  ��������ڴ湲��δ�Сbytes  
kernel.shmmax = 68719476736  
kernel.shmall = 4294967296  
<br/>  
<br/>  
:  /proc/sys/fs/file-max  
:  This file defines a system-wide limit on the number of open files for all processes. (See also setrlimit(2), which can be used by a process to set the per-process limit, RLIMIT_NOFILE, on the number of files it may open.) If you get lots of error messages about running out of file handles, try increasing this value  
:  ��file-max������ ϵͳ���н���һ�����Դ򿪵��ļ����� ��ͬʱһЩ�������ͨ��setrlimit���ã�����ÿ�����̵����ơ�����õ�����ʹ�����ļ�����Ĵ�����Ϣ����Ӧ���������ֵ��Ҳ����˵�����������ϵͳ����ġ�  
fs.file-max = 819200  
<br/>  
<br/>  
:  /proc/sys/net/core/netdev_max_backlog  
:  �����������豸����.Ĭ����1000,���ظ��ط���������,��ֵ̫��,�ɵ�����16384/32768/65535  
:  ���ļ���ʾ��ÿ������ӿڽ������ݰ������ʱ��ں˴�����Щ�������ʿ�ʱ�������͵����е����ݰ��������Ŀ��  
:  �����������豸����.Ĭ����1000,���ظ��ط���������,��ֵ̫��,�ɵ�����16384.  
net.core.netdev_max_backlog = 32768  
<br/>  
<br/>  
:  listen()��Ĭ�ϲ���,����������������.Ĭ����128.�Է�æ�ķ�����,���Ӹ�ֵ��������������.�ɵ�����8192/16384/32768  
net.core.somaxconn = 16384  
<br/>  
<br/>  
:  /proc/sys/net/core/optmem_max  
:  ÿ��socket buffer������������С,Ĭ��10K(10240),Ҳ�ɵ�����20k(20480),�����鱣��  
net.core.optmem_max = 10240  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_wmem  
:  TCPдbuffer,�ɲο����Ż�ֵ:873200/1746400/3492800/6985600  
:  ���ļ�����3������ֵ���ֱ��ǣ�min��default��max  
:  Min��ΪTCP socketԤ�����ڷ��ͻ�����ڴ���Сֵ��ÿ��TCP socket������ʹ������  
:  Default��ΪTCP socketԤ�����ڷ��ͻ�����ڴ�������Ĭ������¸�ֵ��Ӱ������Э��ʹ�õ�net.core.wmem��default�� ֵ��һ��Ҫ����net.core.wmem��default��ֵ��  
:  Max��ΪTCP socketԤ�����ڷ��ͻ�����ڴ����ֵ����ֵ����Ӱ��net.core.wmem_max������ѡ�����SO_SNDBUF���ܸ�ֵӰ�졣Ĭ��ֵΪ 128K��  
:  ȱʡ���ã�4096 16384 131072  
:  �������ã�873200 1746400 3492800  
net.ipv4.tcp_wmem = 873200 1746400 3492800  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_rmem  
:  TCP��buffer,�ɲο����Ż�ֵ:873200/1746400/3492800/6985600  
:  ���ļ�����3������ֵ���ֱ��ǣ�min��default��max  
:  Min��ΪTCP socketԤ�����ڽ��ջ�����ڴ���������ʹ���ڴ���ֽ��������TCP socket�����ٻ�����ô���������ڴ����ڽ��ջ��塣  
:  Default��ΪTCP socketԤ�����ڽ��ջ�����ڴ�������Ĭ������¸�ֵӰ������Э��ʹ�õ� net.core.wmem��default�� ֵ����ֵ��������tcp_adv_win_scale��tcp_app_win��tcp_app_win��Ĭ��ֵ����£�TCP ���ڴ�СΪ65535��  
:  Max��ΪTCP socketԤ�����ڽ��ջ�����ڴ����ֵ����ֵ����Ӱ�� net.core.wmem��max��ֵ������ѡ����� SO_SNDBUF���ܸ�ֵӰ�졣  
:  ȱʡ���ã�4096 87380 174760  
:  �������ã�873200 1746400 3492800  
net.ipv4.tcp_rmem = 873200 1746400 3492800  
<br/>  
<br/>  
:  /proc/sys/net/core/wmem_default  
:  tcp ���ڴ��ǻ���ϵͳ���ڴ��Զ������  
:  ���ļ�ָ���˷����׽��ֻ�������С��ȱʡֵ�����ֽ�Ϊ��λ����ȱʡ���ã�110592  
:  /proc/sys/net/core/wmem_max  
:  ���ļ�ָ���˷����׽��ֻ�������С�����ֵ�����ֽ�Ϊ��λ����ȱʡ���ã�131071  
:  ȱʡsocketдbuffer,�ɲο����Ż�ֵ:873200/1746400/3492800  
net.core.wmem_default = 1746400  
:  ���socketдbuffer,�ɲο����Ż�ֵ:1746400/3492800/6985600  
net.core.wmem_max = 3492800  
:  ȱʡsocket��buffer,�ɲο����Ż�ֵ:873200/1746400/3492800  
net.core.rmem_default = 1746400  
:  ���socket��buffer,�ɲο����Ż�ֵ:1746400/3492800/6985600  
net.core.rmem_max = 3492800  
<br/>  
<br/>  
<br/>  
<br/>  
<br/>  
<br/>  
### ������Э�鹤��������--���ɶ������Դ�������  
<br/>  
:  ���������ڶ���ھ���Ŀ  
:  �ں�ά����arp������Ӵ�, ��������, ��˵������������,�����ں�ARP����:  
:  =================================  
:  gc_stale_time  
:  �������һ�����ڲ��¼����Ч�Ե����ڡ������ڲ��¼ʧЧʱ�����ڸ�����������ǰ���ٽ���һ�Ρ�ȱʡֵ��60�롣  
:  gc_thresh1  
:  ������ARP���ٻ����е����ٲ������������������������ռ������������С�ȱʡֵ��128��  
:  gc_thresh2  
:  ������ ARP ���ٻ����е����ļ�¼�����ơ������ռ����ڿ�ʼ�ռ�ǰ�������¼������������� 5 �롣ȱʡֵ�� 512��  
:  gc_thresh3  
:  ������ ARP ���ٻ����е�����¼��Ӳ���ƣ�һ�����ٻ����е���Ŀ���ڴˣ������ռ������������С�ȱʡֵ��1024��  
:  =================================  
:  ����arp -an|wc -l�Ľ����300����, ��ôӦ������gc_thresh������ֵ,��ֹ�����ķ���:  
:  echo "net.ipv4.neigh.default.gc_thresh1 = 512" >> sysctl.conf  
:  echo "net.ipv4.neigh.default.gc_thresh2 = 2048" >> sysctl.conf  
:  echo "net.ipv4.neigh.default.gc_thresh3 = 4096" >> sysctl.conf  
net.ipv4.neigh.default.gc_stale_time=120  
<br/>  
<br/>  
:  ʹ��arp_announce / arp_ignore���ARPӳ������  
:  https://www.jianshu.com/p/734640384fda  
:  arp_ignore��arp_announce��������ARPЭ����أ���Ҫ���ڿ���ϵͳ����arp��Ӧ�ͷ���arp����ʱ�Ķ�������������������Ҫ���ر�����LVS��DR�����£����ǵ�����ֱ��Ӱ�쵽DRת���Ƿ�������  
:  ���ȿ�һ��Linux�ں��ĵ��ж������ǵ�������  
:  arp_ignore - INTEGER  
:  Define different modes for sending replies in response to  
:  received ARP requests that resolve local target IP addresses:  
:  0 - (default): reply for any local target IP address, configured on any interface  
:  1 - reply only if the target IP address is local address configured on the incoming interface  
:  2 - reply only if the target IP address is local address configured on the incoming interface and both with the sender's IP address are part from same subnet on this interface  
:  3 - do not reply for local addresses configured with scope host, only resolutions for global and link addresses are replied  
:  4-7 - reserved  
:  8 - do not reply for all local addresses The max value from conf/{all,interface}/arp_ignore is used when ARP request is received on the {interface}  
:  arp_ignore�����������ǿ���ϵͳ���յ��ⲿ��arp����ʱ���Ƿ�Ҫ����arp��Ӧ��  
:  arp_ignore�������õ�ȡֵ��Ҫ��0��1��2��3~8�����õ���  
:  0����Ӧ���������Ͻ��յ��ĶԱ���IP��ַ��arp���󣨰������������ϵĵ�ַ���������ܸ�Ŀ��IP�Ƿ��ڽ��������ϡ�  
:  1��ֻ��ӦĿ��IP��ַΪ���������ϵı��ص�ַ��arp����  
:  2��ֻ��ӦĿ��IP��ַΪ���������ϵı��ص�ַ��arp���󣬲���arp�����ԴIP����ͽ�������ͬ���Ρ�  
:  3�����ARP�������ݰ��������IP��ַ��Ӧ�ı��ص�ַ��������scope��Ϊ������host�����򲻻�ӦARP��Ӧ���ݰ������������Ϊȫ�֣�global������·��link�������ӦARP��Ӧ���ݰ���  
:  4~7������δʹ��  
:  8������Ӧ���е�arp����  
<br/>  
<br/>  
:  ����Ŵ󹥻�,�����ping������������ַ�����еĻ�����Ӧ�����Ի�Ӧ������ܳ�Ϊ�ǳ����õľܾ����񹥻����ߡ�����Ϊ1��������Щ�����㲥��Ϣ��  
net.ipv4.icmp_echo_ignore_broadcasts = 1  
:  ��������icmp������Ϣ����  
net.ipv4.icmp_ignore_bogus_error_responses = 1  
:  /proc/sys/net/ipv4/icmp_echo_ignore_all  
:  /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts  
:  ���ļ���ʾ�ں��Ƿ�������е�ICMP ECHO���󣬻���Թ㲥�Ͷಥ����  
:  0�� ��Ӧ����  
:  1�� ��������  
:  ȱʡ���ã���  
:  �������ã�1  
<br/>  
<br/>  
:  arp_announce�������ǿ���ϵͳ�ڶ��ⷢ��arp����ʱ�����ѡ��arp�������ݰ���ԴIP��ַ��������ϵͳ׼��ͨ����������һ�����ݰ�a����ʱ���ݰ�a��ԴIP��Ŀ��IPһ�㶼��֪���ģ�������Ŀ��IP��ѯ·�ɱ���������Ҳ��ȷ���ģ���ԴMAC��ַҲ��֪���ģ���ʱ�Ͳ�ȷ��Ŀ��MAC��ַ�ˡ�����Ҫ��ȡĿ��IP��Ӧ��Ŀ��MAC��ַ������Ҫ����arp����arp�����Ŀ��IP��Ȼ������Ҫ��ȡ��MAC��ַ��IP����arp�����ԴIP��ʲô�أ� ���ܵ�һ��Ӧ����Ϊ�϶������ݰ�a��ԴIP��ַ���������Ҳ����һ���ģ�arp�����ԴIP�ǿ���ѡ��ģ����������ַ���ѡ�����arp_announce�����ã�  
:  arp_announce�������õ�ȡֵ��0��1��2��  
:  0������ʹ�����������ϵ�IP��ַ��Ϊarp�����ԴIP��ͨ������ʹ�����ݰ�a��ԴIP��  
:  1����������ʹ�ò����ڸ÷������������ı��ص�ַ��Ϊ����arp�����ԴIP��ַ��  
:  2������IP���ݰ���ԴIP��ַ��ѡ��÷�������������ʵı��ص�ַ��Ϊarp�����ԴIP��ַ��  
:  sysctl.conf�а���all��eth/lo��������������arp_ignore������ȡ���нϴ��ֵ��Ч��  
net.ipv4.conf.default.arp_announce = 2  
net.ipv4.conf.all.arp_announce=2  
net.ipv4.conf.lo.arp_announce=2  
<br/>  
<br/>  
:  ��ʾ����SYN Cookies��������SYN�ȴ��������ʱ������cookies�������ɷ�������SYN������Ĭ��Ϊ0����ʾ�رա�  
:  14) /proc/sys/net/ipv4/tcp_syncookies  
:  ���ļ���ʾ�Ƿ��TCPͬ����ǩ(syncookie)���ں˱������ CONFIG_SYN_COOKIES����б��롣 ͬ����ǩ(syncookie)���Է�ֹһ���׽������й�����ͼ���ӵ���ʱ������ء�  
:  ȱʡ���ã�0  
net.ipv4.tcp_syncookies = 1  
<br/>  
<br/>  
net.ipv4.tcp_tw_recycle = 1  
:  ��ʾ����TCP������TIME-WAIT sockets�Ŀ��ٻ��գ�Ĭ��Ϊ0����ʾ�رա�  
:  Enable fast recycling of TIME-WAIT sockets. Enabling this option is not recommended since this causes problems when working with NAT (Network Address Translation).  
:  ����TIME-WAIT״̬sockets�Ŀ��ٻ��գ����ѡ��Ƽ����á���NAT(Network Address Translation)�����£��ᵼ�´�����TCP���ӽ�������  
net.ipv4.tcp_tw_reuse = 1  
:  ���书�����ƵĲ���net.ipv4.tcp_tw_reuse���ֲ�����΢�е����������£�  
:  tcp_tw_reuse (Boolean; default: disabled; since Linux 2.4.19/2.6)  
:  Allow to reuse TIME-WAIT sockets for new connections when it is safe from protocol viewpoint. It should not be changed without advice/request of technical experts.  
:  ��Э�����������������TIME-WAIT״̬��sockets���õ��µ�TCP��������˵���ǰ�ȫ�ġ������ڿͻ���ʱ�����ã���ʾ��������,����TIME-WAIT sockets���������µ�TCP����,Ĭ��Ϊ0,��ʾ�ر�  
<br/>  
<br/>  
:  ��ʾ����׽����ɱ���Ҫ��رգ����������������������FIN-WAIT-2״̬��ʱ�䡣  
:  /proc/sys/net/ipv4/tcp_fin_timeout  
:  ���ڱ��˶Ͽ���socket���ӣ�TCP������FIN-WAIT-2״̬��ʱ�䡣�Է�����  
:  ��Ͽ����ӻ�һֱ���������ӻ򲻿�Ԥ�ϵĽ���������Ĭ��ֵΪ 60 �롣��ȥ��2.2�汾���ں����� 180 �롣���������ø�ֵ������Ҫע�⣬������Ļ���Ϊ���غ��ص�web��������������Ҫð�ڴ汻������Ч���ݱ������ķ��գ�FIN-WAIT-2 sockets ��Σ���Ե��� FIN-WAIT-1����Ϊ�������ֻ�� 1.5K���ڴ棬�������Ǵ���ʱ�����������ο� tcp_max_orphans��  
:  ȱʡ���ã�60���룩  
net.ipv4.tcp_fin_timeout = 30  
<br/>  
<br/>  
:  ���ƽ�����Ϊ�˷�ֹ�򵥵�DoS ����  
:  /proc/sys/net/ipv4/tcp_max_orphans  
:  ϵͳ���ܴ��������κν��̵�TCP sockets������������糬�������������ô�������κν��̵����ӻᱻ����reset����ͬʱ��ʾ������Ϣ��֮����Ҫ�趨������ƣ�����Ϊ�˵�����Щ�򵥵� DoS ������ǧ��Ҫ�������������Ϊ�Ľ���������ơ�  
:  ȱʡ���ã�8192  
net.ipv4.tcp_max_orphans = 3276800  
<br/>  
<br/>  
:  ��ʾ�����������ӵĶ˿ڷ�Χ��ȱʡ����¹�խ��32768��61000  
:  /proc/sys/net/ipv4/ip_local_port_range  
net.ipv4.ip_local_port_range = 10000 65535  
<br/>  
<br/>  
:  ��ʾSYN���еĳ��ȣ�RHEL 7.7 Ĭ��Ϊ128���Ӵ���г���Ϊ8192���������ɸ���ȴ����ӵ�������������  
:  /proc/sys/net/ipv4/tcp_max_syn_backlog  
:  ����SYN��������������.Ĭ��1024.���ظ��ط�����,���Ӹ�ֵ��Ȼ�кô�.�ɵ�����16384.  
:  ������Щ��Ȼ��δ��ÿͻ���ȷ�ϵ�����������Ҫ�����ڶ����������Ŀ�����ڳ��� 128Mb �ڴ��ϵͳ��Ĭ��ֵ�� 1024������ 128Mb ����Ϊ 128������������������ֹ��أ����Գ�������������֡����棡����������ֵ��Ϊ����1024������޸� include/net/tcp.h ����� TCP_SYNQ_HSIZE���Ա���  
:  TCP_SYNQ_HSIZE*16 0)����bytes-bytes/2^(-tcp_adv_win_scale)(���tcp_adv_win_scale 128Mb 32768-610000)��ϵͳ���������з��͸��Լ���ICMP ECHO�������Щ�㲥��ַ������  
:  ȱʡ���ã�1024  
net.ipv4.tcp_max_syn_backlog = 16384  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_timestamps  
:  ���ļ���ʾ�Ƿ�������һ�ֱȳ�ʱ�ط�����ȷ�ķ���������� RFC 1323�������ö� RTT �ļ��㣻Ϊ��ʵ�ָ��õ�����Ӧ���������ѡ�  
:  ȱʡ���ã�1  
net.ipv4.tcp_timestamps = 0  
<br/>  
<br/>  
:  ��ʾϵͳͬʱ����TIME_WAIT�׽��ֵ�����������������������֣�TIME_WAIT�׽��ֽ����̱��������ӡ������Ϣ��Ĭ��Ϊ180000�������С������TIME_WAIT״̬����������������������Դ����Ҳ����̫С�������˵Ĵ����ٶ��йأ�����ٶȿ����С���ٶ������ʵ��Ӵ󣬷���߸��ػ��������޷���Ӧ��ǳ�����  
:  /proc/sys/net/ipv4/tcp_max_tw_bucketsϵͳ��ͬʱ����������timewait sockets ��Ŀ��������������Ļ���time-wait socket �ᱻ��������������ʾ������Ϣ��֮����Ҫ�趨������ƣ�����Ϊ�˵�����Щ�򵥵� DoS ������ǧ��Ҫ��Ϊ�Ľ���������ƣ��������������������Ҫ��Ĭ��ֵ���࣬����������(����Ҫ�����ڴ�)��  
:  RHEL 7.7 ȱʡ���ã�8192  
net.ipv4.tcp_max_tw_buckets = 8192  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_sack  
:  ���ļ���ʾ�Ƿ�������ѡ���Ӧ��Selective Acknowledgment���������ͨ����ѡ���Ӧ��������յ��ı�����������ܣ����������÷�����ֻ���Ͷ�ʧ�ı��ĶΣ��������ڹ�����ͨ����˵���� ��ѡ��Ӧ�����ã�����������Ӷ� CPU ��ռ�á�  
:  ȱʡ���ã�1  
net.ipv4.tcp_sack = 1  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_window_scaling  
:  ���ļ���ʾ����tcp/ip�Ự�Ļ������ڴ�С�Ƿ�ɱ䡣����ֵΪ����ֵ��Ϊ1ʱ��ʾ�ɱ䣬Ϊ0ʱ��ʾ���ɱ䡣tcp/ipͨ��ʹ�õĴ������ɴﵽ 65535 �ֽڣ����ڸ������磬��ֵ����̫С����ʱ����������˸ù��ܣ�����ʹtcp/ip�������ڴ�С�����������������Ӷ�������ݴ����������  
:  ȱʡ���ã�1  
net.ipv4.tcp_window_scaling = 1  
<br/>  
<br/>  
:  ����3��������TCP KeepAlive�й�.��λΪ��,Ĭ��ֵ��  
:  tcp_keepalive_time = 7200  
:  tcp_keepalive_probes = 9  
:  tcp_keepalive_intvl = 75  
:  /proc/sys/net/ipv4/tcp_keepalive_intvl  
:  ���ļ���ʾ����TCP̽���Ƶ�ʣ�����tcp_keepalive_probes��ʾ�Ͽ�û����Ӧ��TCP���ӵ�ʱ�䡣  
:  ȱʡ���ã�75���룩  
:  ��˼�����ĳ��TCP������idle 2��Сʱ��,�ں˲ŷ���probe.���probe 9��(ÿ��75��)���ɹ�,�ں˲ų��׷���,��Ϊ��������ʧЧ.�Է���������,��Ȼ����ֵ̫��.�ɵ�����:  
net.ipv4.tcp_keepalive_time = 1200  
net.ipv4.tcp_keepalive_probes = 3  
net.ipv4.tcp_keepalive_intvl = 30  
:  ��ʾ��keepalive���õ�ʱ��TCP����keepalive��Ϣ��Ƶ�ȡ�ȱʡ��2Сʱ����Ϊ20���ӡ�  
<br/>  
<br/>  
#��ʾ����SYN Cookies,������SYN�ȴ��������ʱ,����cookies������,�ɷ�������SYN����,Ĭ��Ϊ0,��ʾ�ر�  
net.ipv4.tcp_syncookies = 1  
<br/>  
<br/>  
#��ʾ����TCP������TIME-WAIT sockets�Ŀ��ٻ���,Ĭ��Ϊ0,��ʾ�ر�  
<br/>  
<br/>  
#������һЩ����  
net.ipv4.route.gc_timeout = 100  
<br/>  
<br/>  
:  �ں˷�����������֮ǰ����SYNACK ��������  
:  /proc/sys/net/ipv4/tcp_syn_retries  
:  ���ļ���ʾ�������ⷢ��TCP SYN���ӳ�ʱ�ش��Ĵ�������Ӧ�ø���255����ֵ���������������ӣ����ڽ�����������tcp_retries1���ơ�  
:  ȱʡ���ã�5  
net.ipv4.tcp_syn_retries = 2  
net.ipv4.tcp_synack_retries = 2  
<br/>  
:  /proc/sys/net/ipv4/tcp_retries1  
:  ���ļ���ʾ������Ӧһ��TCP��������ǰ�����ش��Ĵ�����ȱʡ���ã�3  
net.ipv4.tcp_retries1 = 3  
<br/>  
:  ���ļ���ʾ�������Ѿ�����ͨѶ״̬�µ�һ��TCP���ݰ�ǰ�����ش��Ĵ�����TCPʧ���ش�����,Ĭ��ֵ15,��ζ���ش�15�βų��׷���.�ɼ��ٵ�5,�Ծ����ͷ��ں���Դ  
:  /proc/sys/net/ipv4/tcp_retries2  
:  ȱʡ���ã�15  
net.ipv4.tcp_retries2 = 5  
<br/>  
<br/>  
<br/>  
:  core�ļ��������pid��Ϊ��չ��---RHEL 7.7 Ĭ��ֵ���Ǵ�ֵ  
kernel.core_uses_pid = 1  
<br/>  
<br/>  
:  rp_filter�������ڿ���ϵͳ�Ƿ��������ݰ�Դ��ַ��У��---RHEL 7.7 Ĭ��ֵ���Ǵ�ֵ  
:  https://www.jianshu.com/p/717e6cd9d2bb  
:  ���ȿ�һ��Linux�ں��ĵ�documentation/networking/ip-sysctl.txt�е�������  
:  rp_filter - INTEGER  
:  0 - No source validation.  
:  1 - Strict mode as defined in RFC3704 Strict Reverse Path Each incoming packet is tested against the FIB and if the interface is not the best reverse path the packet check will fail. By default failed packets are discarded.  
:  2 - Loose mode as defined in RFC3704 Loose Reverse Path Each incoming packet's source address is also tested against the FIBand if the source address is not reachable via any interface the packet check will fail.Current recommended practice in RFC3704 is to enable strict mode to prevent IP spoofing from DDos attacks. If using asymmetric routing or other complicated routing, then loose mode is recommended.The max value from conf/{all,interface}/rp_filter is used when doing source validation on the {interface}. Default value is 0. Note that some distributions enable itin startup scripts.��rp_filter����������ֵ��0��1��2�����庬�壺  
:  0��������Դ��ַУ�顣  
:  1�������ϸ�ķ���·��У�顣��ÿ�����������ݰ���У���䷴��·���Ƿ������·�����������·���������·������ֱ�Ӷ��������ݰ���  
:  2��������ɢ�ķ���·��У�顣��ÿ�����������ݰ���У����Դ��ַ�Ƿ�ɴ������·���Ƿ���ͨ��ͨ���������ڣ����������·����ͬ����ֱ�Ӷ��������ݰ���  
net.ipv4.conf.all.rp_filter = 1  
net.ipv4.conf.default.rp_filter = 1  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/tcp_mem  
:  ���ļ�����3������ֵ���ֱ��ǣ�low��pressure��high  
:  Low����TCPʹ���˵��ڸ�ֵ���ڴ�ҳ����ʱ��TCP���ῼ���ͷ��ڴ档  
:  Pressure����TCPʹ���˳�����ֵ���ڴ�ҳ������ʱ��TCP��ͼ�ȶ����ڴ�ʹ�ã�����pressureģʽ�����ڴ����ĵ���lowֵʱ���˳� pressure״̬��  
:  High����������tcp sockets�����Ŷӻ������ݱ���ҳ������  
:  һ���������Щֵ����ϵͳ����ʱ����ϵͳ�ڴ���������õ��ġ�  
:  ȱʡ���ã�24576 32768 49152  
:  �������ã�78643200 104857600 157286400  
net.ipv4.tcp_mem = 94500000 915000000 927000000  
<br/>  
<br/>  
<br/>  
<br/>  
<br/>  
### ��·���ࡿ  
<br/>  
<br/>  
:  ����·��ת��--ȡ�����Ƿ�䵱·�����Ĺ�������  
net.ipv4.ip_forward = 1  
net.ipv4.conf.all.send_redirects = 1  
net.ipv4.conf.default.send_redirects = 1  
<br/>  
<br/>  
<br/>  
:  �޸ķ���ǽ���С��Ĭ��65536  
net.netfilter.nf_conntrack_max=655350  
net.netfilter.nf_conntrack_tcp_timeout_established=1200  
<br/>  
<br/>  
<br/>  
:  /proc/sys/net/ipv4/conf/*/accept_redirects  
:  ����������ڵ�������������·�������㽫����һ�����ó���ȱʡ���أ����Ǹ��������յ����ip��ʱ���ָ�ip�����뾭������һ��·��������ʱ���·�����ͻ���㷢һ����ν�ġ��ض���icmp�������߽�ip��ת��������һ��·����������ֵΪ����ֵ��1��ʾ���������ض���icmp ��Ϣ��0��ʾ���ԡ�  
:  �ڳ䵱·������linux������ȱʡֵΪ0  
:  ��һ���linux������ȱʡֵΪ1  
:  ���齫���Ϊ0��������ȫ������  
net.ipv4.conf.all.accept_redirects = 0  
net.ipv4.conf.default.accept_redirects = 0  
net.ipv4.conf.all.secure_redirects = 0  
net.ipv4.conf.default.secure_redirects = 0  
<br/>  
<br/>  
<br/>  
:  ������Դ·�ɵİ�, ����ĳЩ·��������������趨ֵ�� ����Ŀǰ���豸����ʹ�õ�������Դ·�ɣ������ȡ������趨ֵ---RHEL 7.7 Ĭ��ֵ���Ǵ�ֵ  
net.ipv4.conf.all.accept_source_route = 0  
net.ipv4.conf.default.accept_source_route = 0  
<br/>  
<br/>  
<br/>  
<br/>  
<br/>  
***************************************************************************************  
1)   Linux Proc�ļ�ϵͳ��ͨ����Proc�ļ�ϵͳ���е������ﵽ�����Ż���Ŀ�ġ�  
2)   Linux������Ϲ��ߣ��������ʹ��Linux�Դ�����Ϲ��߽���������ϡ�  
<br/>  
<br/>  
����/proc/sys/kernel/�Ż�  
<br/>  
:  1) /proc/sys/kernel/ctrl-alt-del  
<br/>  
:  ���ļ���һ��������ֵ����ֵ����ϵͳ�ڽ��յ�ctrl+alt+delete�������ʱ��η�Ӧ��������ֵ�ֱ��ǣ�  
:  �㣨0��ֵ����ʾ����ctrl+alt+delete������������ init �����⽫����ϵͳ���԰�ȫ�عرպ��������ͺ�������shutdown����һ����  
:  Ҽ��1��ֵ����ʾ������ctrl+alt+delete����ִ�з������Ĺرգ��ͺ���ֱ�ӹرյ�Դһ����  
:  ȱʡ���ã�0  
:  �������ã�1����ֹ���ⰴ��ctrl+alt+delete����ϵͳ������������  
<br/>  
<br/>  
<br/>  
2) /proc/sys/kernel/msgmax  
���ļ�ָ���˴�һ�����̷��͵���һ�����̵���Ϣ����󳤶ȣ�bytes�������̼����Ϣ���������ں˵��ڴ��н��еģ����ύ���������ϣ�����������Ӹ�ֵ�������Ӳ���ϵͳ��ʹ�õ��ڴ�������  
ȱʡ���ã�8192  
<br/>  
<br/>  
4) /proc/sys/kernel/msgmni  
���ļ�ָ����Ϣ���б�ʶ�������Ŀ����ϵͳ��Χ�������ٸ���Ϣ���С�  
ȱʡ���ã�16  
<br/>  
5) /proc/sys/kernel/panic  
���ļ���ʾ����������ں����ش���kernel panic���������ں�����������֮ǰ�ȴ���ʱ�䣨����Ϊ��λ�����㣨0���룬��ʾ�ڷ����ں����ش���ʱ����ֹ�Զ�����������  
ȱʡ���ã�0  
<br/>  
<br/>  
<br/>  
8) /proc/sys/kernel/shmmni  
���ļ���ʾ��������ϵͳ�Ĺ����ڴ�ε������Ŀ��������  
ȱʡ���ã�4096  
<br/>  
9) /proc/sys/kernel/threads-max  
���ļ���ʾ�ں�����ʹ�õ��̵߳������Ŀ��  
ȱʡ���ã�2048  
<br/>  
10) /proc/sys/kernel/sem  
���ļ����ڿ����ں��ź������ź�����System VIPC���ڽ��̼�ͨѶ�ķ�����  
�������ã�250 32000 100 128  
��һ�У���ʾÿ���źż��е�����ź�����Ŀ��  
�ڶ��У���ʾϵͳ��Χ�ڵ�����ź�������Ŀ��  
�����У���ʾÿ���źŷ���ʱ�����ϵͳ������Ŀ��  
�����У���ʾϵͳ��Χ�ڵ�����źż�����Ŀ��  
���ԣ�����һ�У�*�������У�=���ڶ��У�  
�������ã�����ͨ��ִ��ipcs -l����֤��  
<br/>  
<br/>  
����/proc/sys/vm/�Ż�  
1) /proc/sys/vm/block_dump  
���ļ���ʾ�Ƿ��Block Debugģʽ�����ڼ�¼���еĶ�д��Dirty Blockд�ض�����  
ȱʡ���ã�0������Block Debugģʽ  
<br/>  
2) /proc/sys/vm/dirty_background_ratio  
���ļ���ʾ�����ݵ���ϵͳ�����ڴ�İٷֱȣ���ʱ����pdflush���̰�������д�ش��̡�  
ȱʡ���ã�10  
<br/>  
3) /proc/sys/vm/dirty_expire_centisecs  
���ļ���ʾ������������ڴ���פ��ʱ�䳬����ֵ��pdflush��������һ�ν�����Щ����д�ش��̡�  
ȱʡ���ã�3000��1/100�룩  
   
4) /proc/sys/vm/dirty_ratio  
���ļ���ʾ������̲����������ݵ���ϵͳ�����ڴ�İٷֱȣ���ʱ�������а�������д�ش��̡�  
ȱʡ���ã�40  
<br/>  
5) /proc/sys/vm/dirty_writeback_centisecs  
���ļ���ʾpdflush���������Լ����ð�������д�ش��̡�  
ȱʡ���ã�500��1/100�룩  
   
6) /proc/sys/vm/vfs_cache_pressure  
���ļ���ʾ�ں˻�������directory��inode cache�ڴ������ȱʡֵ100��ʾ�ں˽�����pagecache��swapcache����directory��inode cache������һ������İٷֱȣ����͸�ֵ����100���������ں������ڱ���directory��inode cache�����Ӹ�ֵ����100���������ں������ڻ���directory��inode cache��  
ȱʡ���ã�100  
<br/>  
7) /proc/sys/vm/min_free_kbytes  
���ļ���ʾǿ��Linux VM��ͱ������ٿ����ڴ棨Kbytes����  
ȱʡ���ã�724��512M�����ڴ棩  
<br/>  
8) /proc/sys/vm/nr_pdflush_threads  
���ļ���ʾ��ǰ�������е�pdflush������������I/O���ظߵ�����£��ں˻��Զ����Ӹ����pdflush���̡�  
ȱʡ���ã�2��ֻ����  
<br/>  
9) /proc/sys/vm/overcommit_memory  
���ļ�ָ�����ں�����ڴ����Ĳ��ԣ���ֵ������0��1��2��  
0�� ��ʾ�ں˽�����Ƿ����㹻�Ŀ����ڴ湩Ӧ�ý���ʹ�ã�������㹻�Ŀ����ڴ棬�ڴ��������������ڴ�����ʧ�ܣ����Ѵ��󷵻ظ�Ӧ�ý��̡�  
1�� ��ʾ�ں�����������е������ڴ棬�����ܵ�ǰ���ڴ�״̬��Ρ�  
2�� ��ʾ�ں�������䳬�����������ڴ�ͽ����ռ��ܺ͵��ڴ棨����overcommit_ratio����  
ȱʡ���ã�0  
<br/>  
10) /proc/sys/vm/overcommit_ratio  
���ļ���ʾ�����overcommit_memory=2�����Թ����ڴ�İٷֱȣ�ͨ�����¹�ʽ������ϵͳ��������ڴ档  
ϵͳ�ɷ����ڴ�=�����ռ�+�����ڴ�*overcommit_ratio/100  
ȱʡ���ã�50��%��  
<br/>  
11) /proc/sys/vm/page-cluster  
���ļ���ʾ��дһ�ε�swap����ʱ��д���ҳ��������0��ʾ1ҳ��1��ʾ2ҳ��2��ʾ4ҳ��  
ȱʡ���ã�3��2��3�η���8ҳ��  
<br/>  
12) /proc/sys/vm/swapiness  
���ļ���ʾϵͳ���н�����Ϊ�ĳ̶ȣ���ֵ��0-100��Խ�ߣ�Խ���ܷ������̽�����  
ȱʡ���ã�60  
<br/>  
13) legacy_va_layout  
���ļ���ʾ�Ƿ�ʹ�����µ�32λ�����ڴ�mmap()ϵͳ���ã�Linux֧�ֵĹ����ڴ���䷽ʽ����mmap()��Posix��System VIPC��  
0�� ʹ������32λmmap()ϵͳ���á�  
1�� ʹ��2.4�ں��ṩ��ϵͳ���á�  
ȱʡ���ã�0  
<br/>  
14) nr_hugepages  
���ļ���ʾϵͳ������hugetlbҳ����  
<br/>  
15) hugetlb_shm_group  
���ļ���ʾ����ʹ��hugetlbҳ����System VIPC�����ڴ�ε�ϵͳ��ID��  
<br/>  
�ġ�/proc/sys/fs/�Ż�  
1) /proc/sys/fs/file-max  
���ļ�ָ���˿��Է�����ļ�����������Ŀ������û��õ��Ĵ�����Ϣ�������ڴ��ļ����Ѿ��ﵽ�����ֵ���Ӷ����ǲ��ܴ򿪸����ļ����������Ҫ���Ӹ�ֵ��  
ȱʡ���ã�4096  
�������ã�65536  
<br/>  
2) /proc/sys/fs/file-nr  
���ļ��� file-max ��أ���������ֵ��  
�ѷ����ļ��������Ŀ  
��ʹ���ļ��������Ŀ  
�ļ�����������Ŀ  
���ļ���ֻ���ģ���������ʾ��Ϣ��  
<br/>  
<br/>  
�塢/proc/sys/net/core/�Ż�  
��Ŀ¼�µ������ļ���Ҫ���������ں˺������֮��Ľ�����Ϊ��  
1�� /proc/sys/net/core/message_burst  
д�µľ�����Ϣ�����ʱ�䣨�� 1/10 ��Ϊ��λ���������ʱ����ϵͳ���յ�������������Ϣ�ᱻ�����������ڷ�ֹĳЩ��ͼ����Ϣ����û��ϵͳ������ʹ�õľܾ�����Denial of Service��������  
ȱʡ���ã�50��5�룩  
   
2�� /proc/sys/net/core/message_cost  
���ļ���ʾдÿ��������Ϣ��صĳɱ�ֵ����ֵԽ��Խ�п��ܺ��Ծ�����Ϣ��  
ȱʡ���ã�5  
<br/>  
<br/>  
5�� /proc/sys/net/core/rmem_default  
���ļ�ָ���˽����׽��ֻ�������С��ȱʡֵ�����ֽ�Ϊ��λ����  
ȱʡ���ã�110592  
<br/>  
6�� /proc/sys/net/core/rmem_max  
���ļ�ָ���˽����׽��ֻ�������С�����ֵ�����ֽ�Ϊ��λ����  
ȱʡ���ã�131071  
<br/>  
����/proc/sys/net/ipv4/�Ż�  
1) /proc/sys/net/ipv4/ip_forward  
���ļ���ʾ�Ƿ��IPת����  
0����ֹ  
1��ת��  
ȱʡ���ã�0  
<br/>  
2) /proc/sys/net/ipv4/ip_default_ttl  
���ļ���ʾһ�����ݱ����������ڣ�Time To Live��������ྭ������·������  
ȱʡ���ã�64  
���Ӹ�ֵ�ή��ϵͳ���ܡ�  
   
3) /proc/sys/net/ipv4/ip_no_pmtu_disc  
���ļ���ʾ��ȫ�ַ�Χ�ڹر�·��MTU̽�⹦�ܡ�  
ȱʡ���ã�0  
<br/>  
4) /proc/sys/net/ipv4/route/min_pmtu  
���ļ���ʾ��С·��MTU�Ĵ�С��  
ȱʡ���ã�552  
<br/>  
5) /proc/sys/net/ipv4/route/mtu_expires  
���ļ���ʾPMTU��Ϣ����೤ʱ�䣨�룩��  
ȱʡ���ã�600���룩  
<br/>  
6) /proc/sys/net/ipv4/route/min_adv_mss  
���ļ���ʾ��С��MSS��Maximum Segment Size����С��ȡ���ڵ�һ����·����MTU��  
ȱʡ���ã�256��bytes��  
<br/>  
6.1 IP Fragmentation  
1) /proc/sys/net/ipv4/ipfrag_low_thresh/proc/sys/net/ipv4/ipfrag_low_thresh  
�����ļ��ֱ��ʾ��������IP�ֶε��ڴ�������ֵ�����ֵ��һ���ﵽ����ڴ����ֵ�������ֶν���������ֱ���ﵽ����ڴ����ֵ��  
ȱʡ���ã�196608��ipfrag_low_thresh��  
����������262144��ipfrag_high_thresh��  
<br/>  
2) /proc/sys/net/ipv4/ipfrag_time  
���ļ���ʾһ��IP�ֶ����ڴ��б��������롣  
ȱʡ���ã�30���룩  
<br/>  
6.2 INET Peer Storage  
1) /proc/sys/net/ipv4/inet_peer_threshold  
INET�Զ˴洢��ĳ������ֵ���������÷�ֵ��Ŀ�����������÷�ֵͬ����������ʱ���Լ������ռ�ͨ����ʱ��������ĿԽ�࣬�����Խ�ͣ�GC ���Խ�̡�  
ȱʡ���ã�65664  
<br/>  
2) /proc/sys/net/ipv4/inet_peer_minttl  
��Ŀ����ʹ���ڡ�������˱���Ҫ���㹻����Ƭ(fragment)����ڡ������ʹ���ڱ��뱣֤������ݻ��Ƿ����� inet_peer_threshold����ֵ�� jiffiesΪ��λ������  
ȱʡ���ã�120  
<br/>  
3) /proc/sys/net/ipv4/inet_peer_maxttl  
��Ŀ��������ڡ��ڴ����޵���֮����������û�кľ�ѹ���Ļ�(���磺������е���Ŀ��Ŀ�ǳ���)����ʹ�õ���Ŀ���ᳬʱ����ֵ�� jiffiesΪ��λ������  
ȱʡ���ã�600  
<br/>  
4) /proc/sys/net/ipv4/inet_peer_gc_mintime  
�����ռ�(GC)ͨ������̼������������Ӱ�쵽��������ڴ�ĸ�ѹ���� ��ֵ�� jiffiesΪ��λ������  
ȱʡ���ã�10  
<br/>  
<br/>  
5) /proc/sys/net/ipv4/inet_peer_gc_maxtime  
�����ռ�(GC)ͨ�������������������Ӱ�쵽��������ڴ�ĵ�ѹ���� ��ֵ�� jiffiesΪ��λ������  
ȱʡ���ã�120  
<br/>  
<br/>  
3) /proc/sys/net/ipv4/tcp_keepalive_time  
���ļ���ʾ�Ӳ��ٴ������ݵ��������Ϸ��ͱ��������ź�֮�������������  
ȱʡ���ã�7200��2Сʱ��  
<br/>  
<br/>  
7) /proc/sys/net/ipv4/tcp_orphan_retries  
�ڽ��˶���TCP����֮ǰ��Ҫ���ж��ٴ����ԡ�Ĭ��ֵ�� 7 �����൱�� 50��C16���ӣ��� RTO �������������ϵͳ�Ǹ��غܴ��web����������ôҲ����  
Ҫ���͸�ֵ������ sockets ���ܻ�ķѴ�������Դ������ο�tcp_max_orphans��  
<br/>  
<br/>  
13) /proc/sys/net/ipv4/tcp_abort_on_overflow  
���ػ�����̫æ�����ܽ����µ����ӣ�����Է�����reset��Ϣ��Ĭ��ֵ��false������ζ�ŵ������ԭ������Ϊһ��żȻ��⧷�����ô���ӽ��ָ�״̬��ֻ������ȷ���ػ�������Ĳ��������������ʱ�Ŵ򿪸�ѡ���ѡ���Ӱ��ͻ���ʹ�á�  
ȱʡ���ã�0  
<br/>  
<br/>  
15) /proc/sys/net/ipv4/tcp_stdurg  
ʹ�� TCP urg pointer �ֶ��е�����������͹��ܡ��󲿷ݵ�������ʹ���Ͼɵ�BSD���ͣ����������� Linux ��������ᵼ�²��ܺ�������ȷ��ͨ��  
ȱʡ���ã�0  
<br/>  
<br/>  
20) /proc/sys/net/ipv4/tcp_fack  
���ļ���ʾ�Ƿ��FACKӵ������Ϳ����ش����ܡ�  
ȱʡ���ã�1  
<br/>  
<br/>  
21) /proc/sys/net/ipv4/tcp_dsack  
���ļ���ʾ�Ƿ�����TCP���͡�������ȫ��ͬ����SACK��  
ȱʡ���ã�1  
<br/>  
<br/>  
22) /proc/sys/net/ipv4/tcp_ecn  
���ļ���ʾ�Ƿ��TCP��ֱ��ӵ��ͨ�湦�ܡ�  
ȱʡ���ã�0  
<br/>  
<br/>  
23) /proc/sys/net/ipv4/tcp_reordering  
���ļ���ʾTCP��������������ݱ����������  
ȱʡ���ã�3  
   
24) /proc/sys/net/ipv4/tcp_retrans_collapse  
���ļ���ʾ����ĳЩ��bug�Ĵ�ӡ���Ƿ��ṩ�����bug�ļ����ԡ�  
ȱʡ���ã�1  
<br/>  
<br/>  
28) /proc/sys/net/ipv4/tcp_app_win  
���ļ���ʾ����max(window/2^tcp_app_win, mss)�����Ĵ�������Ӧ�û��塣��Ϊ0ʱ��ʾ����Ҫ���塣  
ȱʡ���ã�31  
<br/>  
29) /proc/sys/net/ipv4/tcp_adv_win_scale  
���ļ���ʾ���㻺�忪��bytes/2^tcp_adv_win_scale(���tcp_adv_win_scale >; 0)����bytes-bytes/2^(-tcp_adv_win_scale)(���tcp_adv_win_scale <= 0����    
ȱʡ���ã�2    
<br/>  
2) /proc/sys/net/ipv4/ip_nonlocal_bind  
���ļ���ʾ�Ƿ�������̰���Ǳ��ص�ַ��  
ȱʡ���ã�0  
<br/>  
3) /proc/sys/net/ipv4/ip_dynaddr  
�ò���ͨ������ʹ�ò������ӵ����������ʹϵͳ���ܹ������ı�ip����Դ��ַΪ��ip��ַ��ͬʱ�ж�ԭ�е�tcp�Ի������µ�ַ���·���һ��syn���� ������ʼ�µ�tcp�Ի�����ʹ��ip��ƭʱ���ò������������ı�αװ��ַΪ�µ�ip��ַ�����ļ���ʾ�Ƿ�����̬��ַ�������ֵ��0����ʾ���������ֵ ����1���ں˽�ͨ��log��¼��̬��ַ��д��Ϣ��  
ȱʡ���ã�0  
<br/>  
5) /proc/sys/net/ipv4/icmp_ratelimit  
<br/>  
6) /proc/sys/net/ipv4/icmp_ratemask  
<br/>  
7) /proc/sys/net/ipv4/icmp_ignore_bogus_error_reponses  
ĳЩ·����Υ��RFC1122��׼����Թ㲥֡����α�����Ӧ��Ӧ������Υ����Ϊͨ���ᱻ�Ը澯�ķ�ʽ��¼��ϵͳ��־�С������ѡ������ΪTrue���ں˲����¼���־�����Ϣ��  
ȱʡ���ã�0  
<br/>  
8) /proc/sys/net/ipv4/igmp_max_memberships  
���ļ���ʾ�ಥ���е�����Ա������  
ȱʡ���ã�20  
   
6.5 Other Configuration  
<br/>  
<br/>  
<br/>  
2) /proc/sys/net/ipv4/*/accept_source_route  
�Ƿ���ܺ���Դ·����Ϣ��ip��������ֵΪ����ֵ��1��ʾ���ܣ�0��ʾ�����ܡ��ڳ䵱���ص�linux������ȱʡֵΪ1����һ���linux������ȱʡֵΪ0���Ӱ�ȫ�ԽǶȳ���������رոù��ܡ�  
   
3) /proc/sys/net/ipv4/*/secure_redirects  
��ʵ��ν�ġ���ȫ�ض��򡱾���ֻ�����������صġ��ض���icmp�����ò��������������á���ȫ�ض��򡱹��ܵġ�  
����ֵΪ����ֵ��1��ʾ���ã�0��ʾ��ֹ��  
ȱʡֵΪ���á�  
<br/>  
4) /proc/sys/net/ipv4/*/proxy_arp  
�����Ƿ�������ϵ�arp�������м̡�����ֵΪ����ֵ��1��ʾ�м̣�0��ʾ���ԣ�  
ȱʡֵΪ0���ò���ͨ��ֻ�Գ䵱·������linux�������á�  
