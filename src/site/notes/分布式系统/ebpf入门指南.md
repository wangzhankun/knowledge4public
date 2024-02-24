---
{"dg-publish":true,"date":"2024-01-22","time":"14:35","progress":"进行中","tags":["ebpf"],"permalink":"/分布式系统/ebpf入门指南/","dgPassFrontmatter":true}
---


值得注意的是，现在一般把ebpf直接成为bpf.

# ebpf技术架构


![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202401221447525.png)

上图中，虚线左侧是用户态，右侧是内核态。首先BPF程序被编译成字节码，通过系统调用注册进内核态，内核态的验证器验证通过后注册进内核态。当内核启用了JIT功能时，就会将字节码编译成机器码，否则则使用解释器解释执行。

ebpf工具分为静态跟踪和动态跟踪两种。


![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202401221454159.png)


# 什么是 ebpf


[[体系结构与操作系统/ebpf/什么是 eBPF  An Introduction and Deep Dive into the eBPF Technology\|什么是 eBPF  An Introduction and Deep Dive into the eBPF Technology]]

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202401221457246.png)

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202401221502079.png)

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202401221601992.png)

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202401221606126.png)

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202401221607126.png)
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202401221607550.png)
