* [目录](#0)
  * [环境安装](#1)
  * [改国内镜像](#2)
  * [docker ps 命令](#3)
  * [卷挂载的几种选择](#4)
  * [修改默认网段](#5)
  * [docker 的几种网络模式](#6)
  * [docker 的 save 与 export 以及 load 和 import 的区别](#7)
  * [容器的DNS的指派](#8)


<h3 id="1">环境安装</h3>

#### docker-ce 在 centos 7 的安装  
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


#### 在 RHEL 8 上的安装

https://help.hcltechsw.com/bigfix/10.0/mcm/MCM/Install/install_docker_ce_docker_compose_on_rhel_8.html

https://www.linuxtechi.com/install-docker-ce-centos-8-rhel-8/

以上两篇帖子覆盖了所需的必要内容  
在 RHEL 8 上使用 yum源安装之所以会出现一些冲突提示, 根源还是红帽是在力推自己的podman, 因为预装的包就与docker所使用的```container-io```有了冲突

以下是我安装成功的示例

```
wget -c https://download.docker.com/linux/centos/8/x86_64/stable/Packages/containerd.io-1.6.9-3.1.el8.x86_64.rpm
yum -y install ./containerd.io-1.6.9-3.1.el8.x86_64.rpm --allowerasing
dnf install --nobest docker-ce
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

示例1

```
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
```

示例2

```
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://registry.docker-cn.com",
    "https://mirror.baidubce.com"
  ]
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

查看当前的镜像站点信息, docker info 输出的最后 Registry Mirrors 部分
```
docker info

...
Registry Mirrors:
 https://hub-mirror.c.163.com/
 https://registry.docker-cn.com/
 https://mirror.baidubce.com/
Live Restore Enabled: false
Product License: Community Engine
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


<h3 id="5">修改默认网段</h3>

前提:  
1) docker 容器使用桥接模式  
2) 发现从docker宿主机上不通容器的IP (通过 ```docker inspect 容器名/ID``` 可以查询)  
3) 与容器的网关IP 可能是通的 (通过 ```docker inspect 容器名/ID``` 可以查询)  

具备以上情景就很可能是docker 的桥接口 (构建的NAT网络) 与真实网络环境中的IP网段相重合导致的.

解决办法就是为docker 的桥接口更换网段

https://blog.51cto.com/wsxxsl/2060761

第一步 删除原有配置

```
sudo service docker stop
sudo ip link set dev docker0 down
sudo brctl delbr docker0
sudo iptables -t nat -F POSTROUTING
```

第二步 创建新的网桥

```
sudo brctl addbr docker0
sudo ip addr add 172.17.10.1/24 dev docker0
sudo ip link set dev docker0 up
```

第三步 配置Docker的文件

增加一个 ```"bip": "172.17.10.1/24"``` 的项

```
[root@rltestapp4-localdomain docker]# cat /etc/docker/daemon.json 
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"],
  "bip": "172.17.10.1/24"
}
```


<h3 id="6">docker 的几种网络模式</h3>

引用自:

https://www.cnblogs.com/davis12/p/14392125.html  

![](/images/2121520-20210209101320897-1516104081.png)

host 模式

![](/images/2121520-20210209101342976-1177695742.png)

bridge模式

![](/images/2121520-20210209101412547-1464356333.png)

其他容器（container）模式

![](/images/2121520-20210209101500011-79014329.png)


<h3 id="7">docker save 与 export 区别</h3>

https://jingsam.github.io/2017/08/26/docker-save-and-docker-export.html

引用原作者的总结:

> docker save保存的是镜像（image），docker export保存的是容器（container）；  
docker load用来载入镜像包，docker import用来载入容器包，但两者都会恢复为镜像；  
docker load不能对载入的镜像重命名，而docker import可以为镜像指定新名称。

<h3 id="8">容器的DNS的指派</h3>

https://docs.docker.com/config/containers/container-networking/

https://gdevillele.github.io/engine/userguide/networking/default_network/configure-dns/

当希望 container 的DNS服务器是使用自己指定的时候, 最简单的形式莫过于

```
docker run --dns x.x.x.x
```

这种形式指定, 得到的效果即如下:

```
[root@opm-server ~]# docker run --rm -dit -v /docker/autodeployment-1.0.2.jar:/123.jar -e JAVA_HOME="/autodeploy/jdk1.8.0_351" -e PATH="/autodeploy/jdk1.8.0_351/bin:$PATH" --dns 61.128.128.68 -p 3532:3532 --name=autodeployment_app jdk_8u351:latest /bin/bash
ef42e2c2cbe4e3985c0d1d70a90de8c258b9f7fa6f2516b8d973deac72c97067
[root@opm-server ~]# docker exec -it autodeployment_app /bin/bash
[root@ef42e2c2cbe4 /]# cat /etc/resolv.conf 
nameserver 61.128.128.68
[root@ef42e2c2cbe4 /]# exit
```

docker 官方文档也已有清晰的描述

相关的讨论也在:

https://stackoverflow.com/questions/41032744/unable-to-edit-etc-resolv-conf-in-docker-container

比较有意思的是下面这篇文章, 对 docker 运行时对  
```/etc/hosts``` ```/etc/resolv.conf```  
文件的处理,做了一个验证

https://blog.csdn.net/Max_Cong/article/details/96861826
