#### 使用代理  
https://docs.huihoo.com/yum/managing-software-with-yum-zh_cn/sn-yum-proxy-server.html   
永久性生效  
写入/etc/yum.conf 的内容  
```
proxy=http://172.16.1.2:9999

# 代理服务器 - proxy server:port number
proxy=http://mycache.mydomain.com:3128

# 用于 yum 连接的帐户细节
proxy_username=yum-user  
proxy_password=qwerty
```

#### 临时性生效
shell 环境下执行
```
http_proxy="http://mycache.mydomain.com:3128"
export http_proxy

# 这个帐号使用的代理服务器和用户名/密码
http_proxy="http://yum-user:qwerty@mycache.mydomain.com:3128"
export http_proxy
```

#### 配置yum仓库  
http://www.zyops.com/autodeploy-yum  
http://blog.csdn.net/huangjin0507/article/details/51351807  
结合两个帖子看已足够  

yum服务器端需要的是http服务  
客户端配置yum指向yum服务器端的目录下，需要存在repodata索引数据  
例如RPM包放在/mnt/rpm下，则repodata应存在于/mnt/rpm/repodata

因此，如果有自行创建的RPM包这种情况， 则需要安装createrepo软件，因为要为其创建repodata索引数据  
yum -y install createrepo

初始化repodata索引文件  
createrepo -pdo <font color="#006600">*索引文件创建的位置  被索引的目录位置*</font><br /> 

每加入一个rpm包就要更新一下  
createrepo --update /application/yum/centos6.6/x86_64/   

<font color="#dd0000">如果是挂载的光盘ISO，在光盘根目录就有repodata，不需要额外创建，本身以iso方式挂载出来的目录也不具备写权限。</font><br /> 

【客户端配置】  
yum默认配置文件的位置 /etc/yum.repos.d/
一个示例
```
[root@PC-20170105RLFT ~]# cat /etc/yum.repos.d/test.repo
[motherfucker]
name=Server
baseurl=http://192.168.0.10
enable=1
gpgcheck=0

[fuck]
name=Server2
baseurl=http://192.168.0.10/iso/
enable=1
gpgcheck=0
```
客户端yum install的效果

![](/images/NZ6nJ8r5BqNJqR1AMujHOYp6CliPzTdf.png)

##### SuSE上创建http的zypper源与红帽类似
https://zh.opensuse.org/index.php?title=SDB:%E5%88%9B%E5%BB%BA%E4%BD%A0%E8%87%AA%E5%B7%B1%E7%9A%84%E8%BD%AF%E4%BB%B6%E6%BA%90&variant=zh

需要安装一个createrepo软件包,在其安装iso里可以获得.  
命令也是一样简单,如:  
```
createrepo /tmp/salt-suse11/
```

也有另外一个方式  
http://www.linuxdiyf.com/linux/21661.html 


#### yum / zypper 保留下载包
SuSE  
默认目录是/var/cache/zypp/packages。  
/etc/zypp/repos.d/目录下对应各个更新源的repo文件里，keeppackages的值设为1。

RHEL / CentOS  
1) yum自身带 --downloadonly参数 , 这个无需额外插件(6.7上如此,再古老的版本另说)  
用法举例:  
yum -y install  --downloadonly python-ordereddict  
2) yumdownloader  
安装了 yum-utils 软件包了的可用,比downloadonly方便在于下到当前目录  
格式:  yumdownloader <package-name>


#### yum指定安装某个源下的软件的方法
反复验证，指定--enablerepo参数并不能产生目标效果，实际有用的方法还是yum加入了优先级控制后，用优先级控制安装源  
yum install nginx --enablerepo=epel  
加 --enablerepo=参数

#### Remi 安装源
http://cnzhx.net/blog/remi-repository/  
Remi repository 是包含最新版本 PHP 和 MySQL 包的 Linux 源，由 Remi 提供维护。有个这个源之后，使用 YUM 安装或更新 PHP、MySQL、phpMyAdmin 等服务器相关程序的时候就非常方便了。
```
# CentOS 6 / RHEL 6
yum -y install http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
 
# CentOS 7 / RHEL 7
yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
```
CentOS 7.x使用EPEL源
http://www.ha97.com/5649.html

#### 使用YUM安装指定版本的包
http://foolishfish.blog.51cto.com/3822001/1437662  
使用  
yum list 软件包名 --showduplicates  
可查询该软件包的历史版本，从而在yum install中给出完整的包名进行安装
例：yum -y install facter-1.6.13-1.el6  

![](/images/NZ6nJ8r5Bq6cCkwuMBjf8IPY3UlrdS4T.png)

#### yum源配置优先级设置
1. 安装 yum-priorities
yum -y install yum-priorities

2. priorities的配置文件是/etc/yum/pluginconf.d/priorities.conf，确认其是否存在。
其内容为:
```
[main]
enabled=1   # 0禁用 1启用
```

3. 编辑 /etc/yum.repos.d/目录下的*.repo 文件来设置优先级。  
参数为：  
priority=N   # N的值为1-99  
推荐的设置为：  
[base], [addons], [updates], [extras] … priority=1   
[centosplus],[contrib] … priority=2  
Third Party Repos such as rpmforge … priority=N   (where N is > 10 and based on your preference)  
数字越大,优先级越低

#### yum的使用技巧
如果使用一个命令，返回提示“bash:xxxxxx：command not found” 
但你并不清楚哪个软件包提供这一命令，可以使用”yum provides xxxxx“或“yum whatprovides xxxxx”来查询。

![](/images/NZ6nJ8r5Bq76OI2DXRJ4wgb81PdkGE9S.jfif)

#### 改用163的yum更新源
参考http://jin771998569.blog.51cto.com/2147853/1068064

#### 没有yum修复yum
http://blog.csdn.net/zcyhappy1314/article/details/17580943  
```
#去掉原有的更新节点
rpm -qa | grep yum | xargs rpm -e --nodeps
 
#下载4个包  
wget http://mirrors.163.com/centos/6/os/x86_64/Packages/yum-3.2.29-69.el6.centos.noarch.rpm
wget http://mirrors.163.com/centos/6/os/x86_64/Packages/yum-metadata-parser-1.1.2-16.el6.x86_64.rpm ;
wget http://mirrors.163.com/centos/6/os/x86_64/Packages/yum-plugin-fastestmirror-1.1.30-30.el6.noarch.rpm ;
wget http://mirrors.163.com/centos/6/os/x86_64/Packages/python-iniparse-0.3.1-2.1.el6.noarch.rpm

#安装下载的4个文件
rpm -ivh python-iniparse-0.3.1-2.1.el6.noarch.rpm 
rpm -ivh yum-metadata-parser-1.1.2-16.el6.x86_64.rpm
rpm -ivh yum-3.2.29-69.el6.centos.noarch.rpm yum-plugin-fastestmirror-1.1.30-30.el6.noarch.rpm               
最后两个需要一起安装，有相互依赖关系
 
#下载配置文件CentOS6-Base-163.repo
wget http://mirrors.163.com/.help/CentOS6-Base-163.repo ;
 
#修改CentOS6-Base-163.repo  ，将其中的$releasever 更改为centos的版本
vi CentOS6-Base-163.repo（使用 vi 命令编辑文件）
：%s/$releasever/6 （在 vi 命令模式下执行上述命令）

#把配置文件放到指定目录 并且删除原来的配置文件
rm -fr  /etc/yum.repos.d*
mv CentOS6-Base-163.repo /etc/yum.repos.d

#清除缓存 
yum clean all
 
#配置获取yum列表
yum  makecache
```

#### 改用安装光盘作yum源  
先将ISO镜像挂载到某处  
修改/etc/yum.repos.d/下的repo文件，Red hat/CentOS版本的不同，repo文件的名字也有区别，查看一下/etc/yum.repos.d/目录即可知，Red hat 6.4下叫rhel-source.repo
在该文件尾部追加  

```
 [RHEL]
name=RHEL6.4
baseurl=file:///mnt/cdrom        #ISO挂载所在的位置
gpgcheck=0gpgkey=file:///mnt/cdrom/RPM-GPG-KEY-redhat-release
enabled=1
```
完成

![](/images/NZ6nJ8r5Bq0NdXoI25wzfP9anWsC81VO.jfif)

可看见响应方是RHEL，即追加内容里方括号的名字。 
