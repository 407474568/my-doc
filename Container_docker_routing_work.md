* [目录](#0)
  * [环境安装](#1)
  * [改国内镜像](#2)
  * [docker ps 命令](#3)



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

```shell
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
.Label - Value of a specific label for this container. For example \{\{ \.Label \"com.docker.swarm.cpu\" \}\}
.Mounts - Names of the volumes mounted in this container.
```


示例:  

