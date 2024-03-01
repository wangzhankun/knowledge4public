---
{"dg-publish":true,"date":"2024-01-22","time":"10:59","progress":"进行中","tags":["开源软件"],"permalink":"/开源软件/vscode-cpptools/","dgPassFrontmatter":true}
---


# 说明

vscode-cpptools: https://github.com/microsoft/vscode-cpptools

Miengine: https://github.com/microsoft/MIEngine

  

微软vscode的CPP拓展仅仅是前端，其与miengine进行通信，与调试相关的逻辑都在miengine进行处理。miengine实现了对底层调试器的抽象。cpp拓展通过debug adapter protocol与miengine进行通信，因此cpp拓展无需改动就是跨平台的，具体的逻辑处理由miengine进行。

## vscode拓展与miengine的关系

参考：https://github.com/Microsoft/MIEngine/wiki/Architecture-of-the-MIEngine

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240121161648.png)




“Visual Studio Core 调试器”、“Visual Studio Code”和“GDB/LLDB”是该项目外部的图表部分。

Visual Studio Code 框代表 Visual Studio Code UI。这将通过调试适配器协议 (DAP) 与该项目进行交互。 OpenDebugAD7 理解 DAP，并将在 DAP 和 AD7 接口之间转换来驱动 MIDebugEngine。

MIDebugEngine/AD7.Impl 是 MIEngine 的顶层。该层包含实现 AD7 接口所需的代码。

MIDebugEngine/Engine.Impl 是 MIEngine 大部分智能的所在。它向 AD7 层提供一个对象模型，以便 AD7 层轻松完成其工作。

MICore 包含 Engine.Impl 层使用的基本功能，尽管该定义有点模糊。 MICore 本质上有五件事：

- Debugger 类是我们从 GDB/LLDB 返回的文本的处理中心
    
- MICommandFactory 抽象类及其派生类。这是我们处理 GDB、LLDB 和我们支持的其他基于 MI 的调试器之间差异的首选机制。
    
- 处理解析 MI 结果的结果解析器（ResultValue 等）
    
- 传输类，处理与 GDB 建立的标准输入/输出连接
    
- The launch options code, 用于处理启动选项 XML 并加载自定义启动器
    

  

## Building miengine for vscode

  

https://github.com/microsoft/MIEngine/wiki/Building-MIEngine-for-vscode

  

## Debug OpenDebugAD7 for VS Code

https://github.com/microsoft/MIEngine/wiki/Debug-OpenDebugAD7-for-VS-Code

  

  

## 环境配置

截止到 2.24.01.18日，miengine使用的是.NET 6，是跨平台的，可在Linux下进行调试。

https://dotnet.microsoft.com/en-us/download

  

# MIEngine

## 加载launch.json

  
![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/202401221058542.png)



## 应用launch.json

AD7Engine.StartDebugging -> DebuggedProcess.Initialize

从下图中可以看出，加载symbol的命令是MIEngine自己添加的

![image.png](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/20240121161719.png)


## 程序开始运行

我怀疑程序的第一次运行是复用了ResumeFromLaunch函数的。

![](https://imp-repo-1300501708.cos.ap-beijing.myqcloud.com/asynccode)

  

## MIEngine与gdb的交互

  

MIEngine在后台会启动gdb进程，并将`launch.json`中定义的一些配置发送给gdb,那么MIEngine是如何与gdb进行交互的呢，答案是**[GDB MI INTERFACE](https://ftp.gnu.org/old-gnu/Manuals/gdb/html_node/gdb_211.html#SEC216)****。**这也是MIEngine中MI的来源（笔者猜测）。

在下面中，我提供了一个用于内核调试的`launch.json`文件。在`setupCommands`的字段我采用了MI Interface的写法，在`postRemoteConnectCommands`中采用了gdb交互命令的写法（但是这并不代表只能这么写，实际上是可以混用的）。

```JSON
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Linux Kernel",
            "type": "cppdbg",
            "request": "launch",
            "program": "/home/wang/Documents/x86-linux-kernel-qemu/documents/build/linux.build/vmlinux",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": true,
            "debugServer": 4711,
            "MIMode": "gdb",
            "miDebuggerPath": "/usr/bin/gdb",
            "miDebuggerServerAddress": "localhost:4921",
            "setupCommands": [
                {
                    "description": "为 gdb 启用整齐打印",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                },
                {
                    "description": "将反汇编风格设置为 Intel",
                    "text": "-gdb-set disassembly-flavor intel",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "Build Kernel Debug",
            "postRemoteConnectCommands": [
                {
                    "description": "set hardware breakpoints",
                    "text": "hbreak kernel/src/open_close.c:113",
                    "ignoreFailures": true
                },
                {
                    "description": "",
                    "text": "break kernel/src/open_close.c:120",
                }
            ]
        }
    ]
}
```

# vscode-cpptools

在 https://code.visualstudio.com/docs/cpp/cpp-debug 和 https://code.visualstudio.com/docs/cpp/launch-json-reference 中对如何使用 cpptools 对c/c++ application进行调试的说明。我这里结合MIEngine对调试的过程进行细致的说明。

vscode-cpptools就可以直接理解在vscode中为调试c/c++提供前端界面。vscode-cpptools将读取`launch.json`和`tasks.json`，并通过DAP协议将数据发送给OpenDebugAD7。后端负责与GDB进行交互。

  

## 如何进行调试配置

在只使用gdb调试的情况下，我们需要指令与gdb进行交互，而一些配置指令是固定不变的，可以把他们写入到.gdbinit文件中。在启动gdb时，gdb会在当前目录自动搜索.gdbinit文件并加载其中的指令。在gdb调试过程中，我们依然可以通过命令的方式与gdb进行交互。

  

当使用vscode作为前端对程序进行调试时，我们就有了更多的选择：

- .gdbinit: 这并不是vscode提供的，只是gdb在启动时会自动搜索当前文件夹下的.gdbinit文件并加载它。在`launch.json`中有`cwd`这个选项，这也是gdb的启动目录，因此gdb会自动加载`cwd`选项指定的目录下的.gdbinit
    
- `setupCommands` in `launch.json`: 这个选项是在gdb启动之后，符号表和待调试二进制文件加载之前执行的（后文会详细介绍）
    
- `postRemoteConnectCommands` in `launch.json`: 这个选项是在gdb启动之后，符号表和待调试文件加载之后执行的（后文会详细介绍）
    
- 调试控制台（debugger console）: vscode提供的gdb命令交互，用户可以在这里输入gdb命令，但是需要在名令前加上`-exec`。例如添加一个断点`-exec break main.cpp:20`
    

  

## 调试配置的加载顺序

在上文我们提到了四种配置gdb的方法，很显然.gdbinit是在MIEngine启动gdb时，gdb自动搜寻并加载的，因此他是最先被加载的。至于调试控制台，则是在调试过程中，vscode 提供的交互式操作台，因此他是最后被加载的。

  

最后在讨论`setupCommands`和`postRemoteConnectCommands`的加载顺序，按照描述，`setupCommands`显然是先于`postRemoteConnectCommands`。但是`setupCommands`是滞后于`.gdbinit`的，因为前文已经说了，MIEngine在启动gdb时，gdb就直接自动加载了.gdbinit。`setupCommands`和`postRemoteConnectCommands`的分割点就是符号表/待调试对象有没有被加载。

在`launch.json`中，我们知道有`program`这个字段，用于指示待调试的对象。`setupCommands`中的命令就是在`program`加载之前执行的，而`postRemoteConnectCommands`是在`program`之后执行的。之所以这么设计是因为，没有加载符号表的话，某些gdb指令例如设置硬件断点的指令将无法执行，这类gdb指令必须在符号表加载完成之后才能够正确执行。


## .gdbinit的加载


```c#
// MICore.Transports.LocalTransport.cs::LocalTransport::InitStreams
if (options.DebuggerMIMode == MIMode.Gdb && !string.IsNullOrWhiteSpace(options.WorkingDirectory))

{

var gdbInitFile = Path.Combine(options.WorkingDirectory, ".gdbinit");

if (File.Exists(gdbInitFile))

proc.StartInfo.Arguments += " -x \"" + gdbInitFile + "\"";

}
```


## gdb command的构造

`setupCommands`和`postRemoteConnectCommands`的构造是在：`MIDebugEngine/Engine.IMpl/DebuggerdProcess.cs::DebuggedProcess::GetInitializeCommands


## 如何调整配置顺序

在某些情况下，我们需要在加载完调试对象之后再加载`.gdbinit`，在这种情况下，建议将`.gdbinit`更名，例如更名为`hello.gdbinit`，然后在`postRemoteConnectCommands`字段中添加`{"text": "source /path/to/hello.gdbinit"}`

# 如何调试vscode-cpptools


