---
{"dg-publish":true,"tags":["入门指南","osbidian"],"permalink":"/入门指南/工具/osbidian 入门/","dgPassFrontmatter":true}
---

## 入门
https://www.bilibili.com/video/BV1i3411k7TQ/?spm_id_from=333.999.0.0&vd_source=47bbcc428387a807dfb9a0a62d6b09d1


# 必备插件
* [pkmer](https://pkmer.cn/) 国内版本的插件市场
* digitalgarden 用于制作在线的网站
* image auto upload plugin 与picgo搭配使用自动上传文件到图床
* note refactor 用于根据heading自动将当前文件拆分为多个子文件
* local rest api 与浏览器的osbidian web插件配合使用剪藏网页，同时该API开放了很多接口，也可以自行开发软件
* dataview
# 发布为网页

## 图床配置

[[入门指南/工具/picgo\|picgo]]


## DIgitalGarden
*  [Hi , Obsidian Digital Garden](https://immmmm.com/hi-obsidian-digital-garden/)
* [利用obsidian构建个人博客](https://zytomorrow.top/%E6%8A%80%E6%9C%AF%E6%8A%98%E8%85%BE/%E5%88%A9%E7%94%A8obsidian%E6%9E%84%E5%BB%BA%E4%B8%AA%E4%BA%BA%E5%8D%9A%E5%AE%A2/)
* [obsidian 目前最完美的免费发布方案 - 渐进式教程](https://notes.oldwinter.top/obsidian-%E7%9B%AE%E5%89%8D%E6%9C%80%E5%AE%8C%E7%BE%8E%E7%9A%84%E5%85%8D%E8%B4%B9%E5%8F%91%E5%B8%83%E6%96%B9%E6%A1%88-%E6%B8%90%E8%BF%9B%E5%BC%8F%E6%95%99%E7%A8%8B)
* [DigitalGarden 配置](https://zytomorrow.top/%E6%8A%80%E6%9C%AF%E6%8A%98%E8%85%BE/%E5%88%A9%E7%94%A8obsidian%E6%9E%84%E5%BB%BA%E4%B8%AA%E4%BA%BA%E5%8D%9A%E5%AE%A2/)
* 美化：https://github.com/uroybd/topobon/tree/main （我是直接把该文件夹下的除了note之外的全部文件都粘贴覆盖进来了，要注意.env隐藏文件的复制）

# 网页剪藏

local rest api 与浏览器的osbidian web插件配合使用剪藏网页，同时该API开放了很多接口，也可以自行开发软件

## osbidian web插件配置

**Capture page snapshot**
```
---
dg-publish: true
page-title: {{json page.title}}
url: {{page.url}}
tags:
---
{{#if page.selectedText}}

{{quote page.selectedText}}

---

{{/if}}{{page.content}}
```


**Create new note**
```
---
dg-publish: true
page-title: {{json page.title}}
url: {{page.url}}
tags:
---
{{#if page.selectedText}}

{{quote page.selectedText}}
{{/if}}
```