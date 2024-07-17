---
{"dg-publish":true,"page-title":"k8s kcm","tags":["云原生/k8s"],"permalink":"/云原生/k8s/kcm kube-controller-manager/","dgPassFrontmatter":true}
---


### Kubernetes中的Kube-Controller-Manager (KCM)

Kube-Controller-Manager (KCM) 是 Kubernetes 集群的核心组件之一，它运行在 Kubernetes 控制平面节点上，负责维护集群的状态。KCM 通过 API 服务器监听资源（如 Pod、Node 等）的变化，并执行相应的控制循环来确保集群的状态达到预期目标。这些控制循环包括节点控制器、路由控制器、服务控制器等，它们负责处理集群中的各种资源和状态管理任务。

### Cloud Controller Manager (CCM)

Cloud Controller Manager (CCM) 是 Kubernetes 的一个可插拔组件，它允许云提供商的特定逻辑与 Kubernetes 核心逻辑分离，从而简化云提供商的集成。CCM 接管了 KCM 中依赖云服务的部分，如节点控制器、路由控制器和服务控制器，并将它们作为独立的进程运行。这样做可以减少 KCM 的复杂性，并允许云提供商提供定制化的功能和优化。

### KCM 在 Kubernetes 集群中承担哪些具体职责

KCM（Kube Controller Manager）是Kubernetes集群中的一个核心组件，它负责管理集群内部的资源，并确保集群的状态达到预期的工作状态。KCM通过API服务器监控集群的状态，并执行以下具体职责：

1.  **Node Controller**：负责处理节点相关的事件，如节点故障时的通知和响应，以及维护节点的状态信息。
2.  **ReplicaSet Controller**：确保系统中每个副本集（Replica Set）维护正确数量的Pod副本。
3.  **Endpoints Controller**：负责填充服务（Service）的端点（Endpoints）对象，即维护服务与后端Pod之间的映射关系。
4.  **Deployment Controller**：管理部署（Deployment）资源，包括滚动更新和回滚操作。
5.  **Service Account & Token Controller**：为新的命名空间创建默认的服务账户和服务访问令牌。

KCM还包括其他控制器，如DaemonSet Controller、Job Controller等，它们共同确保集群的健康和稳定性。此外，KCM与Cloud Controller Manager（CCM）协同工作，后者提供了Kubernetes与云服务提供商之间的集成，管理云特有资源和服务.



### CCM简化云提供商对Kubernetes集成的方法

Cloud Controller Manager (CCM) 是 Kubernetes 的一个组件，它封装了云提供商的特定逻辑，使得核心 Kubernetes 组件能够独立工作，同时允许云提供商通过插件与 Kubernetes 集成。CCM 通过以下方式简化了云提供商对 Kubernetes 的集成：

1.  **模块化控制循环**：CCM 将原本在 Kubernetes 控制器管理器中的云依赖逻辑拆分出来，形成独立的控制循环，这些控制循环直接运行在 Kubernetes 集群内部，减少了对外部云提供商 API 的直接调用，提高了稳定性和性能。
    
2.  **标准化接口**：CCM 实现了 `cloudprovider.Interface` 接口，这意味着云提供商只需要实现这个标准接口，就可以将其控制逻辑集成到 Kubernetes 中，无需为每种云服务编写定制化代码。
    
3.  **简化部署和配置**：云提供商可以通过部署 CCM 来管理集群的节点、路由、服务和存储等资源，而无需修改 Kubernetes 的核心组件。这简化了集群的部署过程，并降低了维护成本。
    
4.  **支持云原生特性**：CCM 支持 Kubernetes 的云原生特性，如动态卷配置和负载均衡器管理，这使得云提供商能够利用 Kubernetes 生态系统中的工具和服务。
    
5.  **提升可扩展性和兼容性**：CCM 的设计允许云提供商轻松扩展其集成功能，同时保持与 Kubernetes 的兼容性，即使在 Kubernetes 版本升级后也能无缝工作。
    

通过这些方法，CCM 不仅简化了云提供商对 Kubernetes 的集成流程，而且提高了集成的效率和可靠性。

### **KCM 和 CCM 在架构上有何不同？**

KCM（Kubernetes Controller Manager）和CCM（Cloud Controller Manager）是Kubernetes集群中用于管理云资源和服务的两个关键组件。它们在架构上的主要区别在于它们的职责范围和设计目标。

### KCM的角色

KCM是Kubernetes的核心组件之一，它包含了一系列控制器，这些控制器负责维护集群的状态，包括节点、服务、路由等。KCM直接运行在Kubernetes控制平面上，与API服务器和调度器紧密集成，共同管理集群的整个生命周期。

### CCM的设计理念

CCM的设计旨在分离云提供商特定的逻辑，以便这些逻辑可以独立于Kubernetes核心代码进化。CCM作为一个独立的进程运行，它接管了KCM中那些依赖于云服务的控制器，如节点控制器、路由控制器和服务控制器。这样的设计允许云提供商更容易地集成他们的服务，同时保持Kubernetes核心的稳定性和通用性。

### 架构差异

-   **集成点的集中**：CCM整合了所有依赖于云的逻辑，形成了一个单一的集成点，简化了云服务与Kubernetes之间的交互。
-   **插件机制**：CCM基于插件机制设计，这意味着新的云服务供应商可以通过实现相应的插件来快速集成到Kubernetes中。
-   **组件拆分**：CCM将KCM的部分功能拆分出来，作为独立的进程运行，减少了KCM的复杂性，并提高了可维护性。

综上所述，CCM的设计重点在于提供一个清晰的接口来管理云资源，同时保持Kubernetes核心的简洁性和灵活性。这种分离还促进了云服务提供商的创新，因为他们可以在不影响Kubernetes核心的情况下更新和优化他们的集成逻辑.

