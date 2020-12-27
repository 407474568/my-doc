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

#### 使用代理
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

#### 使用ssh的方式连接

使用http和https的连接方式  
下面这个是在push过程中出, 但通常并不影响操作结果.
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

#### 自建git server
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

#### 非git删除文件后的恢复
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
接下来git push 一次即可从server端重新拉取被删除的文件  
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

#### 删除了文件, 并且错误的commit的情况下的恢复
待补充

