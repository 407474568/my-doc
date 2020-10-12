#### 手册资料
Ansible中文权威指南  
http://ansible-tran.readthedocs.io/en/latest/index.html

介绍了ansible配置中的各参数含义  
https://micorochio.github.io/2017/05/31/ansible-learning-01/

#### 免密连接受控端
实际上就是配置ssh免密码的操作  
1) ansible控制端ssh-keygen生成密钥对---密钥打开口令为空(没有特殊要求的情况下)  
2) ansible控制端ssh-copy-id把自己的公钥上传到受控客户端 或 复制pub公钥里的文本内容到 /${HOME}/.ssh/authorized_keys  
3) 此时ansible控制端sshh登录受控客户端已不需要验证口令.再配置ansible上的hosts项,在条目中指明ansible控制端生成的私钥位置  
至此,ansible免密操作受控客户端完成  
![](/images/0cigNOUXWxWLHctbTkaJ6g95l3EVFXQz.png)
![](/images/0cigNOUXWxTJjR8sa6Qo73LEpenWZb2G.png)

#### 有密码连接受控端
实际的生产环境中, 极大概率是普通用户连接, 需要切换为root提权的情况

以下是使用ansible的su方式, 成为root身份的配置方式之一, 写入inventory清单里的内容

```
[lab]
192.168.10.101 ansible_ssh_user="user" ansible_ssh_port=22 ansible_ssh_pass=user用户的密码 ansible_become=true ansible_become_method=su ansible_become_user=root ansible_become_pass=root用户的密码
192.168.10.102 ansible_ssh_user="user" ansible_ssh_port=22 ansible_ssh_pass=user用户的密码 ansible_become=true ansible_become_method=su ansible_become_user=root ansible_become_pass=root用户的密码

```

在命令行下执行su的操作方式

https://lvii.github.io/system/2020-02-26-ansible-run-command-with-su-root/
```
ansible -i /etc/ansible/lab lab -m shell -a 'id' --become --become-user=root --become-method=su --ask-become-pass
```
--ask-become-pass 是交互方式输入

#### 首次连接免去回答是否添加key到konwn_hosts
在ansible的默认配置文件/etc/ansible/ansible.cfg中  
方法一:  
取消ssh_args 的注释,并且添加 StrictHostKeyChecking＝no  
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking＝no  

方法二:  
取消注释  
host_key_checking = False  

#### playbook的一个简单示例
一个简单的yaml文件的内容  
```
- hosts: lab
  gather_facts: no
  tasks:
      - name: "test_command"
        shell: id; ip a
```
hosts: lab  是执行的对象, lab是预先在inventory定义的分组

gather_facts: no  不执行ansible的fact信息收集, fact信息收集的耗时可达10几秒乃至更高. 有关fact的内容单独列出

tasks 下的name  任务名称, 用于后续了解进度时的显示  
tasks 下的shell  执行的模块名称, 这里选择的是ansible的shell模块

#### playbook将执行回显显示出来
https://www.codenong.com/20563639/

```
- hosts: lab
  gather_facts: no
  tasks:
      - name: "test_command"
        shell: id; ip a
        register: output
      - debug: var=output.stdout_lines

```
在目标任务增加一项  
register: output  register是使用变量来存放输出, output是自定义的变量名称

&nbsp;
接下另起一行, 精简内容就不用起任务名  
debug: var=output.stdout_lines  
debug 是模块名称, 将output的stdout_lines赋给var, 而这个过程就能触发debug打印其内容.

显示的内容样式如下:  
![](/images/0cigNOUXWxw5cYmvLfIuTq2p31GRHA0Q.png)

#### playbook 加速执行的几个技巧
http://github.com/jlafon/ansible-profile

***关闭 gathering facts***  
yaml执行对象下添加
```
gather_facts: no
```

***启用SSH PIPElinING***  
SSH PIPElinING 是一个加速 Ansible 执行速度的简单方法  
它ansible.cfg里的注释如下:  
```
Enabling pipelining reduces the number of SSH operations required to
execute a module on the remote server. This can result in a significant
performance improvement when enabled, however when using "sudo:" you must
first disable 'requiretty' in /etc/sudoers

By default, this option is disabled to preserve compatibility with
sudoers configurations that have requiretty (the default on many distros).
```

***启用ControlPersist***  
ControlPersist 即持久化 socket，一次验证，多次通信

注意是ssh客户端, 也就是ansible的server所在机器上的ssh_config

```
cat ~/.ssh/config
 Host *
  Compression yes
  ServerAliveInterval 60
  ServerAliveCountMax 5
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 4h
```

新增的是 ```ControlPersist 4h```

#### 为playbook 增加一个显示执行时间的插件
https://github.com/jlafon/ansible-profile

ansible 2.0 已内置, 只需要在ansible.cfg 中启用
```
callback_whitelist = profile_tasks
```

ansible 1.x 里的用法是, 下载这个python脚本, 在你的playbook所在的目录下, 新建一个callback_plugins 目录, 并放入这个python脚本
```
mkdir callback_plugins
cd callback_plugins
wget https://raw.githubusercontent.com/jlafon/ansible-profile/master/callback_plugins/profile_tasks.py
```

#### ansible配置文件ansible.cfg参数含义
```
# (扩展插件存放目录)
action_plugins = /usr/share/ansible_plugins/action_plugins

# (插入Ansible模板的字符串)
ansible_managed = Ansible managed: {file} modified on %Y-%m-%d %H:%M:%S by {uid} on {host}

# （PlayBook是否需要提供密码，默认为No）
# ask_pass=True

# （PlayBook是否需要提供sudo 密码）
# ask_sudo_pass=True

# （回调函数插件存放路径）
action_plugins = /usr/share/ansible_plugins/action_plugins

# （连接插件存放路径）
action_plugins = /usr/share/ansible_plugins/action_plugins

# （是否展示警告信息）
deprecation_warnings = True

# （是否展示跳过的主机的信息）
# display_skipped_hosts=True

# （执行错误时候赋予的变量）
# error_on_undefined_vars=True

# （默认的Shell）
# executable = /bin/bash

# （拦截器插件）
action_plugins = /usr/share/ansible_plugins/action_plugins

# （最大进程数）
forks=5

# （哈希特性，没事不用去动它）
# hash_behavior=replace

# （资产文件存放位置）
hostfile = /etc/ansible/hosts

# （是否检查SSH key）
host_key_checking=True

# （JinJa扩展）
jinja2_extensions = jinja2.ext.do,jinja2.ext.i18n

# （PlayBook变量）
legacy_playbook_variables = no

# （Ansible默认库）
library = /usr/share/ansible

# （日志路径）
log_path=/var/log/ansible.log

# （插件路径）
action_plugins = /usr/share/ansible_plugins/action_plugins

# （默认模块名称）
module_name = command

# (输出样式)
nocolor=0

# (是否使用cowsay打印)
nocows=0

# （主机）
hosts=*

# （pool间隔）
poll_interval=15

# （私钥的存放路径）
private_key_file=/path/to/file.pem

# （远程连接端口号）
remote_port = 22

# (远程目录临时文件夹)
remote_temp = $HOME/.ansible/tmp

# （远程用户）
remote_user = root

# （角色路径）
roles_path = /opt/mysite/roles

# （SUDO执行）
sudo_exe=sudo

# （SUDO标记）
sudo_flags=-H

# （sudo用户）
sudo_user=root

# （重连次数）
timeout = 10

# （传输模式） 默认用的smart
transport

# （变量插件存放路径）
action_plugins = /usr/share/ansible_plugins/action_plugins

# SSH变量

# (SSH连接参数)
ssh_args = -o ControlMaster=auto -o ControlPersist=60s

# （采用SCP还是SFTP进行文件传输）
scp_if_ssh=False
```