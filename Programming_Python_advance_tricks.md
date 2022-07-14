* [目录](#0)
  * [Python-语法糖-动态生成变量](#1)
  * [反射与自省(内省)](#2)


<h3 id="1">Python-语法糖-动态生成变量</h3>

https://muyuuuu.github.io/2020/01/07/python-create-and-call-variables-batches/

https://www.cnblogs.com/dcb3688/p/4347688.html  

在编程中一定会有遇到操作一组变量的情况, 这时候如果有一个简化的操作显然强于逐个复制粘贴  
例如序列化命名的变量: user_var1, user_var2, user_var3 ....以此类推  

在Python里的操作方法, 有函数方法和类方法之分

#### 函数方法
当python在使用变量时，会按照下面的步骤去搜索：
1、函数或类的局部变量。  
2、全局变量。  
3、内置变量。  
以上三个步骤，其中一下步骤找到对应的变量，就不会再往下找。如果在这三个步骤都找不到，就会抛出异常。  

使用 locals() 方法  
```
for i in range(3):
    locals() ['x' + str(i)] = i

for j in range(3):
    print(locals() ['x' + str(j)])
print(x0)
```
x 就是变量名称的前缀部分
迭代器生成的0, 1, 2作为变量的后半部分
从而得到x0, x1, x2 三个变量

#### 类方法
locals() 作为python解释器的内置方法, 在函数式编程是可以满足的, 在面向对象编程上则不可行.  

面向对象编程上的一种方法是, 使用字典, 这个字典作为实例属性
```
class test(object):
    def __init__(self):
        self.d = {}
        for i in range(3):
            self.d['x' + str(i)] = i
    def run(self):
        for i in range(3):
            a = self.d['x' + str(i)]
            print(a)

asd = test()
asd.run()
```

<h3 id="2">反射与自省(内省)</h3>

内省-维基百科  
[维基百科](https://zh.wikipedia.org/wiki/%E5%86%85%E7%9C%81_(%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%A7%91%E5%AD%A6))

反射-维基百科  
[维基百科](https://zh.wikipedia.org/wiki/%E5%8F%8D%E5%B0%84_(%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%A7%91%E5%AD%A6))

基本概念  
https://www.cnblogs.com/Yunya-Cnblogs/p/13114684.html  
https://www.cnblogs.com/huxi/archive/2011/01/02/1924317.html  

操作  
https://www.cnblogs.com/vipchenwei/p/6991209.html

在python中, 通过4个内置函数进行
1. getattr(object, name[, default])
2. hasattr(object, name)
3. setattr(object, name, value)
4. delattr(object, name)
