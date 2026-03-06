# Git 提交信息规范指南

## 概述

为了保持代码库的整洁和可维护性，我们采用统一的 Git 提交信息格式。所有提交信息都应遵循 `[TAG] description` 的格式。

## 标签类型

### [FEAT] - 新功能
用于添加新功能或特性。

**示例:**
```
[FEAT] add user authentication system
[FEAT] implement dark mode toggle
[FEAT] add export to PDF functionality
```

### [FIX] - 修复
用于修复bug、错误或问题。

**示例:**
```
[FIX] resolve null pointer exception in login module
[FIX] correct memory leak in image processing
[FIX] fix broken build on Windows platform
```

### [DOCS] - 文档
用于文档更新、注释或README修改。

**示例:**
```
[DOCS] update API documentation for v2.0
[DOCS] add installation guide
[DOCS] fix typos in README.md
```

### [STYLE] - 代码风格
用于代码格式化、风格调整，不影响功能。

**示例:**
```
[STYLE] format code according to PEP8 standards
[STYLE] fix indentation in config files
[STYLE] remove unused imports
```

### [REFACTOR] - 重构
用于代码重构，不添加新功能也不修复bug。

**示例:**
```
[REFACTOR] simplify authentication logic
[REFACTOR] extract common functions to utils module
[REFACTOR] optimize database queries
```

### [TEST] - 测试
用于添加或修改测试代码。

**示例:**
```
[TEST] add unit tests for user model
[TEST] update integration tests for API endpoints
[TEST] fix failing test cases
```

### [CHORE] - 维护
用于构建工具、配置或辅助文件的修改。

**示例:**
```
[CHORE] update dependencies to latest versions
[CHORE] configure CI/CD pipeline
[CHORE] add gitignore rules
```

### [PERF] - 性能优化
专门用于性能改进。

**示例:**
```
[PERF] optimize database query performance
[PERF] reduce memory usage in image processing
[PERF] improve loading speed of main page
```

### [BREAKING] - 破坏性更改
用于不向后兼容的重大更改。

**示例:**
```
[BREAKING] remove deprecated API endpoints
[BREAKING] change function signature for better usability
[BREAKING] update minimum Node.js version requirement
```

## 提交信息格式

### 基本格式
```
[TAG] 简洁明了的描述

可选的详细说明...
```

### 详细说明
- 对于复杂的更改，可以添加多行详细说明
- 解释更改的原因和影响
- 如果有关联的issue，可以提及issue编号

**示例:**
```
[FIX] resolve memory leak in image processing

- Fixed memory leak in JPEG decoder
- Added proper cleanup in error paths
- Related to issue #123
```

### 特殊情况
- **多个标签**: 如果一个提交涉及多种类型的更改，使用主要标签
- **紧急修复**: 可以添加 `HOTFIX` 前缀，如 `[HOTFIX][FIX] critical security patch`
- **撤销**: 使用 `[REVERT]` 标签

## 最佳实践

### ✅ 好的提交信息
```
[FIX] alientek_tf-a build system improvements

- Fix stm32wrapper4dbg tool paths in Makefile.sdk
- Add missing -d parameter in wrapper tool call
- Add .gitignore and build.sh for better development experience
```

```
[FEAT] add tool stm32wrapper4dbg

Add STM32 wrapper tool for debugging with CMake build system
and proper .gitignore configuration.
```

### ❌ 不好的提交信息
```
fix bug
update
changes
```

### 提交前的检查清单
- [ ] 标签是否正确？
- [ ] 描述是否清晰简洁？
- [ ] 是否包含必要的详细信息？
- [ ] 拼写是否正确？
- [ ] 是否遵循了项目规范？

## 工具推荐

### 自动格式化提交信息
```bash
# 使用 git commit 时添加模板
git config commit.template .git-commit-template
```

### 提交信息检查钩子
可以设置 pre-commit 钩子来检查提交信息格式。

## 相关链接

- [Conventional Commits](https://conventionalcommits.org/)
- [Git 最佳实践](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project)

---

*本规范基于项目需求制定，如有疑问请随时讨论改进。*