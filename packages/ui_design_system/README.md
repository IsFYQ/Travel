# UI Design System

旅行搭子视图层唯一组件库。新 UI 请使用本包，避免页面内散落 `Color(0x…)` / 魔法圆角。

## 约定

- **字体**：使用系统默认字体，不引入 Google Fonts / 自定义 fontFamily。
- **颜色 / 圆角 / 间距 / 阴影**：用 `UdsColors` / `UdsRadii` / `UdsSpacing` / `UdsElevation`。
- **主题**：通过 `UdsTheme.light()/dark()` 与 `context.uds`（ThemeExtension）。
- **弹层遮罩**：统一 `UdsColors.scrim`（勿用 `Colors.black54`）。
- **组件**：优先 `UdsButton` / `UdsTextField` / `UdsChip` / `UdsCard` / `UdsPageHeader` / `UdsEmptyState` / `UdsLoading` / `showUdsConfirmSheet` 等。
- **宽屏**：表单与设置页可用 `UdsContentConstrained` 限制最大内容宽。

存量代码可通过 `AppTheme` 静态别名过渡，新代码直接依赖本包。
