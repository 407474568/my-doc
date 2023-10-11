* [目录](#0)
  * [基本概念](#1)
  * [标题与正文字体](#2)


Pypi 上能找到的, 关于 word 操作的库主要有两个  
- docx
- python-docx

名字非常相近, 查阅文档时需要留意分辨, 避免库本身就不同而产生的误导

```docx``` 已多年没有更新  

本文均以 ```python-docx``` 作为对象进行描述

python-docx 的主页

https://python-docx.readthedocs.io/en/latest

<h3 id="1">基本概念</h3>

在 ```python-docx``` 中, word 文档的对象有几类

```docx.Document()``` 是实例化一个 word 对象, 是总体

标题是 ```heading```  
段落是 ```paragraph```  
```run``` 则是文本对象  
其中的 ```paragraph``` 和 ```run``` 又与"人"的思维习惯有所不同. 一个典型例子就是
当一段文字中需要切换不同的字体字号等场景, 则需要不同的```run```对象, 配置不同的属性来进行实现;
同样的, 在```python-docx```中的```paragraph```也并非仅限于我们, 尤其是中国人习惯上的"段落".  
概念性的介绍, 这篇文章已介绍得挺不错  
https://cloud.tencent.com/developer/article/1898865

引用它的一张图  
![](images/c08e7af90bb55c09673b403ff55961ce.png)


<h3 id="2">标题与正文字体</h3>

默认字体可以像这样设置

```
    doc = docx.Document()
    doc.styles['Normal'].font.name = u'仿宋'
    doc.styles['Normal']._element.rPr.rFonts.set(qn('w:eastAsia'), u'仿宋')
    doc.styles['Normal'].font.size = Pt(14)
    doc.styles['Normal'].font.color.rgb = RGBColor(0, 0, 0)
```

在 ```docx.Document()``` 实例化后, 对其属性进行设置.  
其中:  
2,3行的字体名称, 包括了一个东亚文字的属性设置, 是必要的, 具体原理在互联网上有文章介绍  
4,5行分别是字号与字体颜色  
其余更多属性, 有属性可另查文档

标题

```
    head = doc.add_heading('', level=1)
    run = head.add_run("一级标题")
    run.font.name = '仿宋'
    run.font.size = Pt(30)
    run._element.rPr.rFonts.set(qn('w:eastAsia'), '仿宋')
    run.font.color.rgb = RGBColor(0, 0, 0)
```

标题不同于正文, 默认字体的设置的作用于仅限于正文, 当需要对标题进行字体字号的设置时,
以上的方式是最合适的  
不少文章会在```doc.add_heading('', level=1)```里加入标题内的文字, 即''留空的部分  
然而又并未提及修改字体字号的方法  
上述方式, 通过新增一个空标题, 再添加一个 run 对象, 然后设置 run 对象的属性来实现字体字号的控制  
