* [目录](#0)
  * [编译安装环境](#1)
  * [编译安装中的异常处理](#2)
  

<h3 id="1">编译安装环境</h3>

```
# 查看编译时的参数是哪些
python3 -c "import sysconfig; print(sysconfig.get_config_var('CONFIG_ARGS'))"

# 查看当前导入的 ssl 模块的 openssl 的版本
python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"
```

<h3 id="2">编译安装中的异常处理</h3>

#### python 3 编译报错 Could not import runpy module 解决方案

https://blog.csdn.net/whatday/article/details/103903955

导致原因
- 在低版本的gcc版本中带有 --enable-optimizations 参数时会出现上面问题
- gcc 8.1.0修复此问题  

解决方法选择
- 升级gcc
- ./configure参数中去掉 --enable-optimizations
