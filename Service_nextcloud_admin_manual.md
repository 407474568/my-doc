#### 官网  
https://nextcloud.com/athome/  
https://nextcloud.com/install/#  

#### 官方手册
https://docs.nextcloud.com/server/latest/user_manual/en/  
https://docs.nextcloud.com/server/latest/user_manual/zh_CN/  

#### 入门手册  
https://support.websoft9.com/docs/nextcloud/zh/
http://www.garfielder.com/post/990cc2cb.html  


#### 新建用户首次登录的默认语言从英文改变到中文
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
