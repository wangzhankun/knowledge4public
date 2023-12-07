---
{"dg-publish":true,"dg-home":"true","permalink":"/osbidian 设置/","tags":["gardenEntry"],"dgPassFrontmatter":true}
---


# 必备插件
* [pkmer](https://pkmer.cn/)
* digitalgarden
* image auto upload plugin
# 发布为网页
[my-knowledge-public](https://my-knowledge-public.vercel.app)

## 图床配置
![2023-12-07_13-29.png](https://cdn.jsdelivr.net/gh/wangzhankun/img-repo/2023-12-07_13-29.png)

* [如何利用 Github 搭建自己的免费图床？](https://zhuanlan.zhihu.com/p/353775844)
* [【Obsidian绝配！】为你的OB搭建专属图床，保姆级教程！](https://sspai.com/post/75765)

## DIgitalGarden
* [obsidian 目前最完美的免费发布方案 - 渐进式教程](https://notes.oldwinter.top/obsidian-%E7%9B%AE%E5%89%8D%E6%9C%80%E5%AE%8C%E7%BE%8E%E7%9A%84%E5%85%8D%E8%B4%B9%E5%8F%91%E5%B8%83%E6%96%B9%E6%A1%88-%E6%B8%90%E8%BF%9B%E5%BC%8F%E6%95%99%E7%A8%8B)
* [DigitalGarden 配置](https://zytomorrow.top/%E6%8A%80%E6%9C%AF%E6%8A%98%E8%85%BE/%E5%88%A9%E7%94%A8obsidian%E6%9E%84%E5%BB%BA%E4%B8%AA%E4%BA%BA%E5%8D%9A%E5%AE%A2/)

模板
```
<%* fileName = await tp.system.prompt("请输入笔记名", "新建笔记") await tp.file.rename(fileName) tp.file.cursor() -%> 
--- 
dg-publish: true title: <% fileName %> 
dg-created: <% tp.date.now("YYYY-MM-DDTHH:mm:ss.SSS+08:00") %> 
tags: [""]
```