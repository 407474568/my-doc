* [目录](#0)
  * [环境安装](#1)
  * [改国内镜像](#2)
  * [docker ps 命令](#3)
  * [卷挂载的几种选择](#4)


<h3 id="2">环境安装</h3>

docker-ce 在 centos 7 的安装  
https://docs.docker.com/engine/install/centos/  

移除可能存在的旧版  

```
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

添加 docker-ce 的 官方repo
```
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

```
yum -y install docker-ce docker-ce-cli containerd.io
```


<h3 id="2">改国内镜像</h3>

镜像搜索  
https://hub.docker.com/search?q=  

国内镜像仓库

| 国内Docker镜像仓库名称 | 链接                                 | 
|----------------|------------------------------------|
| Docker 官方中国区   | https://registry.docker-cn.com     |
| 网易             | http://hub-mirror.c.163.com        |
| 中国科学技术大学       | https://docker.mirrors.ustc.edu.cn |
| 阿里云 | https://<你的ID>.mirror.aliyuncs.com |

修改配置文件  
修改/etc/docker/daemon.json文件，如果没有先建一个即可  

```
sudo vim /etc/docker/daemon.json
```

```
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
```

使配置文件生效  

```
systemctl daemon-reload
```

重启Docker  

```
systemctl restart docker
```

<h3 id="3">docker ps 命令</h3>
##### --format 用法
docker ps –format参数可以实现格式化输出自定义列。各列意义如下：  

{%raw%}
-format="TEMPLATE"  
Pretty-print containers using a Go template.  
Valid placeholders:  
.ID - Container ID  
.Image - Image ID  
.Command - Quoted command  
.CreatedAt - Time when the container was created.  
.RunningFor - Elapsed time since the container was started.  
.Ports - Exposed ports.  
.Status - Container status.  
.Size - Container disk size.  
.Names - Container names.  
.Labels - All labels assigned to the container.  
.Label - Value of a specific label for this container. For example {{ .Label "com.docker.swarm.cpu" }}  
.Mounts - Names of the volumes mounted in this container.  
{%endraw%}

示例:  

{%raw%}
docker ps --format "table {{ .Names }}\t{{ .Ports }}\t{{ .Status }}\t{{ .ID }}\t{{.Image}}"  
{%endraw%}


<h3 id="4">卷挂载的几种选择</h3>

除了常规的 -v 选项,当使用 -v 不能正常工作时, 还有其他选项可以尝试

https://docs.docker.com/storage/bind-mounts/  
https://stackoverflow.com/questions/66898187/docker-mount-vol-error-includes-invalid-characters-for-a-local-volume
-name  

mount type为volume的示例

```
docker run \
    -p 5000:5000 \
    --mount type=volume,source=/Users/jake/Desktop/source,target=/data \
    --name testvol test
```

mount type为bind的示例

```
docker run \
    -p 5000:5000 \
    --mount type=bind,source=/Users/jake/Desktop/source,target=/data \
    --name test test
```

其中, readonly 也是可选参数

```
docker run --rm -dit \
-v /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime \
-v /docker/nextcloud/var_www_html:/var/www/html/ \
-v /docker/nextcloud/data:/var/www/html/data \
--mount type=bind,source=/mnt/百度云同步盘,target=/var/www/html/data/tanhuang/files,readonly \
-p 999:80 --name=my_nextcloud nextcloud:24.0.0
```
