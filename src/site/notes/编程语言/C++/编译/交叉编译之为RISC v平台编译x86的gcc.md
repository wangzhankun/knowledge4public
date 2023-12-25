---
{"dg-publish":true,"date":"2023-12-15","time":"16:49","progress":"完成","tags":["编译","交叉编译"],"permalink":"/编程语言/C++/编译/交叉编译之为RISC v平台编译x86的gcc/","dgPassFrontmatter":true}
---

# 交叉编译之为RISC v平台编译x86的gcc

读者应该比较了解交叉编译的概念，一般都是在x86平台下使用gcc编译出其它平台的代码，这里我尝试在RISC v平台下编译出可以在x86平台使用的代码。

## 环境

1. 在 x86_64 平台上编译 riscv64-unknown-linux-gnu-gcc 编译器，网上教程很多不再赘述
1. 在 x86_64 平台上使用 riscv64-unknown-linux-gnu-gcc 编译出能够在RISC v平台上使用的 x86_64 gcc



请在命令行中输入以下命令测试riscv编译器是否能够正常工作：

```Bash
riscv64-unknown-linux-gnu-gcc -v
```


## 下载源码



根据 https://gcc.gnu.org/install/prerequisites.html 中的说明下载对应版本的MPFR\MPC\ISL\GMP源码和gcc的源码。

```Bash
wget http://ftpmirror.gnu.org/binutils/binutils-2.38.tar.gz
wget http://ftpmirror.gnu.org/gcc/gcc-11.1.0/gcc-11.1.0.tar.gz
wget https://mirrors.tuna.tsinghua.edu.cn/kernel/v5.x/linux-5.10.5.tar.xz
wget http://ftpmirror.gnu.org/glibc/glibc-2.33.tar.xz
wget ftp://gcc.gnu.org/pub/gcc/infrastructure/cloog-0.18.1.tar.gz
```

解压缩

```Bash
for f in *.tar*; do tar xf $f; done
```



## 设置变量

这里一定不能设置成环境变量！！！否则会出错！！！


```sh
# ROOT 是 源码文件的跟路径
ROOT=/root/x86-gcc
GCCSRC=$ROOT/gcc-11.1.0
BINUTILS=$ROOT/binutils-2.38
LINUX=$ROOT/linux-5.10.5
GLIBC=$ROOT/glibc-2.33

BUILD=x86_64-linux-gnu
HOST=riscv64-unknown-linux-gnu
TARGET=x86_64-linux-gnu
TARGET_ARCH=x86_64

# PREFIX 是把交叉编译器安装到哪里
PREFIX=/opt/$TARGET
SYSROOT=$PREFIX/sysroot
```



## 创建文件夹

```Bash
# 删除已有的路径
rm -rf $PREFIX
mkdir -p $SYSROOT
```



## 编译binutils



```Bash
rm -rf $BINUTILS/build-${TARGET}
mkdir $BINUTILS/build-${TARGET}
cd $BINUTILS/build-${TARGET}
../configure --host=$HOST --target=${TARGET} \
    --prefix=${PREFIX} --with-sysroot=$SYSROOT \
    --disable-multilib --disable-werror
make -j32
make install
```



## 安装Linux头文件

```Bash
cd $LINUX
make mrproper
make ARCH=${TARGET_ARCH} INSTALL_HDR_PATH=$SYSROOT/usr headers_install
```



## 编译 gcc

### 准备文件

下载gmp、mpfr、mpc和isl:

```Bash
cd $GCCSRC
./contrib/download_prerequisites
```

如果下载成功将会看到如下输出：

```log
gmp-6.1.0.tar.bz2: OK
mpfr-3.1.4.tar.bz2: OK
mpc-1.0.3.tar.gz: OK
isl-0.18.tar.bz2: OK
All prerequisites downloaded successfully.
```



将cloog链接到GCC目录：

```Bash
cd $GCCSRC
ln -s $ROOT/cloog-0.18.1 cloog
file cloog # 确认一下软链接是否成功
```



### 编译



这里会出现 fenv.h:58:11: error: ‘::fenv_t’ has not been declared，解决方法见[链接](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=80196)的 comment13。这里直接给出解决方案：

1. 把`$GCCSRC/configure`中的`RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET"`改为`RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET -nostdinc++"`
2. 把`$GCCSRC/configure.ac`中的 `RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET"`改为`RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET -nostdinc++"`

```sh
sed -i 's/RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET"/RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET -nostdinc++"/g' $GCCSRC/configure
sed -i 's/RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET"/RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET -nostdinc++"/g' $GCCSRC/configure.ac
```

```Bash
rm -rf $GCCSRC/build-${TARGET}
mkdir $GCCSRC/build-${TARGET}
cd $GCCSRC/build-${TARGET}
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=80196
# 这里会出现 fenv.h:58:11: error: ‘::fenv_t’ has not been declared
# 解决方法见链接的 comment13
../configure --host=$HOST   --target=${TARGET} \
    --prefix=${PREFIX} --with-sysroot=$SYSROOT \
    --enable-languages=c,c++ \
    --enable-threads=posix \
    --disable-multilib --disable-werror --without-selinux --disable-libstdcxx-pch \
    --disable-libmudflap --disable-libssp --disable-libquadmath \
    --disable-libsanitizer --disable-nls
make -j32 
make install
```



## 编译glibc

```Bash
rm -rf $GLIBC/build-${TARGET}
mkdir $GLIBC/build-${TARGET}
cd $GLIBC/build-${TARGET}
../configure --build=$BUILD --host=$TARGET --target=${TARGET} \
    --prefix=$SYSROOT/usr \
    --with-headers=$SYSROOT/usr/include \
    --enable-threads=posix \
    --without-selinux \
    --disable-multilib libc_cv_forced_unwind=yes --disable-libstdcxx-pch \
    --disable-libmudflap --disable-libssp --disable-libquadmath \
    --disable-libsanitizer --disable-nls
make -j64

make install_root=$SYSROOT install
```



## 测试

### 测试文件

main.c

```C++
#include <stdio.h>

int main(int argc, char *argv[])
{
    printf("Hello, world!\n");
    return 0;
}
```

hello.cpp

```C++
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>

int main(int argc, char const *argv[])
{
    std::cout << "Hello, world!" << std::endl;
    std::vector<int> v = {1, 2, 3, 4, 5};
    std::for_each(v.begin(), v.end(), [](int i) { std::cout << i << std::endl; });
    
    return 0;
}
```

### 测试

```Bash
export LD_LIBRARY_PATH=/opt/riscv-gnu-toolchain/sysroot/lib64/lp64d
cd $ROOT/test
$PREFIX/bin/x86_64-linux-gnu-gcc -o main main.c 
$PREFIX/bin/x86_64-linux-gnu-g++ -o hello hello.cpp
```

## 脚本汇总

```sh
#!/bin/bash

# ROOT 是 源码文件的跟路径
ROOT=/root/x86-gcc
GCCSRC=$ROOT/gcc-11.1.0
BINUTILS=$ROOT/binutils-2.38
LINUX=$ROOT/linux-5.10.5
GLIBC=$ROOT/glibc-2.33

BUILD=x86_64-linux-gnu
HOST=riscv64-unknown-linux-gnu
TARGET=x86_64-linux-gnu
TARGET_ARCH=x86_64

# PREFIX 是把交叉编译器安装到哪里
PREFIX=/opt/$TARGET
SYSROOT=$PREFIX/sysroot


# 删除已有的路径
rm -rf $PREFIX
mkdir -p $SYSROOT

# 编译 binutils
rm -rf $BINUTILS/build-${TARGET}
mkdir $BINUTILS/build-${TARGET}
cd $BINUTILS/build-${TARGET}
../configure --host=$HOST --target=${TARGET} \
    --prefix=${PREFIX} --with-sysroot=$SYSROOT \
    --disable-multilib --disable-werror
make -j32
make install

# 安装linux头文件
cd $LINUX
make mrproper
make ARCH=${TARGET_ARCH} INSTALL_HDR_PATH=$SYSROOT/usr headers_install

# 编译 gcc
## 下载gmp、mpfr、mpc和isl:
cd $GCCSRC
./contrib/download_prerequisites
# gmp-6.1.0.tar.bz2: OK
# mpfr-3.1.4.tar.bz2: OK
# mpc-1.0.3.tar.gz: OK
# isl-0.18.tar.bz2: OK
# All prerequisites downloaded successfully.
# 这里的下载可能会出错，一定要认真检查

cd $GCCSRC
ln -s $ROOT/cloog-0.18.1 cloog
file cloog # 确认一下软链接是否成功

# 这里会出现 fenv.h:58:11: error: ‘::fenv_t’ has not been declared，解决方法见[链接](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=80196)的 comment13。这里直接给出解决方案：
sed -i 's/RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET"/RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET -nostdinc++"/g' $GCCSRC/configure
sed -i 's/RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET"/RAW_CXX_FOR_TARGET="$CXX_FOR_TARGET -nostdinc++"/g' $GCCSRC/configure.ac

rm -rf $GCCSRC/build-${TARGET}
mkdir $GCCSRC/build-${TARGET}
cd $GCCSRC/build-${TARGET}
../configure --host=$HOST   --target=${TARGET} \
    --prefix=${PREFIX} --with-sysroot=$SYSROOT \
    --enable-languages=c,c++ \
    --enable-threads=posix \
    --disable-multilib --disable-werror --without-selinux --disable-libstdcxx-pch \
    --disable-libmudflap --disable-libssp --disable-libquadmath \
    --disable-libsanitizer --disable-nls
make -j64
make install


rm -rf $GLIBC/build-${TARGET}
mkdir $GLIBC/build-${TARGET}
cd $GLIBC/build-${TARGET}
../configure --build=$BUILD --host=$TARGET --target=${TARGET} \
    --prefix=$SYSROOT/usr \
    --with-headers=$SYSROOT/usr/include \
    --enable-threads=posix \
    --without-selinux \
    --disable-multilib libc_cv_forced_unwind=yes --disable-libstdcxx-pch \
    --disable-libmudflap --disable-libssp --disable-libquadmath \
    --disable-libsanitizer --disable-nls
make -j64

make install_root=$SYSROOT install
```

## 参考文献

[Ubuntu构建ARM交叉编译器](https://blog.csdn.net/weixin_43283275/article/details/125030556)

[insall gcc](https://gcc.gnu.org/install/index.html)

[编译工具链](https://zhuanlan.zhihu.com/p/110402378)

