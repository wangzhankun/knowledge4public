---
{"dg-publish":true,"date":"2023-12-08","time":"15:38","progress":"进行中","tags":["入门"],"permalink":"/工具/picgo/","dgPassFrontmatter":true}
---




![2023-12-07_13-29.png](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/2023-12-07_13-29.png)

* [如何利用 Github 搭建自己的免费图床？](https://zhuanlan.zhihu.com/p/353775844)
* [【Obsidian绝配！】为你的OB搭建专属图床，保姆级教程！](https://sspai.com/post/75765)

为了使用gitee作为图床，需要安装gitee的插件，该插件依赖于node,因此在创建启动命令时需要以下命令传入node的path：
```sh
cd /home/wang/opt/picgo && env PATH=/home/wang/opt/go/bin:$PATH ./PicGo-2.3.1.AppImage
```