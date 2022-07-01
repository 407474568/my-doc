* [目录](#0)
  * [IPMI 命令列表](#1)

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
