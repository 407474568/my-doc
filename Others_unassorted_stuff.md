* [目录](#0)
  * [IPMI 命令列表](#1)
  * [PCI-E 版本与对应速率](#2)

<h3 id="1">IPMI 命令列表</h3>

引用自  
https://www.cnblogs.com/zhangxinglong/p/10529877.html


<table>
    <tr>
        <th>命令集</th><th>命令行格式</th><th>命令行说明</th>
    </tr>
    <tr>
        <td rowspan="8">User</td><td>ipmitool -H &#60;IP地址&#62; -I lanplus -U &#60;用户名&#62; -P &#60;密码&#62; user summary</td><td>查询用户概要信息</td>
    </tr>
    <tr>
        <td>ipmitool -H &#60;IP地址&#62; -I lanplus -U &#60;用户名&#62; -P &#60;密码&#62; user list</td><td>查询BMC上所有用户</td>
    </tr>
    <tr>
        <td>ipmitool -H &#60;IP地址&#62; -I lanplus -U &#60;用户名&#62; -P &#60;密码&#62; user set name &#60;用户ID&#62; &#60;用户名&#62;</td><td>设置用户名</td>
    </tr>
</table>


<h3 id="2">PCI-E 版本与对应速率</h3>

| PCI Express 版本 | 编码方案 | 传输速率 | x1 | x4 | x8 | x16 | 
| --- | --- |---------------|-----------------| --- | ---- | --- | 
| 1.0 | 8b/10b | 2.5GT/s       | 250MB/s         | 1GB/s | 5 GB/s | 4GB/s | 
| 2.0 | 8b/10b | 5GT/s         | 500MB/s         | 2GB/s | 4GB/s | 8GB/s | 
| 3.0 | 128b/130b | 8GT/s         | 984.6MB/s       | 3.938GB/s |7.877GB/s | 15.754GB/s | 
| 4.0 | 128b/130b | 16GT/s        | 1.969GB/s       | 7.877GB/s | 15.754GB/s | 31.508GB/s | 
| 5.0 | 128b/130b | 32 or 25 GT/s | 3.9 or 3.08GB/s | 15.8 or 12.3 GB/s	| 31.5 or 244.6GB/s	| 63.0 or 49.2GB/s | 

