http://jameswxx.iteye.com/blog/2096461  总结得最详细

http://blog.ihipop.info/2011/01/2053.html 

简单概括为

1) 修改/etc/security/limits.conf 里的值

2) sshd的配置文件(例: /etc/ssh/sshd_config)应有以下两条

UsePAM yes

UseLogin yes

3) 检查以下三个文件(通常 /etc/pam.d/sshd就应有效)

/etc/pam.d/login

/etc/pam.d/system-auth

/etc/pam.d/sshd

是否已有以下内容

session    required     pam_limits.so

(必要时也可以指定详细路径,如/lib64/security/pam_limits.so)

另外确保/etc/pam.d/system-auth文件有下面内容

session required /lib/security/$ISA/pam_limits.so

这一行确保系统会执行这个限制。

4) 最后,不要在其他文件写死了ulimit，比如:ulimit -n 65535


#### 2023-03-17 增补

红帽7 及以后或者说使用 systemctl 作为服务管理项的发行版  
而该服务项/进程本身并非使用 systemctl 进行管理的对象  
一个场景示例:  
openssh 使用源码包openssh 编译升级后, 由于选择的是 openssh 源码包里提供的 旧版本(红帽6及以下)的服务管理方式(即 SysV), 因此它不受systemctl 服务项配置的值的影响.  

基于此, 对systemd 下的 service 增加如```LimitNOFILE=xxx``` 的语句并不能使之得到预期的结果

目前暂时有的替代解决办法如下:

https://superuser.com/questions/1200539/cannot-increase-open-file-limit-past-4096-ubuntu

```
$ grep DefaultLimitNOFILE /etc/systemd/system.conf
DefaultLimitNOFILE=65535


or better here:


$ grep NOFILE /etc/systemd/system.conf.d/limits.conf
DefaultLimitNOFILE=65535
```

缺点:
1) 修改对象就不再仅限于该服务, 而是系统上的全部服务项
2) 需要重启操作系统才能生效

#### 2021-11-06 增补  
https://bbs.huaweicloud.com/blogs/108323  
受systemd 管理的服务进程的配置方式  
该场景仅针对被systemd管理的进程（也就是可以通过systemctl来控制的进程）生效.    
可以通过修改该进程的service文件（通常在/etc/systemd/system/目录下）.   
在“[Service]”下面添加“LimitNOFILE=20480000”来实现.   
修改完成之后需要执行"systemctl daemon-reload"来使该配置生效。

inotify达到上限  
inotify是linux提供的一种监控机制，可以监控文件系统的变化。该机制受到2个内核参数的影响：“fs.inotify.max_user_instances”和“fs.inotify.max_user_watches”，其中“fs.inotify.max_user_instances”表示每个用户最多可以创建的inotify instances数量上限，“fs.inotify.max_user_watches”表示么个用户同时可以添加的watch数目，当出现too many open files问题而上面三种方法都无法解决时，可以尝试通过修改这2个内核参数来生效。修改方法是修改"/etc/sysctl.conf"文件，并执行"sysctl -p"。


#### 字段含义
https://www.ibm.com/developerworks/cn/linux/l-cn-ulimit/index.html

/etc/security/limits.conf配置格式如下：
<domain> <type> <item> <value>
domain  代表限制的用户对象，可以是：用户名、@用户组名、*（表示所所有用户的默认配置）、%
type      代表限制的资源类型，可以是：
hard      --硬限制，受限用户不可自己通过ulimit动态修改此项的值
soft       --软限制，用户自己可以自己使用ulimit加资源对应的参数动态修改此项的值（但其范围要在hard限制范围以内不然无效）
-            --代表软硬两种限制
![](/images/b6be90b3gy1gj2wlf3jl9j20u00ufn2y.jpg)


#### 关于修改了/etc/security/limits.conf, 从会话可见新设置的值,但程序仍可能会引起问题的情况
https://access.redhat.com/solutions/30316

红帽官方文档提到  90-nproc.conf, 但感觉依然没有足够强调 90-nproc.conf 对生效值的机制.
In Red Hat Enterprise Linux 6, there's a default setting in /etc/security/limits.d/90-nproc.conf. Change the default limit for all users or add a new limit for the affected user.

Root Cause
The user fails to log in because an EAGAIN error occurs if the user's number of executing threads has reached the nproc resource limit.

Note: Despite the name, this is a limit on threads, not processes.

This error may occur if user's nproc limit is set to /etc/security/limits.conf.

In Red Hat Enterprise Linux 6, this error occurs even if the limit is not explicitly set because the default configuration for all users is set in /etc/security/limits.d/90-nproc.conf.


https://www.cnblogs.com/lsdb/p/7526448.html

RHEL6.x版本后引入/etc/security/limits.d/90-nproc.conf用于限制用户打开进程数，与limits.conf的关系是：
如果90-nproc.onf与limits.conf存在相同条目的配置那么90-nproc覆盖limits.conf的配置
但是如果90-nproc.conf用的是*没有指定用户而limits.conf指定用户那么90-nproc的限制不生效.
其实90-nproc.conf除了限制nproc其他资源一样可以限制，生效原则与nproc一样
其实在/etc/security/limit.d目录下你还可以创建其他任意名字的.conf文件，这些文件中首字母ACSII大的覆盖首字母ASCII小的（首字母一样大的比较第二个字母以此类推）


#### 亲测的几个结论
https://www.cnblogs.com/lsdb/p/7526448.html   对此文章观点的验证

- 结论1:

在RHEL 6上, 90-nproc.conf的存在

```
*          soft    nproc     1024
```
的情况下,
在/etc/security/limits.conf文件中添加
```
*           -      nproc     65535
```
不会改变普通用户的"max user processes"即nproc值,此时sshd进程和操作系统分别进行过重启,结果都相同.

此点与我们在生产环境看到的效果不同, 生产环境同样的配置方法,su到weblogic下,ulimit -u看到的max user processes的值是生效的,为65535,但依然出现can not set id: resource temporarily unavilable,
使用ps -u weblogic -L 统计weblogic用户总的线程数为1025

- 结论2:

nproc, 即ulimit命令看到的max user processes的值,对应的是该用户的所有进程+线程的总数,不能只以ps看进程数为参考,要以ps -u 用户名 -L统计该用户的计数为准.

测试方法

1) python代码创建一个无限循环的函数,使其永远不结束  
2) 主函数以多线程方式调用该函数,数量1300个---为超过1024  
3) 执行python代码---代码抛出异常: thread.error: can't start new thread  
4) 此时统计该用户的线程总数, ps -u test -L | wc -l,  值为1025. 与生产环境所见结果相同.  

python代码截图  
![](/images/b6be90b3gy1gj52jn0gjbj20g508gmxv.jpg)

执行过程抛异常截图

![](/images/b6be90b3gy1gj52jpvp4sj20le07caan.jpg)

此时统计”test”用户的线程数截图

![](/images/b6be90b3gy1gj52js994sj20ec04iwem.jpg)

- 结论3:

/etc/security/limits.conf 与 /etc/security/limits.d/90-nproc.conf 的相互关系

1) 说法: 如果90-nproc.onf与limits.conf存在相同条目的配置那么90-nproc覆盖limits.conf的配置

测试结论: 说法正确

测试方法

/etc/security/limits.conf 与 /etc/security/limits.d/90-nproc.conf 都配置

“* -nproc”项, 但值不同,一个2048,一个65535

![](/images/b6be90b3gy1gj52juo05zj20ov09lgmp.jpg)

此时重新su 到 test用户,会话可见值为2048

![](/images/b6be90b3gy1gj52jxktv8j20h50frtao.jpg)

python代码实测,创建线程数为2500---为超过2048
![](/images/b6be90b3gy1gj52yum6v0j20gr0b2mxs.jpg)

![](/images/b6be90b3gy1gj52yxzh4ij20ed0370sq.jpg)

2) 说法: 但是如果90-nproc.conf用的是*没有指定用户而limits.conf指定用户, 那么90-nproc的限制不生效

测试结论: 说法正确

测试方法

/etc/security/limits.d/90-nproc.conf 保持 “*          soft    nproc     2048” 不变

/etc/security/limits.conf 同时存在两条

```
* -nproc 65535
test -nproc 10240
```

![](/images/b6be90b3gy1gj52z2shsej20pb0aqwfo.jpg)

此时,su到test用户,可见值为10240

![](/images/b6be90b3gy1gj52z5nsxbj20h40ffjtb.jpg)

python代码实测,线程数13000---为超过10240

![](/images/b6be90b3gy1gj52z9lcv0j20lw0h3ta3.jpg)

此时test用户的线程总数10241

![](/images/b6be90b3gy1gj532ej44wj20e803bt8p.jpg)

综上:

1) 如果不希望改变/etc/security/limits.d/90-nproc.conf的内容, 则需要改大nproc时,在/etc/security/limits.conf 中就必须明确指明用户名, 如:

weblogic -nproc 65535

2) 反之, 

注释 /etc/security/limits.d/90-nproc.conf 中的 “ *          soft    nproc     1024”

和

删除(重命名) /etc/security/limits.d/90-nproc.conf 文件

都可以使 /etc/security/limits.conf 中

以” * -nproc 65535”方式配置的值生效

3) RHEL 7不存在90-nproc.conf,但存在/etc/security/limits.d/20-nproc.conf, 机制相同,默认值由1024变为了4096


