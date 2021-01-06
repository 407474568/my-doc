#### awk ɸѡ�������
��������ļ�������awk �жϷ������������ݣ���ɸѡ��������ݣ����뵽��Ӧ���ļ��С�
```
awk '{if ($7>5) print}' A|less            ###ɸѡA�ļ��е����д���5�����ݣ���ʾ���з��ϵĽ��
awk '{if ($6>5 && $7>5) print}' A|less   ###ɸѡA�ļ��е����к����ж�����5�����ݣ���ʾ���з��ϵĽ��
awk '{if ($6>5 || $7>5) print}' A|less   ###ɸѡA�ļ��е����л����ж�����5�����ݣ���ʾ���з��ϵĽ��
awk '{if ($7>5) print}' A|less>B          ###ɸѡA�ļ��е����д���5�����ݣ��������ϵĽ�����뵽B�ļ���
```

#### awk����С������
https://blog.51cto.com/radish/1736900
����ʾ��:
```
echo "$A $B $C $D" | awk '{printf ("%.2f\n",$1*$2/$3-$4)}'
``` 
awk�Դ�����ʽ����, ��ͬshell�ĺ�������,��ʽ������prinft �����
Ҳ֧�ֿ�ѧ����������ʽ
```
[wangdong@centos715-node1 uncomp]$ echo "6.8923e+08" | awk '{printf ("%.0f\n",$1)}'
689230000
```

#### awk��RS,ORS,FS,OFS ������
http://blog.51yip.com/shell/1151.html  
һ��RS��ORS  
1��RS�Ǽ�¼�ָ�����Ĭ�ϵķָ�����\n�������÷�����
```
[root@krlcgcms01 mytest]# cat test1     //�����ļ�  
 111 222  
 333 444  
 555 666  
```
2��RSĬ�Ϸָ���� \n
```
[root@krlcgcms01 mytest]# awk '{print $0}' test1  //awk 'BEGIN{RS="\n"}{print $0}' test1 �������һ����  
111 222  
333 444  
555 666  
```
��ʵ����԰�����test1�ļ�����������Ϊ��111 222\n333 444\n555 6666������\n���зָ����һ������  
3���Զ���RS�ָ��
```
[zhangy@localhost test]$ echo "111 222|333 444|555 666"|awk 'BEGIN{RS="|"}{print $0,RT}'  
 111 222 |  
 333 444 |  
 555 666
```  
�������һ�����ӣ��ͺ��������RS���÷��ˡ�

4��RSҲ������������ʽ
```
[zhangy@localhost test]$ echo "111 222a333 444b555 666"|awk 'BEGIN{RS="[a-z]+"}{print $1,RS,RT}'  
 111 [a-z]+ a  
 333 [a-z]+ b  
 555 [a-z]+
```  
����3����4�����ǿ��Է���һ�㣬��RT������RSƥ����������ݡ����RS��ĳ���̶���ֵʱ��RT����RS�����ݡ�

5��RSΪ��ʱ
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

[zhangy@localhost test]$ awk 'BEGIN{RS="";}{print "<",$0,">"}' test2  //������ӿ��űȽ�����  
< 111 222 >  
< 333 444     //��һ�к�����һ�У���һ��  
333 444 >  
< 555 666 >
```  
��������ӣ����Կ�����RSΪ��ʱ��awk���Զ��Զ�������Ϊ�ָ����

6��ORS��¼����ַ�����Ĭ��ֵ��\n

��ORS����RS�����̣����������׼������⣬����������ӡ�
```
[zhangy@localhost test]$ awk 'BEGIN{ORS="\n"}{print $0}' test1  //awk '{print $0}' test1������һ����  
111 222  
333 444  
555 666  
[zhangy@localhost test]$ awk 'BEGIN{ORS="|"}{print $0}' test1  
111 222|333 444|555 666|  
```
����FS��OFS

1��FSָ���зָ��
```
[zhangy@localhost test]$ echo "111|222|333"|awk '{print $1}'  
 111|222|333  
[zhangy@localhost test]$ echo "111|222|333"|awk 'BEGIN{FS="|"}{print $1}'  
 111  
 ```
2��FSҲ����������
```
[zhangy@localhost test]$ echo "111||222|333"|awk 'BEGIN{FS="[|]+"}{print $1}'  
111  
```
3��FSΪ�յ�ʱ��
```
[zhangy@localhost test]$ echo "111|222|333"|awk 'BEGIN{FS=""}{NF++;print $0}'  
1 1 1 | 2 2 2 | 3 3 3  
```
��FSΪ�յ�ʱ��awk���һ���е�ÿ���ַ�������һ��������

4��RS���趨�ɷ�\nʱ��\n���FS�ָ���е�һ��

```
[zhangy@localhost test]$ cat test1  
 111 222  
 333 444  
 555 666  
[zhangy@localhost test]$ awk 'BEGIN{RS="444";}{print $2,$3}' test1  
 222 333  
 666  
 ```
222��333֮������һ��\n�ģ���RS�趨��444��222��333���϶���ͬһ�еĶ����ˣ���ʵ������˼���Ƕ��е�һ�вŶԡ�

5��OFS������ָ���

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
test1ֻ�ж��У����100�У���д����̫�鷳�˰ɡ�

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
Ϊʲô�ڶ��ַ����е�OFS��Ч�أ����˾��ã�awk���鵽�������仯ʱ���ͻ���OFS��Ч��û�仯ֱ������ˡ�

#### AWK ��8��ǿ������ñ���
http://blog.chinaunix.net/uid-28903506-id-5211480.html

AWK�����ñ������������ͣ�  
��1��. һ����ֵ���Ա��޸ĵı�����������ָ�������¼�ָ����ȡ�  
��2��.  ��һ���Ǳ����ڴ����ı��Ĺ����У���¼�����״̬����������ͳ�ƣ������¼������ĸ����ȡ�

FS ������ָ�������  
awk �������ж�ȡ�ʹ���ÿһ�У�Ĭ�����Կո���Ϊ�ָ�����ͬʱ���ñ���$1��$2�ȵȡ�FS ��������������Ϊÿһ����¼�е���ָ�����  
FS �����������ַ�ʽ��  
��1��ͨ�� -F ������ѡ��  
```
$ awk -F 'FS' 'commands' inputfilename
```
��2��ֱ�Ӱ�����ͨ�����ĸ�ֵ��ʽ
```
$ awk 'BEGIN{FS="FS";}'
```
ע�⣺
��1��FS ���Ա�����Ϊ����ĵ����ַ���������ʽ��  
��2��FS ���Ա������Σ�����һֱ����ֵ��ֱ������ʽ���޸ġ��������Ҫ�޸���ָ���������ڶ�ȡһ��֮ǰ������������������ڶ�ȡ���С�

OFS ������ָ�������  
OFS ����������FS������������������ı���Ĭ��ֵ�ǵ����ո��ַ���
```
$ awk -F':' '{print $3,$4;}' /etc/passwd
41 41
100 101
```

print ����е����ӷ���,������ʹ��OFSֵ����������������������OFS���ã�
```
$ awk -F':' 'BEGIN{OFS="=";} {print $3,$4;}' /etc/passwd
41=41
100=101
```

RS �����¼�ָ�������  
RS���ڶ���һ�У���AWKĬ�ϼ���һ�н�һ�ж�ȡ�ġ�  
����һ���洢ѧ���������ļ�����¼�����������з��ָ�����ÿһ����ͨ��һ�����з��ָ�����
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

���Ҫ��ȡѧ�������͵�һ������ֵ������ʹ������awk�ű���
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

�����Ͻű��У���ΪRS����������Ϊ�������з�������awk��ȡÿһ��ѧ������ϸ��Ϣ��Ϊһ����¼��FS ֵΪ���з������Լ�¼�е�ÿһ����һ����

ORS �����¼�ָ�������
ORS����RS������������������ʱ��ӡÿһ����¼��ͬʱ���ӡ����������
```
$  awk 'BEGIN{ORS="=";} {print;}' student-marks
Jones 2143 78 84 77=Gondrol 2321 56 58 45=RinRao 2122 38 37 65=
```

NR ��¼��������  
NR �����Ѵ���ļ�¼�����кš�  
������������У�NR���������кţ���awk�ű���END���֣�NR�������Ը�����һ���ļ��еļ�¼������
```
$ awk '{print "Processing Record - ",NR;}END {print NR, "Students Records are processed";}' student-marks
Processing Record -  1
Processing Record -  2
Processing Record -  3
3 Students Records are processed
```

��ע�����ڴ������ļ�ʱ�����������ͬ��NRֵ���ۼӣ������һ���ļ���10����¼���������ڶ����ļ��ĵ�2����¼ʱ��NRֵΪ12

NF ���������  
NF����һ����¼�����������  
NF���ж�һ����¼���Ƿ����е��������ʱ�ǳ����á�

�޸��������ѧ����Ϣ�ļ�����������¼�ĵ���������û���ˣ���
```
$cat student-marks
Jones 2143 78 84 77
Gondrol 2321 56 58 45
RinRao 2122 38 37
```

������ű��������
```
$ awk '{print NR,"->",NF}' student-marks
1 -> 5
2 -> 5
3 -> 4
```

FILENAME ��ǰ�����ļ�������  
FILENAME �����������ڱ���ȡ���ļ�����  
awk�ǿ��Խ��ܶ�������ļ�������ġ�
```
$ awk '{print FILENAME}' student-marks
student-marks
student-marks
student-marks
```
�������ʵ���У��ڴ����ļ���ÿһ����¼ʱ������ӡFILENAME��Ҳ���� student-marks��

FNR ��ǰ�����ļ���¼��������
��awk�Ӷ���ļ���ȡʱ��NR������������������ļ��ļ�¼�������� FNR ��������ÿ�������ļ��ļ�¼����
```
$awk '{print FILENAME, NR, FNR;}' student-marks bookdetails
student-marks 1 1
student-marks 2 2
student-marks 3 3
bookdetails 4 1
bookdetails 5 2
bookdetails 6 3
```
