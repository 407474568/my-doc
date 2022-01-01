### 官网  
https://nextcloud.com/athome/  
https://nextcloud.com/install/#  

### 官方手册
https://docs.nextcloud.com/server/latest/user_manual/en/  
https://docs.nextcloud.com/server/latest/user_manual/zh_CN/  

### 入门手册  
https://support.websoft9.com/docs/nextcloud/zh/  
http://www.garfielder.com/post/990cc2cb.html  

### NextCloud config 配置参数
https://www.gooccoo.com/nextcloud/870/  
<a href="files/NextCloud%20config%20配置参数%20–%20GOC云.rar" target="_blank">NextCloud config 配置参数.rar</a>

* [目录](#0)
  * [新建用户首次登录的默认语言从英文改变到中文](#1)
  * [设置用户的密码复杂度策略](#2)
  * [用户的配额限制](#3)


    
<h3 id="1">新建用户首次登录的默认语言从英文改变到中文</h3>
https://hostloc.com/thread-609835-1-1.html  
如此帖里提到的  
config/config.php
需要新增语句
```
'default_language' => 'zh',
```
![](images/lTGqcJNXAS9DIirqYxlRbskWeMSng1u5.png)

如帖子中所说, 原本的zh_CN应是在nextcloud 新版中失效  
同时, 经过此设置后, 新增用户同样有报错, 但新用户数次登录后的确已变为中文.


<h3 id="2">设置用户的密码复杂度策略</h3>
管理员账户登录nextcloud, 从个人设置里"设置"导航到左侧"管理"部分里的"安全"  

![](images/lTGqcJNXAScHLahnO5kW9AX0G4idxBtR.png)

![](images/lTGqcJNXASOq5Z8H6GSiLPYfgBTyzDke.png)

![](images/lTGqcJNXAS8sKmCLctUhrfaRJqM9Q3BS.png)


<h3 id="3">用户的配额限制</h3>
https://help.nextcloud.com/t/custom-quota-option/54000/3  
![](images/lTGqcJNXASRitLPAKHaQuFGr5nCq3DcI.png)  
以为是要改php代码等手段才能实现, 实际上, 官方论坛上的答复是, 你直接设置就可以了  
不过实测,nextcloud的管理员很多功能, 典型的如下拉列表等, 在chrome, firefox浏览器上都表现异常  
在opera浏览器上完成了该操作.
![](images/lTGqcJNXASo4yvz1fB6TwDenKHhU073Z.png)  
这里需要注意的是, 先在文本框输入你想限制的数值+单位, 待下方提示框出现后, 点击提示框的选择才可选择.  
如果输入完成直接回车, 则不会生效.  

