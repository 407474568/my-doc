https://muyuuuu.github.io/2020/01/07/python-create-and-call-variables-batches/  
https://www.cnblogs.com/dcb3688/p/4347688.html  

�ڱ����һ��������������һ����������, ��ʱ�������һ���򻯵Ĳ�����Ȼǿ���������ճ��  
�������л������ı���: user_var1, user_var2, user_var3 ....�Դ�����  

��Python��Ĳ�������, �к����������෽��֮��

#### ��������
��python��ʹ�ñ���ʱ���ᰴ������Ĳ���ȥ������
1����������ľֲ�������  
2��ȫ�ֱ�����  
3�����ñ�����  
�����������裬����һ�²����ҵ���Ӧ�ı������Ͳ����������ҡ���������������趼�Ҳ������ͻ��׳��쳣��  

ʹ�� locals() ����  
```
for i in range(3):
    locals() ['x' + str(i)] = i

for j in range(3):
    print(locals() ['x' + str(j)])
print(x0)
```
x ���Ǳ������Ƶ�ǰ׺����
���������ɵ�0, 1, 2��Ϊ�����ĺ�벿��
�Ӷ��õ�x0, x1, x2 ��������

#### �෽��
locals() ��Ϊpython�����������÷���, �ں���ʽ����ǿ��������, ��������������򲻿���.  

����������ϵ�һ�ַ�����, ʹ���ֵ�, ����ֵ���Ϊʵ������
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