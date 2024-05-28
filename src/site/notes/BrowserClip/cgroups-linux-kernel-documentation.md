---
{"dg-publish":true,"page-title":"","url":"https://www.kernel.org/doc/Documentation/cgroup-v2.txt","tags":null,"permalink":"/BrowserClip/cgroups-linux-kernel-documentation/","dgPassFrontmatter":true}
---

\================
Control Group v2
================  
\================ 控制组 v2 ================  
:Date: October, 2015
:Author: Tejun Heo <tj@kernel.org>  
：日期：2015 年 10 月 ：作者：Tejun Heo <tj@kernel.org>  
This is the authoritative documentation on the design, interface and
conventions of cgroup v2.  It describes all userland-visible aspects
of cgroup including core and specific controller behaviors.  All
future changes must be reflected in this document.  Documentation for
v1 is available under Documentation/cgroup-v1/.  
这是关于cgroup v2的设计、接口和约定的权威文档。它描述了 cgroup 的所有用户可见的方面，包括核心和特定控制器行为。未来的所有变更都必须反映在本文件中。 v1 的文档可在 Documentation/cgroup-v1/ 下找到。  

Introduction
============ 简介============  
Terminology
----------- 术语----------  
"cgroup" stands for "control group" and is never capitalized.  The
singular form is used to designate the whole feature and also as a
qualifier as in "cgroup controllers".  When explicitly referring to
multiple individual control groups, the plural form "cgroups" is used.  
“cgroup”代表“控制组”，并且从不大写。单数形式用于指定整个功能，也用作“cgroup 控制器”中的限定符。当明确指代多个单独的对照组时，使用复数形式“cgroups”。  
What is cgroup?
--------------- 什么是cgroup？ ----------------  
cgroup is a mechanism to organize processes hierarchically and
distribute system resources along the hierarchy in a controlled and
configurable manner.  
cgroup 是一种按层次结构组织进程并以受控和可配置的方式沿层次结构分配系统资源的机制。  
cgroup is largely composed of two parts - the core and controllers.
cgroup core is primarily responsible for hierarchically organizing
processes.  A cgroup controller is usually responsible for
distributing a specific type of system resource along the hierarchy
although there are utility controllers which serve purposes other than
resource distribution.  
cgroup主要由两部分组成——核心和控制器。 cgroup核心主要负责分层组织流程。 cgroup 控制器通常负责沿层次结构分配特定类型的系统资源，尽管还有一些实用程序控制器可用于资源分配以外的目的。  
cgroups form a tree structure and every process in the system belongs
to one and only one cgroup.  All threads of a process belong to the
same cgroup.  On creation, all processes are put in the cgroup that
the parent process belongs to at the time.  A process can be migrated
to another cgroup.  Migration of a process doesn't affect already
existing descendant processes.  
cgroup形成一种树形结构，系统中的每个进程都属于一个且唯一的cgroup。一个进程的所有线程都属于同一个cgroup。创建时，所有进程都被放入父进程当时所属的cgroup中。一个进程可以迁移到另一个cgroup。进程的迁移不会影响已经存在的后代进程。  
Following certain structural constraints, controllers may be enabled or
disabled selectively on a cgroup.  All controller behaviors are
hierarchical - if a controller is enabled on a cgroup, it affects all
processes which belong to the cgroups consisting the inclusive
sub-hierarchy of the cgroup.  When a controller is enabled on a nested
cgroup, it always restricts the resource distribution further.  The
restrictions set closer to the root in the hierarchy can not be
overridden from further away.  
遵循某些结构约束，可以在 cgroup 上选择性地启用或禁用控制器。所有控制器行为都是分层的 - 如果在 cgroup 上启用控制器，它会影响属于包含该 cgroup 子层次结构的 cgroup 的所有进程。当在嵌套 cgroup 上启用控制器时，它始终会进一步限制资源分配。靠近层次结构中的根设置的限制不能从更远的地方覆盖。  
Basic Operations
================ 基本操作================  
Mounting
-------- 安装  -  -  -  -   
Unlike v1, cgroup v2 has only single hierarchy.  The cgroup v2
hierarchy can be mounted with the following mount command::  
与 v1 不同，cgroup v2 仅具有单一层次结构。可以使用以下挂载命令挂载 cgroup v2 层次结构：  
  # mount -t cgroup2 none $MOUNT\_POINT # mount -t cgroup2 无 $MOUNT\_POINT  
cgroup2 filesystem has the magic number 0x63677270 ("cgrp").  All
controllers which support v2 and are not bound to a v1 hierarchy are
automatically bound to the v2 hierarchy and show up at the root.
Controllers which are not in active use in the v2 hierarchy can be
bound to other hierarchies.  This allows mixing v2 hierarchy with the
legacy v1 multiple hierarchies in a fully backward compatible way.  
cgroup2 文件系统具有幻数 0x63677270（“cgrp”）。所有支持 v2 并且未绑定到 v1 层次结构的控制器都会自动绑定到 v2 层次结构并显示在根目录中。 v2 层次结构中未主动使用的控制器可以绑定到其他层次结构。这允许以完全向后兼容的方式将 v2 层次结构与旧版 v1 多个层次结构混合。  
A controller can be moved across hierarchies only after the controller
is no longer referenced in its current hierarchy.  Because per-cgroup
controller states are destroyed asynchronously and controllers may
have lingering references, a controller may not show up immediately on
the v2 hierarchy after the final umount of the previous hierarchy.
Similarly, a controller should be fully disabled to be moved out of
the unified hierarchy and it may take some time for the disabled
controller to become available for other hierarchies; furthermore, due
to inter-controller dependencies, other controllers may need to be
disabled too.  
仅当控制器的当前层次结构中不再引用该控制器时，才可以跨层次结构移动该控制器。由于每个 cgroup 控制器状态被异步销毁，并且控制器可能具有延迟引用，因此在先前层次结构最终卸载后，控制器可能不会立即显示在 v2 层次结构上。同样，控制器应完全禁用才能移出统一层次结构，并且禁用的控制器可能需要一些时间才能可用于其他层次结构；此外，由于控制器间的依赖性，其他控制器可能也需要禁用。  
While useful for development and manual configurations, moving
controllers dynamically between the v2 and other hierarchies is
strongly discouraged for production use.  It is recommended to decide
the hierarchies and controller associations before starting using the
controllers after system boot.  
虽然对于开发和手动配置很有用，但强烈建议不要在生产使用中在 v​​2 和其他层次结构之间动态移动控制器。建议在系统启动后开始使用控制器之前确定层次结构和控制器关联。  
During transition to v2, system management software might still
automount the v1 cgroup filesystem and so hijack all controllers
during boot, before manual intervention is possible. To make testing
and experimenting easier, the kernel parameter cgroup\_no\_v1= allows
disabling controllers in v1 and make them always available in v2.  
在过渡到 v2 期间，系统管理软件可能仍会自动挂载 v1 cgroup 文件系统，因此在启动期间劫持所有控制器，然后才可以进行手动干预。为了使测试和实验更容易，内核参数 cgroup\_no\_v1= 允许禁用 v1 中的控制器并使其在 v2 中始终可用。  
cgroup v2 currently supports the following mount options.  
cgroup v2 当前支持以下挂载选项。  
  nsdelegate  代理  
	Consider cgroup namespaces as delegation boundaries.  This
	option is system wide and can only be set on mount or modified
	through remount from the init namespace.  The mount option is
	ignored on non-init namespace mounts.  Please refer to the
	Delegation section for details. 将 cgroup 命名空间视为委托边界。此选项是系统范围的，只能在挂载时设置或通过从 init 命名空间重新挂载进行修改。在非 init 命名空间挂载上，挂载选项将被忽略。详情请参阅代表团部分。  
Organizing Processes and Threads
-------------------------------- 组织进程和线程--------------------------------  
Processes
~~~~~~~~~ 进程~~~~~~~~~  
Initially, only the root cgroup exists to which all processes belong.
A child cgroup can be created by creating a sub-directory::  
最初，仅存在所有进程所属的根 cgroup。可以通过创建子目录来创建子 cgroup::  
  # mkdir $CGROUP\_NAME  
A given cgroup may have multiple child cgroups forming a tree
structure.  Each cgroup has a read-writable interface file
"cgroup.procs".  When read, it lists the PIDs of all processes which
belong to the cgroup one-per-line.  The PIDs are not ordered and the
same PID may show up more than once if the process got moved to
another cgroup and then back or the PID got recycled while reading.  
给定的 cgroup 可能有多个子 cgroup，形成树结构。每个cgroup都有一个可读写的接口文件“cgroup.procs”。读取时，它会逐行列出属于该 cgroup 的所有进程的 PID。 PID 没有排序，如果进程移动到另一个 cgroup 然后又返回，或者 PID 在读取时被回收，则相同的 PID 可能会多次出现。  
A process can be migrated into a cgroup by writing its PID to the
target cgroup's "cgroup.procs" file.  Only one process can be migrated
on a single write(2) call.  If a process is composed of multiple
threads, writing the PID of any thread migrates all threads of the
process.  
通过将进程的 PID 写入目标 cgroup 的“cgroup.procs”文件，可以将进程迁移到 cgroup 中。一次 write(2) 调用只能迁移一个进程。如果一个进程由多个线程组成，写入任意线程的PID就会迁移该进程的所有线程。  
When a process forks a child process, the new process is born into the
cgroup that the forking process belongs to at the time of the
operation.  After exit, a process stays associated with the cgroup
that it belonged to at the time of exit until it's reaped; however, a
zombie process does not appear in "cgroup.procs" and thus can't be
moved to another cgroup.  
当一个进程fork出一个子进程时，新进程就会诞生到fork进程运行时所属的cgroup中。退出后，进程将与其退出时所属的 cgroup 保持关联，直到被回收；但是，僵尸进程不会出现在“cgroup.procs”中，因此无法移动到另一个 cgroup。  
A cgroup which doesn't have any children or live processes can be
destroyed by removing the directory.  Note that a cgroup which doesn't
have any children and is associated only with zombie processes is
considered empty and can be removed::  
没有任何子进程或活动进程的 cgroup 可以通过删除目录来销毁。请注意，没有任何子进程且仅与僵尸进程关联的 cgroup 被视为空的，可以删除::  
  # rmdir $CGROUP\_NAME  
"/proc/$PID/cgroup" lists a process's cgroup membership.  If legacy
cgroup is in use in the system, this file may contain multiple lines,
one for each hierarchy.  The entry for cgroup v2 is always in the
format "0::$PATH"::  
“/proc/$PID/cgroup”列出进程的 cgroup 成员资格。如果系统中正在使用旧版 cgroup，则此文件可能包含多行，每个层次结构一行。 cgroup v2 的条目始终采用“0::$PATH”:: 格式  
  # cat /proc/842/cgroup
  ...
  0::/test-cgroup/test-cgroup-nested  
If the process becomes a zombie and the cgroup it was associated with
is removed subsequently, " (deleted)" is appended to the path::  
如果该进程成为僵尸进程，并且随后删除了与其关联的 cgroup，则“（已删除）”将附加到路径::  
  # cat /proc/842/cgroup
  ...
  0::/test-cgroup/test-cgroup-nested (deleted) # cat /proc/842/cgroup ... 0::/test-cgroup/test-cgroup-nested (已删除)  
Threads
~~~~~~~  主题~~~~~~~  
cgroup v2 supports thread granularity for a subset of controllers to
support use cases requiring hierarchical resource distribution across
the threads of a group of processes.  By default, all threads of a
process belong to the same cgroup, which also serves as the resource
domain to host resource consumptions which are not specific to a
process or thread.  The thread mode allows threads to be spread across
a subtree while still maintaining the common resource domain for them.  
cgroup v2 支持控制器子集的线程粒度，以支持需要跨一组进程的线程进行分层资源分配的用例。默认情况下，进程的所有线程都属于同一个 cgroup，该 cgroup 也充当资源域，用于托管非特定于进程或线程的资源消耗。线程模式允许线程分布在子树上，同时仍然维护它们的公共资源域。  
Controllers which support thread mode are called threaded controllers.
The ones which don't are called domain controllers.  
支持线程模式的控制器称为线程控制器。没有的称为域控制器。  
Marking a cgroup threaded makes it join the resource domain of its
parent as a threaded cgroup.  The parent may be another threaded
cgroup whose resource domain is further up in the hierarchy.  The root
of a threaded subtree, that is, the nearest ancestor which is not
threaded, is called threaded domain or thread root interchangeably and
serves as the resource domain for the entire subtree.  
将 cgroup 标记为线程化会使其作为线程化 cgroup 加入其父级的资源域。父级可能是另一个线程 cgroup，其资源域在层次结构中更靠上。线程子树的根，即非线程化的最近祖先，可互换地称为线程域或线程根，并充当整个子树的资源域。  
Inside a threaded subtree, threads of a process can be put in
different cgroups and are not subject to the no internal process
constraint - threaded controllers can be enabled on non-leaf cgroups
whether they have threads in them or not.  
在线程子树内部，进程的线程可以放入不同的 cgroup 中，并且不受无内部进程约束 - 可以在非叶 cgroup 上启用线程控制器，无论它们是否有线程。  
As the threaded domain cgroup hosts all the domain resource
consumptions of the subtree, it is considered to have internal
resource consumptions whether there are processes in it or not and
can't have populated child cgroups which aren't threaded.  Because the
root cgroup is not subject to no internal process constraint, it can
serve both as a threaded domain and a parent to domain cgroups.  
由于线程域 cgroup 托管子树的所有域资源消耗，因此无论其中是否有进程，它都被认为具有内部资源消耗，并且不能填充非线程化的子 cgroup。由于根 cgroup 不受内部进程约束，因此它既可以充当线程域，也可以充当域 cgroup 的父级。  
The current operation mode or type of the cgroup is shown in the
"cgroup.type" file which indicates whether the cgroup is a normal
domain, a domain which is serving as the domain of a threaded subtree,
or a threaded cgroup.  
cgroup当前的操作模式或类型显示在“cgroup.type”文件中，该文件指示cgroup是普通域、充当线程子树域的域还是线程cgroup。  
On creation, a cgroup is always a domain cgroup and can be made
threaded by writing "threaded" to the "cgroup.type" file.  The
operation is single direction::  
创建时，cgroup 始终是域 cgroup，并且可以通过将“threaded”写入“cgroup.type”文件来使其线程化。操作是单向的::  
  # echo threaded > cgroup.type # echo 线程 > cgroup.type  
Once threaded, the cgroup can't be made a domain again.  To enable the
thread mode, the following conditions must be met.  
一旦线程化，cgroup 就无法再次成为域。要启用线程模式，必须满足以下条件。  
\- As the cgroup will join the parent's resource domain.  The parent
  must either be a valid (threaded) domain or a threaded cgroup.  
\- 由于 cgroup 将加入父级的资源域。父级必须是有效（线程）域或线程 cgroup。  
\- When the parent is an unthreaded domain, it must not have any domain
  controllers enabled or populated domain children.  The root is
  exempt from this requirement.  
\- 当父域是非线程域时，它不得启用任何域控制器或填充域子域。根不受此要求的约束。  
Topology-wise, a cgroup can be in an invalid state.  Please consider
the following topology::  
从拓扑角度来看，cgroup 可能处于无效状态。请考虑以下拓扑：：  
  A (threaded domain) - B (threaded) - C (domain, just created)  
A（线程域）- B（线程）- C（域，刚刚创建）  
C is created as a domain but isn't connected to a parent which can
host child domains.  C can't be used until it is turned into a
threaded cgroup.  "cgroup.type" file will report "domain (invalid)" in
these cases.  Operations which fail due to invalid topology use
EOPNOTSUPP as the errno.  
C 作为域创建，但未连接到可以托管子域的父域。 C 必须变成线程 cgroup 才能使用。在这些情况下，“cgroup.type”文件将报告“域（无效）”。由于无效拓扑而失败的操作使用 EOPNOTSUPP 作为 errno。  
A domain cgroup is turned into a threaded domain when one of its child
cgroup becomes threaded or threaded controllers are enabled in the
"cgroup.subtree\_control" file while there are processes in the cgroup.
A threaded domain reverts to a normal domain when the conditions
clear.  
当域 cgroup 的一个子 cgroup 成为线程化或在“cgroup.subtree\_control”文件中启用线程控制器且 cgroup 中有进程时，该域 cgroup 将转变为线程域。当条件清除时，线程域将恢复为正常域。  
When read, "cgroup.threads" contains the list of the thread IDs of all
threads in the cgroup.  Except that the operations are per-thread
instead of per-process, "cgroup.threads" has the same format and
behaves the same way as "cgroup.procs".  While "cgroup.threads" can be
written to in any cgroup, as it can only move threads inside the same
threaded domain, its operations are confined inside each threaded
subtree.  
读取时，“cgroup.threads”包含cgroup中所有线程的线程ID列表。除了操作是针对每个线程而不是针对每个进程之外，“cgroup.threads”与“cgroup.procs”具有相同的格式和行为方式。虽然“cgroup.threads”可以写入任何 cgroup 中，但由于它只能在同一线程域内移动线程，因此它的操作被限制在每个线程子树内。  
The threaded domain cgroup serves as the resource domain for the whole
subtree, and, while the threads can be scattered across the subtree,
all the processes are considered to be in the threaded domain cgroup.
"cgroup.procs" in a threaded domain cgroup contains the PIDs of all
processes in the subtree and is not readable in the subtree proper.
However, "cgroup.procs" can be written to from anywhere in the subtree
to migrate all threads of the matching process to the cgroup.  
线程域 cgroup 充当整个子树的资源域，并且虽然线程可以分散在子树中，但所有进程都被视为位于线程域 cgroup 中。线程域 cgroup 中的“cgroup.procs”包含子树中所有进程的 PID，并且在子树中不可读。但是，可以从子树中的任何位置写入“cgroup.procs”，以将匹配进程的所有线程迁移到 cgroup。  
Only threaded controllers can be enabled in a threaded subtree.  When
a threaded controller is enabled inside a threaded subtree, it only
accounts for and controls resource consumptions associated with the
threads in the cgroup and its descendants.  All consumptions which
aren't tied to a specific thread belong to the threaded domain cgroup.  
在线程子树中只能启用线程控制器。当线程控制器在线程子树内启用时，它仅考虑和控制与 cgroup 及其后代中的线程相关的资源消耗。所有不依赖于特定线程的消耗都属于线程域 cgroup。  
Because a threaded subtree is exempt from no internal process
constraint, a threaded controller must be able to handle competition
between threads in a non-leaf cgroup and its child cgroups.  Each
threaded controller defines how such competitions are handled.  
由于线程子树不受任何内部进程约束，因此线程控制器必须能够处理非叶 cgroup 及其子 cgroup 中的线程之间的竞争。每个线程控制器定义如何处理此类竞争。  
\[Un\]populated Notification
-------------------------- \[未\]填充通知 --------------------------  
Each non-root cgroup has a "cgroup.events" file which contains
"populated" field indicating whether the cgroup's sub-hierarchy has
live processes in it.  Its value is 0 if there is no live process in
the cgroup and its descendants; otherwise, 1.  poll and \[id\]notify
events are triggered when the value changes.  This can be used, for
example, to start a clean-up operation after all processes of a given
sub-hierarchy have exited.  The populated state updates and
notifications are recursive.  Consider the following sub-hierarchy
where the numbers in the parentheses represent the numbers of processes
in each cgroup::  
每个非根 cgroup 都有一个“cgroup.events”文件，其中包含“填充”字段，指示 cgroup 的子层次结构中是否有实时进程。如果 cgroup 及其后代中没有活动进程，则其值为 0；否则， 1. 当值发生变化时，会触发 poll 和 \[id\]notify 事件。例如，这可以用于在给定子层次结构的所有进程退出后启动清理操作。填充的状态更新和通知是递归的。考虑以下子层次结构，其中括号中的数字表示每个 cgroup 中的进程数：  
  A(4) - B(0) - C(1)
              \\ D(0)  
A, B and C's "populated" fields would be 1 while D's 0.  After the one
process in C exits, B and C's "populated" fields would flip to "0" and
file modified events will be generated on the "cgroup.events" files of
both cgroups.  
A、B 和 C 的“填充”字段将为 1，而 D 为 0。C 中的一个进程退出后，B 和 C 的“填充”字段将翻转为“0”，并且文件修改事件将在“cgroup.events”上生成" 两个 cgroup 的文件。  
Controlling Controllers
----------------------- 控制控制器 ----------------------------------  
Enabling and Disabling
~~~~~~~~~~~~~~~~~~~~~~  
启用和禁用 ~~~~~~~~~~~~~~~~~~~~~~  
Each cgroup has a "cgroup.controllers" file which lists all
controllers available for the cgroup to enable::  
每个 cgroup 都有一个“cgroup.controllers”文件，其中列出了可供该 cgroup 启用的所有控制器：  
  # cat cgroup.controllers
  cpu io memory # cat cgroup.controllers cpu io 内存  
No controller is enabled by default.  Controllers can be enabled and
disabled by writing to the "cgroup.subtree\_control" file::  
默认情况下不启用任何控制器。可以通过写入“cgroup.subtree\_control”文件来启用和禁用控制器：  
  # echo "+cpu +memory -io" > cgroup.subtree\_control  
Only controllers which are listed in "cgroup.controllers" can be
enabled.  When multiple operations are specified as above, either they
all succeed or fail.  If multiple operations on the same controller
are specified, the last one is effective.  
只能启用“cgroup.controllers”中列出的控制器。当如上所述指定多个操作时，它们要么全部成功，要么全部失败。如果对同一控制器指定了多次操作，则最后一次有效。  
Enabling a controller in a cgroup indicates that the distribution of
the target resource across its immediate children will be controlled.
Consider the following sub-hierarchy.  The enabled controllers are
listed in parentheses::  
启用 cgroup 中的控制器表示目标资源在其直接子级之间的分配将受到控制。考虑以下子层次结构。启用的控制器列在括号中：：  
  A(cpu,memory) - B(memory) - C()
                            \\ D() A(CPU、内存) - B(内存) - C() \\ D()  
As A has "cpu" and "memory" enabled, A will control the distribution
of CPU cycles and memory to its children, in this case, B.  As B has
"memory" enabled but not "CPU", C and D will compete freely on CPU
cycles but their division of memory available to B will be controlled.  
由于 A 启用了“cpu”和“内存”，A 将控制对其子级（在本例中为 B）分配 CPU 周期和内存。由于 B 启用了“内存”但未启用“CPU”，因此 C 和 D 将竞争在 CPU 周期上自由，但 B 可用的内存分配将受到控制。  
As a controller regulates the distribution of the target resource to
the cgroup's children, enabling it creates the controller's interface
files in the child cgroups.  In the above example, enabling "cpu" on B
would create the "cpu." prefixed controller interface files in C and
D.  Likewise, disabling "memory" from B would remove the "memory."
prefixed controller interface files from C and D.  This means that the
controller interface files - anything which doesn't start with
"cgroup." are owned by the parent rather than the cgroup itself.  
当控制器调节目标资源到 cgroup 子级的分配时，使其能够在子 cgroup 中创建控制器的接口文件。在上面的示例中，在 B 上启用“cpu”将创建“cpu”。 C 和 D 中带有前缀的控制器接口文件。同样，从 B 禁用“内存”将会删除“内存”。来自 C 和 D 的前缀控制器接口文件。这意味着控制器接口文件 - 任何不以“cgroup”开头的文件。由父级而不是 cgroup 本身拥有。  
Top-down Constraint
~~~~~~~~~~~~~~~~~~~ 自上而下的约束 ~~~~~~~~~~~~~~~~~~~  
Resources are distributed top-down and a cgroup can further distribute
a resource only if the resource has been distributed to it from the
parent.  This means that all non-root "cgroup.subtree\_control" files
can only contain controllers which are enabled in the parent's
"cgroup.subtree\_control" file.  A controller can be enabled only if
the parent has the controller enabled and a controller can't be
disabled if one or more children have it enabled.  
资源是自上而下分配的，只有当资源已从父级分配给 cgroup 时，cgroup 才能进一步分配资源。这意味着所有非根“cgroup.subtree\_control”文件只能包含在父级“cgroup.subtree\_control”文件中启用的控制器。仅当父级启用了控制器时才可以启用该控制器，并且如果一个或多个子级启用了该控制器，则无法禁用该控制器。  
No Internal Process Constraint
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 无内部流程限制~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
Non-root cgroups can distribute domain resources to their children
only when they don't have any processes of their own.  In other words,
only domain cgroups which don't contain any processes can have domain
controllers enabled in their "cgroup.subtree\_control" files.  
非根 cgroup 仅当它们没有自己的任何进程时才可以将域资源分配给其子级。换句话说，只有不包含任何进程的域 cgroup 才能在其“cgroup.subtree\_control”文件中启用域控制器。  
This guarantees that, when a domain controller is looking at the part
of the hierarchy which has it enabled, processes are always only on
the leaves.  This rules out situations where child cgroups compete
against internal processes of the parent.  
这保证了当域控制器查看启用它的层次结构部分时，进程始终仅位于叶子上。这排除了子 cgroup 与父 cgroup 的内部进程竞争的情况。  
The root cgroup is exempt from this restriction.  Root contains
processes and anonymous resource consumption which can't be associated
with any other cgroups and requires special treatment from most
controllers.  How resource consumption in the root cgroup is governed
is up to each controller (for more information on this topic please
refer to the Non-normative information section in the Controllers
chapter).  
根 cgroup 不受此限制。 Root 包含进程和匿名资源消耗，它们不能与任何其他 cgroup 关联，并且需要大多数控制器的特殊处理。如何管理根 cgroup 中的资源消耗取决于每个控制器（有关此主题的更多信息，请参阅控制器章节中的非规范信息部分）。  
Note that the restriction doesn't get in the way if there is no
enabled controller in the cgroup's "cgroup.subtree\_control".  This is
important as otherwise it wouldn't be possible to create children of a
populated cgroup.  To control resource distribution of a cgroup, the
cgroup must create children and transfer all its processes to the
children before enabling controllers in its "cgroup.subtree\_control"
file.  
请注意，如果 cgroup 的“cgroup.subtree\_control”中没有启用的控制器，则该限制不会妨碍。这很重要，否则将无法创建已填充 cgroup 的子级。为了控制 cgroup 的资源分配，cgroup 必须创建子级并将其所有进程转移到子级，然后才能在其“cgroup.subtree\_control”文件中启用控制器。  
Delegation
----------  代表团  -  -  -  -  -   
Model of Delegation
~~~~~~~~~~~~~~~~~~~  
代表团模式~~~~~~~~~~~~~~~~~~  
A cgroup can be delegated in two ways.  First, to a less privileged
user by granting write access of the directory and its "cgroup.procs",
"cgroup.threads" and "cgroup.subtree\_control" files to the user.
Second, if the "nsdelegate" mount option is set, automatically to a
cgroup namespace on namespace creation.  
cgroup 可以通过两种方式进行委托。首先，通过向用户授予目录及其“cgroup.procs”、“cgroup.threads”和“cgroup.subtree\_control”文件的写访问权限来授予特权较低的用户。其次，如果设置了“nsdelegate”挂载选项，则在创建命名空间时自动到 cgroup 命名空间。  
Because the resource control interface files in a given directory
control the distribution of the parent's resources, the delegatee
shouldn't be allowed to write to them.  For the first method, this is
achieved by not granting access to these files.  For the second, the
kernel rejects writes to all files other than "cgroup.procs" and
"cgroup.subtree\_control" on a namespace root from inside the
namespace.  
由于给定目录中的资源控制接口文件控制父级资源的分配，因此不应允许受委托者对它们进行写入。对于第一种方法，这是通过不授予对这些文件的访问权限来实现的。对于第二个，内核拒绝从命名空间内部写入命名空间根上除“cgroup.procs”和“cgroup.subtree\_control”之外的所有文件。  
The end results are equivalent for both delegation types.  Once
delegated, the user can build sub-hierarchy under the directory,
organize processes inside it as it sees fit and further distribute the
resources it received from the parent.  The limits and other settings
of all resource controllers are hierarchical and regardless of what
happens in the delegated sub-hierarchy, nothing can escape the
resource restrictions imposed by the parent.  
两种委托类型的最终结果是相同的。一旦委派，用户就可以在目录下构建子层次结构，根据需要组织其中的流程，并进一步分配从父级接收的资源。所有资源控制器的限制和其他设置都是分层的，无论委托的子层次结构中发生什么，没有任何东西可以逃脱父级施加的资源限制。  
Currently, cgroup doesn't impose any restrictions on the number of
cgroups in or nesting depth of a delegated sub-hierarchy; however,
this may be limited explicitly in the future.  
目前，cgroup 对委派子层次结构中的 cgroup 数量或嵌套深度没有任何限制；但是，将来这可能会受到明确限制。  
Delegation Containment
~~~~~~~~~~~~~~~~~~~~~~ 代表团收容~~~~~~~~~~~~~~~~~~~~~  
A delegated sub-hierarchy is contained in the sense that processes
can't be moved into or out of the sub-hierarchy by the delegatee.  
委派的子层次结构是包含在进程不能由委派者移入或移出子层次结构的意义上。  
For delegations to a less privileged user, this is achieved by
requiring the following conditions for a process with a non-root euid
to migrate a target process into a cgroup by writing its PID to the
"cgroup.procs" file.  
对于权限较低的用户的委派，这是通过要求具有非 root euid 的进程满足以下条件来将目标进程迁移到 cgroup（通过将其 PID 写入“cgroup.procs”文件）来实现的。  
\- The writer must have write access to the "cgroup.procs" file.  
\- 作者必须具有对“cgroup.procs”文件的写访问权限。  
\- The writer must have write access to the "cgroup.procs" file of the
  common ancestor of the source and destination cgroups.  
\- 编写者必须对源 cgroup 和目标 cgroup 的共同祖先的“cgroup.procs”文件具有写入权限。  
The above two constraints ensure that while a delegatee may migrate
processes around freely in the delegated sub-hierarchy it can't pull
in from or push out to outside the sub-hierarchy.  
上述两个约束确保虽然委托者可以在委托的子层次结构中自由地迁移进程，但它不能从子层次结构外部拉入或推出到子层次结构之外。  
For an example, let's assume cgroups C0 and C1 have been delegated to
user U0 who created C00, C01 under C0 and C10 under C1 as follows and
all processes under C0 and C1 belong to U0::  
例如，假设 cgroup C0 和 C1 已委托给用户 U0，用户 U0 在 C0 下创建了 C00、C01，在 C1 下创建了 C10，如下所示，并且 C0 和 C1 下的所有进程都属于 U0：  
  ~~~~~~~~~~~~~ - C0 - C00
  ~ cgroup    ~      \\ C01
  ~ hierarchy ~
  ~~~~~~~~~~~~~ - C1 - C10 ~~~~~~~~~~~~~ - C0 - C00 ~ cgroup ~ \\ C01 ~ 层次结构 ~ ~~~~~~~~~~~~~ - C1 - C10  
Let's also say U0 wants to write the PID of a process which is
currently in C10 into "C00/cgroup.procs".  U0 has write access to the
file; however, the common ancestor of the source cgroup C10 and the
destination cgroup C00 is above the points of delegation and U0 would
not have write access to its "cgroup.procs" files and thus the write
will be denied with -EACCES.  
还假设 U0 想要将当前位于 C10 中的进程的 PID 写入“C00/cgroup.procs”。 U0 对文件有写权限；然而，源 cgroup C10 和目标 cgroup C00 的共同祖先位于委派点之上，并且 U0 对其“cgroup.procs”文件没有写入访问权限，因此写入将被 -EACCES 拒绝。  
For delegations to namespaces, containment is achieved by requiring
that both the source and destination cgroups are reachable from the
namespace of the process which is attempting the migration.  If either
is not reachable, the migration is rejected with -ENOENT.  
对于命名空间的委派，通过要求源 cgroup 和目标 cgroup 都可从尝试迁移的进程的命名空间访问来实现遏制。如果其中一个无法访问，则迁移会被 -ENOENT 拒绝。  
Guidelines
----------  指导方针----------  
Organize Once and Control
~~~~~~~~~~~~~~~~~~~~~~~~~  
组织一次，控制~~~~~~~~~~~~~~~~~~~~~~~~  
Migrating a process across cgroups is a relatively expensive operation
and stateful resources such as memory are not moved together with the
process.  This is an explicit design decision as there often exist
inherent trade-offs between migration and various hot paths in terms
of synchronization cost.  
跨 cgroup 迁移进程是一项相对昂贵的操作，并且内存等有状态资源不会随进程一起移动。这是一个明确的设计决策，因为迁移和各种热路径之间在同步成本方面通常存在固有的权衡。  
As such, migrating processes across cgroups frequently as a means to
apply different resource restrictions is discouraged.  A workload
should be assigned to a cgroup according to the system's logical and
resource structure once on start-up.  Dynamic adjustments to resource
distribution can be made by changing controller configuration through
the interface files.  
因此，不鼓励频繁地跨 cgroup 迁移进程作为应用不同资源限制的手段。启动时，应根据系统的逻辑和资源结构将工作负载分配给 cgroup。可以通过接口文件更改控制器配置来动态调整资源分配。  
Avoid Name Collisions
~~~~~~~~~~~~~~~~~~~~~ 避免名称冲突~~~~~~~~~~~~~~~~~~~~~  
Interface files for a cgroup and its children cgroups occupy the same
directory and it is possible to create children cgroups which collide
with interface files.  
cgroup 及其子 cgroup 的接口文件占用相同的目录，并且可以创建与接口文件冲突的子 cgroup。  
All cgroup core interface files are prefixed with "cgroup." and each
controller's interface files are prefixed with the controller name and
a dot.  A controller's name is composed of lower case alphabets and
'\_'s but never begins with an '\_' so it can be used as the prefix
character for collision avoidance.  Also, interface file names won't
start or end with terms which are often used in categorizing workloads
such as job, service, slice, unit or workload.  
所有 cgroup 核心接口文件都以“cgroup”为前缀。每个控制器的接口文件都以控制器名称和点为前缀。控制器的名称由小写字母和“\_”组成，但绝不以“\_”开头，因此可以用作避免冲突的前缀字符。此外，接口文件名不会以工作负载分类中常用的术语开头或结尾，例如作业、服务、切片、单元或工作负载。  
cgroup doesn't do anything to prevent name collisions and it's the
user's responsibility to avoid them.  
cgroup 不会采取任何措施来防止名称冲突，用户有责任避免名称冲突。  
Resource Distribution Models
============================  
资源分配模型==============================  
cgroup controllers implement several resource distribution schemes
depending on the resource type and expected use cases.  This section
describes major schemes in use along with their expected behaviors.  
cgroup 控制器根据资源类型和预期用例实现多种资源分配方案。本节描述了正在使用的主要方案及其预期行为。  
Weights
-------  重量--------  
A parent's resource is distributed by adding up the weights of all
active children and giving each the fraction matching the ratio of its
weight against the sum.  As only children which can make use of the
resource at the moment participate in the distribution, this is
work-conserving.  Due to the dynamic nature, this model is usually
used for stateless resources.  
通过将所有活动子级的权重相加并给予每个子级与其权重与总和的比率相匹配的分数来分配父级的资源。由于只有当前可以使用资源的孩子才参与分配，因此这是节省工作的。由于动态特性，该模型通常用于无状态资源。  
All weights are in the range \[1, 10000\] with the default at 100.  This
allows symmetric multiplicative biases in both directions at fine
enough granularity while staying in the intuitive range.  
所有权重均在 \[1, 10000\] 范围内，默认值为 100。这允许在两个方向上以足够细的粒度进行对称乘法偏差，同时保持在直观范围内。  
As long as the weight is in range, all configuration combinations are
valid and there is no reason to reject configuration changes or
process migrations.  
只要权重在范围内，所有配置组合都是有效的，没有理由拒绝配置更改或流程迁移。  
"cpu.weight" proportionally distributes CPU cycles to active children
and is an example of this type.  
“cpu.weight”按比例将 CPU 周期分配给活动的子进程，是这种类型的一个示例。  
Limits
------  限制------  
A child can only consume upto the configured amount of the resource.
Limits can be over-committed - the sum of the limits of children can
exceed the amount of resource available to the parent.  
子级最多只能消耗配置的资源量。限制可能会被过度使用 - 子级的限制总和可能超过父级可用的资源量。  
Limits are in the range \[0, max\] and defaults to "max", which is noop.  
限制范围为 \[0, max\]，默认为“max”，即 noop。  
As limits can be over-committed, all configuration combinations are
valid and there is no reason to reject configuration changes or
process migrations.  
由于限制可能会被过度使用，因此所有配置组合都是有效的，没有理由拒绝配置更改或流程迁移。  
"io.max" limits the maximum BPS and/or IOPS that a cgroup can consume
on an IO device and is an example of this type.  
“io.max”限制 cgroup 可在 IO 设备上消耗的最大 BPS 和/或 IOPS，是此类的一个示例。  
Protections
-----------  保护措施----------  
A cgroup is protected to be allocated upto the configured amount of
the resource if the usages of all its ancestors are under their
protected levels.  Protections can be hard guarantees or best effort
soft boundaries.  Protections can also be over-committed in which case
only upto the amount available to the parent is protected among
children.  
如果 cgroup 的所有祖先的使用量都在其受保护级别之下，则该 cgroup 将受到保护，最多可分配配置的资源量。保护可以是硬保证，也可以是尽力而为的软边界。保护也可能会过度承诺，​​在这种情况下，儿童只能受到父母可用的保护。  
Protections are in the range \[0, max\] and defaults to 0, which is
noop.  
保护范围为 \[0, max\]，默认为 0，即 noop。  
As protections can be over-committed, all configuration combinations
are valid and there is no reason to reject configuration changes or
process migrations.  
由于保护可能会被过度使用，因此所有配置组合都是有效的，没有理由拒绝配置更改或流程迁移。  
"memory.low" implements best-effort memory protection and is an
example of this type.  
“memory.low”实现尽力而为的内存保护，并且是这种类型的一个示例。  
Allocations
-----------  分配------------  
A cgroup is exclusively allocated a certain amount of a finite
resource.  Allocations can't be over-committed - the sum of the
allocations of children can not exceed the amount of resource
available to the parent.  
一个cgroup 被专门分配一定数量的有限资源。分配不能过度承诺 - 子级分配的总和不能超过父级可用的资源量。  
Allocations are in the range \[0, max\] and defaults to 0, which is no
resource.  
分配范围为 \[0, max\]，默认为 0，即没有资源。  
As allocations can't be over-committed, some configuration
combinations are invalid and should be rejected.  Also, if the
resource is mandatory for execution of processes, process migrations
may be rejected.  
由于分配不能过度分配，因此某些配置组合无效，应被拒绝。此外，如果该资源对于进程的执行是必需的，则进程迁移可能会被拒绝。  
"cpu.rt.max" hard-allocates realtime slices and is an example of this
type.  
“cpu.rt.max”硬分配实时切片，是这种类型的一个示例。  
Interface Files
=============== 接口文件==============  
Format
------ 格式  -  -  -   
All interface files should be in one of the following formats whenever
possible::  
所有接口文件应尽可能采用以下格式之一：  
  New-line separated values
  (when only one value can be written at once) 换行分隔值（当一次只能写入一个值时）  
	VAL0\\n
	VAL1\\n
	...  
  Space separated values
  (when read-only or multiple values can be written at once) 空格分隔的值（当只读或可以一次写入多个值时）  
	VAL0 VAL1 ...\\n  
  Flat keyed  平键  
	KEY0 VAL0\\n
	KEY1 VAL1\\n
	...  
  Nested keyed  嵌套键控  
	KEY0 SUB\_KEY0=VAL00 SUB\_KEY1=VAL01...
	KEY1 SUB\_KEY0=VAL10 SUB\_KEY1=VAL11...
	...  
For a writable file, the format for writing should generally match
reading; however, controllers may allow omitting later fields or
implement restricted shortcuts for most common use cases.  
对于可写文件，写入的格式一般应与读取的格式一致；然而，控制器可能允许省略后面的字段或为最常见的用例实现受限的快捷方式。  
For both flat and nested keyed files, only the values for a single key
can be written at a time.  For nested keyed files, the sub key pairs
may be specified in any order and not all pairs have to be specified.  
对于平面和嵌套键控文件，一次只能写入单个键的值。对于嵌套密钥文件，可以按任何顺序指定子密钥对，并且不必指定所有对。  
Conventions
-----------  惯例------------  
\- Settings for a single feature should be contained in a single file.  
\- 单个功能的设置应包含在单个文件中。  
\- The root cgroup should be exempt from resource control and thus
  shouldn't have resource control interface files.  Also,
  informational files on the root cgroup which end up showing global
  information available elsewhere shouldn't exist.  
\- 根 cgroup 应不受资源控制，因此不应具有资源控制接口文件。此外，根 cgroup 上最终显示其他地方可用的全局信息的信息文件不应该存在。  
\- If a controller implements weight based resource distribution, its
  interface file should be named "weight" and have the range \[1,
  10000\] with 100 as the default.  The values are chosen to allow
  enough and symmetric bias in both directions while keeping it
  intuitive (the default is 100%).  
\- 如果控制器实现基于权重的资源分配，则其接口文件应命名为“weight”，范围为 \[1, 10000\]，默认为 100。选择这些值是为了在两个方向上允许足够的对称偏差，同时保持直观（默认值为 100%）。  
\- If a controller implements an absolute resource guarantee and/or
  limit, the interface files should be named "min" and "max"
  respectively.  If a controller implements best effort resource
  guarantee and/or limit, the interface files should be named "low"
  and "high" respectively.  
\- 如果控制器实现绝对资源保证和/或限制，则接口文件应分别命名为“min”和“max”。如果控制器实现尽力而为资源保证和/或限制，则接口文件应分别命名为“low”和“high”。  
  In the above four control files, the special token "max" should be
  used to represent upward infinity for both reading and writing. 在上面的四个控制文件中，应该使用特殊标记“max”来表示读和写的向上无穷大。  
\- If a setting has a configurable default value and keyed specific
  overrides, the default entry should be keyed with "default" and
  appear as the first entry in the file.  
\- 如果设置具有可配置的默认值和键入的特定覆盖，则默认条目应键入“default”并显示为文件中的第一个条目。  
  The default value can be updated by writing either "default $VAL" or
  "$VAL". 可以通过写入“default $VAL”或“$VAL”来更新默认值。  
  When writing to update a specific override, "default" can be used as
  the value to indicate removal of the override.  Override entries
  with "default" as the value must not appear when read.  
当写入更新特定覆盖时，“默认”可以用作指示删除覆盖的值。使用“默认”覆盖条目，因为读取时不得出现该值。  
  For example, a setting which is keyed by major:minor device numbers
  with integer values may look like the following:: 例如，由具有整数值的主设备号：次设备号作为键控的设置可能如下所示：  
    # cat cgroup-example-interface-file
    default 150
    8:0 300 # cat cgroup-example-interface-file 默认 150 8:0 300  
  The default value can be updated by:: 默认值可以通过以下方式更新：  
    # echo 125 > cgroup-example-interface-file # echo 125 > cgroup-示例-接口-文件  
  or::  或者：：  
    # echo "default 125" > cgroup-example-interface-file # echo "默认 125" > cgroup-example-interface-file  
  An override can be set by:: 可以通过以下方式设置覆盖：  
    # echo "8:16 170" > cgroup-example-interface-file  
  and cleared by::  并由:: 清除  
    # echo "8:0 default" > cgroup-example-interface-file
    # cat cgroup-example-interface-file
    default 125
    8:16 170 # echo "8:0 默认值" > cgroup-example-interface-file # cat cgroup-example-interface-file 默认 125 8:16 170  
\- For events which are not very high frequency, an interface file
  "events" should be created which lists event key value pairs.
  Whenever a notifiable event happens, file modified event should be
  generated on the file.  
\- 对于频率不是很高的事件，应创建一个接口文件“events”，其中列出事件键值对。每当发生可通知事件时，应在文件上生成文件修改事件。  
Core Interface Files
-------------------- 核心接口文件--------------------  
All cgroup core files are prefixed with "cgroup."  
所有 cgroup 核心文件都以“cgroup”为前缀。  
  cgroup.type  cgroup.类型  
	A read-write single value file which exists on non-root
	cgroups. 存在于非根 cgroup 上的读写单值文件。  
	When read, it indicates the current type of the cgroup, which
	can be one of the following values. 读取时，它指示 cgroup 的当前类型，可以是以下值之一。  
	- "domain" : A normal valid domain cgroup. - “domain”：正常有效的域 cgroup。  
	- "domain threaded" : A threaded domain cgroup which is
          serving as the root of a threaded subtree. - “domain threaded”：线程域 cgroup，用作线程子树的根。  
	- "domain invalid" : A cgroup which is in an invalid state.
	  It can't be populated or have controllers enabled.  It may
	  be allowed to become a threaded cgroup. - “domain invalid”：处于无效状态的cgroup。它无法填充或启用控制器。它可能被允许成为线程化的cgroup。  
	- "threaded" : A threaded cgroup which is a member of a
          threaded subtree. - “threaded”：线程 cgroup，它是线程子树的成员。  
	A cgroup can be turned into a threaded cgroup by writing
	"threaded" to this file. 通过向此文件写入“threaded”，可以将 cgroup 转变为线程化 cgroup。  
  cgroup.procs
	A read-write new-line separated values file which exists on
	all cgroups. cgroup.procs 存在于所有 cgroup 上的读写换行分隔值文件。  
	When read, it lists the PIDs of all processes which belong to
	the cgroup one-per-line.  The PIDs are not ordered and the
	same PID may show up more than once if the process got moved
	to another cgroup and then back or the PID got recycled while
	reading.  
读取时，它会逐行列出属于该 cgroup 的所有进程的 PID。 PID 没有排序，如果进程移动到另一个 cgroup 然后又返回，或者 PID 在读取时被回收，则相同的 PID 可能会多次出现。  
	A PID can be written to migrate the process associated with
	the PID to the cgroup.  The writer should match all of the
	following conditions. 可以写入PID，将与该PID关联的进程迁移到cgroup中。作者应满足以下所有条件。  
	- It must have write access to the "cgroup.procs" file. - 它必须具有对“cgroup.procs”文件的写访问权限。  
	- It must have write access to the "cgroup.procs" file of the
	  common ancestor of the source and destination cgroups. - 它必须对源 cgroup 和目标 cgroup 的共同祖先的“cgroup.procs”文件具有写访问权限。  
	When delegating a sub-hierarchy, write access to this file
	should be granted along with the containing directory. 委派子层次结构时，应授予对此文件及其包含目录的写访问权限。  
	In a threaded cgroup, reading this file fails with EOPNOTSUPP
	as all the processes belong to the thread root.  Writing is
	supported and moves every thread of the process to the cgroup. 在线程 cgroup 中，读取此文件会失败并显示 EOPNOTSUPP，因为所有进程都属于线程根。支持写入，并将进程的每个线程移动到 cgroup。  
  cgroup.threads
	A read-write new-line separated values file which exists on
	all cgroups. cgroup.threads 存在于所有 cgroup 上的读写换行分隔值文件。  
	When read, it lists the TIDs of all threads which belong to
	the cgroup one-per-line.  The TIDs are not ordered and the
	same TID may show up more than once if the thread got moved to
	another cgroup and then back or the TID got recycled while
	reading. 读取时，它会逐行列出属于该 cgroup 的所有线程的 TID。 TID 没有排序，如果线程移动到另一个 cgroup 然后又返回，或者 TID 在读取时被回收，则相同的 TID 可能会出现多次。  
	A TID can be written to migrate the thread associated with the
	TID to the cgroup.  The writer should match all of the
	following conditions. 可以写入TID，将与该TID关联的线程迁移到cgroup中。作者应满足以下所有条件。  
	- It must have write access to the "cgroup.threads" file. - 它必须具有对“cgroup.threads”文件的写访问权限。  
	- The cgroup that the thread is currently in must be in the
          same resource domain as the destination cgroup. - 线程当前所在的cgroup必须与目标cgroup位于同一资源域中。  
	- It must have write access to the "cgroup.procs" file of the
	  common ancestor of the source and destination cgroups. - 它必须对源 cgroup 和目标 cgroup 的共同祖先的“cgroup.procs”文件具有写访问权限。  
	When delegating a sub-hierarchy, write access to this file
	should be granted along with the containing directory. 委派子层次结构时，应授予对此文件及其包含目录的写访问权限。  
  cgroup.controllers
	A read-only space separated values file which exists on all
	cgroups.  
cgroup.controllers 存在于所有 cgroup 上的只读空格分隔值文件。  
	It shows space separated list of all controllers available to
	the cgroup.  The controllers are not ordered. 它显示了 cgroup 可用的所有控制器的空格分隔列表。控制器未订购。  
  cgroup.subtree\_control
	A read-write space separated values file which exists on all
	cgroups.  Starts out empty. cgroup.subtree\_control 存在于所有 cgroup 上的读写空格分隔值文件。开始是空的。  
	When read, it shows space separated list of the controllers
	which are enabled to control resource distribution from the
	cgroup to its children. 读取时，它显示以空格分隔的控制器列表，这些控制器用于控制从 cgroup 到其子级的资源分配。  
	Space separated list of controllers prefixed with '+' or '-'
	can be written to enable or disable controllers.  A controller
	name prefixed with '+' enables the controller and '-'
	disables.  If a controller appears more than once on the list,
	the last one is effective.  When multiple enable and disable
	operations are specified, either all succeed or all fail. 可以写入以“+”或“-”为前缀的空格分隔的控制器列表来启用或禁用控制器。控制器名称以“+”为前缀可启用控制器，“-”则可禁用。如果某个控制器在列表中出现多次，则最后一个有效。当指定多个启用和禁用操作时，要么全部成功，要么全部失败。  
  cgroup.events
	A read-only flat-keyed file which exists on non-root cgroups.
	The following entries are defined.  Unless specified
	otherwise, a value change in this file generates a file
	modified event. cgroup.events 存在于非根 cgroup 上的只读平键文件。定义了以下条目。除非另有指定，否则此文件中的值更改会生成文件修改事件。  
	  populated
		1 if the cgroup or its descendants contains any live
		processes; otherwise, 0. 如果 cgroup 或其后代包含任何活动进程，则填充 1；否则，0。  
  cgroup.max.descendants
	A read-write single value files.  The default is "max". cgroup.max.descendants 一个可读写的单值文件。默认值为“最大”。  
	Maximum allowed number of descent cgroups.
	If the actual number of descendants is equal or larger,
	an attempt to create a new cgroup in the hierarchy will fail. 允许的最大下降 cgroup 数量。如果后代的实际数量等于或大于，则尝试在层次结构中创建新的 cgroup 将失败。  
  cgroup.max.depth
	A read-write single value files.  The default is "max". cgroup.max.depth 一个可读写的单值文件。默认值为“最大”。  
	Maximum allowed descent depth below the current cgroup.
	If the actual descent depth is equal or larger,
	an attempt to create a new child cgroup will fail. 当前 cgroup 下方允许的最大下降深度。如果实际下降深度等于或更大，则尝试创建新的子 cgroup 将失败。  
  cgroup.stat
	A read-only flat-keyed file with the following entries: cgroup.stat 具有以下条目的只读平键文件：  
	  nr\_descendants
		Total number of visible descendant cgroups.  
nr\_descendants 可见后代 cgroup 的总数。  
	  nr\_dying\_descendants
		Total number of dying descendant cgroups. A cgroup becomes
		dying after being deleted by a user. The cgroup will remain
		in dying state for some time undefined time (which can depend
		on system load) before being completely destroyed.  
nr\_dying\_descendants 垂死的后代 cgroup 总数。 cgroup 在被用户删除后就会死亡。在完全销毁之前，cgroup 将在一段不确定的时间内保持死亡状态（这可能取决于系统负载）。  
		A process can't enter a dying cgroup under any circumstances,
		a dying cgroup can't revive. 进程在任何情况下都无法进入垂死的 cgroup，垂死的 cgroup 无法复活。  
		A dying cgroup can consume system resources not exceeding
		limits, which were active at the moment of cgroup deletion. 垂死的 cgroup 可以消耗不超过限制的系统资源，这些资源在 cgroup 删除时处于活动状态。  
Controllers
===========  控制器===========  
CPU
--- 中央处理器  - -  
The "cpu" controllers regulates distribution of CPU cycles.  This
controller implements weight and absolute bandwidth limit models for
normal scheduling policy and absolute bandwidth allocation model for
realtime scheduling policy.  
“cpu”控制器调节 CPU 周期的分配。该控制器实现了正常调度策略的权重和绝对带宽限制模型以及实时调度策略的绝对带宽分配模型。  
WARNING: cgroup2 doesn't yet support control of realtime processes and
the cpu controller can only be enabled when all RT processes are in
the root cgroup.  Be aware that system management software may already
have placed RT processes into nonroot cgroups during the system boot
process, and these processes may need to be moved to the root cgroup
before the cpu controller can be enabled.  
警告：cgroup2 尚不支持实时进程的控制，并且只有当所有 RT 进程都位于根 cgroup 中时才能启用 cpu 控制器。请注意，系统管理软件可能已在系统引导过程中将 RT 进程放入非 root cgroup，并且可能需要将这些进程移至 root cgroup，然后才能启用 cpu 控制器。  
CPU Interface Files
~~~~~~~~~~~~~~~~~~~ CPU接口文件~~~~~~~~~~~~~~~~~~  
All time durations are in microseconds.  
所有持续时间均以微秒为单位。  
  cpu.stat
	A read-only flat-keyed file which exists on non-root cgroups.
	This file exists whether the controller is enabled or not. cpu.stat 存在于非根 cgroup 上的只读平键文件。无论控制器是否启用，该文件都存在。  
	It always reports the following three stats: 它始终报告以下三个统计数据：  
	- usage\_usec
	- user\_usec
	- system\_usec - 使用情况\_usec - 用户\_usec - 系统\_usec  
	and the following three when the controller is enabled: 当控制器启用时，以下三个：  
	- nr\_periods
	- nr\_throttled
	- throttled\_usec -nr\_periods -nr\_throttled -throttled\_usec  
  cpu.weight
	A read-write single value file which exists on non-root
	cgroups.  The default is "100". cpu.weight 存在于非根 cgroup 上的读写单值文件。默认值为“100”。  
	The weight in the range \[1, 10000\]. 范围 \[1, 10000\] 内的权重。  
  cpu.weight.nice
	A read-write single value file which exists on non-root
	cgroups.  The default is "0". cpu.weight.nice 存在于非根 cgroup 上的读写单值文件。默认值为“0”。  
	The nice value is in the range \[-20, 19\]. 好的值在 \[-20, 19\] 范围内。  
	This interface file is an alternative interface for
	"cpu.weight" and allows reading and setting weight using the
	same values used by nice(2).  Because the range is smaller and
	granularity is coarser for the nice values, the read value is
	the closest approximation of the current weight.  
该接口文件是“cpu.weight”的替代接口，允许使用与nice(2)相同的值读取和设置权重。由于良好值的范围较小且粒度较粗，因此读取的值是当前权重的最接近的近似值。  
  cpu.max
	A read-write two value file which exists on non-root cgroups.
	The default is "max 100000". cpu.max 存在于非根 cgroup 上的读写二值文件。默认值为“最大 100000”。  
	The maximum bandwidth limit.  It's in the following format:: 最大带宽限制。它的格式如下::  
	  $MAX $PERIOD  
	which indicates that the group may consume upto $MAX in each
	$PERIOD duration.  "max" for $MAX indicates no limit.  If only
	one number is written, $MAX is updated. 这表明该组在每个 $PERIOD 持续时间内最多可以消耗 $MAX。 $MAX 的“max”表示没有限制。如果只写入一个数字，则更新 $MAX。  
Memory
------  记忆  -  -  -   
The "memory" controller regulates distribution of memory.  Memory is
stateful and implements both limit and protection models.  Due to the
intertwining between memory usage and reclaim pressure and the
stateful nature of memory, the distribution model is relatively
complex.  
“内存”控制器调节内存的分配。内存是有状态的，并实现限制和保护模型。由于内存使用和回收压力之间的相互交织以及内存的有状态特性，分配模型相对复杂。  
While not completely water-tight, all major memory usages by a given
cgroup are tracked so that the total memory consumption can be
accounted and controlled to a reasonable extent.  Currently, the
following types of memory usages are tracked.  
虽然不是完全无懈可击，但会跟踪给定 cgroup 的所有主要内存使用情况，以便可以计算总内存消耗并将其控制在合理的范围内。目前，跟踪以下类型的内存使用情况。  
\- Userland memory - page cache and anonymous memory.  
\- 用户态内存 - 页面缓存和匿名内存。  
\- Kernel data structures such as dentries and inodes.  
\- 内核数据结构，例如 dentry 和 inode。  
\- TCP socket buffers. \- TCP 套接字缓冲区。  
The above list may expand in the future for better coverage.  
上述列表将来可能会扩大，以获得更好的覆盖范围。  
Memory Interface Files
~~~~~~~~~~~~~~~~~~~~~~ 内存接口文件~~~~~~~~~~~~~~~~~~~~~  
All memory amounts are in bytes.  If a value which is not aligned to
PAGE\_SIZE is written, the value may be rounded up to the closest
PAGE\_SIZE multiple when read back.  
所有内存量均以字节为单位。如果写入的值未与 PAGE\_SIZE 对齐，则读回时该值可能会向上舍入为最接近的 PAGE\_SIZE 倍数。  
  memory.current
	A read-only single value file which exists on non-root
	cgroups. memory.current 存在于非根 cgroup 上的只读单值文件。  
	The total amount of memory currently being used by the cgroup
	and its descendants. cgroup 及其后代当前使用的内存总量。  
  memory.low
	A read-write single value file which exists on non-root
	cgroups.  The default is "0".  
memory.low 存在于非根 cgroup 上的读写单值文件。默认值为“0”。  
	Best-effort memory protection.  If the memory usages of a
	cgroup and all its ancestors are below their low boundaries,
	the cgroup's memory won't be reclaimed unless memory can be
	reclaimed from unprotected cgroups. 尽最大努力的内存保护。如果某个 cgroup 及其所有祖先的内存使用量低于其下限，则该 cgroup 的内存将不会被回收，除非可以从未受保护的 cgroup 回收内存。  
	Putting more memory than generally available under this
	protection is discouraged. 不鼓励在此保护下放置比一般可用内存更多的内存。  
  memory.high
	A read-write single value file which exists on non-root
	cgroups.  The default is "max". memory.high 存在于非根 cgroup 上的读写单值文件。默认值为“最大”。  
	Memory usage throttle limit.  This is the main mechanism to
	control memory usage of a cgroup.  If a cgroup's usage goes
	over the high boundary, the processes of the cgroup are
	throttled and put under heavy reclaim pressure. 内存使用限制。这是控制 cgroup 内存使用的主要机制。如果 cgroup 的使用量超过上限，则该 cgroup 的进程将受到限制并承受沉重的回收压力。  
	Going over the high limit never invokes the OOM killer and
	under extreme conditions the limit may be breached. 超过上限永远不会调用 OOM 杀手，并且在极端条件下可能会突破该限制。  
  memory.max
	A read-write single value file which exists on non-root
	cgroups.  The default is "max". memory.max 存在于非根 cgroup 上的读写单值文件。默认值为“最大”。  
	Memory usage hard limit.  This is the final protection
	mechanism.  If a cgroup's memory usage reaches this limit and
	can't be reduced, the OOM killer is invoked in the cgroup.
	Under certain circumstances, the usage may go over the limit
	temporarily. 内存使用硬限制。这是最终的保护机制。如果某个 cgroup 的内存使用量达到此限制并且无法减少，则会在该 cgroup 中调用 OOM Killer。在某些情况下，使用量可能会暂时超出限制。  
	This is the ultimate protection mechanism.  As long as the
	high limit is used and monitored properly, this limit's
	utility is limited to providing the final safety net. 这是最终的保护机制。只要正确使用和监控上限，该限制的效用就仅限于提供最终的安全网。  
  memory.events
	A read-only flat-keyed file which exists on non-root cgroups.
	The following entries are defined.  Unless specified
	otherwise, a value change in this file generates a file
	modified event. memory.events 存在于非根 cgroup 上的只读平键文件。定义了以下条目。除非另有指定，否则此文件中的值更改会生成文件修改事件。  
	  low
		The number of times the cgroup is reclaimed due to
		high memory pressure even though its usage is under
		the low boundary.  This usually indicates that the low
		boundary is over-committed. low 由于高内存压力而回收 cgroup 的次数，即使其使用率低于低边界。这通常表明低边界被过度使用。  
	  high
		The number of times processes of the cgroup are
		throttled and routed to perform direct memory reclaim
		because the high memory boundary was exceeded.  For a
		cgroup whose memory usage is capped by the high limit
		rather than global memory pressure, this event's
		occurrences are expected.  
high 由于超出高内存边界而对 cgroup 的进程进行限制并路由以执行直接内存回收的次数。对于内存使用量受到上限而不是全局内存压力限制的 cgroup，此事件的发生是预料之中的。  
	  max
		The number of times the cgroup's memory usage was
		about to go over the max boundary.  If direct reclaim
		fails to bring it down, the cgroup goes to OOM state. max cgroup 的内存使用量即将超过最大边界的次数。如果直接回收无法将其关闭，则 cgroup 将进入 OOM 状态。  
	  oom
		The number of time the cgroup's memory usage was
		reached the limit and allocation was about to fail. oom cgroup 内存使用达到限制并且分配即将失败的次数。  
		Depending on context result could be invocation of OOM
		killer and retrying allocation or failing allocation. 根据上下文结果，可能会调用 OOM Killer 并重试分配或分配失败。  
		Failed allocation in its turn could be returned into
		userspace as -ENOMEM or silently ignored in cases like
		disk readahead.  For now OOM in memory cgroup kills
		tasks iff shortage has happened inside page fault. 失败的分配又可以作为 -ENOMEM 返回到用户空间，或者在磁盘预读等情况下默默地忽略。目前，内存中的 OOM 如果在页面错误内发生短缺，则 cgroup 会终止任务。  
	  oom\_kill
		The number of processes belonging to this cgroup
		killed by any kind of OOM killer. oom\_kill 被任何类型的 OOM 杀手杀死的属于此 cgroup 的进程数。  
  memory.stat
	A read-only flat-keyed file which exists on non-root cgroups. memory.stat 存在于非根 cgroup 上的只读平键文件。  
	This breaks down the cgroup's memory footprint into different
	types of memory, type-specific details, and other information
	on the state and past events of the memory management system. 这将 cgroup 的内存占用量分解为不同类型的内存、特定于类型的详细信息以及有关内存管理系统的状态和过去事件的其他信息。  
	All memory amounts are in bytes. 所有内存量均以字节为单位。  
	The entries are ordered to be human readable, and new entries
	can show up in the middle. Don't rely on items remaining in a
	fixed position; use the keys to look up specific values! 这些条目被排序为人类可读的，并且新条目可以显示在中间。不要依赖保持在固定位置的物品；使用按键查找特定值！  
	  anon
		Amount of memory used in anonymous mappings such as
		brk(), sbrk(), and mmap(MAP\_ANONYMOUS) anon 匿名映射（例如 brk()、sbrk() 和 mmap(MAP\_ANONYMOUS)）中使用的内存量  
	  file
		Amount of memory used to cache filesystem data,
		including tmpfs and shared memory. file 用于缓存文件系统数据的内存量，包括 tmpfs 和共享内存。  
	  kernel\_stack
		Amount of memory allocated to kernel stacks. kernel\_stack 分配给内核堆栈的内存量。  
	  slab
		Amount of memory used for storing in-kernel data
		structures. 用于存储内核数据结构的内存量。  
	  sock
		Amount of memory used in network transmission buffers  
sock 网络传输缓冲区使用的内存量  
	  shmem
		Amount of cached filesystem data that is swap-backed,
		such as tmpfs, shm segments, shared anonymous mmap()s shmem 交换支持的缓存文件系统数据量，例如 tmpfs、shm 段、共享匿名 mmap()  
	  file\_mapped
		Amount of cached filesystem data mapped with mmap() file\_mapped 使用 mmap() 映射的缓存文件系统数据量  
	  file\_dirty
		Amount of cached filesystem data that was modified but
		not yet written back to disk file\_dirty 已修改但尚未写回磁盘的缓存文件系统数据量  
	  file\_writeback
		Amount of cached filesystem data that was modified and
		is currently being written back to disk file\_writeback 已修改且当前正在写回磁盘的缓存文件系统数据量  
	  inactive\_anon, active\_anon, inactive\_file, active\_file, unevictable
		Amount of memory, swap-backed and filesystem-backed,
		on the internal memory management lists used by the
		page reclaim algorithm inactive\_anon、active\_anon、inactive\_file、active\_file、unevictable 页面回收算法使用的内部内存管理列表上的交换支持和文件系统支持的内存量  
	  slab\_reclaimable
		Part of "slab" that might be reclaimed, such as
		dentries and inodes. lab\_reclaimable 可能被回收的“slab”的一部分，例如 dentry 和 inode。  
	  slab\_unreclaimable
		Part of "slab" that cannot be reclaimed on memory
		pressure. lab\_unreclaimable 因内存压力而无法回收的“slab”部分。  
	  pgfault
		Total number of page faults incurred pgfault 发生的页面错误总数  
	  pgmajfault
		Number of major page faults incurred pgmajfault 发生的主要页面错误数  
	  workingset\_refault  工作集错误  
		Number of refaults of previously evicted pages 先前被驱逐页面的拒绝次数  
	  workingset\_activate  工作集\_激活  
		Number of refaulted pages that were immediately activated 立即激活的拒绝页面数  
	  workingset\_nodereclaim  工作集节点回收  
		Number of times a shadow node has been reclaimed 影子节点被回收的次数  
	  pgrefill  预填充  
		Amount of scanned pages (in an active LRU list) 扫描的页面数量（在活动 LRU 列表中）  
	  pgscan  扫描仪  
		Amount of scanned pages (in an inactive LRU list) 扫描的页面数量（在非活动 LRU 列表中）  
	  pgsteal  PG窃取  
		Amount of reclaimed pages 回收的页面数量  
	  pgactivate  激活  
		Amount of pages moved to the active LRU list 移动到活动 LRU 列表的页面数量  
	  pgdeactivate  PG停用  
		Amount of pages moved to the inactive LRU lis 移动到非活动 LRU 列表的页面数量  
	  pglazyfree  免维护  
		Amount of pages postponed to be freed under memory pressure 在内存压力下推迟释放的页面数量  
	  pglazyfreed  普格拉兹弗里德  
		Amount of reclaimed lazyfree pages 回收的lazyfree页面数量  
  memory.swap.current
	A read-only single value file which exists on non-root
	cgroups. memory.swap.current 存在于非根 cgroup 上的只读单值文件。  
	The total amount of swap currently being used by the cgroup
	and its descendants. cgroup 及其后代当前使用的交换总量。  
  memory.swap.max
	A read-write single value file which exists on non-root
	cgroups.  The default is "max". memory.swap.max 存在于非根 cgroup 上的读写单值文件。默认值为“最大”。  
	Swap usage hard limit.  If a cgroup's swap usage reaches this
	limit, anonymous memory of the cgroup will not be swapped out.  
交换使用硬限制。如果cgroup的交换使用量达到此限制，则该cgroup的匿名内存将不会被换出。  
Usage Guidelines
~~~~~~~~~~~~~~~~ 使用指南~~~~~~~~~~~~~~~  
"memory.high" is the main mechanism to control memory usage.
Over-committing on high limit (sum of high limits > available memory)
and letting global memory pressure to distribute memory according to
usage is a viable strategy.  
“memory.high”是控制内存使用的主要机制。过度承诺上限（上限总和>可用内存）并让全局内存压力根据使用情况分配内存是一个可行的策略。  
Because breach of the high limit doesn't trigger the OOM killer but
throttles the offending cgroup, a management agent has ample
opportunities to monitor and take appropriate actions such as granting
more memory or terminating the workload.  
由于违反上限不会触发 OOM 杀手，而是会限制违规 cgroup，因此管理代理有充足的机会来监视并采取适当的操作，例如授予更多内存或终止工作负载。  
Determining whether a cgroup has enough memory is not trivial as
memory usage doesn't indicate whether the workload can benefit from
more memory.  For example, a workload which writes data received from
network to a file can use all available memory but can also operate as
performant with a small amount of memory.  A measure of memory
pressure - how much the workload is being impacted due to lack of
memory - is necessary to determine whether a workload needs more
memory; unfortunately, memory pressure monitoring mechanism isn't
implemented yet.  
确定 cgroup 是否有足够的内存并非易事，因为内存使用情况并不表明工作负载是否可以从更多内存中受益。例如，将从网络接收的数据写入文件的工作负载可以使用所有可用内存，但也可以使用少量内存进行高性能操作。衡量内存压力（由于内存不足而影响工作负载的程度）对于确定工作负载是否需要更多内存是必要的；不幸的是，内存压力监控机制尚未实现。  
Memory Ownership
~~~~~~~~~~~~~~~~ 内存所有权~~~~~~~~~~~~~~~  
A memory area is charged to the cgroup which instantiated it and stays
charged to the cgroup until the area is released.  Migrating a process
to a different cgroup doesn't move the memory usages that it
instantiated while in the previous cgroup to the new cgroup.  
内存区域被实例化它的 cgroup 占用，并保持被 cgroup 占用，直到该区域被释放。将进程迁移到不同的 cgroup 不会将其在前一个 cgroup 中实例化的内存使用量移动到新的 cgroup。  
A memory area may be used by processes belonging to different cgroups.
To which cgroup the area will be charged is in-deterministic; however,
over time, the memory area is likely to end up in a cgroup which has
enough memory allowance to avoid high reclaim pressure.  
内存区域可以由属于不同 cgroup 的进程使用。该区域将被计入哪个 cgroup 是不确定的；然而，随着时间的推移，内存区域很可能最终出现在一个有足够内存空间以避免高回收压力的 cgroup 中。  
If a cgroup sweeps a considerable amount of memory which is expected
to be accessed repeatedly by other cgroups, it may make sense to use
POSIX\_FADV\_DONTNEED to relinquish the ownership of memory areas
belonging to the affected files to ensure correct memory ownership.  
如果一个 cgroup 扫描了大量内存，并且预计会被其他 cgroup 重复访问，则使用 POSIX\_FADV\_DONTNEED 放弃属于受影响文件的内存区域的所有权以确保正确的内存所有权可能是有意义的。  
IO
--  IO——  
The "io" controller regulates the distribution of IO resources.  This
controller implements both weight based and absolute bandwidth or IOPS
limit distribution; however, weight based distribution is available
only if cfq-iosched is in use and neither scheme is available for
blk-mq devices.  
“io”控制器调节IO资源的分配。该控制器实现基于权重和绝对带宽或IOPS限制分配；但是，仅当使用 cfq-iosched 时，基于权重的分配才可用，并且这两种方案均不适用于 blk-mq 设备。  
IO Interface Files
~~~~~~~~~~~~~~~~~~ IO接口文件~~~~~~~~~~~~~~~~~~  
  io.stat
	A read-only nested-keyed file which exists on non-root
	cgroups. io.stat 存在于非根 cgroup 上的只读嵌套键控文件。  
	Lines are keyed by $MAJ:$MIN device numbers and not ordered.
	The following nested keys are defined. 线路由 $MAJ:$MIN 设备编号键入，并且不排序。定义了以下嵌套键。  
	  ======	===================
	  rbytes	Bytes read
	  wbytes	Bytes written
	  rios		Number of read IOs
	  wios		Number of write IOs
	  ======	=================== ====== =================== rbytes 读取的字节数 wbytes 写入的字节数 rios 读取 IO 数量 wios 写入 IO 数量 ====== === ===============  
	An example read output follows: 读取输出示例如下：  
	  8:16 rbytes=1459200 wbytes=314773504 rios=192 wios=353
	  8:0 rbytes=90430464 wbytes=299008000 rios=8950 wios=1252  
  io.weight
	A read-write flat-keyed file which exists on non-root cgroups.
	The default is "default 100".  
io.weight 存在于非根 cgroup 上的读写平键文件。默认值为“默认 100”。  
	The first line is the default weight applied to devices
	without specific override.  The rest are overrides keyed by
	$MAJ:$MIN device numbers and not ordered.  The weights are in
	the range \[1, 10000\] and specifies the relative amount IO time
	the cgroup can use in relation to its siblings. 第一行是应用于没有特定覆盖的设备的默认权重。其余的都是由 $MAJ:$MIN 设备编号键入的覆盖，并且未排序。权重范围为 \[1, 10000\]，指定 cgroup 与其同级组相比可以使用的相对 IO 时间量。  
	The default weight can be updated by writing either "default
	$WEIGHT" or simply "$WEIGHT".  Overrides can be set by writing
	"$MAJ:$MIN $WEIGHT" and unset by writing "$MAJ:$MIN default". 可以通过写入“default $WEIGHT”或简单地“$WEIGHT”来更新默认重量。可以通过写入“$MAJ:$MIN $WEIGHT”来设置覆盖，并通过写入“$MAJ:$MIN default”来取消设置。  
	An example read output follows:: 读取输出示例如下：  
	  default 100
	  8:16 200
	  8:0 50 默认 100 8:16 200 8:0 50  
  io.max
	A read-write nested-keyed file which exists on non-root
	cgroups. io.max 存在于非根 cgroup 上的读写嵌套键控文件。  
	BPS and IOPS based IO limit.  Lines are keyed by $MAJ:$MIN
	device numbers and not ordered.  The following nested keys are
	defined. 基于 BPS 和 IOPS 的 IO 限制。线路由 $MAJ:$MIN 设备编号键入，并且不排序。定义了以下嵌套键。  
	  =====		==================================
	  rbps		Max read bytes per second
	  wbps		Max write bytes per second
	  riops		Max read IO operations per second
	  wiops		Max write IO operations per second
	  =====		================================== ===== ==================================== rbps 每秒最大读取字节数 wbps 每秒最大写入字节数Second riops 每秒最大读取 IO 操作数 wiops 每秒最大写入 IO 操作数 ===== ================================ ====  
	When writing, any number of nested key-value pairs can be
	specified in any order.  "max" can be specified as the value
	to remove a specific limit.  If the same key is specified
	multiple times, the outcome is undefined. 写入时，可以按任意顺序指定任意数量的嵌套键值对。可以将“max”指定为删除特定限制的值。如果多次指定相同的键，则结果不确定。  
	BPS and IOPS are measured in each IO direction and IOs are
	delayed if limit is reached.  Temporary bursts are allowed. BPS 和 IOPS 在每个 IO 方向上进行测量，如果达到限制，IO 就会延迟。允许临时突发。  
	Setting read limit at 2M BPS and write at 120 IOPS for 8:16:: 将读取限制设置为 2M BPS，写入限制为 120 IOPS，持续 8:16::  
	  echo "8:16 rbps=2097152 wiops=120" > io.max 回声“8：16 rbps = 2097152 wiops = 120”> io.max  
	Reading returns the following:: 读取返回以下内容：：  
	  8:16 rbps=2097152 wbps=max riops=max wiops=120 8:16 rbps=2097152 wbps=最大 riops=最大 wiops=120  
	Write IOPS limit can be removed by writing the following:: 写入 IOPS 限制可以通过写入以下内容来删除：  
	  echo "8:16 wiops=max" > io.max  
	Reading now returns the following:: 现在读取返回以下内容：：  
	  8:16 rbps=2097152 wbps=max riops=max wiops=max 8:16 rbps=2097152 wbps=最大 riops=最大 wiops=最大  
Writeback
~~~~~~~~~  回帖~~~~~~~~~  
Page cache is dirtied through buffered writes and shared mmaps and
written asynchronously to the backing filesystem by the writeback
mechanism.  Writeback sits between the memory and IO domains and
regulates the proportion of dirty memory by balancing dirtying and
write IOs.  
页面缓存通过缓冲写入和共享 mmap 被弄脏，并通过写回机制异步写入到支持文件系统。 Writeback位于内存和IO域之间，通过平衡脏数据和写IO来调节脏内存的比例。  
The io controller, in conjunction with the memory controller,
implements control of page cache writeback IOs.  The memory controller
defines the memory domain that dirty memory ratio is calculated and
maintained for and the io controller defines the io domain which
writes out dirty pages for the memory domain.  Both system-wide and
per-cgroup dirty memory states are examined and the more restrictive
of the two is enforced.  
io控制器与内存控制器配合，实现对页缓存写回IO的控制。内存控制器定义计算和维护脏内存比率的内存域，io控制器定义为内存域写出脏页的io域。系统范围和每个 cgroup 的脏内存状态都会被检查，并强制执行两者中更严格的状态。  
cgroup writeback requires explicit support from the underlying
filesystem.  Currently, cgroup writeback is implemented on ext2, ext4
and btrfs.  On other filesystems, all writeback IOs are attributed to
the root cgroup.  
cgroup 写回需要底层文件系统的显式支持。目前，cgroup writeback 在 ext2、ext4 和 btrfs 上实现。在其他文件系统上，所有写回 IO 都归属于根 cgroup。  
There are inherent differences in memory and writeback management
which affects how cgroup ownership is tracked.  Memory is tracked per
page while writeback per inode.  For the purpose of writeback, an
inode is assigned to a cgroup and all IO requests to write dirty pages
from the inode are attributed to that cgroup.  
内存和写回管理存在固有的差异，这会影响 cgroup 所有权的跟踪方式。内存按页进行跟踪，而写回按索引节点进行。出于写回的目的，一个 inode 被分配给一个 cgroup，所有从该 inode 写入脏页的 IO 请求都归属于该 cgroup。  
As cgroup ownership for memory is tracked per page, there can be pages
which are associated with different cgroups than the one the inode is
associated with.  These are called foreign pages.  The writeback
constantly keeps track of foreign pages and, if a particular foreign
cgroup becomes the majority over a certain period of time, switches
the ownership of the inode to that cgroup.  
由于内存的 cgroup 所有权是按页跟踪的，因此可能存在与与 inode 关联的 cgroup 不同的 cgroup 关联的页面。这些被称为外国页面。写回会不断跟踪外部页面，如果特定的外部 cgroup 在一段时间内成为多数，则将 inode 的所有权切换到该 cgroup。  
While this model is enough for most use cases where a given inode is
mostly dirtied by a single cgroup even when the main writing cgroup
changes over time, use cases where multiple cgroups write to a single
inode simultaneously are not supported well.  In such circumstances, a
significant portion of IOs are likely to be attributed incorrectly.
As memory controller assigns page ownership on the first use and
doesn't update it until the page is released, even if writeback
strictly follows page ownership, multiple cgroups dirtying overlapping
areas wouldn't work as expected.  It's recommended to avoid such usage
patterns.  
虽然此模型足以满足大多数用例，其中给定 inode 大部分被单个 cgroup 弄脏，即使主要写入 cgroup 随着时间的推移而变化，但不能很好地支持多个 cgroup 同时写入单个 inode 的用例。在这种情况下，很大一部分 IO 可能会被错误归因。由于内存控制器在第一次使用时分配页面所有权，并且在释放页面之前不会更新它，即使回写严格遵循页面所有权，多个 cgroup 弄脏重叠区域也无法按预期工作。建议避免此类使用模式。  
The sysctl knobs which affect writeback behavior are applied to cgroup
writeback as follows.  
影响写回行为的 sysctl 旋钮应用于 cgroup 写回，如下所示。  
  vm.dirty\_background\_ratio, vm.dirty\_ratio
	These ratios apply the same to cgroup writeback with the
	amount of available memory capped by limits imposed by the
	memory controller and system-wide clean memory. vm.dirty\_background\_ratio, vm.dirty\_ratio 这些比率同样适用于 cgroup 写回，可用内存量受内存控制器和系统范围的干净内存施加的限制。  
  vm.dirty\_background\_bytes, vm.dirty\_bytes
	For cgroup writeback, this is calculated into ratio against
	total available memory and applied the same way as
	vm.dirty\[\_background\]\_ratio. vm.dirty\_background\_bytes, vm.dirty\_bytes 对于 cgroup 写回，这被计算为与总可用内存的比率，并以与 vm.dirty\[\_background\]\_ratio 相同的方式应用。  
PID
---  PID---  
The process number controller is used to allow a cgroup to stop any
new tasks from being fork()'d or clone()'d after a specified limit is
reached.  
进程号控制器用于允许 cgroup 在达到指定限制后停止任何新任务的 fork() 或 clone() 操作。  
The number of tasks in a cgroup can be exhausted in ways which other
controllers cannot prevent, thus warranting its own controller.  For
example, a fork bomb is likely to exhaust the number of tasks before
hitting memory restrictions.  
cgroup 中的任务数量可能会以其他控制器无法阻止的方式耗尽，因此需要有自己的控制器。例如，分叉炸弹可能会在达到内存限制之前耗尽任务数量。  
Note that PIDs used in this controller refer to TIDs, process IDs as
used by the kernel.  
请注意，此控制器中使用的 PID 指的是内核使用的 TID、进程 ID。  
PID Interface Files
~~~~~~~~~~~~~~~~~~~ PID接口文件~~~~~~~~~~~~~~~~~~  
  pids.max
	A read-write single value file which exists on non-root
	cgroups.  The default is "max". pids.max 存在于非根 cgroup 上的读写单值文件。默认值为“最大”。  
	Hard limit of number of processes. 进程数量的硬限制。  
  pids.current
	A read-only single value file which exists on all cgroups.  
pids.current 存在于所有 cgroup 上的只读单值文件。  
	The number of processes currently in the cgroup and its
	descendants. cgroup 及其后代中当前进程的数量。  
Organisational operations are not blocked by cgroup policies, so it is
possible to have pids.current > pids.max.  This can be done by either
setting the limit to be smaller than pids.current, or attaching enough
processes to the cgroup such that pids.current is larger than
pids.max.  However, it is not possible to violate a cgroup PID policy
through fork() or clone(). These will return -EAGAIN if the creation
of a new process would cause a cgroup policy to be violated.  
组织操作不会被 cgroup 策略阻止，因此 pids.current > pids.max 是可能的。这可以通过将限制设置为小于 pids.current 或将足够的进程附加到 cgroup 以使 pids.current 大于 pids.max 来完成。但是，不可能通过 fork() 或 clone() 违反 cgroup PID 策略。如果创建新进程会导致违反 cgroup 策略，这些将返回 -EAGAIN。  
Device controller
----------------- 设备控制器-----------------  
Device controller manages access to device files. It includes both
creation of new device files (using mknod), and access to the
existing device files.  
设备控制器管理对设备文件的访问。它包括创建新设备文件（使用 mknod）以及访问现有设备文件。  
Cgroup v2 device controller has no interface files and is implemented
on top of cgroup BPF. To control access to device files, a user may
create bpf programs of the BPF\_CGROUP\_DEVICE type and attach them
to cgroups. On an attempt to access a device file, corresponding
BPF programs will be executed, and depending on the return value
the attempt will succeed or fail with -EPERM.  
Cgroup v2 设备控制器没有接口文件，并且在 cgroup BPF 之上实现。为了控制对设备文件的访问，用户可以创建 BPF\_CGROUP\_DEVICE 类型的 bpf 程序并将它们附加到 cgroup。尝试访问设备文件时，将执行相应的 BPF 程序，并且根据返回值，尝试将成功或失败，并显示 -EPERM。  
A BPF\_CGROUP\_DEVICE program takes a pointer to the bpf\_cgroup\_dev\_ctx
structure, which describes the device access attempt: access type
(mknod/read/write) and device (type, major and minor numbers).
If the program returns 0, the attempt fails with -EPERM, otherwise
it succeeds.  
BPF\_CGROUP\_DEVICE 程序采用指向 bpf\_cgroup\_dev\_ctx 结构的指针，该结构描述了设备访问尝试：访问类型（mknod/读/写）和设备（类型、主设备号和次设备号）。如果程序返回 0，则尝试失败并返回 -EPERM，否则成功。  
An example of BPF\_CGROUP\_DEVICE program may be found in the kernel
source tree in the tools/testing/selftests/bpf/dev\_cgroup.c file.  
BPF\_CGROUP\_DEVICE 程序的示例可以在 tools/testing/selftests/bpf/dev\_cgroup.c 文件的内核源代码树中找到。  
RDMA
----  RDMA----  
The "rdma" controller regulates the distribution and accounting of
of RDMA resources.  
“rdma”控制器调节RDMA资源的分配和记账。  
RDMA Interface Files
~~~~~~~~~~~~~~~~~~~~  
RDMA 接口文件 ~~~~~~~~~~~~~~~~~~~~~  
  rdma.max
	A readwrite nested-keyed file that exists for all the cgroups
	except root that describes current configured resource limit
	for a RDMA/IB device.  
rdma.max 一个读写嵌套键控文件，存在于除 root 之外的所有 cgroup 中，用于描述 RDMA/IB 设备当前配置的资源限制。  
	Lines are keyed by device name and are not ordered.
	Each line contains space separated resource name and its configured
	limit that can be distributed. 线路按设备名称键入，并且不排序。每行包含空格分隔的资源名称及其可分发的配置限制。  
	The following nested keys are defined. 定义了以下嵌套键。  
	  ==========	=============================
	  hca\_handle	Maximum number of HCA Handles
	  hca\_object 	Maximum number of HCA Objects
	  ==========	============================= ========== =============================== hca\_handle HCA 句柄最大数量 hca\_object HCA 最大数量对象 ========= ===============================  
	An example for mlx4 and ocrdma device follows:: mlx4 和 ocrdma 设备的示例如下：  
	  mlx4\_0 hca\_handle=2 hca\_object=2000
	  ocrdma1 hca\_handle=3 hca\_object=max  
  rdma.current
	A read-only file that describes current resource usage.
	It exists for all the cgroup except root. rdma.current 描述当前资源使用情况的只读文件。除 root 之外的所有 cgroup 都存在它。  
	An example for mlx4 and ocrdma device follows:: mlx4 和 ocrdma 设备的示例如下：  
	  mlx4\_0 hca\_handle=1 hca\_object=20
	  ocrdma1 hca\_handle=1 hca\_object=23  
Misc
---- 杂项 ----  
perf\_event
~~~~~~~~~~ 性能事件 ~~~~~~~~~~  
perf\_event controller, if not mounted on a legacy hierarchy, is
automatically enabled on the v2 hierarchy so that perf events can
always be filtered by cgroup v2 path.  The controller can still be
moved to a legacy hierarchy after v2 hierarchy is populated.  
perf\_event 控制器如果未安装在旧层次结构上，则会在 v2 层次结构上自动启用，以便始终可以通过 cgroup v2 路径过滤 perf 事件。填充 v2 层次结构后，控制器仍然可以移动到旧层次结构。  
Non-normative information
------------------------- 非规范信息------------------------  
This section contains information that isn't considered to be a part of
the stable kernel API and so is subject to change.  
本节包含不被视为稳定内核 API 一部分的信息，因此可能会发生更改。  
CPU controller root cgroup process behaviour
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
CPU控制器根cgroup进程行为~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ～  
When distributing CPU cycles in the root cgroup each thread in this
cgroup is treated as if it was hosted in a separate child cgroup of the
root cgroup. This child cgroup weight is dependent on its thread nice
level.  
在根 cgroup 中分配 CPU 周期时，该 cgroup 中的每个线程都被视为托管在根 cgroup 的单独子 cgroup 中。该子 cgroup 的权重取决于其线程的良好级别。  
For details of this mapping see sched\_prio\_to\_weight array in
kernel/sched/core.c file (values from this array should be scaled
appropriately so the neutral - nice 0 - value is 100 instead of 1024).  
有关此映射的详细信息，请参阅 kernel/sched/core.c 文件中的 sched\_prio\_to\_weight 数组（该数组中的值应适当缩放，以便中性 - 好的 0 - 值为 100 而不是 1024）。  
IO controller root cgroup process behaviour
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ IO 控制器 root cgroup 进程行为 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
Root cgroup processes are hosted in an implicit leaf child node.
When distributing IO resources this implicit child node is taken into
account as if it was a normal child cgroup of the root cgroup with a
weight value of 200.  
根 cgroup 进程托管在隐式叶子节点中。分配 IO 资源时，会考虑此隐式子节点，就好像它是权重值为 200 的根 cgroup 的普通子 cgroup 一样。  
Namespace
=========  命名空间=========  
Basics
------ 基本  -  -  -   
cgroup namespace provides a mechanism to virtualize the view of the
"/proc/$PID/cgroup" file and cgroup mounts.  The CLONE\_NEWCGROUP clone
flag can be used with clone(2) and unshare(2) to create a new cgroup
namespace.  The process running inside the cgroup namespace will have
its "/proc/$PID/cgroup" output restricted to cgroupns root.  The
cgroupns root is the cgroup of the process at the time of creation of
the cgroup namespace.  
cgroup 命名空间提供了一种虚拟化“/proc/$PID/cgroup”文件和 cgroup 挂载视图的机制。 CLONE\_NEWCGROUP 克隆标志可以与clone(2) 和unshare(2) 一起使用来创建新的cgroup 命名空间。在 cgroup 命名空间内运行的进程将其“/proc/$PID/cgroup”输出限制为 cgroupns 根目录。 cgroupns 根是创建 cgroup 命名空间时进程的 cgroup。  
Without cgroup namespace, the "/proc/$PID/cgroup" file shows the
complete path of the cgroup of a process.  In a container setup where
a set of cgroups and namespaces are intended to isolate processes the
"/proc/$PID/cgroup" file may leak potential system level information
to the isolated processes.  For Example::  
如果没有cgroup命名空间，“/proc/$PID/cgroup”文件显示进程cgroup的完整路径。在一组 cgroup 和命名空间旨在隔离进程的容器设置中，“/proc/$PID/cgroup”文件可能会将潜在的系统级信息泄漏给隔离的进程。例如：：  
  # cat /proc/self/cgroup
  0::/batchjobs/container\_id1  
The path '/batchjobs/container\_id1' can be considered as system-data
and undesirable to expose to the isolated processes.  cgroup namespace
can be used to restrict visibility of this path.  For example, before
creating a cgroup namespace, one would see::  
路径“/batchjobs/container\_id1”可以被视为系统数据，并且不希望暴露给隔离的进程。 cgroup 命名空间可用于限制此路径的可见性。例如，在创建 cgroup 命名空间之前，我们会看到：  
  # ls -l /proc/self/ns/cgroup
  lrwxrwxrwx 1 root root 0 2014-07-15 10:37 /proc/self/ns/cgroup -> cgroup:\[4026531835\]
  # cat /proc/self/cgroup
  0::/batchjobs/container\_id1 # ls -l /proc/self/ns/cgroup lrwxrwxrwx 1 root root 0 2014-07-15 10:37 /proc/self/ns/cgroup -> cgroup:\[4026531835\] # cat /proc/self/cgroup 0: ：/批处理/container\_id1  
After unsharing a new namespace, the view changes::  
取消共享新命名空间后，视图会发生变化：  
  # ls -l /proc/self/ns/cgroup
  lrwxrwxrwx 1 root root 0 2014-07-15 10:35 /proc/self/ns/cgroup -> cgroup:\[4026532183\]
  # cat /proc/self/cgroup
  0::/  
\# ls -l /proc/self/ns/cgroup lrwxrwxrwx 1 root root 0 2014-07-15 10:35 /proc/self/ns/cgroup -> cgroup:\[4026532183\] # cat /proc/self/cgroup 0: :/  
When some thread from a multi-threaded process unshares its cgroup
namespace, the new cgroupns gets applied to the entire process (all
the threads).  This is natural for the v2 hierarchy; however, for the
legacy hierarchies, this may be unexpected.  
当多线程进程中的某个线程取消共享其 cgroup 命名空间时，新的 cgroupns 将应用于整个进程（所有线程）。这对于 v2 层次结构来说是很自然的；然而，对于遗留层次结构来说，这可能是意想不到的。  
A cgroup namespace is alive as long as there are processes inside or
mounts pinning it.  When the last usage goes away, the cgroup
namespace is destroyed.  The cgroupns root and the actual cgroups
remain.  
只要内部有进程或挂载固定它，cgroup 命名空间就处于活动状态。当最后一次使用消失时，cgroup 命名空间将被销毁。 cgroupns 根和实际的 cgroup 仍然存在。  
The Root and Views
------------------ 根与见 ------------------  
The 'cgroupns root' for a cgroup namespace is the cgroup in which the
process calling unshare(2) is running.  For example, if a process in
/batchjobs/container\_id1 cgroup calls unshare, cgroup
/batchjobs/container\_id1 becomes the cgroupns root.  For the
init\_cgroup\_ns, this is the real root ('/') cgroup.  
cgroup 命名空间的“cgroupns root”是调用 unshare(2) 的进程正在其中运行的 cgroup。例如，如果 /batchjobs/container\_id1 cgroup 中的进程调用 unshare，则 cgroup /batchjobs/container\_id1 将成为 cgroupns 根。对于 init\_cgroup\_ns，这是真正的根（'/'）cgroup。  
The cgroupns root cgroup does not change even if the namespace creator
process later moves to a different cgroup::  
即使名称空间创建者进程稍后移动到不同的 cgroup，cgroupns 根 cgroup 也不会更改：  
  # ~/unshare -c # unshare cgroupns in some cgroup
  # cat /proc/self/cgroup
  0::/
  # mkdir sub\_cgrp\_1
  # echo 0 > sub\_cgrp\_1/cgroup.procs
  # cat /proc/self/cgroup
  0::/sub\_cgrp\_1 # ~/unshare -c # 取消共享某些 cgroup 中的 cgroupns # cat /proc/self/cgroup 0::/ # mkdir sub\_cgrp\_1 # echo 0 > sub\_cgrp\_1/cgroup.procs # cat /proc/self/cgroup 0::/sub\_cgrp\_1  
Each process gets its namespace-specific view of "/proc/$PID/cgroup"  
每个进程都会获取其名称空间特定的“/proc/$PID/cgroup”视图  
Processes running inside the cgroup namespace will be able to see
cgroup paths (in /proc/self/cgroup) only inside their root cgroup.
From within an unshared cgroupns::  
在 cgroup 命名空间内运行的进程将只能在其根 cgroup 内看到 cgroup 路径（在 /proc/self/cgroup 中）。来自非共享 cgroupns::  
  # sleep 100000 &
  \[1\] 7353
  # echo 7353 > sub\_cgrp\_1/cgroup.procs
  # cat /proc/7353/cgroup
  0::/sub\_cgrp\_1 # 睡眠 100000 & \[1\] 7353 # echo 7353 > sub\_cgrp\_1/cgroup.procs # cat /proc/7353/cgroup 0::/sub\_cgrp\_1  
From the initial cgroup namespace, the real cgroup path will be
visible::  
从初始的 cgroup 命名空间中，真正的 cgroup 路径将是可见的::  
  $ cat /proc/7353/cgroup
  0::/batchjobs/container\_id1/sub\_cgrp\_1  
From a sibling cgroup namespace (that is, a namespace rooted at a
different cgroup), the cgroup path relative to its own cgroup
namespace root will be shown.  For instance, if PID 7353's cgroup
namespace root is at '/batchjobs/container\_id2', then it will see::  
从同级 cgroup 命名空间（即以不同 cgroup 为根的命名空间），将显示相对于其自己的 cgroup 命名空间根的 cgroup 路径。例如，如果 PID 7353 的 cgroup 命名空间根位于“/batchjobs/container\_id2”，那么它将看到：  
  # cat /proc/7353/cgroup
  0::/../container\_id2/sub\_cgrp\_1  
\# 猫 /proc/7353/cgroup 0::/../container\_id2/sub\_cgrp\_1  
Note that the relative path always starts with '/' to indicate that
its relative to the cgroup namespace root of the caller.  
请注意，相对路径始终以“/”开头，表示它相对于调用者的 cgroup 命名空间根。  
Migration and setns(2)
---------------------- 迁移和setns(2) ----------------------  
Processes inside a cgroup namespace can move into and out of the
namespace root if they have proper access to external cgroups.  For
example, from inside a namespace with cgroupns root at
/batchjobs/container\_id1, and assuming that the global hierarchy is
still accessible inside cgroupns::  
如果 cgroup 命名空间内的进程具有对外部 cgroup 的适当访问权限，则它们可以移入和移出命名空间根。例如，从 cgroupns 根位于 /batchjobs/container\_id1 的命名空间内部，并假设全局层次结构仍然可以在 cgroupns 内访问：  
  # cat /proc/7353/cgroup
  0::/sub\_cgrp\_1
  # echo 7353 > batchjobs/container\_id2/cgroup.procs
  # cat /proc/7353/cgroup
  0::/../container\_id2  
Note that this kind of setup is not encouraged.  A task inside cgroup
namespace should only be exposed to its own cgroupns hierarchy.  
请注意，不鼓励这种设置。 cgroup 命名空间内的任务只能暴露给它自己的 cgroupns 层次结构。  
setns(2) to another cgroup namespace is allowed when:  
在以下情况下允许 setns(2) 到另一个 cgroup 命名空间：  
(a) the process has CAP\_SYS\_ADMIN against its current user namespace
(b) the process has CAP\_SYS\_ADMIN against the target cgroup
    namespace's userns  
(a) 进程针对其当前用户命名空间拥有 CAP\_SYS\_ADMIN (b) 进程针对目标 cgroup 命名空间的用户拥有 CAP\_SYS\_ADMIN  
No implicit cgroup changes happen with attaching to another cgroup
namespace.  It is expected that the someone moves the attaching
process under the target cgroup namespace root.  
连接到另一个 cgroup 命名空间时不会发生隐式 cgroup 更改。预计某人会将附加进程移动到目标 cgroup 命名空间根下。  
Interaction with Other Namespaces
--------------------------------- 与其他命名空间的交互--------------------------------  
Namespace specific cgroup hierarchy can be mounted by a process
running inside a non-init cgroup namespace::  
命名空间特定的 cgroup 层次结构可以由在非 init cgroup 命名空间内运行的进程挂载：  
  # mount -t cgroup2 none $MOUNT\_POINT # mount -t cgroup2 无 $MOUNT\_POINT  
This will mount the unified cgroup hierarchy with cgroupns root as the
filesystem root.  The process needs CAP\_SYS\_ADMIN against its user and
mount namespaces.  
这将挂载统一的 cgroup 层次结构，并将 cgroupns 根作为文件系统根。该进程需要针对其用户和安装命名空间的 CAP\_SYS\_ADMIN。  
The virtualization of /proc/self/cgroup file combined with restricting
the view of cgroup hierarchy by namespace-private cgroupfs mount
provides a properly isolated cgroup view inside the container.  
/proc/self/cgroup 文件的虚拟化与通过命名空间私有 cgroupfs 挂载限制 cgroup 层次结构视图相结合，在容器内提供了正确隔离的 cgroup 视图。  
Information on Kernel Programming
================================= 内核编程信息 ===================================  
This section contains kernel programming information in the areas
where interacting with cgroup is necessary.  cgroup core and
controllers are not covered.  
本节包含需要与 cgroup 交互的区域的内核编程信息。 cgroup 核心和控制器不包括在内。  
Filesystem Support for Writeback
-------------------------------- 文件系统对写回的支持--------------------------------  
A filesystem can support cgroup writeback by updating
address\_space\_operations->writepage\[s\]() to annotate bio's using the
following two functions.  
文件系统可以通过更新address\_space\_operations->writepage\[s\]()来支持cgroup写回，以使用以下两个函数注释bio。  
  wbc\_init\_bio(@wbc, @bio)
	Should be called for each bio carrying writeback data and
	associates the bio with the inode's owner cgroup.  Can be
	called anytime between bio allocation and submission. wbc\_init\_bio(@wbc, @bio) 应该为每个携带写回数据的bio调用，并将bio与inode的所有者cgroup相关联。可以在生物分配和提交之间随时调用。  
  wbc\_account\_io(@wbc, @page, @bytes)
	Should be called for each data segment being written out.
	While this function doesn't care exactly when it's called
	during the writeback session, it's the easiest and most
	natural to call it as data segments are added to a bio.  
wbc\_account\_io(@wbc, @page, @bytes) 应该为每个被写出的数据段调用。虽然此函数并不关心在写回会话期间何时调用它，但在将数据段添加到 Bio 时调用它是最简单、最自然的。  
With writeback bio's annotated, cgroup support can be enabled per
super\_block by setting SB\_I\_CGROUPWB in ->s\_iflags.  This allows for
selective disabling of cgroup writeback support which is helpful when
certain filesystem features, e.g. journaled data mode, are
incompatible.  
通过写回 Bio 的注释，可以通过在 ->s\_iflags 中设置 SB\_I\_CGROUPWB 来启用每个 super\_block 的 cgroup 支持。这允许有选择地禁用 cgroup 写回支持，这在某些文件系统功能（例如日志数据模式，不兼容。  
wbc\_init\_bio() binds the specified bio to its cgroup.  Depending on
the configuration, the bio may be executed at a lower priority and if
the writeback session is holding shared resources, e.g. a journal
entry, may lead to priority inversion.  There is no one easy solution
for the problem.  Filesystems can try to work around specific problem
cases by skipping wbc\_init\_bio() or using bio\_associate\_blkcg()
directly.  
wbc\_init\_bio() 将指定的bio绑定到它的cgroup。根据配置，如果写回会话持有共享资源，例如，bio 可能会以较低优先级执行。日记条目可能会导致优先级倒置。对于这个问题，没有一种简单的解决方案。文件系统可以尝试通过跳过 wbc\_init\_bio() 或直接使用 bio\_associate\_blkcg() 来解决特定问题。  
Deprecated v1 Core Features
=========================== 已弃用的 v1 核心功能 =============================  
\- Multiple hierarchies including named ones are not supported.  
\- 不支持多个层次结构，包括命名层次结构。  
\- All v1 mount options are not supported.  
\- 不支持所有 v1 安装选项。  
\- The "tasks" file is removed and "cgroup.procs" is not sorted.  
\- “tasks”文件被删除，“cgroup.procs”未排序。  
\- "cgroup.clone\_children" is removed.  
\- “cgroup.clone\_children”被删除。  
\- /proc/cgroups is meaningless for v2.  Use "cgroup.controllers" file
  at the root instead.  
\- /proc/cgroups 对于 v2 没有意义。请改用根目录下的“cgroup.controllers”文件。  
Issues with v1 and Rationales for v2
==================================== v1 的问题和 v2 的原理========================================  
Multiple Hierarchies
--------------------  
多重层次结构--------------------  
cgroup v1 allowed an arbitrary number of hierarchies and each
hierarchy could host any number of controllers.  While this seemed to
provide a high level of flexibility, it wasn't useful in practice.  
cgroup v1 允许任意数量的层次结构，每个层次结构可以托管任意数量的控制器。虽然这似乎提供了高度的灵活性，但在实践中并没有什么用处。  
For example, as there is only one instance of each controller, utility
type controllers such as freezer which can be useful in all
hierarchies could only be used in one.  The issue is exacerbated by
the fact that controllers couldn't be moved to another hierarchy once
hierarchies were populated.  Another issue was that all controllers
bound to a hierarchy were forced to have exactly the same view of the
hierarchy.  It wasn't possible to vary the granularity depending on
the specific controller.  
例如，由于每个控制器只有一个实例，因此可在所有层次结构中使用的诸如冰箱之类的实用型控制器只能在一个层次结构中使用。一旦填充了层次结构，控制器就无法移动到另一个层次结构，这一事实加剧了这个问题。另一个问题是绑定到层次结构的所有控制器都被迫具有完全相同的层次结构视图。无法根据特定控制器来改变粒度。  
In practice, these issues heavily limited which controllers could be
put on the same hierarchy and most configurations resorted to putting
each controller on its own hierarchy.  Only closely related ones, such
as the cpu and cpuacct controllers, made sense to be put on the same
hierarchy.  This often meant that userland ended up managing multiple
similar hierarchies repeating the same steps on each hierarchy
whenever a hierarchy management operation was necessary.  
实际上，这些问题严重限制了哪些控制器可以放置在同一层次结构中，并且大多数配置都诉诸于将每个控制器放置在其自己的层次结构中。只有紧密相关的控制器（例如 cpu 和 cpuacct 控制器）才有意义放在同一层次结构中。这通常意味着用户空间最终会管理多个相似的层次结构，每当需要层次结构管理操作时，就会在每个层次结构上重复相同的步骤。  
Furthermore, support for multiple hierarchies came at a steep cost.
It greatly complicated cgroup core implementation but more importantly
the support for multiple hierarchies restricted how cgroup could be
used in general and what controllers was able to do.  
此外，对多个层次结构的支持需要付出高昂的代价。它极大地复杂了 cgroup 核心实现，但更重要的是，对多个层次结构的支持限制了 cgroup 的一般使用方式以及控制器能够执行的操作。  
There was no limit on how many hierarchies there might be, which meant
that a thread's cgroup membership couldn't be described in finite
length.  The key might contain any number of entries and was unlimited
in length, which made it highly awkward to manipulate and led to
addition of controllers which existed only to identify membership,
which in turn exacerbated the original problem of proliferating number
of hierarchies.  
可能存在的层次结构数量没有限制，这意味着线程的 cgroup 成员身份无法以有限长度进行描述。密钥可能包含任意数量的条目并且长度不受限制，这使得操作非常困难，并导致添加仅用于识别成员身份的控制器，这反过来又加剧了层次结构数量激增的原始问题。  
Also, as a controller couldn't have any expectation regarding the
topologies of hierarchies other controllers might be on, each
controller had to assume that all other controllers were attached to
completely orthogonal hierarchies.  This made it impossible, or at
least very cumbersome, for controllers to cooperate with each other.  
此外，由于控制器不能对其他控制器可能所在的层次结构的拓扑有任何期望，因此每个控制器必须假设所有其他控制器都附加到完全正交的层次结构。这使得控制器之间的协作变得不可能，或者至少非常麻烦。  
In most use cases, putting controllers on hierarchies which are
completely orthogonal to each other isn't necessary.  What usually is
called for is the ability to have differing levels of granularity
depending on the specific controller.  In other words, hierarchy may
be collapsed from leaf towards root when viewed from specific
controllers.  For example, a given configuration might not care about
how memory is distributed beyond a certain level while still wanting
to control how CPU cycles are distributed.  
在大多数用例中，没有必要将控制器放在彼此完全正交的层次结构上。通常需要的是能够根据特定的控制器具有不同级别的粒度。换句话说，当从特定控制器查看时，层次结构可能会从叶向根折叠。例如，给定的配置可能不关心超出特定级别的内存如何分配，但仍希望控制 CPU 周期的分配方式。  
Thread Granularity
------------------ 线程粒度 ------------------  
cgroup v1 allowed threads of a process to belong to different cgroups.
This didn't make sense for some controllers and those controllers
ended up implementing different ways to ignore such situations but
much more importantly it blurred the line between API exposed to
individual applications and system management interface.  
cgroup v1 允许进程的线程属于不同的 cgroup。这对于某些控制器来说没有意义，并且这些控制器最终实现了不同的方式来忽略此类情况，但更重要的是，它模糊了暴露给单个应用程序的 API 和系统管理接口之间的界限。  
Generally, in-process knowledge is available only to the process
itself; thus, unlike service-level organization of processes,
categorizing threads of a process requires active participation from
the application which owns the target process.  
一般来说，进程内知识仅适用于进程本身；因此，与进程的服务级组织不同，对进程的线程进行分类需要拥有目标进程的应用程序的积极参与。  
cgroup v1 had an ambiguously defined delegation model which got abused
in combination with thread granularity.  cgroups were delegated to
individual applications so that they can create and manage their own
sub-hierarchies and control resource distributions along them.  This
effectively raised cgroup to the status of a syscall-like API exposed
to lay programs.  
cgroup v1 有一个定义不明确的委托模型，该模型与线程粒度结合起来被滥用。 cgroup 被委托给各个应用程序，以便它们可以创建和管理自己的子层次结构并控制它们的资源分配。这有效地将 cgroup 提升为向非专业程序公开的类似系统调用的 API 的地位。  
First of all, cgroup has a fundamentally inadequate interface to be
exposed this way.  For a process to access its own knobs, it has to
extract the path on the target hierarchy from /proc/self/cgroup,
construct the path by appending the name of the knob to the path, open
and then read and/or write to it.  This is not only extremely clunky
and unusual but also inherently racy.  There is no conventional way to
define transaction across the required steps and nothing can guarantee
that the process would actually be operating on its own sub-hierarchy.  
首先，cgroup 的接口根本不足以以这种方式公开。对于要访问自己的旋钮的进程，它必须从 /proc/self/cgroup 中提取目标层次结构上的路径，通过将旋钮的名称附加到路径来构造路径，打开然后读取和/或写入它。这不仅极其笨重和不寻常，而且本质上很活泼。没有传统的方法来定义跨所需步骤的事务，并且无法保证流程实际上在其自己的子层次结构上运行。  
cgroup controllers implemented a number of knobs which would never be
accepted as public APIs because they were just adding control knobs to
system-management pseudo filesystem.  cgroup ended up with interface
knobs which were not properly abstracted or refined and directly
revealed kernel internal details.  These knobs got exposed to
individual applications through the ill-defined delegation mechanism
effectively abusing cgroup as a shortcut to implementing public APIs
without going through the required scrutiny.  
cgroup 控制器实现了许多永远不会被接受为公共 API 的旋钮，因为它们只是向系统管理伪文件系统添加控制旋钮。 cgroup 最终得到了没有正确抽象或细化的接口旋钮，并且直接揭示了内核内部细节。这些旋钮通过定义不明确的委托机制暴露给各个应用程序，有效地滥用 cgroup 作为实现公共 API 的捷径，而无需经过所需的审查。  
This was painful for both userland and kernel.  Userland ended up with
misbehaving and poorly abstracted interfaces and kernel exposing and
locked into constructs inadvertently.  
这对于用户态和内核来说都是痛苦的。用户态最终会出现行为不当和抽象不良的接口，并且内核会无意中暴露并锁定到构造中。  
Competition Between Inner Nodes and Threads
------------------------------------------- 内部节点和线程之间的竞争--------------------------------------------------------  
cgroup v1 allowed threads to be in any cgroups which created an
interesting problem where threads belonging to a parent cgroup and its
children cgroups competed for resources.  This was nasty as two
different types of entities competed and there was no obvious way to
settle it.  Different controllers did different things.  
cgroup v1 允许线程位于任何 cgroup 中，这产生了一个有趣的问题，即属于父 cgroup 及其子 cgroup 的线程竞争资源。这是令人讨厌的，因为两种不同类型的实体之间存在竞争，并且没有明显的方法来解决它。不同的控制器做了不同的事情。  
The cpu controller considered threads and cgroups as equivalents and
mapped nice levels to cgroup weights.  This worked for some cases but
fell flat when children wanted to be allocated specific ratios of CPU
cycles and the number of internal threads fluctuated - the ratios
constantly changed as the number of competing entities fluctuated.
There also were other issues.  The mapping from nice level to weight
wasn't obvious or universal, and there were various other knobs which
simply weren't available for threads.  
CPU 控制器将线程和 cgroup 视为等效项，并将良好级别映射到 cgroup 权重。这在某些情况下有效，但当孩子们想要分配特定比率的 CPU 周期和内部线程数量波动时，这种方法就会失败——这些比率随着竞争实体数量的波动而不断变化。还有其他问题。从良好级别到重量的映射并不明显或通用，并且还有各种其他旋钮根本不适用于线程。  
The io controller implicitly created a hidden leaf node for each
cgroup to host the threads.  The hidden leaf had its own copies of all
the knobs with \`\`leaf\_\`\` prefixed.  While this allowed equivalent
control over internal threads, it was with serious drawbacks.  It
always added an extra layer of nesting which wouldn't be necessary
otherwise, made the interface messy and significantly complicated the
implementation.  
io 控制器隐式地为每个 cgroup 创建一个隐藏的叶节点来托管线程。隐藏的叶子有自己的所有旋钮的副本，并带有“leaf\_”前缀。虽然这允许对内部线程进行同等的控制，但它有严重的缺点。它总是添加一个额外的嵌套层，否则就没有必要，使界面变得混乱，并使实现变得非常复杂。  
The memory controller didn't have a way to control what happened
between internal tasks and child cgroups and the behavior was not
clearly defined.  There were attempts to add ad-hoc behaviors and
knobs to tailor the behavior to specific workloads which would have
led to problems extremely difficult to resolve in the long term.  
内存控制器无法控制内部任务和子 cgroup 之间发生的情况，并且行为也没有明确定义。有人尝试添加临时行为和旋钮来根据特定工作负载定制行为，但从长远来看，这会导致问题极难解决。  
Multiple controllers struggled with internal tasks and came up with
different ways to deal with it; unfortunately, all the approaches were
severely flawed and, furthermore, the widely different behaviors
made cgroup as a whole highly inconsistent.  
多个控制者都在努力处理内部任务，并想出了不同的方法来处理它；不幸的是，所有方法都存在严重缺陷，而且，广泛不同的行为使得 cgroup 作为一个整体高度不一致。  
This clearly is a problem which needs to be addressed from cgroup core
in a uniform way.  
这显然是一个需要从 cgroup 核心以统一方式解决的问题。  
Other Interface Issues
---------------------- 其他接口问题----------------------  
cgroup v1 grew without oversight and developed a large number of
idiosyncrasies and inconsistencies.  One issue on the cgroup core side
was how an empty cgroup was notified - a userland helper binary was
forked and executed for each event.  The event delivery wasn't
recursive or delegatable.  The limitations of the mechanism also led
to in-kernel event delivery filtering mechanism further complicating
the interface.  
cgroup v1 在没有监督的情况下成长并产生了大量的特性和不一致。 cgroup 核心方面的一个问题是如何通知空 cgroup——为每个事件分叉并执行一个用户态辅助二进制文件。事件传递不是递归的或可委托的。该机制的局限性还导致内核内的事件传递过滤机制使接口进一步复杂化。  
Controller interfaces were problematic too.  An extreme example is
controllers completely ignoring hierarchical organization and treating
all cgroups as if they were all located directly under the root
cgroup.  Some controllers exposed a large amount of inconsistent
implementation details to userland.  
控制器接口也存在问题。一个极端的例子是控制器完全忽略层次结构并将所有 cgroup 视为直接位于根 cgroup 下。一些控制器向用户空间暴露了大量不一致的实现细节。  
There also was no consistency across controllers.  When a new cgroup
was created, some controllers defaulted to not imposing extra
restrictions while others disallowed any resource usage until
explicitly configured.  Configuration knobs for the same type of
control used widely differing naming schemes and formats.  Statistics
and information knobs were named arbitrarily and used different
formats and units even in the same controller.  
控制器之间也没有一致性。创建新的 cgroup 时，某些控制器默认不施加额外限制，而其他控制器则在明确配置之前不允许使用任何资源。相同类型的控件的配置旋钮使用了截然不同的命名方案和格式。统计和信息旋钮被任意命名，即使在同一控制器中也使用不同的格式和单位。  
cgroup v2 establishes common conventions where appropriate and updates
controllers so that they expose minimal and consistent interfaces.  
cgroup v2 在适当的情况下建立通用约定并更新控制器，以便它们公开最少且一致的接口。  
Controller Issues and Remedies
------------------------------ 控制器问题和补救措施 ------------------------------------------  
Memory
~~~~~~ 内存~~~~~~  
The original lower boundary, the soft limit, is defined as a limit
that is per default unset.  As a result, the set of cgroups that
global reclaim prefers is opt-in, rather than opt-out.  The costs for
optimizing these mostly negative lookups are so high that the
implementation, despite its enormous size, does not even provide the
basic desirable behavior.  First off, the soft limit has no
hierarchical meaning.  All configured groups are organized in a global
rbtree and treated like equal peers, regardless where they are located
in the hierarchy.  This makes subtree delegation impossible.  Second,
the soft limit reclaim pass is so aggressive that it not just
introduces high allocation latencies into the system, but also impacts
system performance due to overreclaim, to the point where the feature
becomes self-defeating.  
原始下限（软限制）被定义为默认未设置的限制。因此，全局回收首选的 cgroup 集是选择加入，而不是选择退出。优化这些大多是负面查找的成本是如此之高，以至于尽管其规模巨大，但其实现甚至无法提供基本的理想行为。首先，软限制没有等级意义。所有配置的组都组织在全局 rbtree 中，并被视为平等的对等体，无论它们位于层次结构中的哪个位置。这使得子树委托不可能。其次，软限制回收过程非常激进，不仅会给系统带来较高的分配延迟，还会因过度回收而影响系统性能，甚至导致该功能弄巧成拙。  
The memory.low boundary on the other hand is a top-down allocated
reserve.  A cgroup enjoys reclaim protection when it and all its
ancestors are below their low boundaries, which makes delegation of
subtrees possible.  Secondly, new cgroups have no reserve per default
and in the common case most cgroups are eligible for the preferred
reclaim pass.  This allows the new low boundary to be efficiently
implemented with just a minor addition to the generic reclaim code,
without the need for out-of-band data structures and reclaim passes.
Because the generic reclaim code considers all cgroups except for the
ones running low in the preferred first reclaim pass, overreclaim of
individual groups is eliminated as well, resulting in much better
overall workload performance.  
另一方面，memory.low 边界是自上而下分配的保留。当 cgroup 及其所有祖先都低于其低边界时，它享有回收保护，这使得子树的委派成为可能。其次，新的 cgroup 没有默认储备，并且在常见情况下，大多数 cgroup 都有资格获得首选回收通行证。这使得新的低边界只需对通用回收代码进行少量添加即可有效实现，而不需要带外数据结构和回收通道。由于通用回收代码会考虑除首选第一回收过程中运行速度较低的 cgroup 之外的所有 cgroup，因此也会消除各个组的过度回收，从而实现更好的整体工作负载性能。  
The original high boundary, the hard limit, is defined as a strict
limit that can not budge, even if the OOM killer has to be called.
But this generally goes against the goal of making the most out of the
available memory.  The memory consumption of workloads varies during
runtime, and that requires users to overcommit.  But doing that with a
strict upper limit requires either a fairly accurate prediction of the
working set size or adding slack to the limit.  Since working set size
estimation is hard and error prone, and getting it wrong results in
OOM kills, most users tend to err on the side of a looser limit and
end up wasting precious resources.  
最初的高边界，即硬限制，被定义为一个不能移动的严格限制，即使必须调用 OOM 杀手。但这通常违背了充分利用可用内存的目标。工作负载的内存消耗在运行时会发生变化，这需要用户过量使用。但要在严格的上限下做到这一点，需要对工作集大小进行相当准确的预测，或者在极限上增加松弛度。由于工作集大小估计很困难且容易出错，并且错误会导致 OOM 终止，因此大多数用户倾向于选择更宽松的限制，最终浪费宝贵的资源。  
The memory.high boundary on the other hand can be set much more
conservatively.  When hit, it throttles allocations by forcing them
into direct reclaim to work off the excess, but it never invokes the
OOM killer.  As a result, a high boundary that is chosen too
aggressively will not terminate the processes, but instead it will
lead to gradual performance degradation.  The user can monitor this
and make corrections until the minimal memory footprint that still
gives acceptable performance is found.  
另一方面，memory.high 边界可以设置得更加保守。当受到攻击时，它会通过强制直接回收来消除多余的分配来限制分配，但它永远不会调用 OOM 杀手。因此，过于激进地选择高边界不会终止进程，反而会导致性能逐渐下降。用户可以对此进行监控并进行纠正，直到找到仍能提供可接受性能的最小内存占用量。  
In extreme cases, with many concurrent allocations and a complete
breakdown of reclaim progress within the group, the high boundary can
be exceeded.  But even then it's mostly better to satisfy the
allocation from the slack available in other groups or the rest of the
system than killing the group.  Otherwise, memory.max is there to
limit this type of spillover and ultimately contain buggy or even
malicious applications.  
在极端情况下，由于组内存在许多并发分配和回收进度完全崩溃，因此可能会超出上限。但即便如此，从其他组或系统其余部分中可用的闲置资源中满足分配也比杀死该组要好。否则，memory.max 会限制这种类型的溢出，并最终包含有错误甚至恶意的应用程序。  
Setting the original memory.limit\_in\_bytes below the current usage was
subject to a race condition, where concurrent charges could cause the
limit setting to fail. memory.max on the other hand will first set the
limit to prevent new charges, and then reclaim and OOM kill until the
new limit is met - or the task writing to memory.max is killed.  
将原始内存.limit\_in\_bytes 设置为低于当前使用量会受到竞争条件的影响，其中并发费用可能会导致限制设置失败。另一方面，memory.max 将首先设置限制以防止新的费用，然后回收并 OOM 终止，直到满足新的限制 - 或者写入 memory.max 的任务被终止。  
The combined memory+swap accounting and limiting is replaced by real
control over swap space.  
组合的内存+交换计算和限制被对交换空间的实际控制所取代。  
The main argument for a combined memory+swap facility in the original
cgroup design was that global or parental pressure would always be
able to swap all anonymous memory of a child group, regardless of the
child's own (possibly untrusted) configuration.  However, untrusted
groups can sabotage swapping by other means - such as referencing its
anonymous memory in a tight loop - and an admin can not assume full
swappability when overcommitting untrusted jobs.  
原始 cgroup 设计中组合内存+交换设施的主要论点是，全局或父母压力始终能够交换子组的所有匿名内存，无论子组自己的（可能不受信任的）配置如何。但是，不受信任的组可以通过其他方式破坏交换 - 例如在紧密循环中引用其匿名内存 - 并且管理员在过度提交不受信任的作业时无法假设完全可交换性。  
For trusted jobs, on the other hand, a combined counter is not an
intuitive userspace interface, and it flies in the face of the idea
that cgroup controllers should account and limit specific physical
resources.  Swap space is a resource like all others in the system,
and that's why unified hierarchy allows distributing it separately.
  
另一方面，对于受信任的作业，组合计数器不是直观的用户空间界面，并且它违背了 cgroup 控制器应该考虑和限制特定物理资源的想法。交换空间是一种与系统中所有其他资源一样的资源，这就是统一层次结构允许单独分配它的原因。