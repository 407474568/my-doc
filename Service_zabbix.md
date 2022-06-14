### 官网  


### 几个手册性质的网站


* [目录](#0)
  * [py-zabbix的调试](#1)



<h3 id="1">py-zabbix的调试</h3>

```
import sys
import logging
from pyzabbix import ZabbixAPI

stream = logging.StreamHandler(sys.stdout)
stream.setLevel(logging.DEBUG)
log = logging.getLogger('pyzabbix')
log.addHandler(stream)
log.setLevel(logging.DEBUG)

<py-zabbix 进行 send 的业务代码>
```



