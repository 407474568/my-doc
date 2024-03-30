* [目录](#0)
  * [环境安装](#1)
  * [改国内镜像](#2)
  * [docker ps 命令](#3)
  * [卷挂载的几种选择](#4)
  * [修改默认网段](#5)
  * [docker 的几种网络模式](#6)
  * [docker 的 save 与 export 以及 load 和 import 的区别](#7)
  * [容器的DNS的指派](#8)
  * [Docker数据卷挂载命令volume(-v)与mount的区别](#9)
  * [与iptables共存](#10)


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

~~修改配置文件~~  
~~修改/etc/docker/daemon.json文件，如果没有先建一个即可~~  

```
sudo vim /etc/docker/daemon.json
```

~~示例1~~

```
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
```

~~示例2~~

```
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://registry.docker-cn.com",
    "https://mirror.baidubce.com"
  ]
}
```

~~使配置文件生效~~  

```
systemctl daemon-reload
```

~~重启Docker~~  

```
systemctl restart docker
```

~~查看当前的镜像站点信息, docker info 输出的最后 Registry Mirrors 部分~~

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

以上应当不属于有效方法.  
虽然 ```Registry Mirrors``` 能查看到自行配置的镜像站点地址, 但在实际使用中依然能发现与预期不符的痕迹.  
另一个问题是, 实际经验发现有的镜像在使用 mirror 站点并不能获取到的情况, 依然要以 docker hub 的资源为主.  
而经确认过的, 正确的方法如下:

https://www.lfhacks.com/tech/pull-docker-images-behind-proxy/

1) 创建 dockerd 相关的 systemd 目录，这个目录下的配置将覆盖 dockerd 的默认配置

```
$ sudo mkdir -p /etc/systemd/system/docker.service.d
```

2) 新建配置文件 /etc/systemd/system/docker.service.d/http-proxy.conf，这个文件中将包含环境变量

```
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:80"
Environment="HTTPS_PROXY=https://proxy.example.com:443"
```

3) 如果你自己建了私有的镜像仓库，需要 dockerd 绕过代理服务器直连，那么配置 NO_PROXY 变量：

```
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:80"
Environment="HTTPS_PROXY=https://proxy.example.com:443"
Environment="NO_PROXY=your-registry.com,10.10.10.10,*.example.com"
```

多个 NO_PROXY 变量的值用逗号分隔，而且可以使用通配符 ```*```，极端情况下，如果 NO_PROXY=*，那么所有请求都将不通过代理服务器。

4) 重新加载配置文件，重启 dockerd

```
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```

5) 检查确认环境变量已经正确配置：

```
$ sudo systemctl show --property=Environment docker
```

6) 从 docker info 的结果中查看配置项。

```
[root@docker-cluster-node2 ~]# docker info
 ...略...
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 HTTP Proxy: http://192.168.1.40:9998
 HTTPS Proxy: http://192.168.1.40:9998
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


<h3 id="9">Docker数据卷挂载命令volume(-v)与mount的区别</h3>

https://blog.csdn.net/inrgihc/article/details/109001886

--volume(-v)  
参数--volume（或简写为-v）只能创建bind mount。示例：

```
docker run --name $CONTAINER_NAME -it \
-v $PWD/$CONTAINER_NAME/app:/app:rw \
-v $PWD/$CONTAINER_NAME/data:/data:ro \
avocado-cloud:latest /bin/bash
```

注释：

命令格式：[[HOST-DIR:]CONTAINER-DIR[:OPTIONS]]]  
如果指定HOST-DIR则必须是绝对路径，如果路径不存在则会自动创建
实例中的rw为读写，ro为只读

--mount  
参数--mount默认情况下用来挂载volume，但也可以用来创建bind mount和tmpfs。如果不指定type选项，则默认为挂载volume，volume是一种更为灵活的数据管理方式，volume可以通过docker volume命令集被管理。示例：

```
docker run --name $CONTAINER_NAME -it \
--mount type=bind,source=$PWD/$CONTAINER_NAME/app,destination=/app \
--mount source=${CONTAINER_NAME}-data,destination=/data,readonly \
avocado-cloud:latest /bin/bash
```

注释：

挂载volume命令格式：[type=volume,]source=my-volume,destination=/path/in/container[,...]  
创建bind mount命令格式：type=bind,source=/path/on/host,destination=/path/in/container[,...]  
如果创建bind mount并指定source则必须是绝对路径，且路径必须已经存在  
示例中readonly表示只读

#### 差异总结

创建bind mount和挂载volume的比较

| 对比项 | bind mount | volume |
| --- | --- | --- |
| Source位置 | 用户指定 | /var/lib/docker/volumes/ |
| Source为空 | 覆盖dest为空 | 保留dest内容 |
| Source非空 | 覆盖dest内容 | 覆盖dest内容 |
| Source种类 | 文件或目录 | 只能是目录 |
| 可移植性 | 一般（自行维护） | 强（docker托管） |
| 宿主直接访问 | 容易（仅需chown） | 受限（需登陆root用户）* |

> 注释：Docker无法简单地通过  
```sudo chown someuser: -R /var/lib/docker/volumes/somevolume```  
来将volume的内容开放给主机上的普通用户访问，如果开放更多权限则有安全风险。而这点上Podman的设计就要理想得多，volume存放在$HOME/.
local/share/containers/storage/volumes/路径下，既提供了便捷性，又保障了安全性。无需root权限即可运行容器，这正是Podman的优势之一，实际使用过程中的确受益良多。

创建bind mount时使用--volume和--mount的比较

| 对比项 | --volume 或 -v | --mount type=bind |
| --- | --- | --- |
| 如果主机路径不存在 | 自动创建 | 命令报错 |

<h3 id="10">与iptables共存</h3>

在 RHEL 家族的发行版上, 禁用 firewalld 并启用 iptables 可以安装包名为 iptables-services  
此后会创建一个 iptables.service 的 systemctl 管理的服务项  
使用上就完全是 iptables 的习惯与方式.  
但 docker 也是使用 iptables 来进行容器的端口转发, 所以最稳妥的方式是将 iptables.service 添加到 docker 的服务依赖项上去.

```
[root@CQ-docker-02 ~]# cat /usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service containerd.service time-set.target iptables.service
Wants=network-online.target containerd.service
Requires=docker.socket
```

其中 ```After=``` 尾部添加 ```iptables.service```  
以此确保 docker 的守护进程一定是在 iptables 之后启动.
