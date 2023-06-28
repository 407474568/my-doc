* [目录](#0)
  * [Python-语法糖-动态生成变量](#1)
  * [反射与自省(内省)](#2)
  * [Python类的继承](#3)


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


<h3 id="3">Python类的继承</h3>

https://blog.csdn.net/yilulvxing/article/details/85374142  

全文摘录如下  

5个模块：  
（1）：直接调用父类属性方法  
（2）：重写父类属性方法  
（3）：强制调用父类私有属性方法  
（4）：调用父类的__init__方法  
（5）：继承父类初始化过程中的参数

（1）调用父类属性方法

```
class Father():
    def __init__(self):
        self.a='aaa'  
    def action(self):
        print('调用父类的方法')
 
class Son(Father):
    pass
 
son=Son()     # 子类Son 继承父类Father的所有属性和方法
son.action()  # 调用父类方法
son.a         # 调用父类属性
```

输出结果:

```
"C:\Program Files\Python310\python.exe" D:\test.py 
调用父类的方法

Process finished with exit code 0
```

（2）重写父类属性方法

注意：在上面的例子中，子类Son没有属性和action的方法，所以会从父类调用，那我们再来看看，子类Son有自身的属性和方法的结果是怎样的？

```
class Father():
    def __init__(self):
        self.a='aaa'
    
    def action(self):
        print('调用父类的方法')
 
class Son(Father):
    def __init__(self):
        self.a='bbb'
    def action(self):
        print('子类重写父类的方法')
 
son=Son()     # 子类Son继承父类Father的所有属性和方法
son.action()  # 子类Son调用自身的action方法而不是父类的action方法
son.a
```

输出结果

```
"C:\Program Files\Python310\python.exe" D:\test.py 
子类重写父类的方法

Process finished with exit code 0
```

这里，子类Son已经重写了父类Father的action的方法，并且子类Son也有初始化，因此，子类会调用自身的action方法和属性。总结：如果子类没有重写父类的方法，当调用该方法的时候，会调用父类的方法，当子类重写了父类的方法，默认是调用自身的方法。

另外，如果子类Son重写了父类Father的方法，如果想调用父类的action方法，可以利用super()

```
#如果在重新父类方法后，调用父类的方法
class Father():
    def action(self):
        print('调用父类的方法')
 
class Son(Father):
    def action(self):
        super().action()
son=Son()
son.action() 
```

输出结果

```
"C:\Program Files\Python310\python.exe" D:\test.py 
调用父类的方法

Process finished with exit code 0
```

（3）强制调用父类私有属性方法

如果父类的方法是私有方法,如 def __action(self)  这样的话再去调用就提示没有这个方法,其实编译器是把这个方法的名字改成了 _Father__action(),如果强制调用,可以这样:

```
class Father():
    def __action(self):  # 父类的私有方法
        print('调用父类的方法')
 
class Son(Father):
    def action(self):
        super()._Father__action()
son=Son()
son.action()
```

输出结果

```
"C:\Program Files\Python310\python.exe" D:\test.py 
调用父类的方法

Process finished with exit code 0
```

（4）调用父类的__init__方法

如果自己也定义了 __init__ 方法,那么父类的属性是不能直接调用的，比如下面的代码就会报错

```
class Father():
    def __init__(self):
        self.a=a
 
class Son(Father):
    def __init__(self):
        pass
    
son=Son()
print(son.a)
```

输出结果

```
"C:\Program Files\Python310\python.exe" D:\test.py 
Traceback (most recent call last):
  File "D:\test.py", line 12, in <module>
    print(son.a)
AttributeError: 'Son' object has no attribute 'a'

Process finished with exit code 1
```

修改方法：可以在 子类的 __init__中调用一下父类的 __init__ 方法,这样就可以调用了

```
class Father():
    def __init__(self):
        self.a='aaa'
 
class Son(Father):
    def __init__(self):
        super().__init__()
        #也可以用 Father.__init__(self)  这里面的self一定要加上
son=Son()
print(son.a) 
```

输出结果

```
"C:\Program Files\Python310\python.exe" D:\test.py 
aaa

Process finished with exit code 0
```

（5）继承父类初始化过程中的参数

```
class Father():
    def __init__(self):
        self.a=1
        self.b=2
 
class Son(Father):
    def __init__(self):
        super().__init__()
        #也可以用 Father.__init__(self)  这里面的self一定要加上
    def add(self):
        return self.a+self.b
son=Son()
print(son.add())
```

输出结果

```
"C:\Program Files\Python310\python.exe" D:\test.py 
3

Process finished with exit code 0
```

上述代码中，父类在初始化过程中，直接对a，b分别赋值1,2。子类利用super().__init__()继承了父类的初始化参数a和b，所以子类调用自身的add函数（add函数返回a和b的和）会返回结果值。

再看一下，如果不对父类初始化直接赋值，并且子类在调用父类初始化过程中，增加额外自身需要的初始化参数值。

说明：三个参数a,b,c，其中a,b来自父类初始化参数，c表示子类初始化参数，但又分为两种情况：

1）：参数c为初始化默认参数，如下面的5.1代码中Son(1,2)，参数1,2分别表示a,b的值，默认为c=10，即等于：Son(1,2,10)，表明初始化传参过程中c可以不写

2）：显式地将初始化参数c修改为其他值，如下面的5.2代码中Son(1,2,1)，参数值1,2,1分别表示a,b,c的值，即显式地将c=1传入

具体代码如5.1 ， 5.2所示，对比查看：

```
class Father():
    def __init__(self,a,b):
        self.a = a
        self.b = b
    def dev(self):
        return self.a - self.b
 
 #调用父类初始化参数a,b并增加额外参数c
class Son(Father):
    def __init__(self,a,b,c=10):  # 固定值： 例如默认c=10，也可以显示地将c赋值
        Father.__init__(self,a,b)  
        self.c = c
    def add(self):
        return self.a+self.b
    def compare(self):
        if self.c > (self.a+self.b):
            return True
        else:
            return False
        
son=Son(1,2)         # 由于c在初始化过程中默认为10，所以c可以不用显示表达出来
print(son.dev())     # 调用父类dev函数
print(son.add())     # 子类自身add函数
print(son.compare()) # 子类自身compare函数
```

返回结果：

```
"C:\Program Files\Python310\python.exe" D:\test.py 
-1
3
True

Process finished with exit code 0
```

如果将上述5.1代码中，修改c为其他参数值（非默认值），改成显式地将c值传入

```
class Father():
    def __init__(self,a,b):
        self.a = a
        self.b = b
    def dev(self):
        return self.a - self.b
 
 #调用父类初始化参数a,b并增加额外参数c
class Son(Father):
    def __init__(self,a,b,c=10):  # 固定值： 例如默认c=10，也可以显式地将c赋值
        Father.__init__(self,a,b)  
        self.c = c
    def add(self):
        return self.a+self.b
    def compare(self):
        if self.c > (self.a+self.b):
            return True
        else:
            return False
        
son=Son(1,2,1)     #  显式地将c=1传入子类初始化函数
print(son.dev())     # 调用父类dev函数
print(son.add())     # 子类自身add函数
print(son.compare()) # 子类自身compare函数
```

输出结果

```
"C:\Program Files\Python310\python.exe" D:\test.py 
-1
3
False

Process finished with exit code 0
```

另

Python类的实例化，封装，继承，私有变量和私有方法  
https://blog.csdn.net/yilulvxing/article/details/85544382

Python-实例方法静态方法类方法对比总结  
https://blog.csdn.net/yilulvxing/article/details/84892416
