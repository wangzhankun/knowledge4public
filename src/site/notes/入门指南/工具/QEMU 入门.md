---
{"dg-publish":true,"date":"2023-12-08","time":"09:30","progress":"进行中","tags":["入门指南","qemu"],"permalink":"/入门指南/工具/QEMU 入门/","dgPassFrontmatter":true}
---


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