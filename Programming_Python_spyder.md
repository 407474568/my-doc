* [目录](#0)
  * [在 Beautifulsoup 中使用 XPATH 方式捕获对象](#1)
  * [浏览器自动化里的下拉选择框的操作--select类](#2)


<h3 id="1">在 Beautifulsoup 中使用 XPATH 方式捕获对象</h3>


https://www.geeksforgeeks.org/how-to-use-xpath-with-beautifulsoup/

原文的示例

```
from bs4 import BeautifulSoup
from lxml import etree
import requests


URL = "https://en.wikipedia.org/wiki/Nike,_Inc."

HEADERS = ({'User-Agent':
			'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 \
			(KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36',\
			'Accept-Language': 'en-US, en;q=0.5'})

webpage = requests.get(URL, headers=HEADERS)
soup = BeautifulSoup(webpage.content, "html.parser")
dom = etree.HTML(str(soup))
print(dom.xpath('//*[@id="firstHeading"]')[0].text)
```

我的代码片段

```
    soup = BeautifulSoup(masquerade(url, use_proxy='GFW', proxy_server_ip=proxy_server_ip,
                                    proxy_server_port=proxy_server_port), 'html.parser')
    dom = etree.HTML(str(soup))
    # dom = etree.HTML(soup)
    # pool_rate = soup.find(name="div", attrs={"class": "options-val"}).get_text()
    pool_rate = dom.xpath('//*[@id="app"]/div[2]/div/div/div[3]/div[2]/div[1]/div[1]/div[1]')[0].text
```

注意点:  
1) 不管用request 还是其他方式请求回来的web页面内容, 不要用```decode()```去解码, 在这个情景下属于画蛇添足.  
2) 经过```etree```处理, 以xpath 提取后的结果是个列表对象, 内容在下标 [0] 里


<h3 id="2">浏览器自动化里的下拉选择框的操作--select类</h3>

本节主要是对以下文章的摘抄

https://blog.csdn.net/huilan_same/article/details/52246012

- 包的导入

```
from selenium.webdriver.support.ui import Select
# 或者直接从select导入
# from selenium.webdriver.support.select import Select
```

- 选择的方法

Select类提供了三种选择某一选项的方法：

```
select_by_index(index)
select_by_value(value)
select_by_visible_text(text)
```

示例网站中的第一个select框：

```
<select id="s1Id">
<option></option>
<option value="o1" id="id1">o1</option>
<option value="o2" id="id2">o2</option>
<option value="o3" id="id3">o3</option>
</select>
```

> 我自己的补充: 也就是首先要通过查看网站源代码观察是否有 ```select``` 标签

可以这样定位：

```
from selenium import webdriverd
from selenium.webdriver.support.ui import Select

driver = webdriver.Firefox()
driver.get('http://sahitest.com/demo/selectTest.htm')

s1 = Select(driver.find_element_by_id('s1Id'))  # 实例化Select

s1.select_by_index(1)  # 选择第二项选项：o1
s1.select_by_value("o2")  # 选择value="o2"的项
s1.select_by_visible_text("o3")  # 选择text="o3"的值，即在下拉时我们可以看到的文本

driver.quit()
```

以上是三种选择下拉框的方式，注意：

1) index从 0 开始
2) value是option标签的一个属性值，并不是显示在下拉框中的值
3) visible_text是在option标签中间的值，是显示在下拉框的值

- 反选（deselect）

自然的，有选择必然有反选，即取消选择。Select提供了四个方法给我们取消原来的选择：

```
deselect_by_index(index)
deselect_by_value(value)
deselect_by_visible_text(text)
deselect_all()
```

前三种分别于select相对应，第四种是全部取消选择，是的，你没看错，是全部取消。有一种特殊的select标签，即设置了multiple=”multiple”属性的select，这种select框是可以多选的，你可以通过多次select，选择多项选项，而通过deselect_all()来将他们全部取消。

全选？NO，不好意思，没有全选，不过我想这难不倒你，尤其是看了下面的这几个属性。

- 选项（options）

当我们选择了选项之后，想要看看选择的是哪项，所选的是否是我想选的，怎么办？别担心，Select为你提供了相应的方法（或者应该说是属性了）：

```
options
all_selected_options
first_selected_option
```

上面三个属性，分别返回这个select元素所有的options、所有被选中的options以及第一个被选中的option。

1) 想查看一个select所有的选项

```
s1 = Select(driver.find_element_by_id('s1Id'))

for select in s1.options:
    print select.text
```

结果：

```

o1
o2
o3
```

一共四项，第一项为空字符串。

2) 想查看我已选中的选项

```
s4 = Select(driver.find_element_by_id('s4Id'))

s4.select_by_index(1)
s4.select_by_value("o2val")
s4.select_by_visible_text("With spaces")
s4.select_by_visilbe_text("    With nbsp")

for select in s4.all_selected_options:
    print select.text
```

结果：

```
o1
o2
    With spaces
    With nbsp
```

输出所有被选中的选项，适合于能多选的框，仅能单选的下拉框有更合适的方法（当然用这种方法也可以）。这里需要注意的是两种不同空格的选择：

- 空格’ ‘，这种在以visible_text的方式选择时，不计空格，从第一个非空格字符开始  
- 网页空格& nbsp;，对于这种以nbsp为空格的选项，在以visible_text的方式选择时，需要考虑前面的空格，每一个nbsp是一个空格

3) 想要查看选择框的默认值，或者我以及选中的值

```
s2 = Select(driver.find_element_by_id('s2Id'))

print s2.first_selected_option.text

s2.select_by_value("o2")
print s2.first_selected_option.text
```

结果：

```

o2
```

第一行输出默认选项的文本——空字符串”“；第二行输出选中的选择的文本——”o2”。

- 总结

1) Select提供了三种选择方法：

```
select_by_index(index) ——通过选项的顺序，第一个为 0
select_by_value(value) ——通过value属性
select_by_visible_text(text) ——通过选项可见文本
```

2) 同时，Select提供了四种方法取消选择：

```
deselect_by_index(index)
deselect_by_value(value)
deselect_by_visible_text(text)
deselect_all()
```

3) 此外，Select提供了三个属性方法给我们必要的信息：

```
options ——提供所有的选项的列表，其中都是选项的WebElement元素
all_selected_options ——提供所有被选中的选项的列表，其中也均为选项的WebElement元素
first_selected_option ——提供第一个被选中的选项，也是下拉框的默认值
```

通过Select提供的方法和属性，我们可以对标准select下拉框进行任何操作，但是对于非select标签的伪下拉框，就需要用其他的方法了
