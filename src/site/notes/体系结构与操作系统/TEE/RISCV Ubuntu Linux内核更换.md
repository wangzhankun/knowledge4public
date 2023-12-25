---
{"dg-publish":true,"permalink":"/体系结构与操作系统/TEE/RISCV Ubuntu Linux内核更换/","dgPassFrontmatter":true}
---



# RISCV Ubuntu Linux内核更换

# 交叉编译内核

```sh
#!/bin/bash


# LINUXSRC=/root/linux
export LINUXSRC=/keystone/linux
export OUTPUT=/keystone/build/linux-ubuntu.build

#export CONFIG=/keystone/conf/linux64-defconfig
export CONFIG=/keystone/build/config-5.19.0-1012-generic

export CROSS_COMPILE=riscv64-unknown-linux-gnu-
export ARCH=riscv

###########################################################
mkdir -p $OUTPUT/_install
touch $OUTPUT/.exists

##################################################################
cp $CONFIG /keystone/build/linux.build/.config
make -C $LINUXSRC O=$OUTPUT CROSS_COMPILE=riscv64-unknown-linux-gnu- ARCH=riscv olddefconfig
make -C $LINUXSRC O=$OUTPUT CROSS_COMPILE=riscv64-unknown-linux-gnu- ARCH=riscv modules -j16
make -C $LINUXSRC O=$OUTPUT CROSS_COMPILE=riscv64-unknown-linux-gnu- ARCH=riscv -j16

mkdir -p /keystone/build/linux-keystone-driver.build
cp -r /keystone/linux-keystone-driver /keystone/build/linux-keystone-driver.build
make -C $OUTPUT O=$OUTPUT CROSS_COMPILE=riscv64-unknown-linux-gnu- ARCH=riscv M=/keystone/build/linux-keystone-driver.build modules

# https://blog.csdn.net/Mculover666/article/details/126164289
# Linux内核编译安装模块并打包
mkdir -p ${OUTPUT}/_install

make INSTALL_MOD_PATH=${OUTPUT}/_install modules_install O=${OUTPUT}

STRIP=${CROSS_COMPILE}strip
find ${OUTPUT}/_install/ -name "*.ko" | xargs $STRIP --strip-debug \
        --remove-section=.comment --remove-section=.note --preserve-dates

mod_dir=`ls ${OUTPUT}/_install/lib/modules | awk '{ print $1 }'`
rm ${OUTPUT}/_install/lib/modules/${mod_dir}/build
rm ${OUTPUT}/_install/lib/modules/${mod_dir}/source
tar -zcf ${OUTPUT}/install_${mod_dir}.tar.gz -C ${OUTPUT}  _install
tar cf ${OUTPUT}/device-tree.tar  -C ${OUTPUT}/arch/riscv/boot/ dts
```



目前为止我们有`${OUTPUT}/install_${mod_dir}.tar.gz`, `${OUTPUT}/arch/riscv/boot/Image`, `${OUTPUT}/System.map`, `${OUTPUT}/.config`， `${OUTPUT}/device-tree.tar`。



值得注意的是，这里使用的是`${OUTPUT}/arch/riscv/boot/Image`，而非`${OUTPUT}/arch/riscv/boot/Image.gz`



# 内核替换



假设我们编译出的内核的版本号为`$VERSION`, 也就是上文中的`${mod_dir}`。那么，我们将需要的文件传输到RISC v的板子上（或者qemu模拟器中），开始对内核进行替换：

```Assembly
sudo cp .config /boot/config-$VERSION
sudo cp Image /boot/vmlinuz-$VERSION
sudo cp System.map /boot/System.map-$VERSION

tar -zxf install_${VERSION}.tar.gz -C /tmp
sudo cp -r /tmp/_install/lib/modules/${VERSION} /lib/modules

tar -xf device-tree.tar -C /tmp
sudo mkdir -p /lib/firmware/${VERSION}/device-tree
sudo cp -r /tmp/dts/* /lib/firmware/${VERSION}/device-tree


# 自动生成 initrd.img-${VERSION}
sudo update-initramfs -c -k ${VERSION}
# 更新boot menu
sudo u-boot-update
```



最后重启`sudo reboot`

