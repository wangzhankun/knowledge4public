---
{"dg-publish":true,"date":"2023-12-11","time":"19:35","progress":"进行中","tags":["入门指南","云原生/k8s"],"permalink":"/云原生/k8s入门指南/","dgPassFrontmatter":true}
---


# k8s入门指南


## 声明

本文为本人原创，未经授权严禁转载。如需转载需要在文章最前面注明本文原始链接。

## 文件列表
- [[云原生/容器技术/容器技术-Overlay 文件系统浅析 - 掘金\|容器技术-Overlay 文件系统浅析 - 掘金]]
- [[云原生/容器技术/【后台技术】Docker网络篇 - 知乎\|【后台技术】Docker网络篇 - 知乎]]
- [[云原生/容器技术/cgroups-linux-kernel-documentation笔记\|cgroups-linux-kernel-documentation笔记]]
- [[云原生/容器技术/cgroups-linux-kernel-documentation\|cgroups-linux-kernel-documentation]]
- [[云原生/容器技术/Docker深入浅出系列  容器数据持久化 - EvanLeung - 博客园\|Docker深入浅出系列  容器数据持久化 - EvanLeung - 博客园]]
- [[云原生/容器技术/Dockerfile ENTRYPOINT和CMD的区别 - 知乎\|Dockerfile ENTRYPOINT和CMD的区别 - 知乎]]
- [[云原生/容器技术/Docker 基础技术之 Linux namespace 详解\|Docker 基础技术之 Linux namespace 详解]]
- [[云原生/容器技术/Docker 基础技术之 Linux namespace 源码分析\|Docker 基础技术之 Linux namespace 源码分析]]
- [[云原生/容器技术/Docker Compose vs. Dockerfile with Code Examples \|Docker Compose vs. Dockerfile with Code Examples ]]
- [[云原生/k8s入门指南\|k8s入门指南]]
- [[云原生/k8s/kubelet\|kubelet]]
- [[云原生/k8s/kube-scheduler\|kube-scheduler]]
- [[云原生/k8s/监控  Kubernetes指南\|监控  Kubernetes指南]]
- [[云原生/k8s/k8s workload\|k8s workload]]
- [[云原生/k8s/cni\|cni]]
- [[云原生/k8s/k8s pod 网络\|k8s pod 网络]]
- [[云原生/k8s/k8s metric-server\|k8s metric-server]]
- [[云原生/k8s/k8s flannel\|k8s flannel]]
- [[云原生/k8s/k8s etcd\|k8s etcd]]
- [[云原生/k8s/k8s apiserver\|k8s apiserver]]
- [[云原生/Volume -- K8S\|Volume -- K8S]]
- [[云原生/容器技术/【后台技术】Docker基础篇 - 知乎\|【后台技术】Docker基础篇 - 知乎]]
- [[云原生/容器技术/(四)Cgroup详解 - 掘金\|(四)Cgroup详解 - 掘金]]
- [[云原生/k8s/kcm kube-controller-manager\|kcm kube-controller-manager]]

{ .block-language-dataview}

## 参考文献
- [Kubernetes入门90分钟精讲(合集)—可能是B站最简单的K8S教程](https://www.bilibili.com/video/BV1k24y197KC/?p=3&spm_id_from=pageDriver&vd_source=47bbcc428387a807dfb9a0a62d6b09d1)
- [Kubernetes二小时入门教程](https://www.yuque.com/wukong-zorrm/qdoy5p)
- 《kubernetes权威指南》



## 什么是云原生


### 官方定义

云原生技术有利于各组织在公有云、私有云和混合云等新型动态环境中，构建和运行可弹性扩展的应用。云原生的代表技术包括容器、服务网格、微服务、不可变基础设施和声明式API。
这些技术能够构建容错性好、易于管理和便于观察的松耦合系统。结合可靠的自动化手
段，云原生技术使工程师能够轻松地对系统作出频繁和可预测的重大变更。

### chatgpt

云原生是一种构建和运行在云环境中的应用程序的方法论和技术栈。它旨在充分利用云计算的优势，如弹性、可扩展性和高可用性，并支持快速迭代和部署。

云原生应用程序通常具有以下特征：

1. 容器化：将应用程序及其依赖项打包为容器镜像，以实现环境一致性和轻量级部署。
    
2. 微服务架构：将应用程序拆分为小而自治的服务单元，每个服务专注于特定的业务功能，并可以独立开发、测试、部署和扩展。
    
3. 动态编排和自动化管理：使用容器编排工具（如Kubernetes）来自动化应用程序的部署、伸缩、容错和调度等管理操作。
    
4. 持续交付和持续部署：通过自动化流水线和工具链，实现快速、可靠和频繁的软件交付和部署。
    

云原生技术栈包括容器技术（如Docker）、容器编排平台（如Kubernetes）、微服务框架（如Spring Cloud）、服务网格（如Istio）、持续交付工具（如Jenkins）等。这些技术共同为构建和管理云原生应用程序提供了支持。

云原生的好处包括更高的灵活性、可伸缩性和可靠性，更快的交付速度和部署效率，以及更低的运维成本。它适用于各种规模的应用程序，从小型的单体应用到大规模的分布式系统。

## 什么是K8S
Kubernetes（常简称为K8s）是一个开源的容器编排平台，用于自动化部署、扩展和管理容器化应用程序。它提供了一个强大的容器编排系统，可以处理多个容器化应用程序的自动化部署、弹性伸缩、负载均衡、服务发现和容错等方面的任务。

以下是Kubernetes的一些关键概念和组件：

1. Pod（容器组）：是Kubernetes中最小的可调度单元，可以包含一个或多个容器及其共享的资源。Pod作为逻辑主机，提供了一个独立的网络命名空间和存储卷。
    
2. Deployment（部署）：定义了应用程序的期望状态，并负责创建和管理Pod的副本集。Deployment支持滚动更新和回滚操作，以实现无宕机的应用程序更新。
    
3. Service（服务）：为一组Pod提供稳定的网络访问地址和负载均衡。Service可以根据标签选择器自动路由流量到后端的Pod。
    
4. Namespace（命名空间）：用于对Kubernetes资源进行逻辑隔离和分组。不同的命名空间可以用于不同环境（如开发、测试、生产）或不同的项目，注意这里的namespace是k8s级别的概念，不是linux内核中的namespace。
    
5. Ingress（入口）：配置外部流量的访问规则，将外部请求路由到集群内部的Service。
    
6. ConfigMap（配置映射）和Secret（密钥）：用于将应用程序的配置和敏感信息以键值对的形式存储，并注入到Pod的环境变量或挂载到文件系统中。
7. Volume （卷）：

Kubernetes还有其他组件和功能，如存储管理、自动扩缩容、日志监控、安全性等。它提供了丰富的API和命令行工具，使开发人员和运维团队可以方便地管理和操作Kubernetes集群。

Kubernetes的优势包括高度可扩展性、高可用性、自动化管理、弹性伸缩、故障恢复等。它已成为云原生应用程序部署和管理的事实标准，并被广泛应用于各种规模和类型的应用程序。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202406151436488.webp)

## K8S架构


kubernetes架构一个Kubernetes集群至少包含一个控制平面(control plane),以及一个或多个工作节点(worker node)
- 控制平面(Control Plane):控制平面负责管理工作节点和维护集群状态。所有任务分配都来自于控制平面。
- 工作节点(Worker Node):工作节点负责执行由控制平面分配的请求任务，运行实际的应用和工作负载。

### 控制平面

控制平面包含：
- kube-apiserver: 与k8s集群进行交互的接口，是k8s控制平面的前端，用于处理内部和外部请求
- kube-scheduler： 集群状况是否良好？如果需要创建新的容器，要将它们放在哪里？这些是调度程序需要关注的问题。 scheduler调度程序会考虑容器集的资源需求（例如CPU或内存）以及集群的运行状况。随后，它会将容器集安排到适当的计算节点。
- kube-controller-manager：负责实际运行集群
	- 节点控制器（Node Controller）：负责在节点出现故障时进行通知和响应
	- 任务控制器（Job COntroller) : 监测代表一次性任务的job对象，然后创建pods来运行这些任务直至完成
	- 端点控制器（endpoints controller）： 填充端点对象（即加入service 与 pod）
	- 服务账户和令牌控制器（service account & token controllers) : 为新的命名空间创建默认账户和API访问令牌
- etcd： 一个KV数据库，用于存储配置数据和集群状态信息
- cloud-controller-manager(可选)：云控制器管理器(Cloud Controller Manager)允许你将你的集群连接到云提供商的API之上，并将与该云平台交互的组件同与你的集群交互的组件分离开来。如果在自己的环境中运行Kubernetes,或者在本地计算机中运行学习环境，所部署的集群不需要有云控制器管理器。

### Node 组件
节点组件在每个节点上运行，负责维护运行的pod并提供k8s运行环境
- kubelet: kubelet会在集群中每个节点(node)上运行。它保证容器(containers)都运行在 Pod中。当控制平面需要在节点中执行某个操作时，kubelet就会执行该操作。
- kube-proxy : kube-proxy是集群中每个节点(node)上运行的网络代理，是实现Kubernetes服务(Service)概念的一部分。 kube-poxy维护节点网络规则和转发流量，实现从集群内部或外部的网络与Pod进行网络通信。
- continer runtime: 容器运行环境是负责运行容器的软件。 Kubernetes支持许多容器运行环境，例如containerd、docker或者其他实现了 Kubernetes CRI(容器运行环境接口)的容器。


## 什么是pod

Pod是逻辑上的概念。

Pod是包含一个或多个容器的容器组，是Kubernetes中创建和管理的最小对象。 Pod有以下特点：
- Pod是kubernetes中最小的调度单位（原子单元），Kubernetes直接管理Pod而不是容器。
- 同一个Pod中的容器总是会被自动安排到集群中的同一节点（物理机或虚拟机）上，并且一起调度。
- Pod可以理解为运行特定应用的“逻辑主机”，这些容器共享存储、网络和配置声明（如资源限制)。
- 每个Pod有唯一的IP地址。IP地址分配给Pod,在同一个Pod内，所有容器共享一个 IP地址和端口空间，Pod内的容器可以使用localhost互相通信。

Deployment:是对ReplicaSet和Pod更高级的抽象。它使Pod拥有多副本，自愈，扩缩容、滚动升级等能力。 
ReplicaSet(副本集)是一个Pod的集合。它可以设置运行Pod的数量，确保任何时间都有指定数量的Pod副本在运行。通常我们不直接使用ReplicaSet,而是在Deploymentr中声明。

## 什么是service

Service将运行在一组Pods上的应用程序公开为网络服务的抽象方法。
Service为一组Pod提供相同的DNS名，并且在它们之间进行负载均衡。
Kubernetes为Pod提供分配了IP地址，但IP地址可能会发生变化。
集群内的容器可以通过service名称访问服务，而不需要担心Pod的IP发生变化。

Kubernetes Service定义了这样一种抽象：
逻辑上的一组可以互相替换的Pod,通常称为微服务。
Service对应的Pod集合通常是通过选择算符来确定的。
举个例子，在一个Service中运行了3个nginx的副本。这些副本是可互换的，我们不需要
关心它们调用了哪个nginx,也不需要关注Pod的运行状态，只需要调用这个服务就可以
了。

Service是对外的概念，是对外提供的，service内部可以实现不同pod之间的负载均衡。

### ServiceType取值

- ClusterlP：将服务公开在集群内部。kubernetes会给服务分配一个集群内部的IP,集
群内的所有主机都可以通过这个Cluster--IP访问服务。集群内部的Pod可以通过service
名称访问服务。
- NodePort:通过每个节点的主机IP和静态端口(NodePort)暴露服务。集群的外部主
机可以使用节点IP和NodePorti访问服务。
- ExternalName:将集群外部的网络引入集群内部。
- LoadBalancer:使用云提供商的负载均衡器向外部暴露服务。

![2023-12-13_10-33.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/2023-12-13_10-33.png)


## 什么是命名空间

命名空间(Namespace)是一种资源隔离机制，将同一集群中的资源划分为相互隔离的组。命名空间可以在多个用户之间划分集群资源（通过资源配额）。

Kubernetes会创建四个初始命名空间：
- default：默认的命名空间，不可删除，未指定命名空间的对象都会被分配到default中。
- kube-system： Kubernetes系统对象（控制平面和Node组件）所使用的命名空间。
- kube-public：自动创建的公共命名空间，所有用户（包括未经过身份验证的用户)都可以读取它。通常我们约定，将整个集群中公用的可见和可读的资源放在这个空间中。
- kube-node-lease：租约（Lease)对象使用的命名空间。每个节点都有一个关联的 lease对象，lease是一种轻量级资源。lease对象通过发送心跳，检测集群中的每个节点是否发生故障。

## 声明式API

学习链接： https://www.yuque.com/wukong-zorrm/qdoy5p/keiq6i


## 容器运行时接口CRI
Kubelet是运行在每个节点(Node)上，用于管理和维护Pod和容器的状态。容器运行时接口(CRI)是kubelet和容器运行时之间通信的主要协议。它将Kubelet与容器运行时解耦，理论上，实现了CRI接口的容器引擎，都可以作为kubernetes的容器运行时。

crictl命令用于镜像的发布导出等操作，该命令与docker的功能非常相似。


## 金丝雀发布

https://www.yuque.com/wukong-zorrm/qdoy5p/rg4ewv

在生产环境的基础设施中小范围的部署新的应用代码。一旦应用签署发布，只有少数用户被路由到它，最大限度的降低影响。如果没有错误发生，则将新版本逐渐推广到整个基础设施。

**局限性**

按照 Kubernetes 默认支持的这种方式进行金丝雀发布，有一定的局限性：

- 不能根据用户注册时间、地区等请求中的内容属性进行流量分配
- 同一个用户如果多次调用该 Service，有可能第一次请求到了旧版本的 Pod，第二次请求到了新版本的 Pod

在 Kubernetes 中不能解决上述局限性的原因是：Kubernetes Service 只在 TCP 层面解决负载均衡的问题，并不对请求响应的消息内容做任何解析和识别。如果想要更完善地实现金丝雀发布，可以考虑Istio灰度发布。

## 运行有状态应用

### 创建mysql数据库

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mysql-pod
spec:
  containers:
    - name: mysql
      image: mysql:5.7
      env:
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
      ports:
        - containerPort: 3306
      volumeMounts:
        - mountPath: /var/lib/mysql #容器中的目录
          name: data-volume
  volumes:
    - name: data-volume
      hostPath:
        # 宿主机上目录位置
        path: /home/mysql/data
        type: DirectoryOrCreate
```

### ConfigMap与Secret
在Docker中，我们一般通过绑定挂载的方式将配置文件挂载到容器里。

在Kubernetes集群中，容器可能被调度到任意节点，配置文件需要能在集群任意节点上访问、分发和更新。ConfigMap能够解决这个问题。

#### ConfigMap

ConfigMap 用来在键值对数据库(**etcd**)中保存非加密数据。一般用来保存配置文件。

ConfigMap 可以用作环境变量、命令行参数或者存储卷。

ConfigMap 将环境配置信息与 [容器镜像](https://kubernetes.io/zh-cn/docs/reference/glossary/?all=true#term-image) 解耦，便于配置的修改。

ConfigMap 在设计上不是用来保存大量数据的。

在 ConfigMap 中保存的数据不可超过 1 MiB。超出此限制，需要考虑挂载存储卷或者访问文件存储服务。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mysql-pod
  labels:
    app: mysql
spec:
  containers:
    - name: mysql
      image: mysql:5.7
      env:
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
      volumeMounts:
        - mountPath: /var/lib/mysql
          name: data-volume
        - mountPath: /etc/mysql/conf.d
          name: conf-volume
          readOnly: true
  volumes:
    - name: conf-volume
      configMap:
        name: mysql-config
    - name: data-volume
      hostPath:
        # directory location on host
        path: /home/mysql/data
        # this field is optional
        type: DirectoryOrCreate
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
data:
  mysql.cnf: |
    [mysqld]
    character-set-server=utf8mb4
    collation-server=utf8mb4_general_ci
    init-connect='SET NAMES utf8mb4'

    [client]
    default-character-set=utf8mb4

    [mysql]
    default-character-set=utf8mb4
```

#### secret
Secret用于保存机密数据的对象。一般由于保存密码、令牌或密钥等。 data字段用来存储base64编码数据。 stringData存储未编码的字符串。 Secret意味着你不需要在应用程序代码中包含机密数据，减少机密数据（如密码）泄露的风险。 Secret可以用作环境变量、命令行参数或者存储卷文件。
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-password
type: Opaque
data:
  PASSWORD: MTIzNDU2Cg==
---
apiVersion: v1
kind: Pod
metadata:
  name: mysql-pod
spec:
  containers:
    - name: mysql
      image: mysql:5.7
      # 在环境变量中使用 secret ，当secret修改后，环境变量不会更新，需要重启 pod
      env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-password
              key: PASSWORD
              optional: false # 此值为默认值；表示secret已经存在了
      volumeMounts:
        - mountPath: /var/lib/mysql
          name: data-volume
        - mountPath: /etc/mysql/conf.d
          name: conf-volume
          readOnly: true
  volumes:
    - name: conf-volume
      configMap:
        name: mysql-config
    - name: data-volume
      hostPath:
        # directory location on host
        path: /home/mysql/data
        # this field is optional
        type: DirectoryOrCreate
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
data:
  mysql.cnf: |
    [mysqld]
    character-set-server=utf8mb4
    collation-server=utf8mb4_general_ci
    init-connect='SET NAMES utf8mb4'

    [client]
    default-character-set=utf8mb4

    [mysql]
    default-character-set=utf8mb4
```

[[云原生/Volume -- K8S\|Volume -- K8S]]