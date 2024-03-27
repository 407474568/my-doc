* [目录](#0)
  * [Python 在Linux上的编译安装](#1)
  * [查看编译安装环境](#2)
  * [编译安装中的异常处理](#3)
  * [有关pyinstaller](#4)
  * [cython 创建完全静态连接的可执行程序](#5)


<h3 id="1">Python 在Linux上的编译安装</h3>

#### 2024-03-27 更新

在 RHEL/Rocky 等红帽家族的发行版上, openssl 适配的版本是 3.x, 当该系统编译安装升级过 openssl, 那么 Python
的编译安装又会遇到问题  
因为截止目前, Python3 也尚未对 openssl 3.x 进行适配, 所以试图以 openssl 3.x 编译安装 Python3 是无解的.  
不过变通的处理方式--提供一个指定的 openssl 的位置, 而这个 openssl 的位置甚至是完成了 make 编译的, 但区别在于不做 
make install 等后续的一系列操作, 即仅仅只完成一个编译好的 openssl 可执行程序, 专供 Python3 编译程序使用.  
这样做的好处是可以与系统使用 openssh openssl 版本分离开, 无需与系统使用版本进行捆绑.

最后在 Python 内核实 openssl lib库的版本

```
[root@kvm-host-simulator ~]# python3
Python 3.10.13 (main, Mar 27 2024, 12:52:02) [GCC 8.5.0 20210514 (Red Hat 8.5.0-20)] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import ssl
>>> print(ssl.OPENSSL_VERSION)
OpenSSL 1.1.1k  FIPS 25 Mar 2021
```

但依然是系统自带的 1.1.1k  
可见编译过程中 Python 依然从 openssl-devel 包中依赖了内容

----------------------------------------------------------

重点在以下参数

```
./configure --prefix=/usr/local/${python_version_main} \
--with-openssl=/usr/local/openssl \
--enable-optimizations \
--enable-shared
```

--with-openssl=/usr/local/openssl  指定openssl所在位置,关键所在  
--enable-shared  动态库共享,关键所在  
--enable-optimizations  启用编译器优化,可选项
--prefix=/usr/local/${python_version_main}  指定编译生成的文件统一放置的位置,可选项

完成以后还需要做 ldd 的动态库链接指向添加工作

截止 Python 3.10.6 我的编译安装脚本

<a href="files/Python-3.10-install.sh" target="_blank">Python-3.10-install.sh</a>

<h3 id="2">查看编译安装环境</h3>

```
# 查看编译时的参数是哪些
python3 -c "import sysconfig; print(sysconfig.get_config_var('CONFIG_ARGS'))"

# 查看当前导入的 ssl 模块的 openssl 的版本
python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"
```

<h3 id="3">编译安装中的异常处理</h3>

#### python 3 编译报错 Could not import runpy module 解决方案

https://blog.csdn.net/whatday/article/details/103903955

导致原因
- 在低版本的gcc版本中带有 --enable-optimizations 参数时会出现上面问题
- gcc 8.1.0修复此问题  

解决方法选择
- 升级gcc
- ./configure参数中去掉 --enable-optimizations


<h3 id="4">有关pyinstaller</h3>

pyinstaller 作为 python的一个lib, 可以将 python 脚本编译生成成可执行程序, 尤其是单个文件

示例, -F 就是单文件的参数

```
pyinstaller -F <Python脚本位置>
```

但可能会遇到在执行过程中出现找不到跟libxxx.so的几个动态链接库文件的相关提示

```
OSError: Python library not found: libpython3.7m.so.1.0, libpython3.7mu.so.1.0, libpython3.7.so.1.0
This would mean your Python installation doesn't come with proper library files.
This usually happens by missing development package, or unsuitable build parameters of Python installation.

* On Debian/Ubuntu, you would need to install Python development packages
* apt-get install python3-dev
* apt-get install python-dev
* If you're building Python by yourself, please rebuild your Python with `--enable-shared` (or, `--enable-framework` on Darwin)
```

https://blog.csdn.net/weixin_39973810/article/details/122041118  
https://www.cnblogs.com/codeBang/p/15856571.html

解决方法:  
python解释器在编译安装时的参数```--enable-shared```极可能是遗漏的, 或者未添加到 ldd 的查找目录中 /etc/ld.so.conf  
参照本文第1条重新编译安装python解释器可以解决问题

##### 由pyinstaller生成的可执行程序在运行过程中获知自身的位置

由 pyinstaller 打包成可执行程序后, 执行程序默认是在 /tmp 下创建一个随机字符串命令的目录作为程序的工作目录

你可能会有获取可执行程序所在位置和自身文件名的需求, 

https://stackoverflow.com/questions/404744/determining-application-path-in-a-python-exe-generated-by-pyinstaller  
https://note.nkmk.me/en/python-os-basename-dirname-split-splitext/

示例方法:

```
if getattr(sys, 'frozen', False):
    # application_path = os.path.dirname(sys.executable)
    conf_file_name = os.path.dirname(sys.executable) + os.sep + os.path.basename(sys.executable) + r".ini"
elif __file__:
    # application_path = os.path.dirname(__file__)
    self_path_name = os.path.split(os.path.realpath(__file__))
    conf_file_name = self_path_name[0] + os.sep + re.sub(r".(py|exe)$", r".ini", self_path_name[1])
```

利用 getattr 获取程序自身的内置属性变量, 来判断是脚本还是可执行程序.


##### 最后

pyinstaller 并非是完全静态编译, 它依然是要依赖OS上的动态链接库

https://github.com/DARIAH-DE/TopicsExplorer/issues/53

![](images/nXOCNdEsmJDQqKcBG5OWus7H4EboedZa.jpg)

所以, 如果是期望生成的可执行程序具有广泛的可移植性, <font color=red>pyinstaller 是做不到这一点的.</font>

![](images/nXOCNdEsmJbgyHq3nw9f6GlaiDTAvtEm.jpg)


<h3 id="5">cython 创建完全静态连接的可执行程序</h3>

