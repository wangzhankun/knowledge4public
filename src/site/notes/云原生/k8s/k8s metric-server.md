---
{"dg-publish":true,"page-title":"k8s metric-server","tags":["云原生/k8s"],"permalink":"/云原生/k8s/k8s metric-server/","dgPassFrontmatter":true}
---


### Kubernetes Metrics Server概述

Kubernetes Metrics Server是一个用于收集和聚合集群中节点和Pod的资源使用指标的组件。它通过Kubelet的Summary API获取数据，并将这些数据以Metrics API的形式提供，以便其他Kubernetes组件（如Horizontal Pod Autoscaler）使用。Metrics Server不保存历史数据，而是提供实时的资源使用信息。

>"metrics" 在这里指的是一系列量化的数据，它们代表了集群资源的使用状态。


### 安装和配置

安装Metrics Server通常涉及到创建必要的RBAC资源以授予适当的权限，以及部署Metrics Server本身。在某些Kubernetes版本中，可能需要在kube-apiserver中启用API Aggregator以使Metrics Server的API可用。此外，Metrics Server的配置可能包括设置资源请求、安全端口、以及调整数据聚合的分辨率等。

### 使用场景和重要性

Metrics Server对于自动化资源管理和集群监控至关重要。它允许自动缩放器根据实际的资源使用情况动态调整Pod的数量，并且可以与监控工具集成，提供更深入的集群性能分析。


### **Kubernetes Metrics Server支持哪些类型的资源指标？**

Kubernetes Metrics Server是一个用于收集、存储和提供关于集群中各种资源的度量数据的核心工具。它主要提供关于CPU和内存使用情况、节点资源利用率以及其他重要指标的信息，这些信息对于水平自动扩展（Horizontal Pod Autoscaling，HPA）和Kubernetes Dashboard等Kubernetes组件的正常运行至关重要。

Metrics Server支持的资源指标类型包括：

-   **节点级指标**：如CPU使用率、内存使用量、磁盘I/O和网络流量等。
-   **Pod和容器级指标**：包括CPU使用率、内存使用量、文件系统使用情况等。
-   **集群级别资源指标**：涉及整个集群的资源使用情况。

这些指标由Metrics Server通过聚合节点上的kubelet报告的度量数据来提供，这些数据来自于kubelet内置的cAdvisor服务，后者负责收集容器的资源使用情况和其他指标. 

Metrics Server提供的是当前的度量数据，并不保存历史数据。因此，它主要用于实时监控和自动化任务，而不适用于需要分析历史性能数据的场景. 

### **如何手动验证Kubernetes Metrics Server是否成功部署并收集指标？**

### 手动验证Kubernetes Metrics Server部署和指标收集步骤

1.  **部署Metics Server**：
    
    -   确保您有`components.yaml`文件，这通常是从Metrics Server的GitHub发行页面下载的。
    -   应用部署文件到您的Kubernetes集群中：
        
        ```
        kubectl apply -f components.yaml
        ```
        
    -   检查Metrics Server Pod是否成功启动：
        
        ```
        kubectl get pods -n kube-system
        ```
        
    -   确认Pod状态为`Running`。
2.  **验证APIService**：
    
    -   检查Metrics Server的APIService是否已正确注册：
        
        ```
        kubectl get apiservice v1beta1.metrics.k8s.io
        ```
        
    -   确保输出显示APIService处于`Available`状态。
3.  **收集指标**：
    
    -   使用`kubectl top`命令来收集节点或Pod的指标：
        
        ```
        kubectl top node <node-name>
        ```
        
        ```
        kubectl top pod <pod-name> -n <namespace>
        ```
        
    -   如果命令返回了指标数据，如CPU和内存使用率，那么Metrics Server正在成功收集并提供指标。

以上步骤综合了多个搜索结果中的信息，确保了操作的正确性和时效性. 

### **Kubernetes Metrics Server与Prometheus相比，它们各自的优势和劣势是什么？**

Kubernetes Metrics Server和Prometheus都是用于监控Kubernetes集群的工具，但它们在设计目标、功能范围和使用场景上有所不同。

| 对比维度   | Kubernetes Metrics Server   | Prometheus                           |
| ------ | --------------------------- | ------------------------------------ |
| 设计目标   | 提供Kubernetes核心资源指标，支持HPA等组件 | 收集和处理大规模、多维度的度量指标数据，支持高级分析和报告        |
| 功能范围   | 支持CPU和内存使用率等基本指标            | 支持自定义指标采集规则和聚合规则，适用于网络、存储、应用程序等多方面监控 |
| 数据模型   | 基于Kubernetes API的资源模型       | 时序数据模型，支持多维标签和灵活的数据操作                |
| 集成与兼容性 | 作为Kubernetes官方组件，易于集成       | 需要额外部署和配置，但提供了更广泛的集成选项，如Grafana      |
| 性能影响   | 轻量级，对集群性能影响小                | 根据配置和规模，可能对集群性能有较大影响                 |
| 可视化和告警 | 集成度较低，通常需要结合其他工具如Grafana    | 内置PromQL查询语言和告警机制，支持复杂的数据可视化         |
| 扩展性    | 通过API扩展，但功能相对固定             | 高度可扩展，支持自定义指标采集器和报警规则                |

综合考虑，Kubernetes Metrics Server适合用于快速部署和简单监控场景，特别是当只需要基本的CPU和内存指标时。Prometheus则更适合需要复杂监控、多维度数据分析和高级告警功能的生产环境。在实际应用中，两者可以根据具体需求和资源情况组合使用，以达到最佳的监控效果。