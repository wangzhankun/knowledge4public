---
{"dg-publish":true,"page-title":"在K8S中，有哪几种控制器类型？ - 黄嘉波 - 博客园","url":"https://www.cnblogs.com/huangjiabobk/p/18050616","tags":["云原生/k8s"],"permalink":"/云原生/k8s/在K8S中，有哪几种控制器类型？ - 黄嘉波 - 博客园.md/","dgPassFrontmatter":true}
---

转载自：[原始链接](https://www.cnblogs.com/huangjiabobk/p/18050616)，如有侵权，联系删除。


在Kubernetes (K8s) 中，控制器（Controller）是用来确保实际集群状态与所需状态保持一致的关键组件。它们监视并自动调整系统以达到预期状态，以下是Kubernetes中主要的几种控制器类型：

1.  **ReplicationController (RC)**:
    
    -   在早期版本的Kubernetes中用于保证指定数量的Pod副本始终运行。
    -   后来被ReplicaSet所取代，但在一些旧版文档或遗留集群中可能仍能看到。
2.  **ReplicaSet (RS)**:
    
    -   继承了ReplicationController的功能，并且支持更灵活的标签选择器。
    -   负责确保一定数量的相同Pod副本按用户设置的数量运行。
3.  **Deployment**:
    
    -   是现代Kubernetes应用中最常用的控制器类型之一。
    -   它使用ReplicaSet在后台来管理Pod的复制和更新过程。
    -   提供滚动更新、滚动回滚、暂停与恢复等功能，使得应用的升级更为平滑和可控。
4.  **DaemonSet**:
    
    -   确保在每个（或满足特定条件的）Node上仅运行一个Pod副本。
    -   通常用于运行那些需要在每个节点上都存在实例的系统守护进程或者agent。
5.  **Job**:
    
    -   用于执行一次性任务到完成的任务控制器，比如批处理作业。
    -   当其关联的Pod成功执行到完成（例如主进程退出码为0）时，Job认为工作已经完成。
6.  **CronJob**:
    
    -   类似于Linux的cron定时任务，它会按照预定的时间表定期启动Job。
    -   CronJob控制器可以自动化周期性任务的执行。
7.  **StatefulSet**:
    
    -   用于管理有序的、持久化的、具有唯一标识符和稳定的网络标识符的Pod集合。
    -   适用于需要存储卷持久化、有序启动和停止以及固定网络标识（如DNS名称）的有状态应用。
8.  **Horizontal Pod Autoscaler (HPA)**:
    
    -   不是严格意义上的控制器，但作为一种自动扩缩容机制，根据CPU使用率或自定义度量指标动态调整Pod副本的数量。

综上所述，以上控制器共同构成了Kubernetes集群管理的核心部分，确保集群资源能够按需创建、更新、调度和销毁，以维持集群整体的状态稳定性和可靠性。