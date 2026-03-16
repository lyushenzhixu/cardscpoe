# Git Worktree 可直接用的命令（cardscpoe）

在项目根目录执行：`cd /Users/reversegame/Documents/cardscpoe` 后再跑下面命令。

---

## 1. 新分支 + 新 worktree（常用）

从当前 `main` 拉一个新分支，并在同级目录开一个工作区：

```bash
# 功能分支：在 ../cardscpoe-feature-explore 里做 Explore 相关开发
git worktree add -b feature/explore ../cardscpoe-feature-explore

# 重构分支：在 ../cardscpoe-refactor-services 里动 Services 层
git worktree add -b refactor/services ../cardscpoe-refactor-services

# 文档/实验分支：在 ../cardscpoe-docs 里写文档或试新依赖
git worktree add -b docs/product ../cardscpoe-docs
```

---

## 2. 已有分支检出到新目录

不新建分支，只把远程已有分支拉到一个新目录：

```bash
# 在 ../cardscpoe-cardscope 里做 cardscope 相关（对应远程 cursor/cardscope-d430）
git worktree add ../cardscpoe-cardscope cursor/cardscope-d430

# 在 ../cardscpoe-swiftui 里做 SwiftUI 相关（对应远程 cursor/cardscope-swiftui-7e3b）
git worktree add ../cardscpoe-swiftui cursor/cardscope-swiftui-7e3b
```

---

## 3. 查看与清理

```bash
# 列出所有 worktree
git worktree list

# 删掉某个 worktree（先 cd 到别的目录再执行）
git worktree remove ../cardscpoe-feature-explore

# 已手动删除了目录时，清理记录
git worktree prune
```

---

## 4. 使用流程示例

```bash
cd /Users/reversegame/Documents/cardscpoe

# 加一个 worktree
git worktree add -b feature/explore ../cardscpoe-feature-explore

# 主目录继续在 main 修 bug
# 新目录专门做 feature
cd ../cardscpoe-feature-explore
# ... 编辑、git add、git commit ...

# 做完后删除 worktree（在任意非该目录下执行）
cd /Users/reversegame/Documents/cardscpoe
git worktree remove ../cardscpoe-feature-explore
# 分支 feature/explore 还在，可 push 或合并
```
