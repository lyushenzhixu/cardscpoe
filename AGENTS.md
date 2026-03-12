# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview
This is a native iOS/iPadOS SwiftUI app (`cardscpoe`) created with Xcode 26.3, targeting iOS 26.2. It is a single-target Xcode project with no external dependencies (no SPM packages, CocoaPods, or Carthage).

### Platform Limitation
This project **requires macOS with Xcode 26.3+** to build, run, and fully test. The Cloud Agent Linux VM cannot:
- Build the iOS app (requires Xcode + iOS SDK)
- Run the iOS Simulator (requires macOS)
- Type-check Swift files that `import SwiftUI` (SwiftUI is Apple-only)

### Available Tooling on Linux

| Tool | Location | Purpose |
|------|----------|---------|
| Swift 6.0.3 | `/opt/swift/usr/bin/swift` | Syntax parsing (`swiftc -parse`) |
| SwiftLint 0.63.2 | `/usr/local/bin/swiftlint` | Linting Swift code |

### Lint
```bash
LINUX_SOURCEKIT_LIB_PATH="/opt/swift/usr/lib" swiftlint lint cardscpoe/
```
Note: The existing `cardscpoeApp` type name triggers a `type_name` violation (lowercase start) — this is from the default Xcode template and is expected.

### Syntax Validation
```bash
swiftc -parse cardscpoe/ContentView.swift cardscpoe/cardscpoeApp.swift
```
This validates Swift syntax only. Full type-checking (`swiftc -typecheck`) fails because `SwiftUI` module is unavailable on Linux.

### Environment Variables
- `PATH` includes `/opt/swift/usr/bin` (set in `~/.bashrc`)
- `LINUX_SOURCEKIT_LIB_PATH=/opt/swift/usr/lib` (required by SwiftLint, set in `~/.bashrc`)
