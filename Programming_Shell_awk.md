#### awk 里的单引号,双引号问题

https://segmentfault.com/q/1010000041476037

在 awk 里, 一旦需要用到的单引号, 双引号嵌套的层数多了, 就变得容易出错,还不方便调试.

>最外层要么使用单引号（避免字符串里面的命令替换$(xxx)被提前解析），要想使用双引号的话，里面的$需要转义处理\$（也是避免被解析）
>
>另外你需要考虑引号嵌套的问题，简单来说最外层是单引号，里面最好都用双引号；反之最外层是双引号，里面全用单引号。
>
>最外层是双引号时，在其他场合你还需要考虑各种转义，建议还是外层单引号省心。

与链接中帖子讨论的内容比较一致, 我个人总结的经验也是如下:

- awk 最外层, 使用单引号 '
- 除最外层之外的, 都使用双引号 "
- 在双引号也有嵌套的情况, 也就是双引号内里还需要包裹双引号, 那么内里的双引号使用 \ 号转义
- 以上也就是最多3层嵌套, 如果嵌套层数更多, 那还是老老实实转函数吧


#### 按行过滤

https://www.itranslater.com/qa/details/2125844298871604224  

需求的起源是, sort 命令做排序, 但首行可能是标题行, 不希望参与排序.  
发现实现的方法用到管道符和awk  
回答中的示例

```
# awk 的方法
extract_data | awk 'NR<3{print $0;next}{print $0| "sort -r"}' 

# 这两种当然也算另一种思路
(read -r; printf "%s\n" "$REPLY"; sort)
(head -n 2 <file> && tail -n +3 <file> | sort) > newfile
```

在我的例子中

```
alias dockerimage="docker image ls | awk 'NR<2{print \$0;next}{print \$0| \"sort\"}'"
```

第2个例子, 同样是利用 awk 的 if...else 语句:

https://www.v2ex.com/t/612650

```goodlucky37``` 的回答

> 这个我想到的方法时可以通过 awk 的"if-else"或条件语句实现：  
command | awk 'NR==1 {print $0};NR!=1 {print $0 | "sort xxx"}'  
eg：  
ps -fxo user,ppid,pid,pgid,command | awk 'NR==1 {print $0};NR!=1 {print $0 | "sort -k4,4nr"}'

我的示例

```
\df -T -B 1G | grep -v -E -e "^(dev)?tmpfs" -e "\boverlay\b"  | awk 'NR==1 {print $0};NR!=1 {print $0 | "sort -k 7"}'
```

#### awk 筛选数据输出
针对数据文件，利用awk 判断符合条件的数据，并筛选出结果数据，输入到对应的文件中。
```
awk '{if ($7>5) print}' A|less           ###筛选A文件中第七列大于5的数据，显示所有符合的结果
awk '{if ($6>5 && $7>5) print}' A|less   ###筛选A文件中第六列和七列都大于5的数据，显示所有符合的结果
awk '{if ($6>5 || $7>5) print}' A|less   ###筛选A文件中第六列或七列都大于5的数据，显示所有符合的结果
awk '{if ($7>5) print}' A|less>B         ###筛选A文件中第七列大于5的数据，并将符合的结果输入到B文件中
```

排除筛选的例子  
https://www.cnblogs.com/chenwenyan/p/8580654.html  
https://segmentfault.com/q/1010000006687483  
以下两种方式都能实现排除以"NAME"为关键字, 且限定在行首或者第一列
```
[root@storage ~]# zpool list
NAME             SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
SAS-4T-group01  40.0T  18.2T  21.8T        -         -     0%    45%  1.00x  DEGRADED  -
my-pool         21.8T  8.32T  13.5T        -         -     0%    38%  1.00x    ONLINE  -
[root@storage ~]# zpool list | awk '!/^NAME/{print $1}'
SAS-4T-group01
my-pool
[root@storage ~]# zpool list | awk '{if($1!="NAME"){print $1}}'
SAS-4T-group01
my-pool
[root@storage ~]# 
```

#### 内置算数函数

https://www.omicsclass.com/article/471  
取对数  
awk 具有内置算术函数log(x)，以e 为底可以对数据取对数运算，而以其他数值为底进行取对数可以基于这一函数进行转换，譬如  以2为底取对数： log(x)/log(2)即可。  

```
[root@3700X ~]# echo 48 | awk '{print (log($1)/log(2))}'
5.58496
[root@3700X ~]# echo 24 | awk '{print (log($1)/log(2))}'
4.58496
[root@3700X ~]# echo 88 | awk '{print (log($1)/log(2))}'
6.45943
[root@3700X ~]# echo 32 | awk '{print (log($1)/log(2))}'
5
```

#### awk进行浮点计算
https://blog.51cto.com/radish/1736900  
典型示例:
```
echo "$A $B $C $D" | awk '{printf ("%.2f\n",$1*$2/$3-$4)}'
``` 
awk以传参形式接收, 等同shell的函数调用,格式控制由prinft 来完成
也支持科学计数法的形式
```
[wangdong@centos715-node1 uncomp]$ echo "6.8923e+08" | awk '{printf ("%.0f\n",$1)}'
689230000
```

传参变量的用法

```
[wangdong@centos715-node1 ~]$ A=5
[wangdong@centos715-node1 ~]$ B=16
[wangdong@centos715-node1 ~]$ C=29
[wangdong@centos715-node1 ~]$ D=6
[wangdong@centos715-node1 ~]$ echo "$A $B $C $D" | awk '{printf ("%.2f\n",$1*$2/$3-$4)}'
-3.24
[wangdong@centos715-node1 ~]$ echo "$A $B $C $D" | awk '{printf ("%.2f\n",$1/$4)}'      
0.83
[wangdong@centos715-node1 ~]$ echo "$A $B $C $D" | awk '{printf ("%.3f\n",$1/$4)}'
0.833
```

#### awk中RS,ORS,FS,OFS 的作用
http://blog.51yip.com/shell/1151.html  
一，RS与ORS  
1，RS是记录分隔符，默认的分隔符是\n，具体用法看下
```
[root@krlcgcms01 mytest]# cat test1     //测试文件  
 111 222  
 333 444  
 555 666  
```
2，RS默认分割符是 \n
```
[root@krlcgcms01 mytest]# awk '{print $0}' test1  //awk 'BEGIN{RS="\n"}{print $0}' test1 这二个是一样的  
111 222  
333 444  
555 666  
```
其实你可以把上面test1文件里的内容理解为，111 222\n333 444\n555 6666，利用\n进行分割。看下一个例子  
3，自定义RS分割符
```
[zhangy@localhost test]$ echo "111 222|333 444|555 666"|awk 'BEGIN{RS="|"}{print $0,RT}'  
 111 222 |  
 333 444 |  
 555 666
```  
结合上面一个例子，就很容易理解RS的用法了。

4，RS也可能是正则表达式
```
[zhangy@localhost test]$ echo "111 222a333 444b555 666"|awk 'BEGIN{RS="[a-z]+"}{print $1,RS,RT}'  
 111 [a-z]+ a  
 333 [a-z]+ b  
 555 [a-z]+
```  
从例3和例4，我们可以发现一点，当RT是利用RS匹配出来的内容。如果RS是某个固定的值时，RT就是RS的内容。

5，RS为空时
```
[zhangy@localhost test]$ cat -n test2  
 1  111 222  
 2  
 3  333 444  
 4  333 444  
 5  
 6  
 7  555 666  
 
[zhangy@localhost test]$ awk 'BEGIN{RS=""}{print $0}' test2  
111 222  
333 444  
333 444  
555 666  

[zhangy@localhost test]$ awk 'BEGIN{RS="";}{print "<",$0,">"}' test2  //这个例子看着比较明显  
< 111 222 >  
< 333 444     //这一行和下面一行，是一行  
333 444 >  
< 555 666 >
```  
从这个例子，可以看出当RS为空时，awk会自动以多行来做为分割符。

6，ORS记录输出分符符，默认值是\n

把ORS理解成RS反过程，这样更容易记忆和理解，看下面的例子。
```
[zhangy@localhost test]$ awk 'BEGIN{ORS="\n"}{print $0}' test1  //awk '{print $0}' test1二者是一样的  
111 222  
333 444  
555 666  
[zhangy@localhost test]$ awk 'BEGIN{ORS="|"}{print $0}' test1  
111 222|333 444|555 666|  
```
二，FS与OFS

1，FS指定列分割符
```
[zhangy@localhost test]$ echo "111|222|333"|awk '{print $1}'  
 111|222|333  
[zhangy@localhost test]$ echo "111|222|333"|awk 'BEGIN{FS="|"}{print $1}'  
 111  
 ```
2，FS也可以用正则
```
[zhangy@localhost test]$ echo "111||222|333"|awk 'BEGIN{FS="[|]+"}{print $1}'  
111  
```
3，FS为空的时候
```
[zhangy@localhost test]$ echo "111|222|333"|awk 'BEGIN{FS=""}{NF++;print $0}'  
1 1 1 | 2 2 2 | 3 3 3  
```
当FS为空的时候，awk会把一行中的每个字符，当成一列来处理。

4，RS被设定成非\n时，\n会成FS分割符中的一个

```
[zhangy@localhost test]$ cat test1  
 111 222  
 333 444  
 555 666  
[zhangy@localhost test]$ awk 'BEGIN{RS="444";}{print $2,$3}' test1  
 222 333  
 666  
 ```
222和333之间是有一个\n的，当RS设定成444后，222和333被认定成同一行的二列了，其实按常规思想是二行的一列才对。

5，OFS列输出分隔符

```
[zhangy@localhost test]$ awk 'BEGIN{OFS="|";}{print $1,$2}' test1  
 111|222  
 333|444  
 555|666  
[zhangy@localhost test]$ awk 'BEGIN{OFS="|";}{print $1 OFS $2}' test1  
 111|222  
 333|444  
 555|666  
 ```
test1只有二列，如果100列，都写出来太麻烦了吧。

```
[zhangy@localhost test]$ awk 'BEGIN{OFS="|";}{print $0}' test1  
 111 222  
 333 444  
 555 666  
[zhangy@localhost test]$ awk 'BEGIN{OFS="|";}{NF=NF;print $0}' test1  
 111|222  
 333|444  
 555|666 
 ``` 
为什么第二种方法中的OFS生效呢？个人觉得，awk觉查到列有所变化时，就会让OFS生效，没变化直接输出了。

#### AWK ：8个强大的内置变量
http://blog.chinaunix.net/uid-28903506-id-5211480.html

AWK的内置变量有两种类型：  
（1）. 一种是值可以被修改的变量，例如域分隔符、记录分隔符等。  
（2）.  另一种是被用在处理文本的过程中（记录处理的状态）或是用于统计，例如记录数、域的个数等。

FS 输入域分隔符变量  
awk 从输入中读取和处理每一行，默认是以空格作为分隔符，同时设置变量$1、$2等等。FS 变量的作用是作为每一个记录中的域分隔符。  
FS 的设置有两种方式：  
（1）通过 -F 命令行选项  
```
$ awk -F 'FS' 'commands' inputfilename
```
（2）直接按照普通变量的赋值方式
```
$ awk 'BEGIN{FS="FS";}'
```
注意：
（1）FS 可以被设置为任意的单个字符或正则表达式。  
（2）FS 可以变更任意次，他会一直保持值，直到被显式的修改。如果你需要修改域分隔符，最好在读取一行之前，这样变更就能作用于读取的行。

OFS 输入域分隔符变量  
OFS 作用类似于FS，不过他作用于输出文本，默认值是单个空格字符。
```
$ awk -F':' '{print $3,$4;}' /etc/passwd
41 41
100 101
```

print 语句中的连接符“,”用于使用OFS值来连接两个参数，如果变更OFS设置：
```
$ awk -F':' 'BEGIN{OFS="=";} {print $3,$4;}' /etc/passwd
41=41
100=101
```

RS 输入记录分隔符变量  
RS用于定义一行，而AWK默认即是一行接一行读取的。  
来看一个存储学生分数的文件（记录间以两个换行符分隔，而每一个域通过一个换行符分隔）：
```
$cat student.txt
Jones
2143
78
84
77


Gondrol
2321
56
58
45


RinRao
2122
38
37
65
```

如果要获取学生姓名和第一个分数值，可以使用以下awk脚本：
```
$cat student.awk
BEGIN {
    RS="\n\n";
    FS="\n";
}
{ print $1,$2; }

$ awk -f student.awk  student.txt
Jones 2143
Gondrol 2321
RinRao 2122
```

在以上脚本中，因为RS变量被设置为两个换行符，所以awk读取每一个学生的详细信息作为一个记录。FS 值为换行符，所以记录中的每一行是一个域。

ORS 输出记录分隔符变量
ORS类似RS，他作用于输出。输出时打印每一条记录的同时会打印这个定界符。
```
$  awk 'BEGIN{ORS="=";} {print;}' student-marks
Jones 2143 78 84 77=Gondrol 2321 56 58 45=RinRao 2122 38 37 65=
```

NR 记录个数变量  
NR 给出已处理的记录数或行号。  
下面这个例子中，NR变量保存行号，在awk脚本的END部分，NR变量可以告诉你一个文件中的记录总数。
```
$ awk '{print "Processing Record - ",NR;}END {print NR, "Students Records are processed";}' student-marks
Processing Record -  1
Processing Record -  2
Processing Record -  3
3 Students Records are processed
```

（注：）在处理多个文件时，情况有所不同，NR值会累加，例如第一个文件有10个记录，当处理到第二个文件的第2个记录时，NR值为12

NF 域个数变量  
NF给出一个记录中域的总数。  
NF在判断一个记录中是否所有的域均存在时非常有用。

修改下上面的学生信息文件（第三个记录的第三个分数没有了）：
```
$cat student-marks
Jones 2143 78 84 77
Gondrol 2321 56 58 45
RinRao 2122 38 37
```

看下面脚本的输出：
```
$ awk '{print NR,"->",NF}' student-marks
1 -> 5
2 -> 5
3 -> 4
```

FILENAME 当前输入文件名变量  
FILENAME 变量给出正在被读取的文件名。  
awk是可以接受多个输入文件来处理的。
```
$ awk '{print FILENAME}' student-marks
student-marks
student-marks
student-marks
```
在上面的实例中，在处理文件的每一条记录时，都打印FILENAME，也就是 student-marks。

FNR 当前输入文件记录个数变量
当awk从多个文件读取时，NR变量将给出所有相关文件的记录总数，而 FNR 给出的是每个输入文件的记录数。
```
$awk '{print FILENAME, NR, FNR;}' student-marks bookdetails
student-marks 1 1
student-marks 2 2
student-marks 3 3
bookdetails 4 1
bookdetails 5 2
bookdetails 6 3
```
