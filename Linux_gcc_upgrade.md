出处:

[https://www.vpser.net/manage/centos-6-upgrade-gcc.html](https://www.vpser.net/manage/centos-6-upgrade-gcc.html)

#### 升级到gcc 7.3：
```
yum -y install centos-release-scl
yum -y install devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-binutils
scl enable devtoolset-7 bash
```

需要注意的是scl命令启用只是临时的，退出shell或重启就会恢复原系统gcc版本。
如果要长期使用gcc 7.3的话：
```
echo "source /opt/rh/devtoolset-7/enable" >>/etc/profile
```

#### 升级到gcc 8.3：
```
yum -y install centos-release-scl
yum -y install devtoolset-8-gcc devtoolset-8-gcc-c++ devtoolset-8-binutils
scl enable devtoolset-8 bash
```

需要注意的是scl命令启用只是临时的，退出shell或重启就会恢复原系统gcc版本。
如果要长期使用gcc 8.3的话：

```
echo "source /opt/rh/devtoolset-8/enable" >>/etc/profile
```

#### 升级到gcc 9.3：
```
yum -y install centos-release-scl
yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils
scl enable devtoolset-9 bash
```

需要注意的是scl命令启用只是临时的，退出shell或重启就会恢复原系统gcc版本。
如果要长期使用gcc 9.3的话：

```
echo "source /opt/rh/devtoolset-9/enable" >>/etc/profile
```

**再说一下已经停止支持的devtoolset4(gcc 5.2)及之前版本的安装方法**

#### 升级到gcc 4.8：

```
wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtoolset-2.repo
yum -y install devtoolset-2-gcc devtoolset-2-gcc-c++ devtoolset-2-binutils
scl enable devtoolset-2 bash
```

#### 升级到gcc 4.9：

```
wget https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo -O /etc/yum.repos.d/devtoolset-3.repo
yum -y install devtoolset-3-gcc devtoolset-3-gcc-c++ devtoolset-3-binutils
scl enable devtoolset-3 bash
```

#### 升级到gcc 5.2

```
wget https://copr.fedoraproject.org/coprs/hhorak/devtoolset-4-rebuild-bootstrap/repo/epel-6/hhorak-devtoolset-4-rebuild-bootstrap-epel-6.repo -O /etc/yum.repos.d/devtoolset-4.repo
yum install devtoolset-4-gcc devtoolset-4-gcc-c++ devtoolset-4-binutils -y
scl enable devtoolset-4 bash
```
升级完成后一定要运行：gcc --version 看一下版本号变成升级后的gcc版本才算升级成功。

#### 升级到gcc 6.3
devtoolset-6已经结束支持，请安装devtoolset-7
```
yum -y install centos-release-scl
yum -y install devtoolset-6-gcc devtoolset-6-gcc-c++ devtoolset-6-binutils
scl enable devtoolset-6 bash
```
需要注意的是scl命令启用只是临时的，退出shell或重启就会恢复原系统gcc版本。
如果要长期使用gcc 6.3的话：

```
echo "source /opt/rh/devtoolset-6/enable" >>/etc/profile
```
这样退出shell重新打开就是新版的gcc了
以下其他版本同理，修改devtoolset版本号即可。
