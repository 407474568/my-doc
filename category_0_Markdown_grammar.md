#### 字体加颜色

CSS样式解决

https://blog.csdn.net/heimu24/article/details/81189700

https://www.zhihu.com/question/22504694

https://blog.csdn.net/manjianchao/article/details/53668280  颜色,大小,字体

&nbsp; 

方法1:
```
<font face="黑体">我是黑体字</font>
<font face="微软雅黑">我是微软雅黑</font>
<font face="STCAIYUN">我是华文彩云</font>
<font color=red>我是红色</font>
<font color=#008000>我是绿色</font>
<font color=Blue>我是蓝色</font>
<font size=5>我是尺寸</font>
<font face="黑体" color=green size=5>我是黑体，绿色，尺寸为5</font>
```

```
浅红色文字：<font color="#dd0000">浅红色文字</font><br /> 
深红色文字：<font color="#660000">深红色文字</font><br /> 
浅绿色文字：<font color="#00dd00">浅绿色文字</font><br /> 
深绿色文字：<font color="#006600">深绿色文字</font><br /> 
浅蓝色文字：<font color="#0000dd">浅蓝色文字</font><br /> 
深蓝色文字：<font color="#000066">深蓝色文字</font><br /> 
浅黄色文字：<font color="#dddd00">浅黄色文字</font><br /> 
深黄色文字：<font color="#666600">深黄色文字</font><br /> 
浅青色文字：<font color="#00dddd">浅青色文字</font><br /> 
深青色文字：<font color="#006666">深青色文字</font><br /> 
浅紫色文字：<font color="#dd00dd">浅紫色文字</font><br /> 
深紫色文字：<font color="#660066">深紫色文字</font><br /> 
```

方法2:

```
<span style="color:red;"> 红色 </span>
```

#### 加粗和斜体
```
**加粗**
```
**加粗**

```
*斜体*
```
*斜体*

#### 添加换行符

https://www.zhihu.com/question/20134106

以下两个都有效  

<font color=red>注意上下要空行, 否则会影响下一行内容的格式</font>

```
&nbsp;

<br/>
```

#### 添加多个空格

<font color=red>注意上下要空行, 否则会影响下一行内容的格式</font>

一个空格大小的表示

```
&ensp;

&#8194
```

两个空格的大小表示

```
&emsp;

&#8195;
```

不换行空格
```
&nbsp;

&#160;
```

#### 标记锚点

```
[显示文字](#标题)
```

#### 添加删除线
文字前后都加2个 ~ 号
```
~~删除线示例~~
```
~~删除线示例~~

#### 添加表格
https://www.jianshu.com/p/2df05f279331  
https://www.runoob.com/markdown/md-table.html  
语法格式如下:  
```
| 一个普通标题 | 一个普通标题 | 一个普通标题 |
| ------ | ------ | ------ |
| 短文本 | 中等文本 | 稍微长一点的文本 |
| 稍微长一点的文本 | 短文本 | 中等文本 | 
```  
效果如下:  

| 一个普通标题 | 一个普通标题 | 一个普通标题 |
| ------ | ------ | ------ |
| 短文本 | 中等文本 | 稍微长一点的文本 |
| 稍微长一点的文本 | 短文本 | 中等文本 |


<font color=red>需要注意的是表头的上一行要有空格, 否则表格样式不生效</font>  

&nbsp;

对齐方式
```
| 左对齐标题 | 右对齐标题 | 居中对齐标题 |
| :------| ------: | :------: |
| 短文本 | 中等文本 | 稍微长一点的文本 |
| 稍微长一点的文本 | 短文本 | 中等文本 |
```

效果:

| 左对齐标题 | 右对齐标题 | 居中对齐标题 |
| :------| ------: | :------: |
| 短文本 | 中等文本 | 稍微长一点的文本 |
| 稍微长一点的文本 | 短文本 | 中等文本 |

&nbsp;

#### 添加附件

https://www.cnblogs.com/yanh0606/p/10488356.html

```
<a href="files/test.txt" target="_blank">附件1</a>
```

效果如下:

<a href="files/test.txt" target="_blank">附件1</a>
