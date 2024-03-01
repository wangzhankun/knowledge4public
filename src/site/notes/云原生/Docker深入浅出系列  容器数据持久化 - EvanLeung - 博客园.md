---
{"dg-publish":true,"page-title":"Docker深入浅出系列 | 容器数据持久化 - EvanLeung - 博客园","url":"https://www.cnblogs.com/evan-liang/p/12372371.html","tags":["云原生/docker"],"permalink":"/云原生/Docker深入浅出系列  容器数据持久化 - EvanLeung - 博客园/","dgPassFrontmatter":true}
---

转载自 https://www.cnblogs.com/evan-liang/p/12372371.html

> Docker已经上市很多年，不是什么新鲜事物了，很多企业或者开发同学以前也不多不少有所接触，但是有实操经验的人不多，本系列教程主要偏重实战，尽量讲干货，会根据本人理解去做阐述，具体官方概念可以查阅官方教程，因为本系列教程对前一章节有一定依赖，建议先学习前面章节内容。

本系列教程导航:  
[Docker深入浅出系列 | 容器初体验](https://www.cnblogs.com/evan-liang/p/12237400.html)  
[Docker深入浅出系列 | Image实战演练](https://www.cnblogs.com/evan-liang/p/12244304.html)  
[Docker深入浅出系列 | 单节点多容器网络通信](https://www.cnblogs.com/evan-liang/p/12271468.html)

教程目的：

-   了解Docker怎么实现数据存储
-   了解Docker数据挂载方式是什么
-   了解Docker数据持久化怎么使用
-   了解Docker不同数据挂载方式的使用场景

[![](https://img-blog.csdnimg.cn/20200224202643664.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0V2YW5fTGV1bmc=,size_16,color_FFFFFF,t_70)](https://img-blog.csdnimg.cn/20200224202643664.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0V2YW5fTGV1bmc=,size_16,color_FFFFFF,t_70)  
Docker容器对于宿主机器来说只是一个运行在Linux上的应用，因此它的数据存储还是会依赖宿主机器，Docker是通过挂载宿主机文件系统或内存的方式来实现数据存储的，挂载方式有三种:volume、bind mount和tmpfs。

-   volumes - 在宿主的文件系统上的docker工作路径下创建一个文件夹（`/var/lib/docker/volumes`）来存储数据，其他非docker进程是不能修改该路径下的文件，完全由docker来管理
-   bind mounts - 可以存储在宿主机器任何一个地方，但是会依赖宿主机器的目录结构，不能通过docker CLI 去直接管理，并且非docker进程和docker进程都可以修改该路径下的文件
-   tmpfs - 无论是在Docker主机上还是在容器内，tmpfs挂载都不会持久保存在磁盘上，它会将信息存储在宿主机器内存里。 容器在其生存期内可以使用它来存储非持久状态或敏感信息。 例如，在内部，swarm services 使用tmpfs挂载将机密挂载到服务的容器中 或者 我们一些不需要持久化数据的开发测试环境，可以使用tmpfs

---

Volumes 是Docker推荐的挂载方式，与把数据存储在容器的可写层相比，使用Volume可以避免增加容器的容量大小，还可以使存储的数据与容器的生命周期独立。

-   与bind mounts相比，volumes更易于备份或迁移。
-   您可以使用Docker CLI命令或Docker API管理Volumes。
-   volumes在Linux和Windows容器上均可工作。
-   可以在多个容器之间更安全地共享volumes。
-   volumes驱动程序使您可以将volumes存储在远程主机或云提供程序上，以加密volumes内容或添加其他功能。

### **通过默认`-v`方式**

默认情况下，docker会帮我们创建一个随机命名的volume

1.利用我们前面章节下载的image，创建一个容器，命名为`mysql01`

2.我们可以看看容器到底有没有自动帮我们创建一个volumes

通过上面的输出结果可以看到，docker 默认帮我创建了一个volume，并且随机起了一个看不懂的名字

3.通过`docker inspect`查看volume详细信息

从上面volume详情可以了解到，现在容器的数据是挂在在宿主机器上 `/var/lib/docker/`目录下， `scope`是本地

4.通过`-v`指定容器volume的名字，使用我们自定义的一个可读的名字

5.再次查看下volume是否创建成功

刚才创建的volume已经成功了

6.再查看下volume的详细信息

从上面信息可以看到，容器已经成功挂载宿主机器上的evan\_volume

### **通过`--mount`方式**

`-v`能做的`--mount`指令都可以做，与`-v`指令对比，`--mount`指令更灵活，支持更多复杂操作，并且不需要严格按照参数顺序，通过key value键值对方式进行配置，可读性更高。

`--mount`有以下几个参数:

-   **type** - type可以是bind、volume或者tmpfs，默认是volume
-   **source** - 宿主机上的目录路径，可以用缩写`src`
-   **destination** - 目标路径，容器上挂载的路径，可以用`dst`或者 `target`
-   **readonly** - 可选项，如果设置了，那么容器挂载的路径会被设置为只读
-   **volume-opt** - 可选项，当volume驱动接受同时多个参数作为选项时，可以以多个键值对的方式传入

1.创建一个容器，命名为mysql-mount，指定volume名为`mysql-mount`

2.查看volume是否创建成功

从上面查询结果可以看出来，mysql-mount已经创建成功

3.查看宿主机器是否存在对应的目录

从输出结果可以看到，通过`--mount`可以实现跟`-v`同样的操作结果，数据也绑定宿主机器上docker路径对应目录

---

与volumes相比，bind mount的功能有限。 使用绑定安装时，会将主机上的文件或目录安装到容器中。 文件或目录由主机上的完整或相对路径引用。 相比之下，当您使用volume时，将在主机上Docker的存储目录中创建一个新目录，并且Docker管理该目录的内容。

该文件或目录不需要在Docker主机上已经存在。 如果尚不存在，则按需创建。 bind mounts性能非常好，但是它们依赖于具有特定目录结构的主机文件系统。 如果要开发新的Docker应用程序，请考虑使用命名volume。 您不能使用Docker CLI命令直接管理bind mounts

1.创建一个tomcat容器，命名为`tomcat-bind`,挂载宿主机器路径为`/tmp`

2.通过`docker inspect tomcat-mount`查看容器信息

可以看到容器已经成功挂载到宿主机器上的`/tmp`目录，而不是前面我们演示的docker管理路径下

---

使用tmpfs不会持久化数据，数据只会存放在宿主机器内存中

1.创建一个tomcat容器，命名为`tomcat-tmps`，指定挂载方式为`temps`

2.我们通过`docker container inspect tomcat-tmpfs` 查看下是否会创建任务目录在宿主机器

从上面输出结果可以看到，宿主机器上并没有任何目录，只是在目标路径也就是容器里指定了`/tmp`作为数据存储路径

---

> 思路：我们尝试在mysql容器创建一个数据库，然后退出后把容器删除掉，再创建一个新的容器，数据存储路径指向同一个volume，观察是否在新的容器可以看到上一个容器创建好的数据库

[![](https://img-blog.csdnimg.cn/20200227143822577.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0V2YW5fTGV1bmc=,size_16,color_FFFFFF,t_70)](https://img-blog.csdnimg.cn/20200227143822577.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0V2YW5fTGV1bmc=,size_16,color_FFFFFF,t_70)  
1.进入我们上面创建的mysql

2.创建数据库`eshare`

从输出结果可以看到，数据库已经创建成功

3.退出容器，删除mysyql01容器

容器mysql01已经顺利删除

4.查看mysql01挂载的volume是否还在

可以看到，对应的volume还在

5.创建一个新mysql容器，命名为mysql-volume，并且绑定mysql01的volume

6.验证新的容器mysql-volume 中，是否存在已经创建好的数据库`eshare`

从上面输出结果可以看到，新的容器已经存在之前创建好的数据库，这就证明了docker不仅可以持久化数据，并且不同容器还可以共享同一个volume。

---

有兴趣的朋友，欢迎加我公众号一起交流，有问题可以留言，平时工作比较忙，我也抽时间尽量回复每位朋友的留言，谢谢！  
[![](https://img-blog.csdnimg.cn/20200321213157673.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0V2YW5fTGV1bmc=,size_16,color_FFFFFF,t_70)](https://img-blog.csdnimg.cn/20200321213157673.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0V2YW5fTGV1bmc=,size_16,color_FFFFFF,t_70)

\_\_EOF\_\_

![](https://eshare0823.oss-cn-shenzhen.aliyuncs.com/WechatIMG73_1579923663899.png)

Evan Leung，CSDN博客砖家，ACP认证砖家，在IT行业摸滚打爬多年，经历了金融行业和移动互联网行业，参与多个大中型企业级项目设计与核心开发，曾在某一线互联网金融公司担任产品线高级技术经理，目前在某世界500强金融公司打杂。