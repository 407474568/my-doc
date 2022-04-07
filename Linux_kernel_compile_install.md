* [目录](#0)
  * [红帽8 升级 5.10](#1)


<h3 id="1">红帽8 升级 5.10</h3>

绝大部分步骤参考此文档即可  
https://blog.51cto.com/u_3436241/4750925  

编译安装要用的工具集, 但 perl 可能是缺失的, 也需要确保安装

```
yum install -y ncurses-devel gcc-c++ make openssl-devel bison flex elfutils-libelf-devel perl
```

```
tar -xvf linux-5.10.90.tar.xz -C /tmp/
cd /tmp/linux-5.10.90/

# 确认当前使用的内核
uname -r
# 拷贝当前使用内核的 config文件用于节省修改配置工作
cp /boot/config-4.18.0-348.20.1.el8_5.x86_64 ./.config
```

在.config文件中找到 ```CONFIG_SYSTEM_TRUSTED_KEYS```，```CONFIG_DEBUG_INFO_BTF```这两行，并将这两行注释。


接下执行 make menuconfig  
进入UI界面，参数不用改，切换到save直接保存，尔后按两下Esc退出。  

```
make menuconfig
```

编译内核--依次执行以下步骤,注意确认是否有报错  

```
# 手动修改为自己的逻辑CPU总线程, 以获得最快完成速度
make -j8
make modules
make modules_install
make install
```

使用grubby切换内核  
如果没有安装  

```
yum install -y grubby
```

```
# 查看当前系统默认启动的内核
grubby --default-kernel

# 查看当前系统有哪些可用的内核
grubby --info=ALL | grep ^kernel

通过命令 grubby --set-default=可以设置你的默认启动内核
grubby --set-default=/boot/vmlinuz-5.10.90
```
