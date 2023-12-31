---
{"dg-publish":true,"date":"2023-12-08","time":"09:35","progress":"进行中","tags":["交叉编译"],"permalink":"/编程语言/C++/编译/交叉编译第三方库for riscv/","dgPassFrontmatter":true}
---

# Cross-compile Libs for riscv

交叉编译和非交叉编译是完全一致的，唯一的不同之处就在与设置交叉编译环境上。一般交叉编译第三方库的步骤是：

1. 学习非交叉编译，即在正常编译时编译该第三方库的方法
2. 第三方库中关于交叉编译的说明
3. 网络上关于交叉编译的说明


# gcc

```Bash
git clone https://gitee.com/mirrors/riscv-gnu-toolchain.git


cd riscv-gnu-toolchain
git submodule set-url llvm https://gitee.com/mirrors/LLVM.git
git submodule set-url pk https://gh-proxy.com/https://github.com/riscv-software-src/riscv-pk.git
git submodule set-url spike https://gh-proxy.com/https://github.com/riscv-software-src/riscv-isa-sim.git
git submodule set-url musl https://gitee.com/nwpu-ercesi/musl.git
git submodule set-url qemu https://gitee.com/liwg06/qemu.git
git submodule set-url gdb https://gitee.com/dajiang0055/binutils-gdb.git
git submodule set-url newlib https://gh-proxy.com/https://github.com/mirror/newlib-cygwin.git
git submodule set-url dejagnu https://gitee.com/nwpu-ercesi/dejagnu.git
git submodule set-url glibc https://gh-proxy.com/https://github.com/bminor/glibc.git
git submodule set-url gcc https://gh-proxy.com/https://github.com/gcc-mirror/gcc.git
git submodule set-url binutils https://gitee.com/dajiang0055/binutils-gdb.git


git submodule init
git submodule update --recursive
```



# openssl

```Bash
../Configure linux64-riscv64 --cross-compile-prefix=riscv64-unknown-linux-gnu- --prefix=/opt/riscv-gnu-toolchain/sysroot/usr --openssldir=/opt/riscv-gnu-toolchain/sysroot/usr
make -j32
make install
```

# CURL

https://www.matteomattei.com/how-to-cross-compile-curl-library-with-ssl-and-zlib-support/

```Bash
export CROSS_COMPILE="riscv64-unknown-linux-gnu"
export CPPFLAGS="-I/opt/ssl-riscv64/include -I/opt/zlib-riscv/include"
export LDFLAGS="-L/opt/ssl-riscv64/lib -L/opt/zlib-riscv/lib"
export AR=${CROSS_COMPILE}-ar
export AS=${CROSS_COMPILE}-as
export LD=${CROSS_COMPILE}-ld
export RANLIB=${CROSS_COMPILE}-ranlib
export CC=${CROSS_COMPILE}-gcc
export NM=${CROSS_COMPILE}-nm
export LIBS="-lssl -lcrypto"
./configure --prefix=/opt/curl-riscv64 --target=${CROSS_COMPILE} --host=${CROSS_COMPILE} --with-ssl --with-zlib
```

# c-ares

https://github.com/c-ares/c-ares/blob/main/INSTALL.md

```Bash
./buildconf
CC=riscv64-unknown-linux-gnu-gcc ./configure --prefix=/opt/c-ares-riscv --host=riscv64-unknown-linux-gnu --target=riscv64-unknown-linux-gnu
```

# event

https://github.com/libevent/libevent/blob/master/Documentation/Building.md

```Bash
./autogen.sh
```

```Bash
export CROSS_COMPILE="riscv64-unknown-linux-gnu"
export CPPFLAGS="-I/opt/ssl-riscv64/include -I/opt/zlib-riscv/include"
export LDFLAGS="-L/opt/ssl-riscv64/lib -L/opt/zlib-riscv/lib"
export AR=${CROSS_COMPILE}-ar
export AS=${CROSS_COMPILE}-as
export LD=${CROSS_COMPILE}-ld
export RANLIB=${CROSS_COMPILE}-ranlib
export CC=${CROSS_COMPILE}-gcc
export NM=${CROSS_COMPILE}-nm
export LIBS="-lssl -lcrypto"
./configure --prefix=/opt/riscv-gnu-toolchain/sysroot/usr --host=${CROSS_COMPILE}
```

# tirpc

```Bash
wget  https://downloads.sourceforge.net/libtirpc/libtirpc-1.3.4.tar.bz2
CC=riscv64-unknown-linux-gnu-gcc ./configure --prefix=/opt/libtirpc-riscv64 --host=riscv64-unknown-linux-gnu --disable-gssapi
```



