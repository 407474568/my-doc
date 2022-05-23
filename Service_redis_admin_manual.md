### 官网  
https://redis.io/  
http://www.redis.cn/  中文社区


### 几个手册性质的网站
https://www.kancloud.cn/thinkphp/redis-quickstart/36133  
https://www.w3cschool.cn/redis_all_about/  
http://redisdoc.com/index.html  
https://www.w3cschool.cn/redis_all_about/redis_all_about-sfc726u6.html  


* [目录](#0)
  * [只安装redis-cli](#1)



<h3 id="1">只安装redis-cli</h3>

Linux平台, 编译安装

```
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make redis-cli
sudo cp src/redis-cli /usr/local/bin/
redis-cli -h 127.0.0.1 -p 6379 ping
```

