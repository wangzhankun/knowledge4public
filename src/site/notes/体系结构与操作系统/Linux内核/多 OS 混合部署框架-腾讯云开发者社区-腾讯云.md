---
{"dg-publish":true,"date":"2023-12-09","time":"20:32","progress":"进行中","tags":["OS"],"permalink":"/体系结构与操作系统/Linux内核/多 OS 混合部署框架-腾讯云开发者社区-腾讯云/","dgPassFrontmatter":true}
---

# 多 OS 混合部署框架-腾



讯云开发者社区-腾讯云

## **背景：混合关键性系统**

在嵌入式场景中，虽然 Linux 已经得到了广泛应用，但并不能覆盖所有需求，例如高实时、高可靠、高安全的场合。这些场合往往是实时操作系统的用武之地。有些应用场景需要 Linux 的管理能力、丰富的生态又需要实时操作系统的高实时、高可靠、高安全，那么一种典型的设计是采用一颗性能较强的处理器运行 Linux 负责富功能，一颗微控制器/ DSP /实时处理器运行实时操作系统负责实时控制或者信号处理，两者之间通过 I/O、网络或片外总线的形式通信。这种方式存在的问题是，硬件上需要两套系统、集成度不高，通信受限与片外物理机制的限制如速度、时延等，软件上 Linux 和实时操作系统两者之间是割裂的，在灵活性上、可维护性上存在改进空间。

受益于硬件技术的快速发展，嵌入式系统的硬件能力越来越强大，如单核能力不断提升、单核到多核、异构多核乃至众核的演进，虚拟化技术和可信执行环境（TEE）技术的发展和应用，未来先进封装技术会带来更高的集成度等等，使得在一个片上系统中（SoC）部署多个 OS 具备了坚实的物理基础。

同时，受应用需求的推动，如物联网化、智能化、功能安全与信息安全等等，整个嵌入式软件系统也越发复杂，全部由单一 OS 承载所有功能所面临的挑战越来越大。解决方式之一就是不同系统负责各自所擅长的功能，如 Windows 的 UI、Linux 的网络通信与管理、实时操作系统的高实时与高可靠等，而且还要易于开发、部署、扩展，实现的形式可以是 [容器 ](https://cloud.tencent.com/product/tke?from_column=20065&from=20065)、虚拟化等。

面对上述硬件和应用的变化，结合自身原有的特点，嵌入式系统未来演进的方向之一就是 **「混合关键性系统（MCS，Mixed Criticality System）」**, 这可以从典型的嵌入式系统——汽车电子的最近发展趋势略见一斑。

**「图 1」**openEuler Embedded 中的混合关键性系统大致架构



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/TwApbXp4KoqZXNxvdZocHBSanIy.jpeg)





从 openEuler Embedded 的角度，混合关键性系统的大致架构如图 1 所示，所面向的硬件是具有同构或异构多核的片上系统，从应用的角度看会同时部署多个 OS /运行时，例如 Linux 负责系统管理与服务、1 个实时操作系统负责实时控制、1 个实时操作系统负责系统可靠、1 个裸金属运行时运行专用算法，全系统的功能是由各个 OS /运行时协同完成。中间的 **「混合部署框架」**和 **「嵌入式虚拟化」**是具体的支撑技术。关键性（Criticality）狭义上主要是指功能安全等级，参考泛功能安全标准 IEC-61508，Linux 可以达到 SIL1 或 SIL2 级别，实时操作系统可以达到最高等级 SIL3；广义上，关键性可以扩展至实时等级、功耗等级、信息安全等级等目标。

在这样的系统中，需要解决如下几个问题：

* **「高效地混合部署问题」**：如何高效地实现多 OS 协同开发、集成构建、独立部署、独立升级。
* **「高效地通信与协作问题」**：系统的整体功能由各个域协同完成，因此如何高效地实现不同域之间高效、可扩展、实时、安全的通信。
* **「高效地隔离与保护问题」**：如何高效地实现多个域之间的强隔离与保护，使得出故障时彼此不互相影响，以及较小的可信基（Trust Compute Base）。
* **「高效地资源共享与调度问题」**：如何在满足不同目标约束下（实时、功能安全、性能、功耗），高效地管理调度资源，从而提升硬件资源利用率。

对于上述问题，openEuler Embedded 的当前思路是 **「混合关键性系统 = 部署 + 隔离 + 调度」**，即首先实现多 OS 的混合部署，再实现多 OS 之间的隔离与保护，最后通过混合关键性调度提升资源利用率，具体可以映射到 **「混合部署框架」**和 **「嵌入式虚拟化」**。混合部署框架解决 **「高效地混合部署问题」**和 **「高效地通信与协作问题」**，嵌入式虚拟化解决 **「高效地隔离与保护问题」**和 **「高效地资源共享与调度问题」**。

openEuler Embedded 中多 OS 混合部署框架的架构图如下所示，引入了开源框架 OpenAMP[1]作为基础，并结合自身需要进一步创新。

**「图 2」**多 OS 混合部署框架的基础架构



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/M16wbouQRoKMtoxlHPDcVLUtnBc.jpeg)





在上述架构中，libmetal 提供屏蔽了不同系统实现的细节提供了统一的抽象，virtio queue 相当于网络协议中的 MAC 层提供高效的底层通信机制，rpmsg 相当于网络协议中的传输层提供了基于端点（endpoint）与通道(channel）抽象的通信机制，remoteproc 提供生命周期管理功能包括初始化、启动、暂停、结束等。

在 openEuler Embedded 22.03 中，集成了 OpenAMP 相关支持，并与 openEuler 的 SIG Zephyr[2] 合作实现了 openEuler Embedded 与实时操作系统 Zephyr[3] 在 QEMU 平台上的混合部署，具体可以参考

多 OS 混合部署 Demo[4]

在此基础上，openEuler Embedded 的混合部署框架还会继续演进，包括对接更多的实时操作系统，如国产开源实时操作系统 RT-Thread[5]，实现如图 3 所示的多 OS 服务化部署并适时引入基于虚拟化技术的嵌入式弹性底座。

**「图 3」**多 OS 服务化部署架构



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/WTLbbM5spoiSA8xuvJAcbQoGn1f.jpeg)





在上述多 OS 服务化部署架构中，openEuler Embedded 是中心，主要对其他 OS 提供管理、网络、文件系统等通用服务，其他 OS 可以专注于其所擅长的领域，并通过 shell、log 和 debug 等通道与 Linux 丰富而强大维测体对接从而简化开发工作。

本文参与 [腾讯云自媒体分享计划 ](https://cloud.tencent.com/developer/support-plan)，分享自微信公众号。

原始发表：2023-07-18，如有侵权请联系 [cloudcommunity@tencent.com ](https://mailto:cloudcommunity@tencent.com)删除

推荐

[如何在腾讯云上部署 Facebook 的ParlAI 训练框架](https://cloud.tencent.com/developer/article/1005128?areaId=106001)

腾讯云安装ParlAi, AI 对话模型研究和训练框架的过程。

[容器服务：来自外部的你好！](https://cloud.tencent.com/developer/article/1014352?areaId=106001)

容器服务正在改变应用程序的部署和管理方式。但它们究竟是什么呢？它们与其他交付平台的方式相比如何呢？



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/BYgKb0lfWomEVrxQJn3cXbVunPb.png)



[容器服务：来自外部的问好！](https://cloud.tencent.com/developer/article/1017478?areaId=106001)

容器服务正在改变应用程序的部署方式和管理方式。但容器服务究竟是什么？它与其他传送平台方式有何不同？

[关于在BAE上部署ThinkPHP框架的问题](https://cloud.tencent.com/developer/article/1018840?areaId=106001)

现在有点小兴奋，因为在在BAE上部署ThinkPHP框架的问题快折腾一天了，午觉都没睡，不过没白整总算有点结果。不扯淡了，直入正题吧. 　　之前熟悉ThinkPHP框架，想在BAE上用ThinkPHP做点东西，部署了一天的环境了总结一下把： 　　一：首先你得有百度帐号吧，别着急先登上。然后进入快速创建应用如下图所示 ? 　　二.创建应用的具体过程就不多说了吧不是今天的重点，然后ThinkPHP官网上去下一个云引擎版本链接如下：http://www.thinkphp.cn/down.html，我是用的Thi



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/FP9FbtKUJoXM25xItfCcRpC0nAh.jpeg)



[大家之前是不是误解了DC/OS与Kubernetes之间的关系](https://cloud.tencent.com/developer/article/1024709?areaId=106001)

DC/OS 与 Kubernetes 本篇文章将主要介绍“Kubernetes on DC/OS”的实现机制与优势，不会就Mesos与Kubernetes的架构与技术细节做过多的展开。关于Mesos与DC/OS的具体功能细节，大家可以关注本公众号，本公众号后续会陆续推送不同类型的技术文章，这些文章将包括Mesos以及DC/OS的架构介绍、技术原理与实现方式，以及微服务、分布式应用、大数据平台、AI平台在DC/OS平台之上运行的最佳实践。 随着容器技术快速地发展与不断的成熟，与容器相关的生态体系也在不断地丰富



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/D19PbaZ0LonggNxZxffcYPq8nBd.jpeg)



[吴晓斌："吃鸡"游戏全球多地部署架构分析](https://cloud.tencent.com/developer/article/1026566?areaId=106001)

“吃鸡”游戏最近十分流行。针对“吃鸡”类游戏在反外挂、加速、安全等方面的需求，腾讯游戏云资深架构师吴晓斌在现场为大家带来了“‘吃鸡’游戏全球多地部署架构分析”的主题分享。



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/V9iqbDpMmoliPcxdPQxc3ZI0nhW.jpeg)



[Dore 混合应用框架 —— 基于 React Native 的混合应用迁移方案](https://cloud.tencent.com/developer/article/1028767?areaId=106001)

上个周末，在写我的年终总结，有了一点新灵感 —— 其实是 xxx 原因。 在半年前的那篇《我们是如何将 Cordova 应用嵌入到 React Native 中》中，我介绍了如何将 Cordova 嵌入 React Native 应用中。 考虑到有大量的 Cordova 应用，会在未来迁移到 React Native 中，便写了 Dore。 Dore 是一个使用 React Native 实现的 WebView 容器，可以让你在 WebView 调用 React Native 组件。 其设计初衷：用于迁移

[深度神经网络DNN的多GPU数据并行框架 及其在语音识别的应用](https://cloud.tencent.com/developer/article/1029715?areaId=106001)

深度神经网络（Deep Neural Networks, 简称DNN）是近年来机器学习领域中的研究热点，产生了广泛的应用。DNN具有深层结构、数千万参数需要学习，导致训练非常耗时。GPU有强大的计算能力，适合于加速深度神经网络训练。DNN的单机多GPU数据并行框架是腾讯深度学习平台的一部分，腾讯深度学习平台技术团队实现了数据并行技术加速DNN训练，提供公用算法简化实验过程。对微信语音识别应用，在模型收敛速度和模型性能上都取得了有效提升——相比单GPU 4.6倍加速比，数十亿样本的训练数天收敛，测试集字错率

[国内 Mono 相关文章汇总](https://cloud.tencent.com/developer/article/1029966?areaId=106001)

一则新闻《软件服务提供商Xamarin融资1200万美元》，更详细的内容可以看Xamarin的官方博客Xamarin raises $12M to help you make better apps faster →。这篇新闻里告诉了我们目前Mono的用户规模“使用Xamarin软件的应用开发者已经超过15万，其中付费用户约为7500名。在Xamarin的客户中，还包括一些知名的企业，如美国国家仪器（National Instruments）和数字音乐订阅服务商Rdio等”。一直关注和研究Mono项目，今天

[任务记录：OEA 框架中的多类型树控件](https://cloud.tencent.com/developer/article/1031056?areaId=106001)

11年11月我主要对 OEA 框架中 WPF 自动界面生成模块中多类型树型表格控件进行重构，并同时支持更多的功能。这样，整个 OEA 就不再使用 DataGrid，结束了 DataGrid 与树型表格控件混用的情况。 ? 树型表格、一般表格统一为一个控件： ? 另外，附上对重构前的控件类结构设计分析图： ? ?



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/T3BbbELHko09qnxWNdnclghsnHg.png)



[Rafy 领域实体框架演示(3) - 快速使用 C/S 架构部署](https://cloud.tencent.com/developer/article/1031379?areaId=106001)

本系列演示如何使用 Rafy 领域实体框架快速转换一个传统的三层应用程序，并展示转换完成后，Rafy 带来的新功能。 《福利到！Rafy(原OEA)领域实体框架 2.22.2067 发布！》 《Rafy 领域实体框架示例(1) - 转换传统三层应用程序》 《Rafy 领域实体框架演示(2) - 新功能展示》 以 Rafy 开发的应用程序，其实体、仓库、服务代码不需要做任何修改，即可同时支持单机部署、C/S 分布式部署。本文将说明如果快速使用 C/S 分布式部署。 前言 截止到上一篇，我们开发的应用程序都是采



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/UypzbF0NAo1ZIaxhSGecdoR3n39.png)



[Rafy 领域实体框架演示(4) - 使用本地文件型数据库 SQLCE 绿色部署](https://cloud.tencent.com/developer/article/1031387?areaId=106001)

本系列演示如何使用 Rafy 领域实体框架快速转换一个传统的三层应用程序，并展示转换完成后，Rafy 带来的新功能。 《福利到！Rafy(原OEA)领域实体框架 2.22.2067 发布！》 《Rafy 领域实体框架示例(1) - 转换传统三层应用程序》 《Rafy 领域实体框架演示(2) - 新功能展示》 《Rafy 领域实体框架演示(3) - 快速使用 C/S 架构部署》 前言 支持一款与 Access 类似的文件型数据库，对于一些绿色安装的应用程序来说是非常必须的。使用 Rafy 领域实体框架开发的应



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Wo0eb307eoVoBfx9yCJcfbfEnOe.png)



[简述SQL2008部署多实例集群（学习）](https://cloud.tencent.com/developer/article/1032205?areaId=106001)

数据库集群 集群的存在意义是为了保证高可用、数据安全、扩展性以及负载均衡。 什么是集群？ 由二台或更多物理上独立的服务器共同组成的"虚拟"服务器称之为集群服务器。一项称做MicroSoft集群服务(MSCS)的微软服务可对集群服务器进 行管理。一个SQL Server集群是由二台或更多运行SQL Server的服务器(节点)组成的虚拟服务器。如果集群中的一个节点发生故障，集群中的另一个节点就承担这个故障节点的责任。认为一个 SQL Server集群能够给集群中的两个节点带来负载平衡，这是



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Y3ECbq1nEoiF4oxoQawcMLosnHc.png)



[互联网时代需要怎样的网管](https://cloud.tencent.com/developer/article/1036379?areaId=106001)

＂鹅厂网事＂由深圳市腾讯计算机系统有限公司技术工程事业群网络平台部运营，我们希望与业界各位志同道合的伙伴交流切磋最新的网络、服务器行业动态信息，同时分享腾讯在网络与服务器领域，规划、运营、研发、服务等层面的实战干货，期待与您的共同成长。 网络平台部以构建敏捷、弹性、低成本的业界领先海量互联网云计算服务平台，为支撑腾讯公司业务持续发展，为业务建立竞争优势、构建行业健康生态而持续贡献价值！ 1背景 近十年通信和互联网行业飞速发展，人们可以体验越来越丰富的互联网应用，从文本、图片到语音、视频，但万变不离其宗，



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/ZhylbH0UHojXyFxbVWIcFC9Tny1.png)



[前端框架这么多，要学哪个？](https://cloud.tencent.com/developer/article/1037868?areaId=106001)

这个话题很大，没有一定的水平是驾驭不了这个话题的。但我还是说说我的偏见。 现在这前端框架井喷一样的更新，不断的有新东西冒出来，先是Backbone，然后是Knockout，现在是Angular、React，这些都是什么鬼，反正我是一个也没深入学过。 然后就经常会有人问，学不过来啊，太多了，太快了。。学哪个好啊，，等等，， 先说结论，我的建议就是，如无必要，哪个也不要学！ 不要打我，听我解释。 框架这类东西，都是为了解决特定的业务问题而出现的。什么单页啊，模块化啊，分离啊，MVVM啊，双向绑定啊，， 为什么以

[使用Vmware虚拟机部署开发环境之Mac OS X系统安装](https://cloud.tencent.com/developer/article/1040685?areaId=106001)

一、使用VMware虚拟机部署Mac开发环境所需工具： Vmware Workstation 14.0虚拟机软件 VM安装Mac解锁工具Unlock 苹果操作系统（Mac OS X Mavericks 11） 云盘下载地址： 链接：https://pan.baidu.com/s/1o8srANw密码：irik 二、VMwareWorkstation 14上安装并使用Mac OS X 11 1、安装VMware Workstation 14虚拟机，安装过程不再赘述. 请参考《VMware Wo



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/Rb60binyzoVXSrxMWUdcw6Tsn4e.jpeg)



[Mariana DNN 多 GPU 数据并行框架](https://cloud.tencent.com/developer/article/1041933?areaId=106001)

本文是腾讯深度学习系列文章的第二篇，聚焦于腾讯深度学习平台Mariana中深度神经网络DNN的多GPU数据并行框架。 深度神经网络（Deep Neural Networks, 简称DNN）是近年来机器学习领域中的研究热点[1][2]，产生了广泛的应用。DNN具有深层结构、数千万参数需要学习，导致训练非常耗时。GPU有强大的计算能力，适合于加速深度神经网络训练。DNN的单机多GPU数据并行框架是Mariana的一部分，Mariana技术团队实现了数据并行技术加速DNN训练，提供公用算法简化实验过程。对微信



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/XCEHbj36IoBUzLxrQElcBNn8n4d.jpeg)



[Hexo博客的安装部署及多电脑同步](https://cloud.tencent.com/developer/article/1046404?areaId=106001)

Hexo安装教程很多，我这里尽可能的讲的细一些，把容易踩坑的地方以及后期多电脑同步所遇到的问题列出来，以便给自己及大家参考。本文主要讲解安装部署后源文件同步问题，当然，你可以采用网盘方式进行同步，但是这种方式不够程序员，也不能进行版本控制，如果你是一个多系统（windows、mac、linux）爱好者，那我建议你还是和我一样，采用git的方式进行源文件管理。使用github和Hexo，在几秒内，即可利用靓丽的主题生成静态网页。

[开发 | 如何理解Nvidia英伟达的Multi-GPU多卡通信框架NCCL？](https://cloud.tencent.com/developer/article/1060356?areaId=106001)

问题详情： 深度学习中常常需要多GPU并行训 练，而Nvidia的NCCL库NVIDIA/nccl（https://github.com/NVIDIA/nccl）在各大深度学习框架（Caffe/Tensorflow/Torch/Theano）的多卡并行中经常被使用，请问如何理解NCCL的原理以及特点？ 回答： NCCL是Nvidia Collective multi-GPU Communication Library的简称，它是一个实现多GPU的collective communication通信（all-



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/D6Evbe0QVoUoJzxeFxicackOn17.png)



[Github 项目推荐 | 微软开源 MMdnn，模型可在多框架间转换](https://cloud.tencent.com/developer/article/1062832?areaId=106001)

近期，微软开源了 MMdnn，这是一套能让用户在不同深度学习框架间做相互操作的工具。比如，模型的转换和可视化，并且可以让模型在 Caffe、Keras、MXNet、Tensorflow、CNTK、PyTorch 和 CoreML 之间转换。 Github：https://github.com/Microsoft/MMdnn MMdnn 中的「MM」代表模型管理，「dnn」的意思是深度神经网络。它可以将由一个框架训练的 DNN 模型转换到其他框架里，其主要的特点如下： Model File Converter



![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/PSkvb6uwLoXZVHx2iU6cWhbnnbf.jpeg)



 相关推荐

如何在腾讯云上部署 Facebook 的ParlAI 训练框架

更多 >

