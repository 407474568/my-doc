* [目录](#0)
  * [Python 时间格式处理](#1)
  * [Python 常用异常处理](#2)


<h3 id="1">Python 时间格式处理</h3>

https://juejin.cn/post/6844903859257622541  
https://www.cnblogs.com/xuchunlin/p/5920549.html  
https://blog.csdn.net/google19890102/article/details/51355282  
https://blog.csdn.net/mighty13/article/details/78147357  

关于strptime, Python的Doc已经说得很明确了, 在大规模使用的情况下, 应避免使用它--性能问题  
https://python3-cookbook.readthedocs.io/zh_CN/latest/c03/p15_convert_strings_into_datetimes.html  
假设日期格式是 YYYY-MM-DD  
它的意思是让你直接构建datietime格式的数据  

```
from datetime import datetime
def parse_ymd(s):
    year_s, mon_s, day_s = s.split('-')
    return datetime(int(year_s), int(mon_s), int(day_s))
```

究竟strptime会比直接构建datietime格式数据的方式慢上多少?  
以下测试在AMD Ryzen 3700X 处理器上执行, 每个测试项循环100万次

```
>>> start_time = time.time()
>>> a = "2011-09-28 10:00:00"
>>> for i in range(1000000):
...     var = time.strptime(a,'%Y-%m-%d %H:%M:%S')
...
>>> end_time = time.time()
>>> print(str(end_time - start_time) + "秒")
7.145048141479492秒
>>>
>>>
>>>
>>> start_time = time.time()
>>> a = "2011-09-28 10:00:00"
>>> for i in range(1000000):
...     var = datetime.strptime(a,'%Y-%m-%d %H:%M:%S')
...
>>> end_time = time.time()
>>> print(str(end_time - start_time) + "秒")
7.07616662979126秒
>>>
>>>
>>>
>>> start_time = time.time()
>>> a = "2011-09-28 10:00:00"
>>> for i in range(1000000):
...     year_s, mon_s, day_s = a.split(' ')[0].split('-')
...     var = datetime(int(year_s), int(mon_s), int(day_s))
...
>>> end_time = time.time()
>>> print(str(end_time - start_time) + "秒")
0.8247499465942383秒
>>>
```

由此可见与官方文档所说的相差7倍多大致一致  
并且不管datetime还是time下strptime函数, 性能并没有太明显的区别


<font color=red>time模块下的函数作用</font>

- strptime()函数将时间转换成时间数组  
- mktime()函数将时间数组转换成时间戳  

```
#coding:UTF-8
import time

dt = "2016-05-05 20:28:54"

#转换成时间数组
timeArray = time.strptime(dt, "%Y-%m-%d %H:%M:%S")
#转换成时间戳
timestamp = time.mktime(timeArray)

print timestamp
```

<font color=red>字符串转时间戳</font>

```
#设a为字符串
import time
a = "2011-09-28 10:00:00"

#中间过程，一般都需要将字符串转化为时间数组
time.strptime(a,'%Y-%m-%d %H:%M:%S')
>>time.struct_time(tm_year=2011, tm_mon=9, tm_mday=27, tm_hour=10, tm_min=50, tm_sec=0, tm_wday=1, tm_yday=270, tm_isdst=-1)

#将"2011-09-28 10:00:00"转化为时间戳
time.mktime(time.strptime(a,'%Y-%m-%d %H:%M:%S'))
>>1317091800.0

#将时间戳转化为localtime
x = time.localtime(1317091800.0)
time.strftime('%Y-%m-%d %H:%M:%S',x)
>>2011-09-27 10:50:00
```


<font color=red>数字型的时间戳转为Python内的时间戳格式</font>  

例如: 1612236538, 用到  
time.localtime  ---> 把数字转为时间元组

```
>>> time.localtime(1612236538)
time.struct_time(tm_year=2021, tm_mon=2, tm_mday=2, tm_hour=11, tm_min=28, tm_sec=58, tm_wday=1, tm_yday=33, tm_isdst=0)
```

时间元组不可做运算

```
>> time.localtime(1612236538) - time.localtime(1612236539)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: unsupported operand type(s) for -: 'time.struct_time' and 'time.struct_time'
>>>
```

如果是再将这个时间戳转到"YYYY-MM-DD HH:MM:SS"格式

```
>>> time_format = time.localtime(1612236538)
>>> time.strftime("%Y-%m-%d %H:%M:%S", time_format)
'2021-02-02 11:28:58'
>>>
```


<h3 id="2">Python 常用异常处理</h3>

https://docs.python.org/3/tutorial/errors.html  

python 内置的错误类型不必多说, 参考相关文档作了解.

以下示例是一个需要捕获的错误理由不在 error类型里, 而是在error详细理由里.

因此, 处理办法仅仅是将此 类对象 转换成 str 类型.

```
try:
    self.zbx_obj.send(item)
except Exception as error_reason:
    if re.search(r"Network is unreachable", str(error_reason)):
        print("Zabbix Server 网络不可达, 忽略此错误")
```
