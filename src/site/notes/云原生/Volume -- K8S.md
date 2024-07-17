---
{"dg-publish":true,"date":"2024-06-11","time":"15:48","progress":"进行中","tags":["云原生/k8s","k8s/volume"],"permalink":"/云原生/Volume -- K8S/","dgPassFrontmatter":true}
---

# Volume -- K8S


## 声明

本问内容参考自 https://www.yuque.com/wukong-zorrm/qdoy5p/df2ftr 和 《kubernets权威指南》。

## 存储机制概述

Volume与Pod绑定，与Pod具有相同的生命周期。如果容器需要使用某个volume,只需要设置volumeMonts将一个或多个Volume挂载为容器中的目录或文件即可。

在k8s中，有三种类型的存储机制：
- 将特定类型的资源对象映射为目录或文件
	- ConfigMap： 主要保存应用程序所需的配置文件，并通过volume的形式挂载到容器内的文件系统中。与Pod一起创建和删除，生命周期与Pod相同
	- Secret：用于保存机密数据的对象。一般由于保存密码、令牌或密钥等。 data字段用来存储base64编码数据。 stringData存储未编码的字符串。 Secret意味着你不需要在应用程序代码中包含机密数据，减少机密数据（如密码）泄露的风险。 Secret可以用作环境变量、命令行参数或者存储卷文件。与Pod一起创建和删除，生命周期与Pod相同
	- DownwardAPI：将Pod或container的某些元数据信息（例如Pod名称、Pod IP、Node IP、Label、Annotation、容器资源限制等）以文件的形式挂载到容器中。与Pod一起创建和删除，生命周期与Pod相同
	- ServiceAccountToken 与Pod一起创建和删除，生命周期与Pod相同
	- Projected Volume: 一种特殊的存储卷类型，用于将一个或多个上述资源对象一次性挂载到容器内的同一个目录下面
- 宿主机本地存储类型
	- EmptyDIr: 临时存储，与Pod具有相同的生命周期，当Pod被销毁时，其中的数据也会被销毁。
	- HostPath: 宿主机目录，用于将Node文件系统的目录或文件挂载到容器中使用。
	- Local：使用PV（持久化存储）机制管理的宿主机目录
- 持久化存储（PV）类型
	- CephFS 一种开源的共享存储系统
	- Cinder 一种开源的共享存储系统
	- CSI 容器存储接口（由存储提供商提供驱动程序和存储管理程序）
	- Fibre Channel 光线存储设备
	- Flex Volume 一种基于插件式驱动的存储
	- Flocker 一种开源的共享存储系统
	- Clusterfs 一种开源的共享存储系统 
	- iSCSI： iSCSI存储设备
	- Local：本地持久化存储
	- NFS：网络文件系统
	- Persistent Volume Claim (PVC)
	- Portworx Volumes：Portworx提供的存储服务
	- Quobyte Volumes：Quobyte提供的存储服务
	- RBD（Ceph Block Device）：Ceph块存储

- 临时卷(Ephemeral Volume): 与Pod一起创建和删除，生命周期与Pod相同 
	- emptyDir-作为缓存或存储日志 
	- configMap、secret、downwardAPI 给Pod注入数据。
- 持久卷(Persistent Volume): 删除Pod后，持久卷不会被删除 
	- 本地存储：hostPath、local
	- 网络存储：NFS 
	- 分布式存储：Ceph(cephfs:文件存储、rbd块存储)
- 投射卷(Projected Volumes)：projected卷可以将多个卷映射到同一个目录上

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20231213210454.png)


### 临时卷

与Pod一起创建和删除，生命周期与Pod相同 
- emptyDir：初始内容为空的本地临时目录 
- configMap：为Pod注入配置文件 
- secret：为Pod注入加密数据

#### emptyDir

emptyDir会创建一个初始状态为空的目录，存储空间来自本地的kubelet根目录或内存(需要将`emptyDir.medium`设置为`Memory`)。通常使用本地临时存储来设置缓存、保存日志等。例如，将redis的存储目录设置为emptyDir

### 持久卷与持久卷声明

持久卷(Persistent Volume)：删除Pod后，卷不会被删除  
- 本地存储  
	- [hostPath](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#hostpath)节点主机上的目录或文件 (仅供单节点测试使用；多节点集群请用 local 卷代替)  
	- [local](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#local) - 节点上挂载的本地存储设备(不支持动态创建卷)  
- 网络存储  
	- [NFS](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#nfs) - 网络文件系统 (NFS)  
- 分布式存储  
	- Ceph([cephfs](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#cephfs)文件存储、[rbd](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#rbd)块存储)

**持久卷（PersistentVolume，PV）** 是集群中的一块存储。可以理解为一块虚拟硬盘。
持久卷可以由管理员事先创建， 或者使用[存储类（Storage Class）](https://kubernetes.io/zh-cn/docs/concepts/storage/storage-classes/)根据用户请求来动态创建。
持久卷属于集群的公共资源，并不属于某个`namespace`;

**持久卷声明（PersistentVolumeClaim，PVC）** 表达的是用户对存储的请求。
PVC声明好比申请单，它更贴近云服务的使用场景，使用资源先申请，便于统计和计费。
Pod 将 PVC 声明当做存储卷来使用，PVC 可以请求指定容量的存储空间和[访问模式](https://kubernetes.io/zh-cn/docs/concepts/storage/persistent-volumes/#access-modes) 。PVC对象是带有`namespace`的。

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20231213210941.png)

#### 创建持久卷

创建持久卷(PV)是服务端的行为，通常集群管理员会提前创建一些常用规格的持久卷以备使用。

`hostPath`仅供单节点测试使用，当Pod被重新创建时，可能会被调度到与原先不同的节点上，导致新的Pod没有数据。多节点集群使用本地存储，可以使用`local`卷

创建`local`类型的持久卷，需要先创建存储类(StorageClass)。

```yaml
# 创建本地存储类
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: Immediate
```


`local`卷不支持动态创建，必须手动创建持久卷(PV)。
创建`local`类型的持久卷，**必须**设置`nodeAffinity`(节点亲和性)。
调度器使用`nodeAffinity`信息来将使用`local`卷的 Pod 调度到持久卷所在的节点上，不会出现Pod被调度到别的节点上的情况。

>注意：`local`卷也存在自身的问题，当Pod所在节点上的存储出现故障或者整个节点不可用时，Pod和卷都会失效，仍然会丢失数据，因此最安全的做法还是将数据存储到集群之外的存储或云存储上。


# PV和PVC的工作原理
可以将PV看作可用的存储资源，PVC则是对存储资源的需求。

## 生命周期
PV和PVC的生命周期包括：资源供应（provisioning）、资源绑定（binding）、资源使用（using）、资源回收（reclaiming）四个阶段。
### 资源供应 provisioning
分为静态和动态：
- **静态：** 集群管理员预先创建一定数量的PV，在PV的定义中能够体现存储资源的特性
- **动态：** 集群管理员通过StorageClass的设置对后端存储资源进行描述，用户通过创建PVC对存储进行申请，系统将自动完成PV的创建并将其与PVC绑定。如果PVC的Class字段为空，则说明PVC不使用动态模式。

### 资源绑定binding
用户定义好PVC后，系统根据PVC在已存在的PV中选择一个满足PVC要求的PV；如果没有找到满足要求的PV,PVC则会无限期处于Pending状态。

如果是动态分配模式，系统在为PVC找到合适的StorageClass之后，将自动创建一个PV并完成与PVC的绑定。

### 资源使用using
Pod使用存储资源的方式是在volume的定义中引用PVC类型的存储卷，将PVC挂载到容器的某个路径下进行使用。

同一个PVC可以被多个Pod同时挂载，此时需要处理好多进程同时访问同一个存储资源的问题。

为了保证PVC处于活动状态以及该PVC绑定的PV不会从系统中删除，因为一旦被删除，数据可能会丢失。Kubernetes提供了一个功能：使用中的存储对象保护（Storage Object in Use Protection）。因此，当用户删除一个处于活动状态的PVC的时候，该PVC并不会被删除，直到PVC没有被任何pod使用。同样，如果删除一个已经绑定了PVC的PV，PV也不会被删除，直到PV没有被任何PVC绑定。

### 资源回收reclaiming
这个阶段主要指的是PV的回收。当PV被PVC释放之后（解除绑定），集群将会根据回收策略回收PV。  
当前，支持3个策略：Retain（保留）、Recycle（再利用）、Delete（删除）

- **Retained（保留）**：该策略允许手动回收这些存储资源。当其绑定的PVC删除之后，PV仍然保留，但是不会被其它的PVC再次绑定。  
- **Delete（删除）**: 该策略将会删除PV以及其关联的外部存储资源，比如AWS EBS、Azure Disk。`StorageClass`默认的回收策略是`Delete`，根据其动态置备的PV也会继承该值。  适合动态供应的PV，因为它们通常与云服务商的存储服务集成，可以自动处理资源释放。
- **Recycle（再利用，已弃用）**：该策略会删除PV上的所有数据，然后使其可以再次被PVC绑定。

## PVC资源扩容

如果需要扩容PVC，则需要将PVC对应的StorageClass中设置allowVolumeExpansion=true：
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gluster-vol-default
provisioner: kubernetes.io/glusterfs
parameters:
  resturl: "http://192.168.10.100:8080"
  restuser: ""
  secretNamespace: ""
  secretName: ""
allowVolumeExpansion: true
```

对PVC进行扩容时，只需要修改resource.requests.storage的值即可。

## PV详解

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0003
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: slow
  mountOptions:
    - hard
    - nfsvers=4.1
  nfs:
    path: /tmp
    server: 172.17.0.2
```

PV作为存储资源的定义，主要设计存储能力、访问模式、存储类型、回收策略、后端存储类型等关键信息的设置。
PV资源对象需要设置的关键配置参数如下：
- 存储容量（capacity）
- 存储卷模式（volumeMode）
	- filesystem，将以目录的形式挂载到pod内部
	- block，裸块设备
- 访问模式（accessMode）
	- ReadWriteOnce (RWO): 读写权限，只能被单个Node挂载
	- ReadOnlyMany (ROX): 只读，允许被多个Node挂载
	- ReadWriteMany (RWX): 读写，允许被多个NODE挂载
- 存储类别（class），通过storageClassName参数指定一个StorageClass资源对象的名称
- 回收策略（reclaim policy）：retain, delete, reclcle（已弃用）
- 挂载选项（mount options）
- 节点亲和性（node affinity）

PV资源的生命周期为：
- available：可用状态，未与某个PVC绑定
- bound：已与某个PVC绑定
- released：与之绑定的PVC被删除，但未完成资源回收，不能被其他PVC使用
- failed：自动资源回收失败

## PVC详解

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 8Gi
  storageClassName: slow
  selector:
    matchLabels:
      release: "stable"
    matchExpressions:
      - {key: environment, operator: In, values: [dev]}
```

关键参数说明：
- 资源请求（resources）：描述对存储资源的需求，通过resources.requests.storage设置需要的存储空间大小
- accessModes: 用于描述用户应用对存储资源的访问权限，在与PV绑定时需要匹配的访问模式
- volumeMode：存储卷模式，在绑定时需要相匹配的模式，具体匹配规则见后文表格
- selector：通过LabelSelector的设置，可使PVC对于系统中已存在的各种PV进行筛选。系统将根据标签筛选出合适的PV与之绑定。对选择条件可以使用matchLabels和matchExpressions进行设置，如果两个字段都已设置，则selector的逻辑是将两组条件同时满足才能完成匹配。
- class：存储类别，设定需要的后端存储的类别（通过storageClassName指定），也可以将其设置为空。当为空时，需要判断以下情况：
	- 系统启用了名为DefaultStorageClass的admission controller：如果系统中不存在默认的StorageClass，则等效于未启用DefaultStorageClass。如果集群管理员已定义默认的StorageClass，则系统自动为PVC创建一个DefaultStorageClass类型的PV。
	- 未启用时，只能选择未设定Class的PV与之匹配并绑定。


| PV的存储卷模式   | PVC的存储卷模式  | 是否可以绑定 |
| ---------- | ---------- | ------ |
| 未设置        | 未设置        | 是      |
| 未设置        | block      | 否      |
| 未设置        | filesystem | 是      |
| block      | 未设置        | 否      |
| block      | block      | 是      |
| block      | filesystem | 否      |
| filesystem | 未设置        | 是      |
| filesystem | block      | 否      |
| filesystem | filesystem | 是      |
## StorageClass详解

StorageClass资源对象的定义主要包括名称、后端存储提供者（provisioner）、后端存储的香港配置参数和回收策略。

StorageClass定义了如何动态创建PV。

StorageClass一旦被创建将无法修改，只能删除重现创建。

StorageClass的主要用途是简化存储资源的管理过程，使得用户无需关心存储的具体实现细节。它允许管理员将存储资源定义为某种类型的资源，比如快速存储、慢速存储等，用户根据StorageClass的描述就可以非常直观的知道各种存储资源的具体特性了，这样就可以根据应用的特性去申请合适的存储资源了.
创建StorageClass需要定义PV的属性，比如存储类型、大小等；另外创建这种PV需要用到的存储插件，比如GFS、Ceph（插件）等。有了这两部分信息之后，Kubernetes就能够根据用户提交的PVC，找到一个对应的StorageClass，然后Kubernetes就会调用该StorageClass声明的存储插件，自动创建需要的PV并进行绑定.


```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Retain
allowVolumeExpansion: true
mountOptions:
  - debug
volumeBindingMode: Immediate
```


### StorageClass与PV的区别


- **抽象层次**：StorageClass是一个抽象层，定义了PV的创建规则和属性，而PV是具体的存储资源实例。
- **生命周期**：PV有自己的生命周期，可以独立于Pod存在，而StorageClass是定义PV创建规则的模板，不直接参与生命周期管理。
- **动态供应**：StorageClass支持动态供应PV，即在创建PVC时动态地创建PV，而PV可以是静态的，也可以是动态的，取决于是否使用StorageClass。
- **管理方式**：管理员可以直接管理PV，包括创建、更新和删除，而StorageClass的管理相对较少，主要是定义和维护PV的创建规则。
- **使用场景**：PV适用于需要持久化存储的场景，而StorageClass适用于需要动态供应存储资源的场景。