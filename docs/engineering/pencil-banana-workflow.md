# Pencil 原型占位图生成流程

Claude（Opus 4.6）分析 Pencil 中的 mock 原型，识别图片/图标占位符，并在终端用 **zenmux-nano2**（ZenMux Google Nano Banana 2）为每个占位符生成图片。

## 流程概要

1. **获取原型**：通过 Pencil MCP（如 `get_screenshot`）或用户提供的截图/`.pen` 文件拿到当前界面。
2. **识别占位符**：分析哪些元素是图片占位符或图标（头像、卡片图、空状态图、Tab 图标等）。
3. **终端生成**：对每个占位符在项目终端执行：
   ```bash
   source ~/.zshrc   # 若尚未加载
   zenmux-nano2 "英文描述提示词" "assets/输出文件名.png"
   ```
4. **确认与替换**：生成完成后列出文件与对应位置，便于在 Pencil 或代码中替换。

## 终端命令说明

| 命令 | 说明 |
|------|------|
| `zenmux-nano2 "prompt" [output.png]` | 使用 ZenMux Nano Banana 2 生成图片，默认输出 `nano-banana-2.png` |
| 提示词 | 建议用英文、具体（如 "minimal avatar placeholder, neutral gray background"） |
| 输出路径 | 建议 `assets/placeholder-{页面}-{用途}.png` 或 `assets/icons/{名称}.png` |

## 相关配置

- 规则：`.cursor/rules/pencil-mockup-to-banana.mdc`（在编辑 `.pen`、`docs/`、`assets/` 时生效）
- 模型：ZenMux `google/gemini-2.5-flash-image`（Nano Banana 2）
- 环境：`~/.zshrc` 中的 `ZENMUX_API_KEY`、`zenmux-nano2` 函数
