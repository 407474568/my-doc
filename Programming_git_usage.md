官方文档  
https://docs.github.com/cn/free-pro-team@latest/github

git for windows  
https://gitforwindows.org/

git的GUI  
https://desktop.github.com/

手册和入门文章  
https://www.liaoxuefeng.com/wiki/896043488029600  
https://git-scm.com/book/zh/v2  
https://www.kancloud.cn/thinkphp/github-tips/37873  
http://github.phodal.com/  
https://blog.csdn.net/itmyhome1990/article/details/39579099

&nbsp;


* [目录](#0)
  * [使用代理](#1)
  * [使用ssh的方式连接](#2)
  * [自建git server -- SSH协议](#3)
  * [自建git server -- http协议](#4)
  * [非git命令删除文件后的恢复](#5)
  * [删除了文件, 并且还commit的情况下的恢复](#6)


<h3 id="1">使用代理</h3>

https://gist.github.com/laispace/666dd7b27e9116faece6  
```
git config --global https.proxy http://127.0.0.1:1080
git config --global https.proxy https://127.0.0.1:1080

git config --global --unset http.proxy
git config --global --unset https.proxy
```
以上命令的结果写入文件  
Windows上的位置  
%userprofile%\.gitconfig

Linux上的位置  
~/.gitconfig

<br/>

<h3 id="2">使用ssh的方式连接</h3>

使用http和https的连接方式,会有以下两种情况  
下面这个是在push过程中出现, 但通常并不影响操作结果.
```
fatal: NotSupportedException encountered.
   ServicePointManager 不支持具有 socks5 方案的代理。
```
以下这种提示, 则是上传失败.
```
fatal: The remote end hung up unexpectedly
```
如遇到以上两类提示, 其实都是该用ssh连接方式取代  

https://blog.csdn.net/w410589502/article/details/53607691

操作步骤:
1. 在server端页面添加客户端的证书key, 使用openssh的 ssh-keygen生成即可, 公钥xx.pub的内容粘贴添加到git页面上
2. server端去复制ssh地址, 
3. 客户端git操作连接的地址 git@<font color=red>服务器域名或IP</font>:<font color=#008000>某级目录/仓库目录</font>

&nbsp;


<h3 id="3">自建git server -- SSH协议</h3>

Linux下的server端配置方法:  
https://www.jianshu.com/p/0f47fa1894e5  
https://www.liaoxuefeng.com/article/895923490127776  

1. 配置一个git专用的用户
2. 配置该用户家目录下.ssh/authorized_keys, 使客户端可以ssh证书登录
3. 使该用户对某级目录具有完全操作权限
4. git init --bare 某级目录/仓库目录
5. 客户端可以首先使用 ssh -T 用户名@服务器域名或IP 来验证ssh证书登录是否成功
6. 客户端git操作连接的地址 git@<font color=red>服务器域名或IP</font>:<font color=#008000>某级目录/仓库目录</font>

```
[root@docker git]# git init --bare dev
Initialized empty Git repository in /docker/git/dev/
[root@docker git]# ll
total 4.0K
drwxr-xr-x 7 root root 4.0K Dec 27 12:47 dev
[root@docker git]# ll dev/
total 32K
drwxr-xr-x 2 root root 4.0K Dec 27 12:47 branches
-rw-r--r-- 1 root root   66 Dec 27 12:47 config
-rw-r--r-- 1 root root   73 Dec 27 12:47 description
-rw-r--r-- 1 root root   23 Dec 27 12:47 HEAD
drwxr-xr-x 2 root root 4.0K Dec 27 12:47 hooks
drwxr-xr-x 2 root root 4.0K Dec 27 12:47 info
drwxr-xr-x 4 root root 4.0K Dec 27 12:47 objects
drwxr-xr-x 4 root root 4.0K Dec 27 12:47 refs
```

```
D:\Code\private\dev>git remote add local git@192.168.1.30:/docker/git/dev

D:\Code\private\dev>git remote -v
git     git@github.com:407474568/workplace.git (fetch)
git     git@github.com:407474568/workplace.git (push)
gitee   git@gitee.com:tanhuang1985/workplace.git (fetch)
gitee   git@gitee.com:tanhuang1985/workplace.git (push)
local   git@192.168.1.30:/docker/git/dev (fetch)
local   git@192.168.1.30:/docker/git/dev (push)

D:\Code\private\dev>git push local master
 _                    _
| |__   ___ _   _  __| | __ _ _   _
| '_ \ / _ \ | | |/ _` |/ _` | | | |
| | | |  __/ |_| | (_| | (_| | |_| |
|_| |_|\___|\__, |\__,_|\__,_|\__, |
            |___/             |___/
Enumerating objects: 218, done.
Counting objects: 100% (218/218), done.
Delta compression using up to 16 threads
Compressing objects: 100% (216/216), done.
Writing objects: 100% (218/218), 49.86 KiB | 1.92 MiB/s, done.
Total 218 (delta 121), reused 0 (delta 0), pack-reused 0
To 192.168.1.30:/docker/git/dev
 * [new branch]      master -> master

```

&nbsp;

<h3 id="4">自建git server -- http协议</h3>

在已有ssh协议的git server基础上, 扩展出 http / https 协议的支持,以便于匿名权限的下载,也即可以clone,不可以push.

有关 git 所支持的4种协议, 这两篇文章已有详尽的阐述

http://dockone.io/article/8534  
https://blog.51cto.com/u_11990719/3099729

不管apache 还是nginx都需要用到 git-http-backend  
而 git-http-backend 能正常工作的前提是web服务器的fastcgi功能的支持.  
apache是内置fastcgi, nginx 还需要额外扩展来支持

实操参考

https://www.yvanz.com/2016/06/01/Git-server-with-http(s)-protocol.html  

首先是 yum 安装, spawn-fcgi 是让fcgiwarp以daemon方式运行的工具

```
yum -y install fcgi-devel spawn-fcgi
```

但随后的 fcgiwrap 的编译安装在RHEL 8.5上是要出错的

```
git clone https://github.com/gnosek/fcgiwrap.git
cd fcgiwrap
autoreconf -i
./configure
make && make install
```

错误如下:

```
[root@docker-node1 fcgiwrap]# make && make install
cc -std=gnu99 -Wall -Wextra -Werror -pedantic -O2 -g3    fcgiwrap.c  -lfcgi  -o fcgiwrap
fcgiwrap.c: In function ‘handle_fcgi_request’:
fcgiwrap.c:581:4: error: this statement may fall through [-Werror=implicit-fallthrough=]
    cgi_error("502 Bad Gateway", "Cannot execute script", filename);
    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fcgiwrap.c:583:3: note: here
   default: /* parent */
   ^~~~~~~
cc1: all warnings being treated as errors
make: *** [<builtin>: fcgiwrap] Error 1
```

在这篇帖子的最后一个回复里, 提了一个别的办法  
https://github.com/gnosek/fcgiwrap/issues/50

其实也是 epel 源安装预编译好的

```
dnf --enablerepo=epel -y install fcgiwrap
```

但因为换了安装方法, ```fcgiwrap``` 可执行文件的路径变为了 ```/usr/sbin/fcgiwrap```  


因此, 有关 fcgiwrap 在 /etc/init.d/ 下的服务项,有关执行程序的位置, 需要作对应修改.

<a href="files/git-fcgi" target="_blank">git-fcgi服务项文件</a>

启动后的进程如下

```
[root@docker-node1 fcgiwrap]# ps axu | grep cgi
git       440699  0.0  0.0  41820  1996 ?        Ss   12:55   0:00 /usr/sbin/fcgiwrap -f -c 1 -p /usr/libexec/git-core/git-http-backend
root      440712  0.0  0.0  12116  1096 pts/0    S+   12:55   0:00 grep --color cgi
```

nginx 有关此站点的配置文件部分

作者原文

```
#Git nginx conf
server {
    listen 80; 
    server_name yougit.git.com;
    #return 301 https://$server_name$request_uri;
    root       /data/git/;
    error_log  /var/log/nginx/git.error.log  warn;
    access_log /var/log/nginx/git.access.log main;

    location ~ ^/([^/]+\.git)(/.*|$) {
        include fastcgi_params;
        fastcgi_param PATH_INFO           $uri;
        fastcgi_param REMOTE_USER         $remote_user;
        fastcgi_param SCRIPT_FILENAME     /usr/libexec/git-core/git-http-backend;
        fastcgi_param GIT_PROJECT_ROOT    $document_root;
        fastcgi_param GIT_HTTP_EXPORT_ALL ""; 
        fastcgi_pass unix:/var/run/git-fcgi.sock;
    }   
}
```

而我因为之前建git仓库时, 并未按照 xxx.git 格式命名文件夹, 所以需要微调.

```
server {
    listen 3090;
    server_name  code.heyday.net.cn;
    access_log  /etc/nginx/logs/access_code.log;
    error_log  /etc/nginx/logs/error_code.log;
    charset utf-8,gbk;
    root /docker/git;

    location ~ ^/([^/]+)(/.*|$) {
        include fastcgi_params;
        fastcgi_param PATH_INFO           $uri;
        fastcgi_param REMOTE_USER         $remote_user;
        fastcgi_param SCRIPT_FILENAME     /usr/libexec/git-core/git-http-backend;
        fastcgi_param GIT_PROJECT_ROOT    $document_root;
        fastcgi_param GIT_HTTP_EXPORT_ALL ""; 
        fastcgi_pass unix:/var/run/git-fcgi.sock;
    } 
}
```

其实也就是 nginx 的 localtion 段的正则  
```location ~ ^/([^/]+\.git)(/.*|$)```  
需要把 ```\.git``` 去掉

随后重载nginx配置文件生效

```
[root@temp_linux ~]# git clone http://code.heyday.net.cn:3090/dev/
Cloning into 'dev'...
fatal: repository 'http://code.heyday.net.cn:3090/dev/' not found
[root@temp_linux ~]# git clone http://code.heyday.net.cn:3090/dev/
Cloning into 'dev'...
remote: Enumerating objects: 2192, done.
remote: Counting objects: 100% (2192/2192), done.
remote: Compressing objects: 100% (1855/1855), done.
remote: Total 2192 (delta 1353), reused 565 (delta 333), pack-reused 0
Receiving objects: 100% (2192/2192), 3.42 MiB | 0 bytes/s, done.
Resolving deltas: 100% (1353/1353), done.
```

首次 clone 可以采用如上方式, 后续的同步更新, 目前只知道的方式  

```git fetch --all && git reset --hard <repo名>/<分支名> && git pull```

同

```
git fetch --all
git reset --hard <repo名>/<分支名>
git pull local master
```

&nbsp;

<h3 id="5">非git命令删除文件后的恢复</h3>

https://my.oschina.net/u/2000675/blog/3126116  
https://www.iteye.com/blog/hbiao68-2213238

如通过操作系统而不是git rm删除文件, 在没有commit前的恢复很容易  
此时git status 可以看见被删除的文件已被列出  
通过

```
git reset HEAD
```

或

```
git reset HEAD .
```

来使指针指回到删除前的状态  
测试是删除的多个文件, 所以使用 . 号当前位置来进行指代  
同理, checkout 也是使用的 . 号  
接下来git pull 一次即可从server端重新拉取被删除的文件  

```
D:\临时存储\dev>git status
On branch master
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        deleted:    wx.FlexGridSizer.py
        deleted:    wx.GridBagSizer.py
        deleted:    wx.GridBagSizer2.py
        deleted:    wx.cashier_report.py
        deleted:    wx.interface_switch.py
        deleted:    wx.led_clock.py
        deleted:    wx.license_plate_number_header_choice.py
        deleted:    wx.license_plate_number_query.py
        deleted:    wx.media_player.py

no changes added to commit (use "git add" and/or "git commit -a")

D:\临时存储\dev>git reset HEAD
Unstaged changes after reset:
D       wx.FlexGridSizer.py
D       wx.GridBagSizer.py
D       wx.GridBagSizer2.py
D       wx.cashier_report.py
D       wx.interface_switch.py
D       wx.led_clock.py
D       wx.license_plate_number_header_choice.py
D       wx.license_plate_number_query.py
D       wx.media_player.py

D:\临时存储\dev>git reset HEAD .
Unstaged changes after reset:
D       wx.FlexGridSizer.py
D       wx.GridBagSizer.py
D       wx.GridBagSizer2.py
D       wx.cashier_report.py
D       wx.interface_switch.py
D       wx.led_clock.py
D       wx.license_plate_number_header_choice.py
D       wx.license_plate_number_query.py
D       wx.media_player.py

D:\临时存储\dev>git checkout .
Updated 9 paths from the index

D:\临时存储\dev>git pull git-local master
 _                    _
| |__   ___ _   _  __| | __ _ _   _
| '_ \ / _ \ | | |/ _` |/ _` | | | |
| | | |  __/ |_| | (_| | (_| | |_| |
|_| |_|\___|\__, |\__,_|\__,_|\__, |
            |___/             |___/
From 192.168.1.30:/docker/git/dev
 * branch            master     -> FETCH_HEAD
Already up to date.
```

&nbsp;

<h3 id="6">删除了文件, 并且还commit的情况下的恢复</h3>

待补充

