---
{"dg-publish":true,"page-title":"【后台技术】Docker基础篇 - 知乎","url":"https://zhuanlan.zhihu.com/p/683330478","tags":["云原生/docker"],"permalink":"/云原生/【后台技术】Docker基础篇 - 知乎/","dgPassFrontmatter":true}
---

转载自 https://zhuanlan.zhihu.com/p/683330478

> 以下内容来自腾讯工程师 link

## Docker基础篇

云原生技术生态是一个庞大的技术集合，为了便于大家对于Docker、Kubernetes、Prometheus、Envoy、CoreDNS、containerd、Fluentd、Vitess、Jaeger等技术的熟悉，因此整理了云原生二十篇详解相关内容。

## 第一部分：Docker基础知识

对于容器和虚拟机的对比一些知识，读者看这篇文章之前应该已经有所了解： 首先容器比虚拟机更加轻量，不需要在原来的硬件上再做一层虚拟机化； 其次容器是共享宿主机上的一个进程，启动更快，多个容器之间的通讯性能损失最小；

虚拟机和容器的分层架构可以看下图：

![](https://pic2.zhimg.com/v2-06abd90160e8cbc87d1887ddb5737275_b.jpg)

### 1、Docker引擎

![](https://pic1.zhimg.com/v2-29ed1024cae147c00a965d99cd2b1828_b.jpg)

Docker容器架构经过几次演进，随着OCI规范的制定和老的架构问题，现在Docker的架构如上图； （1）Docker Client主要是命令行，比如在终端上执行`docker ps -a`；

（2）Daemon接收CURD指令，主要是与Containerd交互；

（3）Containerd是容器的生命周期管理，主要功能：

-   管理容器的生命周期（从创建容器到销毁容器）
-   拉取/推送容器镜像
-   存储管理（管理镜像及容器数据的存储）
-   调用`runc`运行容器（与`runc`等容器运行时交互）
-   管理容器网络接口及网络

（4）`containerd-shim`是`runc`启动的中间层；

（5）`runc`是OCI容器运行时的规范参考实现，`runc`是从Docker的 libcontainer中迁移而来的，实现了容器启停、资源隔离等功能；

### 2、容器创建流程

（1）Docker容器启动时候，Docker Daemon并不能直接创建，而是请求 `containerd`来创建容器；

（2）当`containerd`收到请求后，也不会直接去操作容器，而是创建`containerd-shim`的进程，让这个进程去操作容器，指定容器进程是需要一个父进程来做状态收集、维持stdin等fd打开等工作的，假如这个父进程就是`containerd`，那如果`containerd`挂掉的话，整个宿主机上所有的容器都得退出，而引入`containerd-shim`中间层规避这个问题；

（3）创建容器需要做一些`namespaces`和`cgroups`的配置，以及挂载`root`文件系统等操作，`runc`就可以按照OCI文档来创建一个符合规范的容器；

（4）真正启动容器是通过`containerd-shim`去调用`runc`来启动容器的，`runc`启动完容器后本身会直接退出，`containerd-shim`则会成为容器进程的父进程, 负责收集容器进程的状态, 上报给`containerd`, 并在容器中`pid=1`的进程退出后接管容器中的子进程进行清理, 确保不会出现僵尸进程；

尝试执行命令 `docker container run --name test -it alpine:latest sh` ，进入容器：

```
[root@VM-16-16-centos ~]# docker container run --name test -it alpine:latest sh
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
7264a8db6415: Pull complete
Digest: sha256:7144f7bab3d4c2648d7e59409f15ec52a18006a128c733fcff20d3a4a54ba44a
Status: Downloaded newer image for alpine:latest
```

### 3、镜像

镜像是一种轻量级、可执行的独立软件包，用来打包软件运行环境和基于运行环境开发的软件，它包含运行某个软件所需的所有内容，包括代码、运行时库、环境变量和配置文件，将所有的应用和环境，直接打包为docker镜像，就可以直接运行。

**（1）镜像加载原理**

-   分层：Docker镜像采用分层的方式构建，每一个镜像都由一组镜像组合而成，每一个镜像层都可以被需要的镜像所引用，实现了镜像之间共享镜像层的效果，同时在镜像的上传与下载过程当中有效的减少了镜像传输的大小，在传输过程当中本地或注册中心只需要存在一份底层的基础镜像层即可，真正被保存和下载的内容是用户构建的镜像层，而在构建过程中镜像层通常会被缓存以缩短构建过程
-   写时复制：底层镜像层在多个容器间共享，每个容器启动时不需要复制一份镜像文件，而是将所有需要的镜像层以只读的方式挂载到一个挂载点，在只读层上再覆盖一层读写层，在容器运行过程中产生的新文件将会写入到读写层，被修改过的底层文件会被复制到读写层并且进行修改，而老文件则被隐藏

![](https://pic4.zhimg.com/v2-107fafb3d56cefcbf210bc5af211ce87_b.jpg)

-   联合挂载：Docker采用联合挂载技术，在同一个挂载点同时挂载多个文件系统，从而使得容器的根目录看上去包含了各个镜像层的所有文件
-   内容寻址：根据镜像层内容计算校验和，生成一个内容哈希值，并使用该值来充当镜像层ID、索引镜像层，内容寻址提高了镜像的安全性，在pull、push和load、save操作后检测数据的完整性，另外基于内容哈希来索引镜像层，对于来自不同构建的镜像层，只要拥有相同的内容哈希值，就能被不同的镜像所引用

**（2）镜像如何解决多架构的问题**

Docker的方便性决定了镜像需要适配多的架构，为了实现这一特性，镜像仓库服务API支持两种重要的架构，Manifest列表和Manifest。

-   首先Manifest列表是指某个镜像标签支持的架构列表，其支持每种架构都有自己的Manifest定义；
-   其次拉取镜像时，Docker Client会先调用镜像仓库相关的API，如果有Manifest列表，则找到当前系统架构这一项（如：ARM），并解析Manifest组成对应的镜像层的SHA；
-   最后就是拉取镜像的过程；

![](https://pic3.zhimg.com/v2-f8263fe00b02542da3a12e410a5e850a_b.jpg)

**（3）镜像的命令行**

**（a）拉取镜像**

`docker image pull <repository>:<tag>`

```
docker image pull alpine:latest

# 输出
latest: Pulling from library/alpine
Digest: sha256:7144f7bab3d4c2648d7e59409f15ec52a18006a128c733fcff20d3a4a54ba44a
Status: Image is up to date for alpine:latest
docker.io/library/alpine:latest 
```

**（b）查看镜像**

`docker image ls --filter=过滤标签`

```
docker images ls

# 输出
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
[root@VM-16-16-centos ~]# docker image ls
REPOSITORY          TAG            IMAGE ID       CREATED         SIZE
alpine              latest         7e01a0d0a1dc   13 days ago     7.34MB
cnrancher/autok3s   v0.6.1         58e8405a4782   9 months ago    254MB
rancher/k3d-tools   5.2.2          ad4072a16136   20 months ago   18.7MB
rancher/k3d-proxy   5.2.2          d0554070bc8c   20 months ago   42.4MB
rancher/k3s         v1.21.7-k3s1   4cbf38ec7da6   20 months ago   174MB 
```

输出字段解释：

-   REPOSITORY：镜像的地址
-   TAG：镜像的标签
-   IMAGE ID：镜像ID
-   CREATED：创建时间
-   SIZE：镜像大小

**（c）搜索镜像**

`docker search alpine --filter 过滤标签`

```
docker search alpine --filter 'is-official=true'

# 输出
NAME      DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
alpine    A minimal Docker image based on Alpine Linux…   10203     [OK] 
```

**（d）镜像详情**

`docker image inspect ubuntu:latest`

```
docker image inspect ubuntu:latest

# 输出
[
    {
        "Id": "sha256:01f29b872827fa6f9aed0ea0b2ede53aea4ad9d66c7920e81a8db6d1fd9ab7f9",
        "RepoTags": [
            "ubuntu:latest"
        ],
        "RepoDigests": [
            "ubuntu@sha256:ec050c32e4a6085b423d36ecd025c0d3ff00c38ab93a3d71a460ff1c44fa6d77"
        ],
        "Parent": "",
        "Comment": "",
        "Created": "2023-08-04T04:53:00.244301537Z",
        "Container": "822f331d59eb72d1131a8a5fcb2b935c8110114c22be26c8572d9881dcff31e0",
        "ContainerConfig": {
            "Hostname": "822f331d59eb",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            ],
            "Cmd": [
                "/bin/sh",
                "-c",
                "#(nop) ",
                "CMD [\"/bin/bash\"]"
            ],
            "Image": "sha256:22d9eb9a70973f7eb625681c244522dad0bf3b4f8e9ea75977b09d8551364a19",
            "Volumes": null,
            "WorkingDir": "",
            "Entrypoint": null,
            "OnBuild": null,
            "Labels": {
                "org.opencontainers.image.ref.name": "ubuntu",
                "org.opencontainers.image.version": "22.04"
            }
        },
        "DockerVersion": "20.10.21",
        "Author": "",
        "Config": {
            "Hostname": "",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            ],
            "Cmd": [
                "/bin/bash"
            ],
            "Image": "sha256:22d9eb9a70973f7eb625681c244522dad0bf3b4f8e9ea75977b09d8551364a19",
            "Volumes": null,
            "WorkingDir": "",
            "Entrypoint": null,
            "OnBuild": null,
            "Labels": {
                "org.opencontainers.image.ref.name": "ubuntu",
                "org.opencontainers.image.version": "22.04"
            }
        },
        "Architecture": "amd64",
        "Os": "linux",
        "Size": 77823376,
        "VirtualSize": 77823376,
        "GraphDriver": {
            "Data": {
                "MergedDir": "/var/lib/docker/overlay2/7340fd0aaa10bc4e4b4bd202b9b4165e3e3c712af3082cbc606cc5e3e93b53a2/merged",
                "UpperDir": "/var/lib/docker/overlay2/7340fd0aaa10bc4e4b4bd202b9b4165e3e3c712af3082cbc606cc5e3e93b53a2/diff",
                "WorkDir": "/var/lib/docker/overlay2/7340fd0aaa10bc4e4b4bd202b9b4165e3e3c712af3082cbc606cc5e3e93b53a2/work"
            },
            "Name": "overlay2"
        },
        "RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:bce45ce613d34bff6a3404a4c2d56a5f72640f804c3d0bd67e2cf0bf97cb950c"
            ]
        },
        "Metadata": {
            "LastTagTime": "0001-01-01T00:00:00Z"
        }
    }
] 
```

以上是包含一个镜像所有的信息，包括CPU架构，容器命令行等信息。

**（e）保存或加载镜像文件**

保存：`docker image save -o [镜像tar文件] [镜像ID]` 加载：`docker load -i [镜像tar文件]`

```
[root@VM-16-16-centos ~]# docker image save -o alpine.tar 7e01a0d0a1dc
[root@VM-16-16-centos ~]# ls
alpine.tar  a.out  core.365609  test.cc

[root@VM-16-16-centos ~]# docker load -i  alpine.tar
Loaded image ID: sha256:7e01a0d0a1dcd9e539f8e9bbd80106d59efbdf97293b3d38f5d7a34501526cdb 
```

**（f）删除镜像**

`docker image rm [镜像ID]`

```
[root@VM-16-16-centos ~]# docker image rm 7e01a0d0a1dc -f
Untagged: alpine:latest
Untagged: alpine@sha256:7144f7bab3d4c2648d7e59409f15ec52a18006a128c733fcff20d3a4a54ba44a
Deleted: sha256:7e01a0d0a1dcd9e539f8e9bbd80106d59efbdf97293b3d38f5d7a34501526cdb 
```

### 4、容器与容器化

前面已经提到过，容器是共享操作系统内核，所以容器比虚拟机的开销更小，往往一台物理机上可以运行数千个容器，而且在后台开发中，容器使用方便，已经成为服务部署的标配，那下面我们来了解一下容器和容器化。

**（1）启动一个简单的容器**

```
docker run -it ubuntu:latest /bin/bash

# 输出
[root@node1 ~]# docker run -it ubuntu:latest /bin/bash
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
7b1a6ab2e44d: Pull complete 
Digest: sha256:626ffe58f6e7566e00254b638eb7e0f3b11d4da9675088f4781a50ae288f3322
Status: Downloaded newer image for ubuntu:latest
root@41b22410e6bc:/#
```

**（2）容器的生命周期**

-   容器有一个PID为1的进程，这个进程是容器的主进程，主进程挂掉，整个容器也会退出
-   容器的退出，可以使用`docker stop <Container ID>`，但是容器退出有时候需要保留容器内运行的文件
-   容器的删除，可以使用`docker rm <Container ID>`，不过删除之前可以先停止容器
-   容器在整个生命周期的数据是安全的，即使容器被删除，容器的数据存储在卷中，这些数据也会保存下来
-   容器`docker stop`背后的原理是什么呢？在Linux下，`docker stop`是先向容器的`PID 1`进程发送`SIGTERM`的信号，如果10s内进程没有终止，就会发送`SIGKILL`的信号
-   容器自动重启策略包括`--restart always`，`--restart unless-stopped`和`--restart on-failed`，分别表示如下：  
    

-   `--restart always`是容器被kill掉后会自动重启或者是`Docker daemon`重启的时候也会重启
-   `--restart unless-stopped`是容器被kill掉后会自动重启，但是`Docker daemon`重启的时候不会重启
-   `--restart on-failed`是容器退出时返回不为0则重启

**（3）快速清理**

```
docker rm $(docker container ls -aq) -f

# 输出
[root@node1 ~]# docker rm $(docker container ls -aq) -f
41b22410e6bc
d280d169f140
2d0ab5f14a5f
654ee324b7ac
2d0694c9e06a
a78be97042fd
b9e7e71c07eb
6a1c7e736b2a
```

**（4）应用容器化流程**

![](https://pic4.zhimg.com/v2-677e37596450a834f80c4ca45fe219f7_b.jpg)

-   构建期间，通过流水线和Dockerfile，执行镜像构建
-   交互期间，通过镜像推送到Docker hub中，获取镜像地址
-   运行期间，通过Docker容器拉取镜像后运行

**（5）Dockerfile**

```
FROM apline
LABEL maintainer="xxx@gmail.com"
RUN apk add --update nodejs nodejs-npm
COPY . /src
WORKDIR /src
RUN npm install
EXPOSE 8080
ENTRYPOINT ["node", "./app.js"]
```

以上是一个Dockerfile文件，字段解释：

-   `FROM` 指定的基础镜像层
-   `LABEL` 指定当前镜像的标签信息，可以以key-value形式存在，这样可以自定义一些元素
-   `RUN` 在镜像内运行的命令
-   `COPY` 拷贝文件到镜像中
-   `WORKDIR` 设定Dockerfile中尚未执行的指令设置工作目录
-   `EXPOSE` 设置镜像对外暴露的端口
-   `ENTRYPOINT` 设置镜像在容器中运行的入口程序

**（6）Dockerfile镜像**

-   在上文中已经提到过镜像，那么上述的Dockerfile有几层镜像呢？四层，分别是指令`FROM apline`，`RUN apk add --update nodejs nodejs-npm`，`COPY . /src`和`RUN npm install`执行后的镜像叠加，可以执行`docker image history 镜像tag`或者`docker image inspect 镜像tag`查看。
-   执行`docker image build -t xxx/web:latest .`或者`docker image build -t xxx/web:latest -f xxxDockerfile`就可以构建镜像
-   执行`docker image push xxx/web:latest`通过登录DockerHUB或者私有化的镜像仓库，将镜像推送到HUB中

**（7）多阶段构建**

在Docker 17.05版本以后，提供了多阶段构建，什么是多阶段构建呢？

```
FROM node:latest AS storefront
WORKDIR /usr/src/app/react-app
COPY react-app .
RUN npm install
RUN npm run build

FROM server:latest AS appserver
WORKDIR /usr/src/app/appserver
...

FROM production:latest AS production
WORKDIR /static
COPY --from=storefront /usr/src/app/react-app/build/ .
WORKDIR /app
COPY --from=appserver /usr/src/app/appserver/build/ .
ENTRYPOINT ["./startup", "--config=..."]
CMD ["xxxx"]
```

以上是一个多阶段构建的Dockerfile文件，字段解释：

-   `COPY --from=`表示从之前的构建阶段的镜像中复制某些文件
-   上面的Dockerfile会生成三个镜像

**（8）最佳实践**

-   利用已有的环境构建镜像：  
    

-   docker build构架镜像的时候会构建和拉取缓存镜像，所以为了加速构建，可以将常用的一些镜像打到一个大的镜像中
-   对于一些不需要缓存的镜像可以使用docker image build --nocache=true

-   合并镜像：

-   有些时候我们构建的镜像比较大，我们可以通过合并镜像减少镜像大小，使用docker image build --squash

-   使用Dockerfile的 `ENV`， `HEALTHCHECK`， `ONBUILD` 指令
-   Dockerfile中`ENTRYPOINT`和`CMD`的区别：  （[[云原生/Dockerfile ENTRYPOINT和CMD的区别 - 知乎\|Dockerfile ENTRYPOINT和CMD的区别 - 知乎]]）
    

-   Dockerfile文件中，必须包含`ENTRYPOINT`或者`CMD`命令
-   `CMD`：指令允许用户指定容器的默认执行的命令。此命令会在容器启动且`docker run`没有指定其他命令时运行
-   `ENTRYPOINT`：`ENTRYPOINT`的Exec格式用于设置容器启动时要执行的命令及其参数，同时可通过`CMD`命令或者命令行参数提供额外的参数，`ENTRYPOINT`中的参数始终会被使用，这是与`CMD`命令不同的一点

### 5、Docker Compose

[[云原生/Docker Compose vs. Dockerfile with Code Examples \|Docker Compose vs. Dockerfile with Code Examples ]]

**（1）Docker-Compose文件**

```
version: '3.4'

services:
  webmvc:
    image: eshop/webmvc
    environment:
      - CatalogUrl=http://catalog-api
      - OrderingUrl=http://ordering-api
      - BasketUrl=http://basket-api
    ports:
      - "5100:80"
    depends_on:
      - catalog-api
      - ordering-api
      - basket-api

  catalog-api:
    image: eshop/catalog-api
    environment:
      - ConnectionString=Server=sqldata;Initial Catalog=CatalogData;User Id=sa;Password=[PLACEHOLDER]
    expose:
      - "80"
    ports:
      - "5101:80"
    #extra hosts can be used for standalone SQL Server or services at the dev PC
    extra_hosts:
      - "CESARDLSURFBOOK:10.0.75.1"
    depends_on:
      - sqldata

  ordering-api:
    image: eshop/ordering-api
    environment:
      - ConnectionString=Server=sqldata;Database=Services.OrderingDb;User Id=sa;Password=[PLACEHOLDER]
    ports:
      - "5102:80"
    #extra hosts can be used for standalone SQL Server or services at the dev PC
    extra_hosts:
      - "CESARDLSURFBOOK:10.0.75.1"
    depends_on:
      - sqldata

  basket-api:
    image: eshop/basket-api
    environment:
      - ConnectionString=sqldata
    ports:
      - "5103:80"
    depends_on:
      - sqldata

  sqldata:
    environment:
      - SA_PASSWORD=[PLACEHOLDER]
      - ACCEPT_EULA=Y
    ports:
      - "5434:1433"

  basketdata:
    image: redis
```

上述语法说明：

-   `build` 指定`Dockerfile`所在文件夹的路径，Compose将会利用它自动构建这个镜像，然后使用这个镜像
-   `command` 覆盖容器启动后默认执行的命令
-   `links` 链接到其它服务中的容器
-   `ports` 暴露端口信息，使用宿主：容器（HOST:CONTAINER）格式或者仅仅指定容器的端口（宿主将会随机选择端口）都可以
-   `expose` 暴露端口，但不映射到宿主机，只被连接的服务访问
-   `volumes` 卷挂载路径设置，可以设置宿主机路径（HOST:CONTAINER）或加上访问模式

**（2）Docker-Compose命令**

-   `docker-compose up -f xxx.yaml` 查找本地文件的docker-compose.yaml或者指定的文件，然后启动
-   `docker-compose down` 停止并删除docker-compose.yaml启动的服务，会删除容器和网络，但是不会删除卷和镜像
-   `docker-compose ps` 查看应用的状态
-   `docker-compose stop` 停止docker-compose.yaml启动的服务
-   `docker-compose top` 列出各个服务的进程
-   `docker-compose restart` 重启启动docker-compose.yaml的服务
-   `docker-compose rm` 删除已经停止的服务

### 6、容器的持久化数据

容器中有持久化数据和非持久化数据，两种在实用场景下有很多，其中非持久化是自动创建，从属于容器，生命周期与容器相同，如果希望数据在容器中保留，可以将需要的数据存储在卷上。

![](https://pic2.zhimg.com/v2-678a9ea050e00aac3061893b8b6a0bf9_b.jpg)

**（1）创建存储卷**

使用命令创建存储卷 `docker volume create myvol`，然后可以通过 `docker volume inspect myvol` 获得输出：

```
[
    {
        "CreatedAt": "2023-09-02T08:03:38+08:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/myvol/_data",
        "Name": "myvol",
        "Options": {},
        "Scope": "local"
    }
]
```

【后台技术】Docker基础篇和网络篇  
热榜最高第1名  
[linkxzhou](https://link.zhihu.com/?target=https%3A//km.woa.com/user/linkxzhou)2023年10月09日  
宽屏  
3232  
7  
274

AI摘要

| 导语IEG增值服务部 - 技术藏经阁 ：秉承增值服务部核心的创新向上的理念，利用KM知识分享开放平台来沉淀和输出部门内的核心技术相关能力。构建与公司团共同交流、共同成长的开放性知识K吧。 更多文章请点击：[http://km.oa.com/group/34294](https://link.zhihu.com/?target=http%3A//km.oa.com/group/34294)

目录  
[Docker基础篇](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%23docker%25E5%259F%25BA%25E7%25A1%2580%25E7%25AF%2587)  
[第一部分：Docker基础知识](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%23%25E7%25AC%25AC%25E4%25B8%2580%25E9%2583%25A8%25E5%2588%2586%25EF%25BC%259Adocker%25E5%259F%25BA%25E7%25A1%2580%25E7%259F%25A5%25E8%25AF%2586)  
[1、Docker引擎](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%231%25E3%2580%2581docker%25E5%25BC%2595%25E6%2593%258E)  
[2、容器创建流程](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%232%25E3%2580%2581%25E5%25AE%25B9%25E5%2599%25A8%25E5%2588%259B%25E5%25BB%25BA%25E6%25B5%2581%25E7%25A8%258B)  
[2、镜像](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%232%25E3%2580%2581%25E9%2595%259C%25E5%2583%258F)  
[3、容器与容器化](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%233%25E3%2580%2581%25E5%25AE%25B9%25E5%2599%25A8%25E4%25B8%258E%25E5%25AE%25B9%25E5%2599%25A8%25E5%258C%2596)  
[4、Docker Compose](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%234%25E3%2580%2581docker-compose)  
[4、容器的持久化数据](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%234%25E3%2580%2581%25E5%25AE%25B9%25E5%2599%25A8%25E7%259A%2584%25E6%258C%2581%25E4%25B9%2585%25E5%258C%2596%25E6%2595%25B0%25E6%258D%25AE)  
[第二部分：Docker Swarm](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%23%25E7%25AC%25AC%25E4%25BA%258C%25E9%2583%25A8%25E5%2588%2586%25EF%25BC%259Adocker-swarm)  
[1、Docker Swarm原理](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%231%25E3%2580%2581docker-swarm%25E5%258E%259F%25E7%2590%2586)  
[2、Docker Swarm基本命令](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%232%25E3%2580%2581docker-swarm%25E5%259F%25BA%25E6%259C%25AC%25E5%2591%25BD%25E4%25BB%25A4)  
[Docker网络篇](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%23docker%25E7%25BD%2591%25E7%25BB%259C%25E7%25AF%2587)  
[第一部分：Docker网络](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%23%25E7%25AC%25AC%25E4%25B8%2580%25E9%2583%25A8%25E5%2588%2586%25EF%25BC%259Adocker%25E7%25BD%2591%25E7%25BB%259C)  
[1、详解](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%231%25E3%2580%2581%25E8%25AF%25A6%25E8%25A7%25A3)  
[第二部分：网桥和Overlay详解](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%23%25E7%25AC%25AC%25E4%25BA%258C%25E9%2583%25A8%25E5%2588%2586%25EF%25BC%259A%25E7%25BD%2591%25E6%25A1%25A5%25E5%2592%258Coverlay%25E8%25AF%25A6%25E8%25A7%25A3)  
[1、网桥（Bridge）](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%231%25E3%2580%2581%25E7%25BD%2591%25E6%25A1%25A5%25EF%25BC%2588bridge%25EF%25BC%2589)  
[2、Overlay](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%232%25E3%2580%2581overlay)  
[第三部分：服务发现和Ingress](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%23%25E7%25AC%25AC%25E4%25B8%2589%25E9%2583%25A8%25E5%2588%2586%25EF%25BC%259A%25E6%259C%258D%25E5%258A%25A1%25E5%258F%2591%25E7%258E%25B0%25E5%2592%258Cingress)  
[1、服务发现](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%231%25E3%2580%2581%25E6%259C%258D%25E5%258A%25A1%25E5%258F%2591%25E7%258E%25B0)  
[2、Ingress](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%232%25E3%2580%2581ingress)  
[参考](https://link.zhihu.com/?target=https%3A//km.woa.com/articles/show/588476%3Fkmref%3Dvkm_discover%23%25E5%258F%2582%25E8%2580%2583)**最近在我的公众号《周末程序猿》整理云原生二十篇，顺便把文章搬过来，有兴趣的可以读读或者关注。**  
Docker基础篇  
云原生技术生态是一个庞大的技术集合，为了便于大家对于Docker、Kubernetes、Prometheus、Envoy、CoreDNS、containerd、Fluentd、Vitess、Jaeger等技术的熟悉，因此整理了云原生二十篇详解相关内容。  
第一部分：Docker基础知识  
对于容器和虚拟机的对比一些知识，读者看这篇文章之前应该已经有所了解： 首先容器比虚拟机更加轻量，不需要在原来的硬件上再做一层虚拟机化； 其次容器是共享宿主机上的一个进程，启动更快，多个容器之间的通讯性能损失最小；  
虚拟机和容器的分层架构可以看下图：

  
1、Docker引擎  

Docker容器架构经过几次演进，随着OCI规范的制定和老的架构问题，现在Docker的架构如上图； （1）Docker Client主要是命令行，比如在终端上执行`docker ps -a`；  
（2）Daemon接收CURD指令，主要是与Containerd交互；  
（3）Containerd是容器的生命周期管理，主要功能：  

-   管理容器的生命周期（从创建容器到销毁容器）
-   拉取/推送容器镜像
-   存储管理（管理镜像及容器数据的存储）
-   调用`runc`运行容器（与`runc`等容器运行时交互）
-   管理容器网络接口及网络

（4）`containerd-shim`是`runc`启动的中间层；  
（5）`runc`是OCI容器运行时的规范参考实现，`runc`是从Docker的 libcontainer中迁移而来的，实现了容器启停、资源隔离等功能；  
2、容器创建流程  
（1）Docker容器启动时候，Docker Daemon并不能直接创建，而是请求 `containerd`来创建容器；  
（2）当`containerd`收到请求后，也不会直接去操作容器，而是创建`containerd-shim`的进程，让这个进程去操作容器，指定容器进程是需要一个父进程来做状态收集、维持stdin等fd打开等工作的，假如这个父进程就是`containerd`，那如果`containerd`挂掉的话，整个宿主机上所有的容器都得退出，而引入`containerd-shim`中间层规避这个问题；  
（3）创建容器需要做一些`namespaces`和`cgroups`的配置，以及挂载`root`文件系统等操作，`runc`就可以按照OCI文档来创建一个符合规范的容器；  
（4）真正启动容器是通过`containerd-shim`去调用`runc`来启动容器的，`runc`启动完容器后本身会直接退出，`containerd-shim`则会成为容器进程的父进程, 负责收集容器进程的状态, 上报给`containerd`, 并在容器中`pid=1`的进程退出后接管容器中的子进程进行清理, 确保不会出现僵尸进程；  
尝试执行命令 `docker container run --name test -it alpine:latest sh` ，进入容器：  
\[root@VM-16-16-centos ~\]# docker container run --name test -it alpine:latest sh Unable to find image 'alpine:latest' locally latest: Pulling from library/alpine 7264a8db6415: Pull complete Digest: sha256:7144f7bab3d4c2648d7e59409f15ec52a18006a128c733fcff20d3a4a54ba44a Status: Downloaded newer image for alpine:latest  
2、镜像  
镜像是一种轻量级、可执行的独立软件包，用来打包软件运行环境和基于运行环境开发的软件，它包含运行某个软件所需的所有内容，包括代码、运行时库、环境变量和配置文件，将所有的应用和环境，直接打包为docker镜像，就可以直接运行。  
**（1）镜像加载原理**  

-   分层：Docker镜像采用分层的方式构建，每一个镜像都由一组镜像组合而成，每一个镜像层都可以被需要的镜像所引用，实现了镜像之间共享镜像层的效果，同时在镜像的上传与下载过程当中有效的减少了镜像传输的大小，在传输过程当中本地或注册中心只需要存在一份底层的基础镜像层即可，真正被保存和下载的内容是用户构建的镜像层，而在构建过程中镜像层通常会被缓存以缩短构建过程
-   写时复制：底层镜像层在多个容器间共享，每个容器启动时不需要复制一份镜像文件，而是将所有需要的镜像层以只读的方式挂载到一个挂载点，在只读层上再覆盖一层读写层，在容器运行过程中产生的新文件将会写入到读写层，被修改过的底层文件会被复制到读写层并且进行修改，而老文件则被隐藏

-   联合挂载：Docker采用联合挂载技术，在同一个挂载点同时挂载多个文件系统，从而使得容器的根目录看上去包含了各个镜像层的所有文件
-   内容寻址：根据镜像层内容计算校验和，生成一个内容哈希值，并使用该值来充当镜像层ID、索引镜像层，内容寻址提高了镜像的安全性，在pull、push和load、save操作后检测数据的完整性，另外基于内容哈希来索引镜像层，对于来自不同构建的镜像层，只要拥有相同的内容哈希值，就能被不同的镜像所引用

**（2）镜像如何解决多架构的问题**  
Docker的方便性决定了镜像需要适配多的架构，为了实现这一特性，镜像仓库服务API支持两种重要的架构，Manifest列表和Manifest。  

-   首先Manifest列表是指某个镜像标签支持的架构列表，其支持每种架构都有自己的Manifest定义；
-   其次拉取镜像时，Docker Client会先调用镜像仓库相关的API，如果有Manifest列表，则找到当前系统架构这一项（如：ARM），并解析Manifest组成对应的镜像层的SHA；
-   最后就是拉取镜像的过程；  
    

**（3）镜像的命令行**  
**（a）拉取镜像**  
`docker image pull <repository>:<tag>`  
docker image pull alpine:latest # 输出 latest: Pulling from library/alpine Digest: sha256:7144f7bab3d4c2648d7e59409f15ec52a18006a128c733fcff20d3a4a54ba44a Status: Image is up to date for alpine:latest [http://docker.io/library/alpine:latest](https://link.zhihu.com/?target=http%3A//docker.io/library/alpine%3Alatest)  
**（b）查看镜像**  
`docker image ls --filter=过滤标签`  
docker images ls # 输出 REPOSITORY TAG IMAGE ID CREATED SIZE \[root@VM-16-16-centos ~\]# docker image ls REPOSITORY TAG IMAGE ID CREATED SIZE alpine latest 7e01a0d0a1dc 13 days ago 7.34MB cnrancher/autok3s v0.6.1 58e8405a4782 9 months ago 254MB rancher/k3d-tools 5.2.2 ad4072a16136 20 months ago 18.7MB rancher/k3d-proxy 5.2.2 d0554070bc8c 20 months ago 42.4MB rancher/k3s v1.21.7-k3s1 4cbf38ec7da6 20 months ago 174MB  
输出字段解释：  

-   REPOSITORY：镜像的地址
-   TAG：镜像的标签
-   IMAGE ID：镜像ID
-   CREATED：创建时间
-   SIZE：镜像大小

**（c）搜索镜像**  
`docker search alpine --filter 过滤标签`  
docker search alpine --filter 'is-official=true' # 输出 NAME DESCRIPTION STARS OFFICIAL AUTOMATED alpine A minimal Docker image based on Alpine Linux… 10203 \[OK\]  
**（d）镜像详情**  
`docker image inspect ubuntu:latest`  
docker image inspect ubuntu:latest # 输出 \[ { "Id": "sha256:01f29b872827fa6f9aed0ea0b2ede53aea4ad9d66c7920e81a8db6d1fd9ab7f9", "RepoTags": \[ "ubuntu:latest" \], "RepoDigests": \[ "ubuntu@sha256:ec050c32e4a6085b423d36ecd025c0d3ff00c38ab93a3d71a460ff1c44fa6d77" \], "Parent": "", "Comment": "", "Created": "2023-08-04T04:53:00.244301537Z", "Container": "822f331d59eb72d1131a8a5fcb2b935c8110114c22be26c8572d9881dcff31e0", "ContainerConfig": { "Hostname": "822f331d59eb", "Domainname": "", "User": "", "AttachStdin": false, "AttachStdout": false, "AttachStderr": false, "Tty": false, "OpenStdin": false, "StdinOnce": false, "Env": \[ "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \], "Cmd": \[ "/bin/sh", "-c", "#(nop) ", "CMD \[\\"/bin/bash\\"\]" \], "Image": "sha256:22d9eb9a70973f7eb625681c244522dad0bf3b4f8e9ea75977b09d8551364a19", "Volumes": null, "WorkingDir": "", "Entrypoint": null, "OnBuild": null, "Labels": { "org.opencontainers.image.ref.name": "ubuntu", "org.opencontainers.image.version": "22.04" } }, "DockerVersion": "20.10.21", "Author": "", "Config": { "Hostname": "", "Domainname": "", "User": "", "AttachStdin": false, "AttachStdout": false, "AttachStderr": false, "Tty": false, "OpenStdin": false, "StdinOnce": false, "Env": \[ "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \], "Cmd": \[ "/bin/bash" \], "Image": "sha256:22d9eb9a70973f7eb625681c244522dad0bf3b4f8e9ea75977b09d8551364a19", "Volumes": null, "WorkingDir": "", "Entrypoint": null, "OnBuild": null, "Labels": { "org.opencontainers.image.ref.name": "ubuntu", "org.opencontainers.image.version": "22.04" } }, "Architecture": "amd64", "Os": "linux", "Size": 77823376, "VirtualSize": 77823376, "GraphDriver": { "Data": { "MergedDir": "/var/lib/docker/overlay2/7340fd0aaa10bc4e4b4bd202b9b4165e3e3c712af3082cbc606cc5e3e93b53a2/merged", "UpperDir": "/var/lib/docker/overlay2/7340fd0aaa10bc4e4b4bd202b9b4165e3e3c712af3082cbc606cc5e3e93b53a2/diff", "WorkDir": "/var/lib/docker/overlay2/7340fd0aaa10bc4e4b4bd202b9b4165e3e3c712af3082cbc606cc5e3e93b53a2/work" }, "Name": "overlay2" }, "RootFS": { "Type": "layers", "Layers": \[ "sha256:bce45ce613d34bff6a3404a4c2d56a5f72640f804c3d0bd67e2cf0bf97cb950c" \] }, "Metadata": { "LastTagTime": "0001-01-01T00:00:00Z" } } \]  
以上是包含一个镜像所有的信息，包括CPU架构，容器命令行等信息。  
**（e）保存或加载镜像文件**  
保存：`docker image save -o [镜像tar文件] [镜像ID]` 加载：`docker load -i [镜像tar文件]`  
\[root@VM-16-16-centos ~\]# docker image save -o alpine.tar 7e01a0d0a1dc \[root@VM-16-16-centos ~\]# ls alpine.tar a.out core.365609 [http://test.cc](https://link.zhihu.com/?target=http%3A//test.cc) \[root@VM-16-16-centos ~\]# docker load -i alpine.tar Loaded image ID: sha256:7e01a0d0a1dcd9e539f8e9bbd80106d59efbdf97293b3d38f5d7a34501526cdb  
**（f）删除镜像**  
`docker image rm [镜像ID]`  
\[root@VM-16-16-centos ~\]# docker image rm 7e01a0d0a1dc -f Untagged: alpine:latest Untagged: alpine@sha256:7144f7bab3d4c2648d7e59409f15ec52a18006a128c733fcff20d3a4a54ba44a Deleted: sha256:7e01a0d0a1dcd9e539f8e9bbd80106d59efbdf97293b3d38f5d7a34501526cdb  
3、容器与容器化  
前面已经提到过，容器是共享操作系统内核，所以容器比虚拟机的开销更小，往往一台物理机上可以运行数千个容器，而且在后台开发中，容器使用方便，已经成为服务部署的标配，那下面我们来了解一下容器和容器化。  
**（1）启动一个简单的容器**  
docker run -it ubuntu:latest /bin/bash # 输出 \[root@node1 ~\]# docker run -it ubuntu:latest /bin/bash Unable to find image 'ubuntu:latest' locally latest: Pulling from library/ubuntu 7b1a6ab2e44d: Pull complete Digest: sha256:626ffe58f6e7566e00254b638eb7e0f3b11d4da9675088f4781a50ae288f3322 Status: Downloaded newer image for ubuntu:latest root@41b22410e6bc:/#  
**（2）容器的生命周期**  

-   容器有一个PID为1的进程，这个进程是容器的主进程，主进程挂掉，整个容器也会退出
-   容器的退出，可以使用`docker stop <Container ID>`，但是容器退出有时候需要保留容器内运行的文件
-   容器的删除，可以使用`docker rm <Container ID>`，不过删除之前可以先停止容器
-   容器在整个生命周期的数据是安全的，即使容器被删除，容器的数据存储在卷中，这些数据也会保存下来
-   容器`docker stop`背后的原理是什么呢？在Linux下，`docker stop`是先向容器的`PID 1`进程发送`SIGTERM`的信号，如果10s内进程没有终止，就会发送`SIGKILL`的信号
-   容器自动重启策略包括`--restart always`，`--restart unless-stopped`和`--restart on-failed`，分别表示如下：  
    

-   `--restart always`是容器被kill掉后会自动重启或者是`Docker daemon`重启的时候也会重启
-   `--restart unless-stopped`是容器被kill掉后会自动重启，但是`Docker daemon`重启的时候不会重启
-   `--restart on-failed`是容器退出时返回不为0则重启

**（3）快速清理**  
docker rm $(docker container ls -aq) -f # 输出 \[root@node1 ~\]# docker rm $(docker container ls -aq) -f 41b22410e6bc d280d169f140 2d0ab5f14a5f 654ee324b7ac 2d0694c9e06a a78be97042fd b9e7e71c07eb 6a1c7e736b2a  
**（4）应用容器化流程**  

-   构建期间，通过流水线和Dockerfile，执行镜像构建
-   交互期间，通过镜像推送到Docker hub中，获取镜像地址
-   运行期间，通过Docker容器拉取镜像后运行

**（5）Dockerfile**  
FROM apline LABEL maintainer="xxx@gmail.com" RUN apk add --update nodejs nodejs-npm COPY . /src WORKDIR /src RUN npm install EXPOSE 8080 ENTRYPOINT \["node", "./app.js"\]  
以上是一个Dockerfile文件，字段解释：  

-   `FROM` 指定的基础镜像层
-   `LABEL` 指定当前镜像的标签信息，可以以key-value形式存在，这样可以自定义一些元素
-   `RUN` 在镜像内运行的命令
-   `COPY` 拷贝文件到镜像中
-   `WORKDIR` 设定Dockerfile中尚未执行的指令设置工作目录
-   `EXPOSE` 设置镜像对外暴露的端口
-   `ENTRYPOINT` 设置镜像在容器中运行的入口程序

**（6）Dockerfile镜像**  

-   在上文中已经提到过镜像，那么上述的Dockerfile有几层镜像呢？四层，分别是指令`FROM apline`，`RUN apk add --update nodejs nodejs-npm`，`COPY . /src`和`RUN npm install`执行后的镜像叠加，可以执行`docker image history 镜像tag`或者`docker image inspect 镜像tag`查看。
-   执行`docker image build -t xxx/web:latest .`或者`docker image build -t xxx/web:latest -f xxxDockerfile`就可以构建镜像
-   执行`docker image push xxx/web:latest`通过登录DockerHUB或者私有化的镜像仓库，将镜像推送到HUB中

**（7）多阶段构建**  
在Docker 17.05版本以后，提供了多阶段构建，什么是多阶段构建呢？  
FROM node:latest AS storefront WORKDIR /usr/src/app/react-app COPY react-app . RUN npm install RUN npm run build FROM server:latest AS appserver WORKDIR /usr/src/app/appserver ... FROM production:latest AS production WORKDIR /static COPY --from=storefront /usr/src/app/react-app/build/ . WORKDIR /app COPY --from=appserver /usr/src/app/appserver/build/ . ENTRYPOINT \["./startup", "--config=..."\] CMD \["xxxx"\]  
以上是一个多阶段构建的Dockerfile文件，字段解释：  

-   `COPY --from=`表示从之前的构建阶段的镜像中复制某些文件
-   上面的Dockerfile会生成三个镜像

**（8）最佳实践**  

-   利用已有的环境构建镜像：  
    

-   docker build构架镜像的时候会构建和拉取缓存镜像，所以为了加速构建，可以将常用的一些镜像打到一个大的镜像中
-   对于一些不需要缓存的镜像可以使用docker image build --nocache=true

-   合并镜像：  
    

-   有些时候我们构建的镜像比较大，我们可以通过合并镜像减少镜像大小，使用docker image build --squash

-   使用Dockerfile的 `ENV`， `HEALTHCHECK`， `ONBUILD` 指令
-   Dockerfile中`ENTRYPOINT`和`CMD`的区别：  
    

-   Dockerfile文件中，必须包含`ENTRYPOINT`或者`CMD`命令
-   `CMD`：指令允许用户指定容器的默认执行的命令。此命令会在容器启动且`docker run`没有指定其他命令时运行
-   `ENTRYPOINT`：`ENTRYPOINT`的Exec格式用于设置容器启动时要执行的命令及其参数，同时可通过`CMD`命令或者命令行参数提供额外的参数，`ENTRYPOINT`中的参数始终会被使用，这是与`CMD`命令不同的一点

4、Docker Compose  
**（1）Docker-Compose文件**  
version: '3.4' services: webmvc: image: eshop/webmvc environment: - CatalogUrl=[http://catalog-api](https://link.zhihu.com/?target=http%3A//catalog-api) - OrderingUrl=[http://ordering-api](https://link.zhihu.com/?target=http%3A//ordering-api) - BasketUrl=[http://basket-api](https://link.zhihu.com/?target=http%3A//basket-api) ports: - "5100:80" depends\_on: - catalog-api - ordering-api - basket-api catalog-api: image: eshop/catalog-api environment: - ConnectionString=Server=sqldata;Initial Catalog=CatalogData;User Id=sa;Password=\[PLACEHOLDER\] expose: - "80" ports: - "5101:80" #extra hosts can be used for standalone SQL Server or services at the dev PC extra\_hosts: - "CESARDLSURFBOOK:10.0.75.1" depends\_on: - sqldata ordering-api: image: eshop/ordering-api environment: - ConnectionString=Server=sqldata;Database=Services.OrderingDb;User Id=sa;Password=\[PLACEHOLDER\] ports: - "5102:80" #extra hosts can be used for standalone SQL Server or services at the dev PC extra\_hosts: - "CESARDLSURFBOOK:10.0.75.1" depends\_on: - sqldata basket-api: image: eshop/basket-api environment: - ConnectionString=sqldata ports: - "5103:80" depends\_on: - sqldata sqldata: environment: - SA\_PASSWORD=\[PLACEHOLDER\] - ACCEPT\_EULA=Y ports: - "5434:1433" basketdata: image: redis  
上述语法说明：  

-   `build` 指定`Dockerfile`所在文件夹的路径，Compose将会利用它自动构建这个镜像，然后使用这个镜像
-   `command` 覆盖容器启动后默认执行的命令
-   `links` 链接到其它服务中的容器
-   `ports` 暴露端口信息，使用宿主：容器（HOST:CONTAINER）格式或者仅仅指定容器的端口（宿主将会随机选择端口）都可以
-   `expose` 暴露端口，但不映射到宿主机，只被连接的服务访问
-   `volumes` 卷挂载路径设置，可以设置宿主机路径（HOST:CONTAINER）或加上访问模式

**（2）Docker-Compose命令**  

-   `docker-compose up -f xxx.yaml` 查找本地文件的docker-compose.yaml或者指定的文件，然后启动
-   `docker-compose down` 停止并删除docker-compose.yaml启动的服务，会删除容器和网络，但是不会删除卷和镜像
-   `docker-compose ps` 查看应用的状态
-   `docker-compose stop` 停止docker-compose.yaml启动的服务
-   `docker-compose top` 列出各个服务的进程
-   `docker-compose restart` 重启启动docker-compose.yaml的服务
-   `docker-compose rm` 删除已经停止的服务

4、容器的持久化数据  
容器中有持久化数据和非持久化数据，两种在实用场景下有很多，其中非持久化是自动创建，从属于容器，生命周期与容器相同，如果希望数据在容器中保留，可以将需要的数据存储在卷上。

![](https://pic2.zhimg.com/v2-678a9ea050e00aac3061893b8b6a0bf9_b.jpg)

**（1）创建存储卷**

使用命令创建存储卷 `docker volume create myvol`，然后可以通过 `docker volume inspect myvol` 获得输出：

```
[
    {
        "CreatedAt": "2023-09-02T08:03:38+08:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/myvol/_data",
        "Name": "myvol",
        "Options": {},
        "Scope": "local"
    }
]
```

其中存储卷支持几种访问类型，包括块存储，文件存储，对象存储

**（2）删除存储卷**

-   `docker volume prune` 删除未装入某个容器或者服务的所有卷
-   `docker volume rm myvol` 删除指定的存储卷

**（3）挂载卷**

使用命令挂载卷 `docker run -it -name voltest --mount source=myvol,target=/vol alpine`，可以通过 `docker volume ls`查看：

```
[root@node1 ~]# docker volume ls
DRIVER              VOLUME NAME
local               myvol
```

Docker volume 支持挂载传播的配置Propagation，比如`docker run –d -v /home:/data:slave nginx`表示主机/home下面挂载的目录，在容器/data下面可用，反之不行，其中可选配置如下：

-   Private：挂载不传播，源目录和目标目录中的挂载都不会在另一方体现
-   Shared：挂载会在源和目的之间传播
-   Slave：源对象的挂载可以传播到目的对象，反之不行
-   Rprivate：递归 Private，默认方式
-   Rshared：递归 Shared
-   Rslave：递归 Slave

**（4）集群节点间共享存储**

集群间共享存储最大的问题就是数据一致性，比如容器A在共享卷中更新了部分数据，但是数据实际写入了本地缓存并未同步卷中，同时容器B也在共享卷中更新了部分数据，并同步到了卷中，这时卷中的数据必然存在冲突，如何解决？一种方案是通过应用层解决，另一种方案是通过第三方存储卷，比如NFS，Ceph或者S3等，这里在后续的文章中会继续介绍。

## 第二部分：Docker Swarm

Docker Swarm与K8S相比使用场景越来越少，但是对于小集群而言，Docker Swarm还是有一些便利的地方，因此在此做一些简单的介绍。

### 1、Docker Swarm原理

Docker Swarm分为Manager和Worker节点，Manager节点是负责整个集群的控制面，进行集群的监控，分发任务等操作；Worker节点接收Manager节点的任务并执行，其中整个集群的配置和状态信息都存储在etcd数据库中，其大概的架构图如下：

![](https://pic2.zhimg.com/v2-eefbd139ba337ad4298cd9ca3213fe15_b.jpg)

### 2、Docker Swarm基本命令

**（1）启动**

命令：`docker swarm init --advertise-addr 9.134.229.3:2377 --listen-addr 9.134.229.3:2399` 输出：

```
Swarm initialized: current node (l5ul5q41m7n4vuxhp8bge5lcv) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-26n7usg20hde1uxz4fo7z4baqvfv5y6i12oznvywrgc56el40c-3pvhlj63uxsz0rkw9cb5jd2gy 9.134.229.3:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

-   `--advertise-addr 9.134.229.3:2377` 指定其他节点连接到当前管理节点的IP和端口
-   `--listen-addr 9.134.229.3:2399` 指定用于承载Swarm流量的IP和端口

**（2）加入节点**

命令：`docker swarm join --token SWMTKN-1-26n7usg20hde1uxz4fo7z4baqvfv5y6i12oznvywrgc56el40c-3pvhlj63uxsz0rkw9cb5jd2gy 9.134.229.3:2377` 输出：

```
[root@VM-229-3-centos ~]# docker node ls
ID                            HOSTNAME               STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
scj0t5d3th79tyd1cw05dqv3o *   VM-229-3-centos        Ready     Active         Leader           23.0.1
tbpeirjj8nj2egnvkec91oewt     VM-230-108-tencentos   Ready     Active                          23.0.1
```

**（3）高可用**

Swarm实现了一种主从方式的多管理节点的HA，但是仅有一个节点处于活动状态。 处于活动状态的管理节点被称为"主节点"，而主节点也是唯一一个会对Swarm发送控制命令的节点，同时只有主节点才会变更配置，或者发送任务到工作节点。 如果一个备用管理节点接收到Swarm命令，则它会将其转发到其他主节点。 关于Swarm高可用的最佳实践原则：

-   由于Swarm使用了Raft共识算法支持管理节点，所以部署的时候建议奇数个节点，这样减少脑裂的情况
-   不要部署太多的管理节点（建议3-7个之间），由于使用共识算法，如果一个节点挂掉了，太多节点达成共识时间会更长
-   管理节点建议部署不同机架或者不同的地域（同城异地部署），以增加抵抗同时挂掉的风险

**（4）扩容和滚动升级**

Swarm中有类似K8S中的service概念，只要在service中配置了端口映射，所有节点都会自动生成映射，将请求转发到运行有服务的副本节点中。

-   执行service创建：`docker service create --name web -p 80:80 --replicas 5 xxx/app:latest`
-   查看service服务：`docker service ls`
-   service扩容到10个副本：`docker service scale web-10`
-   service删除：`docker service rm web`
-   service滚动升级：`docker service update --image xxx/app:v2 --update-paralleism 2 --update-delay 20s web`  
    

-   `--update-paralleism 2` 每次滚动升级2个副本
-   `--update-delay 20s` 滚动升级延时20秒
-   原理是什么呢？为什么在没有服务发现的情况下能滚动升级呢？原因是由于每个Swarm节点都会接收流量，但是会根据滚动升级服务节点状态执行流量转发，如果更新好了就会发送到本节点，否则则转发

## 参考

（1）[https://zhuanlan.zhihu.com/p/558785823](https://zhuanlan.zhihu.com/p/558785823)

（2）[https://www.cnblogs.com/oscar2960/p/16536891.html](https://link.zhihu.com/?target=https%3A//www.cnblogs.com/oscar2960/p/16536891.html)

（3）[https://www.jianshu.com/p/e3a87c76aab4?utm\_campaign=maleskine&utm\_content=note&utm\_medium=seo\_notes&utm\_source=recommendation](https://link.zhihu.com/?target=https%3A//www.jianshu.com/p/e3a87c76aab4%3Futm_campaign%3Dmaleskine%26utm_content%3Dnote%26utm_medium%3Dseo_notes%26utm_source%3Drecommendation)

下期将继续分享【后台技术】Docker网络篇，敬请期待~

**欢迎点赞分享，搜索关注【鹅厂架构师】公众号，一起探索更多业界领先产品技术。**