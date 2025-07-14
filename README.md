# Faith

一个使用Flutter和GetX构建的现代化移动应用。

## 项目特点

- 使用GetX进行状态管理和路由控制
- 响应式UI设计
- 支持多主题切换
- 完整的启动页和错误页面处理
- 网络请求封装
- 屏幕适配支持

## 技术栈

- Flutter SDK: ^3.8.1
- GetX: ^4.7.2
- Dio: ^5.8.0+1
- flutter_screenutil: ^5.9.3
- flutter_svg: ^2.2.0
- 其他依赖详见 pubspec.yaml

## 项目结构

```
lib/
  ├── api/          # API接口
  ├── assets/       # 静态资源
  ├── comm/         # 通用组件
  ├── components/   # 业务组件
  ├── config/       # 配置文件
  ├── pages/        # 页面
  ├── router/       # 路由管理
  └── utils/        # 工具类
```

## 开始使用

1. 确保已安装Flutter SDK并配置好环境
2. 克隆项目
   ```bash
   git clone https://github.com/GX88/Faith.git
   ```
3. 安装依赖
   ```bash
   flutter pub get
   ```
4. 运行项目
   ```bash
   flutter run
   ```

## 开发规范

- 使用`analysis_options.yaml`进行代码规范检查
- 遵循Flutter官方推荐的代码风格
- 组件化开发，保持代码的可复用性
- 使用GetX进行状态管理，避免状态混乱

## 贡献指南

欢迎提交Issue和Pull Request。在提交PR之前，请确保：

1. 代码符合项目规范
2. 添加必要的测试用例
3. 更新相关文档

## 许可证

MIT License
