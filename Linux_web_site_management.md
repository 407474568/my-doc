* [目录](#0)
  * [acme 自动化管理 Web 站点证书](#1)


<h3 id="1">acme 自动化管理 Web 站点证书</h3>

Google对HTTPS的推动是一个长期过程：
- **2014年**：启动大规模推广，将HTTPS作为安全基础。
- **2017年**：HTTPS普及率显著提升，成为行业标准。
- **2021年**：Chrome默认启用HTTPS，强化用户安全体验。
- **2023年**：自动升级HTTP到HTTPS，进一步淘汰不安全协议。

对于个人或无相关预算的组织, ACME 无疑是自动化管理 SSL 证书的最佳选择

**ACME**（Automatic Certificate Management Environment）是一个自动化管理SSL/TLS证书的协议，主要作用是让网站轻松实现HTTPS加密，保障数据安全。它的核心功能包括：

1. **自动申请证书**：  
   帮助服务器自动生成证书请求，并与证书颁发机构（CA）交互，无需手动操作。

2. **验证域名所有权**：  
   通过HTTP、DNS或TLS等方式，自动证明你拥有目标域名的控制权（例如自动添加验证文件或DNS记录）。

3. **自动颁发和续期**：  
   验证通过后，证书会自动颁发并安装到服务器；在证书过期前（如Let's Encrypt的90天有效期），自动续期，避免服务中断。

4. **简化管理**：  
   支持批量管理多个域名证书，减少人工干预，降低错误风险，尤其适合大规模网站或云服务。

**举例**：像Let's Encrypt这样的免费CA，配合工具（如Certbot、acme.sh），通过ACME协议，几分钟内就能为你的网站自动部署HTTPS证书，全程无需手动操作。



#### ACME的脚本获取  
https://github.com/acmesh-official/acme.sh

#### FreeSSL.cn 与之搭配的证书申请站点
https://freessl.cn/automation/auth

#### 新手入门
https://blog.freessl.cn/acme-quick-start/

#### 概述性的总结ACME自动管理Web站点SSL证书的流程

1) 在你的域名服务商那里创建该域名的解析记录(A记录或CNAME记录)
2) 在 FreeSSL.cn 添加对应的证书申请(需要向FreeSSL.cn证明你对该域名的所有权)
3) 在你的域名服务商, 根据 FreeSSL.cn 给出的内容, 添加对应的记录, 以证明你对该域名的所有权
4) FreeSSL.cn 验证DCV通过, 提供ACME的证书申请命令给你
5) 由你具体站点的运行方式(nginx/apache/容器内的web站点), 安装证书到正确的位置
6) 验证结果


