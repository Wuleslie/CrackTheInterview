# 移动端混合开发引言

### 什么是混合开发

所谓混合开发，是指在移动端开发中兼用原生与web能力的开发方式，它的产物是介于web-app、native-app的hybrid app。Hybrid app兼具native app的良好用户交互体验和web app跨平台开发的优势。 

### 优势/劣势对比

|          | Web App | Hybrid App | Native App |
| -------- | ------- | ---------- | ---------- |
| 开发成本 | 低      | 中         | 高         |
| 维护更新 | 简单    | 简单       | 复杂       |
| 用户体验 | 差      | 中         | 优         |
| 可否上架 | 不可    | 可         | 可         |
| 安装     | 不需要  | 需要       | 需要       |
| 跨平台性 | 优      | 优         | 差         |

### 发展历程

#### Cordova

这是社区最早出现的轮子，我们统称为 Cordova。Cordova 主要提供三种能力：

- 前端代码与原生代码通信的能力；
- 原生插件机制；
- 跨平台打包能力。

Cordova是一个移动应用开发框架，你基于这个东西可以用网页代码作出APP。

#### Phonegap Build

Phonegap Build是一个在线打包工具，你把使用cordova写好的项目给Phonegap Build，Phonegap Build就会在线打包成App。

#### JSBridge(WebView UI)

 顾名思义，就是JS和Native之间的桥梁，它只保留了Web和Native的通信部分。简单的说，JSBridge就是定义Native和JS的通信，Native只通过一个固定的桥对象调用JS，JS也只通过固定的桥对象调用Native。 有了JSBridge，体验的痛点问题被解决，但是，还是解决不了一个app需要多端协作，从而导致开发难度增加的问题，于是React Native横空出世。

#### React Native

React Native (简称RN)是Facebook于2015年4月开源的跨平台移动应用开发框架，是Facebook早先开源的JS框架 React在原生移动应用平台的衍生产物，支持iOS和Android两大平台。

RN和普通混合开发的区别就是React Native 采用不同的方法进行混合移动应用开发。它不会生成原生 UI 组件，而是基于 React，React Native 是一个用于构建基于 Web 的交互界面的 JavaScript 库，因此会有更丰富的 UI 体验效果，同时也能够很好地调用底层框架的UI，达到和原生一样的体验。

#### Weex

2016年阿里发布的移动端跨平台开发工具，跟RN大同小异，但是对比RN有那么一些优点：

- js 能写业务，跨平台，热更新；
- Weex 能用Vue的framework，贴近我们的技术栈；
- Weex 比RN更轻量，可以分包，每个页面一个实例性能更好；
- Weex 解决了RN已经存在的一些问题，在RN的基础上进行开发；
- 有良好的扩展性，比较好扩展新的组件和模块。

#### Flutter

2018年，由Google推出。 Flutter使用Dart语言开发，Dart可以被编译（AOT）成不同平台的本地代码，让Flutter可以直接和平台通讯而不需要一个中间的桥接过程，从而提高了性能。