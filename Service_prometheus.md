### 官网  

资源下载  
https://prometheus.io/download/

docker 镜像  
https://hub.docker.com/r/prom/prometheus

Prometheus官方文档  
https://prometheus.io/docs/prometheus/latest/getting_started/

Prometheus中文文档, 域名有点意思  
https://prometheus.fuckcloudnative.io/di-yi-zhang-jie-shao/overview


### 几个手册性质的网站



<br>
<br>

* [目录](#0)
  * [单实例 docker 部署方式的初始化](#1)



<h3 id="1">单实例 docker 部署方式的初始化</h3>

初次上手,参考这个够用  
https://juejin.cn/post/6844904121921699848

docker image 信息

```
[root@docker-node1 docker]# dockerimage | grep prome
prom/prometheus                      2022-07-14   c3d2a0b3481a   4 weeks ago     214MB
prom/prometheus                      latest       c3d2a0b3481a   4 weeks ago     214MB

[root@docker-node1 docker]# docker inspect c3d2a0b3481a | grep -i create
        "Created": "2022-07-14T15:41:01.42407415Z",
```

config file 的初始化  

https://segmentfault.com/a/1190000023272730

只是用这个作为起点

```
[root@docker-node1 docker]# cat /docker/prometheus/prometheus.yml 
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - pro_alert_manager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
# rule_files:
#   - "test_rule.yml"
#     - "first_rules.yml"
#     - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']
```

唯独踩坑的地方, 由于额外的启动参数, 是 ```prommetheus``` 命令行参数形式传递的,
不是环境变量, 不是用 ```-e``` 方式设置环境变量, 只能写在最后

最终启动的参数

```
docker run --rm -dit -u root \
-v /docker/prometheus/data:/etc/prometheus/data \
-v /docker/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
-p 9090:9090 \
--name prometheus \
prom/prometheus:2022-07-14 \
--storage.tsdb.path=/etc/prometheus/data \
--storage.tsdb.retention.time=30d \
--config.file=/etc/prometheus/prometheus.yml
```



