---
{"dg-publish":true,"permalink":"/体系结构与操作系统/TEE/Keystone TEE 学习/Keystone TEE入门指南（复件）（复件）/","dgPassFrontmatter":true}
---


# Keystone TEE入门指南

报告提交要求参见[[体系结构与操作系统/TEE/Keystone TEE 学习/报告提交要求\|报告提交要求]]
# 软件学习

自学！！！

## Linux

*  [ubuntu安装与使用入门_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1ZE411k7U9/?vd_source=47bbcc428387a807dfb9a0a62d6b09d1)
* [【莫烦Python】Linux 简易教学_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1zx411E7KH/?vd_source=47bbcc428387a807dfb9a0a62d6b09d1)
* [美观高效的命令行Shell,ZSH的安装与配置_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1Ga411g7Eh/?spm_id_from=333.337.search-card.all.click&vd_source=47bbcc428387a807dfb9a0a62d6b09d1)

## docker

* [Docker 1小时快速上手教程，无废话纯干货_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV11L411g7U1/?spm_id_from=333.337.search-card.all.click&vd_source=47bbcc428387a807dfb9a0a62d6b09d1)

## Git

* [【莫烦Python】Git 代码版本管理教程_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1Jx411L7VE/)
* https://learngitbranching.js.org/
* [【你一定不能错过的Git教程】非常棒的Git可视化网站_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1CE411E7DT/?vd_source=47bbcc428387a807dfb9a0a62d6b09d1)



## Vscode

* [VSCode 基本介紹_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1RJ411m7Bj/?vd_source=47bbcc428387a807dfb9a0a62d6b09d1)



## Cmake

* [CMake 保姆级教程【C/C++】_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV14s4y1g7Zj/?spm_id_from=333.337.search-card.all.click&vd_source=47bbcc428387a807dfb9a0a62d6b09d1)



## Make

* [Makefile 20分钟入门，简简单单，展示如何使用Makefile管理和编译C++代码_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV188411L7d2/?spm_id_from=333.337.search-card.all.click&vd_source=47bbcc428387a807dfb9a0a62d6b09d1)



## 其他文献资料

链接: https://pan.baidu.com/s/17SKNqM8CtCrrP03MllYkQg 提取码: vvgj 



# 编译

本章的学习尽量要用纯C的代码，不要写C++！不要写C++！不要写C++！

## 环境准备

riscv的编译链环境已经准备好了，拉取环境：

```Bash
docker pull registry.cn-hangzhou.aliyuncs.com/loongenclave/riscv-basic:12.2.0
```

当使用docker创建好环境之后，假设创建的continer id 是 `CONTINER_ID`，那么要进入该容器的方法是：

```Bash
docker exec -it $CONTINER_ID zsh
# 因为我把默认的终端从bash改成了zsh,因此如果你使用bash进入的话会失败
```

提供的编译链如下。

![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/L2VDbP1u5owAaKxZPcFcYlKUnqc.png)

你们要使用的编译链的前缀是：`riscv64-unknown-linux-gnu-`，不要使用`riscv64-unknown-elf-`

## 报告

自学，完成下面内容

所有的编译链，没有特殊说明，都是使用的riscv编译链，且是使用gcc编译的，除非特殊说明，不要使用g++进行编译。

本章的学习尽量要用纯C的代码，不要写C++！不要写C++！不要写C++！

1. 在编译链中，gcc、g++、ld、nm、objcopy、objdump、strings、strip等工具的作用是什么？
1. 了解二进制文件与进程，回答下面问题：
1. 什么是交叉编译？如何实现交叉编译？对问题1中的代码进行交叉编译，自行编写CMakeLists.txt和Makefile
1. 什么是标准库，在哪里可以找到标准库（x86的标准库和riscv的标准库分别在哪里）？问题1中的代码在编译时可以不使用标准库吗？请分析在使用和不使用标准库的情况下二进制文件的段布局有何异同？请绘制出layout对比图。
1. 什么是静态链接，什么是动态链接？把问题1中的代码，`add`函数实现在静态库中，`sub`函数实现在动态库中，同样要求自行编写`CMakeLists.txt`和`Makefile`。要求程序能够正常运行，自行添加测试代码。
1. gcc在编译程序时可以指定第三方库，可以通过以下方式指定库的路径，主要有哪些方法？PS：`-Wl,rpath`方法有什么特殊之处？
1. 输入`x86_64-linux-gnu-gcc -v`   和 `riscv64-unknown-linux-gnu-gcc -v`,观察会有哪些输出
1. 在gcc编译命令中，sysroot参数的作用是什么？如何指定sysroot？
1. 使用`file`命令查看`/usr/bin/find`的架构，并使用合适的工具分析`/usr/bin/find`的段信息，并绘制段layout图。（PS：哪些段在加载到内存中时需要进行清零？）

## 交叉编译

[[交叉编译\|交叉编译]]
## 实验

### ELF解析器

**在x86下实现，不需要使用交叉编译链** 

1. 将`/usr/bin/find`拷贝到实验文件夹下，并命名为`find-bak`
1. 使用`mmap`函数将`find-bak`二进制文件映射到内存中
1. 实现对elf header的解析

### 编译riscv交叉编译链（可选）

[GitHub - riscv-collab/riscv-gnu-toolchain: GNU toolchain for RISC-V, including GCC](https://github.com/riscv-collab/riscv-gnu-toolchain)

## 参考资料

* 对于出现在百度网盘中的已分享资料，这里不再列出
* [[体系结构与操作系统/TEE/Keystone TEE 学习/报告提交要求\|报告提交要求]]
* [自己动手写一个操作系统——elf 和 bin 文件区别_elf文件和bin文件_Li-Yongjun的博客-CSDN博客](https://blog.csdn.net/lyndon_li/article/details/128768087)
* [简单的ELF解析器](https://omasko.github.io/2018/03/19/%E7%AE%80%E5%8D%95%E7%9A%84ELF%E8%A7%A3%E6%9E%90%E5%99%A8/)



## Qemu

## 报告

1. [一键配置可视化Linux内核与驱动调试_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1w34y1V75j/?spm_id_from=333.999.0.0)

在该视频中用到了下面的脚本，请详细分析每个脚本的作用，并撰写报告。

![](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/ERkYbYROxo0PBCxwaqHcZQ5nn1g.png)

1. Qemu user space emulator 和 qemu system emulator 的区别是什么。并以表格的形式列举出至少四种架构的qemu user space emulator 和 qemu system emulator
1. 阐述你对qemu模拟器的理解

## 实验

### 编译qemu

qemu下载链接 https://download.qemu.org/qemu-7.2.7.tar.xz

提示：[一键配置可视化Linux内核与驱动调试_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1w34y1V75j/?spm_id_from=333.999.0.0)中的qemu编译出的是x86_64的模拟器，你需要编译出riscv64的模拟器`qemu-system-riscv64`和`qemu-riscv64`

PS: qemu需要交叉编译吗？为什么？

### 交叉编译hello world

交叉编译个hello world的程序（要求是动态链接的），使用qemu user mode emulator运行该程序。

### 交叉编译ELF解析器

在前文中我们实现了x86下的解析器，现在把他改造成riscv版本的，同时你要学会使用vscode调试交叉编译出来的程序

### 交叉编译busybox

为了后面的实验，你必须交叉编译出busybox.

### 交叉编译Linux内核

在[一键配置可视化Linux内核与驱动调试_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1w34y1V75j/?spm_id_from=333.999.0.0)中编译了x86_64架构的内核，请交叉编译出riscv64的内核。编写`run-qemu.sh`脚本，使用qemu模拟器运行Linux内核，并尝试在vscode中调试Linux内核

## 参考资料

* [QEMU快速上手教程：原理讲解、命令行参数、系统安装、后续拓展_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1444y1w7mv/?spm_id_from=333.337.search-card.all.click&vd_source=47bbcc428387a807dfb9a0a62d6b09d1)
* [Qemu: User mode emulation and Full system emulation - 摩斯电码 - 博客园](https://www.cnblogs.com/pengdonglin137/p/5020143.html)
* [qemu user mode速记](https://wangzhou.github.io/qemu-user-mode%E9%80%9F%E8%AE%B0/)
* [一键配置可视化Linux内核与驱动调试_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1w34y1V75j/?spm_id_from=333.999.0.0)

# RISC-V体系结构

## 报告

我们只学习通用PC级的RV64的体系结构，不完全适用于嵌入式等其他RISC-V体系结构。

1. 了解RISC-V特权架构：M、S、U，回答以下问题：
1. 了解RISC-V的寄存器，回答下面问题：
1. 了解RISC-V的分页机制，回答下面问题：
1. 了解RISC-V的中断与异常，回答下面问题：
1. 

## 实验

### 二进制文件加载

**在x86下实现，不需要使用交叉编译链** 

在用户态仿真实现二进制文件加载和分页机制：根据`find-bak`的段信息，为该二进制文件创建页表，并将各个段加载到相应位置，提示使用`libelf`库实现对二进制文件的加载。

### 

### 

## 参考资料

* [RISC-V from Scratch 7](https://dingfen.github.io/risc-v/2020/08/29/riscv-from-scratch-7.html)分页机制
* [[体系结构与操作系统/TEE/Keystone TEE 学习/报告提交要求\|报告提交要求]]
* 对于出现在百度网盘中的已分享资料，这里不再列出
* libelf用法样例 [tinylab.org](https://tinylab.org/libelf/)
* 

## 内核

1. 以xv6-riscv为例，学习分析以下内容



## 实验

### 运行并调试xv6

这是要撰写报告中有关`xv6`部分的前置条件。



## 参考资料

* [wangzhankun/xv6-os-riscv](https://gitee.com/wangzhankun/xv6-os-riscv) source code



