* [目录](#0)
  * [实例演示notify, listen, regsiter用法](#1)

<h3 id="1">实例演示notify, listen, regsiter用法</h3>
参考:  
https://blog.csdn.net/byygyy/article/details/87822468  
https://blog.51cto.com/jiayimeng/2587601  
https://stackoverflow.com/questions/63719445/how-to-use-the-yum-module-to-clean-and-make-cache-the-yum-repo-in-ansible  
https://stackoverflow.com/questions/61490702/ansible-debug-msg-throws-error-inside-handler  

```
---
- name: 安装所有主机通用的基础软件
  hosts: temp
  tasks:
  - name: 获取初始化的repo
    find:
      path: /etc/yum.repos.d
      pattern: CentOS-*
    register: need_to_delete

  - name: 删除初始化的repo
    file:
      name: "{{ item.path }}"
      state: absent
    with_items: "{{ need_to_delete.files }}"

  - name: 添加清华base源
    yum_repository: 
      name: base
      description: base-repo
      state: present
      enabled: yes
      baseurl: https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/os/$basearch/
    when: ansible_distribution == "RedHat" or ansible_distribution == "CentOS"
    notify: yum_makecache

  - name: 添加清华EPEL源
    yum_repository: 
      name: epel
      description: epel-repo
      state: present
      enabled: yes
      baseurl: https://mirrors.tuna.tsinghua.edu.cn/epel/$releasever/$basearch
    when: ansible_distribution == "RedHat" or ansible_distribution == "CentOS"
    notify: yum_makecache

  handlers:
  - name: yum_makecache
    shell: yum clean all;yum makecache
    args:
      warn: false
    register: output
  - debug: msg="{{ output.stdout_lines }}"
    listen: yum_makecache
```
1) find 按规则查找对象, 参数是path和pattern
2) register 存放find查找出的结果列表
3) 使用file模块进行删除, 迭代方法使用的with_items的形式, 在playbook里的变量应用形式 ```"{{ need_to_delete.files }}"``` \
之所以有.files属性是使用的find模块决定的
4) yum_repository 模块没有特别值得描述的, notify 的特性在于, 只有 "name: 添加清华base源" 这个代码块发生实际更改后才会调用 notify 的对象
5) handlers 的代码块内容, 在这里为了自定义处理什么样的操作, 比如 ```yum makecache``` 就是ansible不包含的功能,
6) debug 在其他模块内使用没有值得特别讲述的要点, 但在handlers 里实测发现debug 的内容未被执行, 通过增加 listen 项得以解决

