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
createrepo -pdo <font color="#00dd00">*索引文件创建的位置  被索引的目录位置*</font><br /> 

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
