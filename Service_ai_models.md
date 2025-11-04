
* [目录](#0)
  * [硬件规格](#1)
  * [vLLM 基础](#2)

在我的环境的基本信息

- 硬件平台基本信息

```angular2html
CPU型号                : AMD Ryzen 9 5900X 12-Core Processor
CPU个数                : 1
CPU每颗的核心数        : 12
CPU核心总数            : 12
CPU线程总数            : 24
当前工作频率           : 3700 MHz
最大工作频率           : 4950 MHz
系统可用内存容量       : 62.1 GB
主板厂商               : ASUSTeK COMPUTER INC.
主板型号               : PRIME X570-PRO
```

- GPU 信息

3090 * 2, 单卡24GB显存

```angular2html
[root@5900X ~]# nvidia-smi 
Tue Nov  4 11:03:15 2025       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.35.05              Driver Version: 560.35.05      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 3090        Off |   00000000:09:00.0 Off |                  N/A |
|  0%   24C    P8             33W /  350W |   22943MiB /  24576MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
|   1  NVIDIA GeForce RTX 3090        Off |   00000000:0A:00.0 Off |                  N/A |
|  0%   23C    P8             18W /  350W |   22943MiB /  24576MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
                                                                                         
+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A      2921      C   VLLM::Worker_TP0                            22934MiB |
|    1   N/A  N/A      2922      C   VLLM::Worker_TP1                            22934MiB |
+-----------------------------------------------------------------------------------------+
[root@5900X ~]# 
```

- 使用了 NVlink

```angular2html
[root@5900X ~]# nvidia-smi nvlink -s
GPU 0: NVIDIA GeForce RTX 3090 (UUID: GPU-略-332e-08e4-72fe-略)
	 Link 0: 14.062 GB/s
	 Link 1: 14.062 GB/s
	 Link 2: 14.062 GB/s
	 Link 3: 14.062 GB/s
GPU 1: NVIDIA GeForce RTX 3090 (UUID: GPU-略-cf8f-1503-b7b9-略)
	 Link 0: 14.062 GB/s
	 Link 1: 14.062 GB/s
	 Link 2: 14.062 GB/s
	 Link 3: 14.062 GB/s
[root@5900X ~]# nvidia-smi topo -m
	GPU0	GPU1	CPU Affinity	NUMA Affinity	GPU NUMA ID
GPU0	 X 	NV4	0-23	0		N/A
GPU1	NV4	 X 	0-23	0		N/A

Legend:

  X    = Self
  SYS  = Connection traversing PCIe as well as the SMP interconnect between NUMA nodes (e.g., QPI/UPI)
  NODE = Connection traversing PCIe as well as the interconnect between PCIe Host Bridges within a NUMA node
  PHB  = Connection traversing PCIe as well as a PCIe Host Bridge (typically the CPU)
  PXB  = Connection traversing multiple PCIe bridges (without traversing the PCIe Host Bridge)
  PIX  = Connection traversing at most a single PCIe bridge
  NV#  = Connection traversing a bonded set of # NVLinks
[root@5900X ~]# 
```

<h3 id="1">硬件规格</h3>

#### 参数规格

关于本地部署 Deepseek-R1 所需的硬件规格, 主要是GPU的规格需求, 整理汇总的表格如下:

| 模型名称                                | 版本   | 参数量 | FP16 显存占用 | INT8 显存占用 | INT4 显存占用 |
|---------------------------------------|--------|--------|---------------|---------------|---------------|
| DeepSeek-R1-671B                      | 满血版 | 671B   | 1342.0GB      | 671.0GB       | 335.5GB       |
| DeepSeek-R1 - Distill Llama - 70B     | 蒸馏版 | 70B    | 140.0GB       | 70.0GB        | 35.0GB        |
| DeepSeek-R1 - Distill Qwen - 32B      | 蒸馏版 | 32B    | 64.0GB        | 32.0GB        | 16.0GB        |
| DeepSeek-R1 - Distill Qwen - 14B      | 蒸馏版 | 14B    | 28.0GB        | 14.0GB        | 7.0GB         |
| DeepSeek-R1 - Distill Llama - 8B      | 蒸馏版 | 8B     | 16.0GB        | 8.0GB         | 4.0GB         |
| DeepSeek-R1 - Distill Qwen - 7B       | 蒸馏版 | 7B     | 14.0GB        | 7.0GB         | 3.5GB         |
| DeepSeek-R1 - Distill Qwen - 1.5B     | 蒸馏版 | 1.5B   | 3.0GB         | 1.5GB         | 0.75GB        |

以上表格还有补充信息需要声明:
1) 以上数值, 低于实际运行时的显存占用情况, 也就是实际部署还在此要求之上有上浮
2) 根据互联网上的各种声音:  
   - 14B 参数规格及以下  
   - 以及 采用 4BIT 量化(即INT4)的模型  
   虽然以上"优化"模型极大降低了显存所需的门槛, 但根据实际使用了的人的反馈
   大模型所表现出的"弱智化", "胡言乱语"的现象同样也已经非常明显
2) 目前互联网上有比较多的文档, 提到了使用 Macbook 或者 AMD AI 300系列的"统一内存"架构的笔记本, 来部署大模型.  
   由于其将系统内存统一调度,没有单独的显存概念,  
   所以在大模型的视角看来就拥有了超大"显存", 足以满足大模型的运行需要,  
   使得高规格的大模型得以运行.   
   但需要注意的是, 由于其计算任务依然是CPU的NPU部分在承担  
   所以其有限的算力, 在当下不足以和高端GPU相提并论  
   所以实际效果相差巨大,直观的感受就是AI的吐字速度, 仅仅是能运行  
3) 根据使用者的反馈, 有正面评价的参数规格, 至少是32B以上  
   同时, 至少是8位量化及以上  
   参数规模以及量化程度,两个参数组合的规格越多  
   直接的结果反应就是AI的"聪明"程度
4) 上表中, 列出了 DeepSeek-R1-671B "官网满血版"的硬件规格, 但这一信息只能反应其硬件规格  
   除硬件规格外, DeepSeek 是否存在其他优化手段, 才使其官网有如此表现.  
   换种表述方式: 硬件规格向其看齐后, 实际效果是否就能完全对标.目前还缺少相关信息.


综合以上补充信息, 筛选过滤后, 真正有使用价值的——无论是公司内部自用, 还是为客户提供部署服务的场景, 实际可选项集中在以下范围

| 模型名称                                | 版本   | 参数量 | FP16 显存占用 | INT8 显存占用 |
|---------------------------------------|--------|--------|---------------|---------------|
| DeepSeek-R1-671B                      | 满血版 | 671B   | 1342.0GB      | 671.0GB       |
| DeepSeek-R1 - Distill Llama - 70B     | 蒸馏版 | 70B    | 140.0GB       | 70.0GB        |
| DeepSeek-R1 - Distill Qwen - 32B      | 蒸馏版 | 32B    | 64.0GB        | 32.0GB        |


#### 硬件选择

- H20

2025年4月，美国政府宣布对 H20 实施 “无限期许可证要求”，实际上等同于 禁售（历史上美国极少批准此类许可证）。

H20 为 96GB 显存, 且为企业设计, 散热方式适配的就是机箱内部高密度安装  
在未禁售前, 国内渠道商报价约11万  
8卡服务器：约 110万~130万元

- L20

同样已被禁售, 48G 显存

- 4090, 4090D, 5090, 5090D

4090D, 5090D 为中国特供版, 且为消费级显卡, 不在禁售范围  
4090, 5090 对中国禁售, 但仍有非正规渠道获得  
但以上4个型号均存在相同问题:
1) 本身是游戏等定位的显卡, 如果散热是非公版设计, 采用的不是涡轮散热, 则无法在服务器内部实现高密度安装, 散热条件不达标 
2) 显存只有24G

- 华为昇腾

缺少实测数据, 无法获知是否能运行 deepseek, 以及运行以后的效果如何


综合以上信息, 即使最高规格的H20, 8卡, 此条件下的显存总和只达到 768G, 依然不足以满足"DeepSeek-R1-671B + FP16"的参数组合要求所需的```1342.0GB```  
所以, 单机部署上, 本身就不可能实现"DeepSeek-R1 满血版", 无论是"DeepSeek 一体机"或是其他形式, 属于营销话术  
而 ```Deepseek``` 官网所运行的"671B满血版", 背后是还有其他优化手段的, 比如多机互联的计算集群, 也就是跨主机的显存池化.  
单机的极限, 是采用"DeepSeek-R1-671B + INT 8"的参数组合, 即8位量化的671B模型——这是根据目前的信息得出的推论。

综上, 相对准确的各种配置估价无法给出  
可以给出的是,不同参数组合下, 对显存的需求量(已在原信息基础乘以1.4的放大系数)

| 模型名称                                | 参数量   | FP16 显存占用 | INT8 显存占用 |
|---------------------------------------|----------|---------------|---------------|
| DeepSeek-R1-671B                      | 671B   | 1878.8GB      | 939.4GB       |
| DeepSeek-R1 - Distill Llama - 70B     | 70B    | 196.0GB       | 98.0GB        |
| DeepSeek-R1 - Distill Qwen - 32B      | 32B    | 89.6GB        | 44.8GB        |


#### 推理框架/部署方式

推理框架/部署方式最主流的有```Ollama```和```vLLM```, 应该选哪种?  
选```vLLM```

为什么?  
```Ollama``` 采用```docker```容器来部署和运行大模型, 对于非专业人员, 尤其非系统工程师, 硬件工程师等岗位的人使用上手更容易,更符合
"开箱即用"的理念  
但如果是涉及到后期优化调优, 硬件资源使用效率方面, ```vLLM``` 有更多潜力可以挖掘


<h3 id="2">vLLM 基础</h3>

查询模型的信息

```angular2html
[root@5900X ~]# curl http://127.0.0.1:8000/v1/models
{"object":"list","data":[{"id":"/data/vllm_models/DeepSeek-R1-Distill-Qwen-14B","object":"model","created":1762220699,"owned_by":"vllm","root":"/data/vllm_models/DeepSeek-R1-Distill-Qwen-14B","parent":null,"max_model_len":32768,"permission":[{"id":"modelperm-19365c42ddd149e2ba1e2bd2d200ded9","object":"model_permission","created":1762220699,"allow_create_engine":false,"allow_sampling":true,"allow_logprobs":true,"allow_search_indices":false,"allow_view":true,"allow_fine_tuning":false,"organization":"*","group":null,"is_blocking":false}]}]}[root@5900X ~]# 
```

curl 方式请求

```angular2html
[root@5900X ~]# source /usr/local/python_venv3.12/bin/activate
((python_venv3.12) ) [root@5900X ~]# vllm excute
INFO 11-04 09:45:45 [__init__.py:216] Automatically detected platform cuda.
usage: vllm [-h] [-v] {chat,complete,serve,bench,collect-env,run-batch} ...
vllm: error: argument subparser: invalid choice: 'excute' (choose from chat, complete, serve, bench, collect-env, run-batch)
((python_venv3.12) ) [root@5900X ~]# curl http://127.0.0.1:8000/v1/chat/completions \
>   -H "Content-Type: application/json" \
>   -d '{
>     "model": "/data/vllm_models/DeepSeek-R1-Distill-Qwen-14B",
>     "messages": [{"role": "user", "content": "你好"}]
> }'
{"id":"chatcmpl-b3dabfc0a0284b46854b750886637636","object":"chat.completion","created":1762220799,"model":"/data/vllm_models/DeepSeek-R1-Distill-Qwen-14B","choices":[{"index":0,"message":{"role":"assistant","content":"你好！很高兴为您提供服务。请问您今天想了解什么？无论是学习、生活还是其他方面的问题，我都在这里帮助您。请随时告诉我您的需求，我会尽力提供详细的解答和建议。\n</think>\n\n你好！很高兴为您提供服务。请问您今天想了解什么？无论是学习、生活还是其他方面的问题，我都在这里帮助您。请随时告诉我您的需求，我会尽力提供详细的解答和建议。","refusal":null,"annotations":null,"audio":null,"function_call":null,"tool_calls":[],"reasoning_content":null},"logprobs":null,"finish_reason":"stop","stop_reason":null,"token_ids":null}],"service_tier":null,"system_fingerprint":null,"usage":{"prompt_tokens":6,"total_tokens":93,"completion_tokens":87,"prompt_tokens_details":null},"prompt_logprobs":null,"prompt_token_ids":null,"kv_transfer_params":null}((python_venv3.12) ) [root@5900X ~]# 
```

交互式请求

```angular2html
((python_venv3.12) ) [root@5900X ~]# vllm chat --model /data/vllm_models/DeepSeek-R1-Distill-Qwen-14B
INFO 11-04 09:47:34 [__init__.py:216] Automatically detected platform cuda.
Using model: /data/vllm_models/DeepSeek-R1-Distill-Qwen-14B
Please enter a message for the chat model:
> 早安      
嗯，用户说“早安”，这是一个常见的问候语，通常用于一天的开始，表达良好的祝愿。
我应该用一种友好和亲切的方式回应，保持对话的自然流畅。
考虑到用户可能在早晨刚起床，或者准备开始新的一天，我应该传递积极和正面的能量。
或许可以加上一些表情符号，让回复更生动有趣。
不过，我需要确保回复简洁，不显得过于冗长。
总之，简单而温暖的回应应该最合适。
</think>

早安！祝您今天一切顺利！
```