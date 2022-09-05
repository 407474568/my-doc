### 官网  

docker 镜像  
https://hub.docker.com/r/grafana/grafana

官方文档  
https://grafana.com/docs/grafana/latest/

插件下载, zabbix数据源就是插件形式而非内置  
https://grafana.com/grafana/plugins/


### 几个手册性质的网站

grafana Transform 功能文档  
https://grafana.com/docs/grafana/v9.0/panels/transform-data/transformation-functions/


<br>
<br>

* [目录](#0)
  * [grafana--zabbix数据源--时间戳不一致情景下数据合并](#1)
  * [grafana--降序的阈值对应不同颜色](#2)

  
<h3 id="1">grafana--zabbix数据源--时间戳不一致情景下数据合并</h3>

效果图参照以下链接内容进行的对标:  
https://www.dounaite.com/article/62626709f86aba5c78840ea8.html

其他参考资料:  

Transform data  
https://grafana.com/docs/grafana/latest/panels/transform-data/

How to best organize your teams and resources in Grafana  
https://grafana.com/blog/2022/03/14/how-to-best-organize-your-teams-and-resources-in-grafana/

Table Panel  
https://docs.huihoo.com/grafana/2.6/reference/table_panel/index.html

grafana结合zabbix数据对其他Pannel设置学习  
http://www.51niux.com/?id=239

最终它的效果图如下:

![](images/EblWMn6sLfQOdE6L5PNqsc132DKteRzv.png)

由于它的数据源是Prometheus, 且数据的时间戳是一致的, 所以它用到 ```Transform``` 里的 ```Merge``` 就完成了多项数据项的合并.  
grafana 会因为相同的时间戳, 将字段拼接到一个结果中.  
正如 grafana Transform 功能文档 (本文档顶部链接) 所示:

![](images/EblWMn6sLfiJUvAGzysfL3NBFECVTXqh.png)

关于目标效果的背景描述

1) 数据源是zabbix  
2) 期望的效果是第一眼能看到关注的重点数据, 只求最新的状态值, 不要求详细变化趋势  
3) 详细的数据变化趋势可以在下方或子页面的形式呈现  
4) 出于种种原因, 各项指标的时间戳还并非大体一致的. 也就是一个指标一个时间戳, 非常普遍  

基于以上背景, 参考了```grafana Transform 功能文档``` 的介绍  
摸索出在此情景下的变通实现相似效果的方法  

![](images/EblWMn6sLf8RbLZtNmnTQPerOF2WX6Gk.png)

依次是:  
1) 创建 ```Table``` 类型的面板  
2) ```Concatenate fields``` 实现拼接字段  
3) ```Reduce``` 减少记录行数, 只保留最新的一条数据--否则是按时间戳顺序都列出来. 注意: 这里还需要选择```mode``` 为 ```Reduce fields```  
4) ```Organize fields``` 组织字段, 实现对字段的重命名以及自由拖拽排序功能.  

需要说明的是, 由于时间戳的不一致, 不能有效```Merge```  
而 ```Concatenate fields``` 只能做的是无脑连接字段.  
在此情景下, 想要一台主机上的信息以一行显示, 多个主机多行显示, 其实是采取的变通方式, 每台主机创建了一个panel, 
除了表头的panel 两行宽度以显示表头以外, 剩余都只有一行宽度, 且隐藏表头.  
有自欺欺人之嫌, 但外观至少看起来基本一致了.

最终效果图

![](/images/FiwKYRa58ojyGz47kJgaMtrYWcLefvpl.png)


<h3 id="2">grafana--降序的阈值对应不同颜色</h3>

升序的阈值对应不同颜色, 很简单, 拿来就用.  
但如果犯过来, 低于某个值, 就以一种不同的颜色显示, grafana 能否实现和如何实现?

https://github.com/grafana/grafana-polystat-panel/issues/46

答案原来很简单, 其实思维逆向一下就好

<img src="images/s8iglpK3NYNjOVLzHay0wJZSYX3lF7v4.png" style="zoom:70%" />
