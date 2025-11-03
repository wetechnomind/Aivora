# 🤝 Contributing to Aivora

Welcome to **Aivora – The Modern Swift Networking Engine**!  
We’re thrilled that you’re interested in contributing to this project.  
Your help is what makes Aivora better for everyone. 🚀

---

## 📋 Table of Contents

1. [Code of Conduct](#-code-of-conduct)
2. [How to Contribute](#-how-to-contribute)
3. [Development Setup](#-development-setup)
4. [Coding Standards](#-coding-standards)
5. [Commit Guidelines](#-commit-guidelines)
6. [Testing](#-testing)
7. [Submitting a Pull Request](#-submitting-a-pull-request)
8. [Reporting Issues](#-reporting-issues)
9. [Feature Requests](#-feature-requests)
10. [Questions](#-questions)

---

## 🌈 Code of Conduct

Please note that this project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/).  
By participating, you agree to uphold this standard of respect and inclusion.

---

## 🛠 How to Contribute

There are many ways to contribute:

- 🐞 Report bugs and crashes  
- 💡 Suggest new features  
- 🧪 Write tests and improve coverage  
- 📖 Improve documentation  
- ⚙️ Optimize performance or fix typos

If you’re new to open-source, no worries! Just follow the steps below.

---

## 🧰 Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/WeTechnoMind/Aivora.git
   cd Aivora
   ```

2. **Open in Xcode**
   ```bash
   open Package.swift
   ```

3. **Build and run tests**
   ```bash
   swift build
   swift test
   ```

---

## 🧾 Coding Standards

To maintain a consistent and professional codebase:

- Prefix all public classes with `Aivora` (e.g., `AivoraClient`, `AivoraRequest`).
- Follow Swift API Design Guidelines.
- Prefer `async/await` over completion handlers.
- Use descriptive variable and function names.
- Keep code lightweight and dependency-free (Foundation only).
- Add documentation comments (`///`) for public APIs.

---

## 🧱 Commit Guidelines

Follow a clear commit message format:

| Type | Description |
|------|--------------|
| `feat:` | New feature (e.g., `feat: add caching layer`) |
| `fix:` | Bug fix (e.g., `fix: retry logic crash on timeout`) |
| `docs:` | Documentation updates |
| `test:` | Add or modify tests |
| `refactor:` | Code improvement without new features |
| `style:` | Formatting or naming changes |
| `chore:` | Non-code changes (build, CI, etc.) |

Example:
```bash
git commit -m "feat: add resumable file download support"
```

---

## 🧪 Testing

Before submitting code, always run:
```bash
swift test
```

✅ Ensure all tests pass.  
✅ Add new tests for new features.  
✅ Keep tests inside `Tests/AivoraTests/`.

---

## 🚀 Submitting a Pull Request

1. Fork the repository.  
2. Create a feature branch:
   ```bash
   git checkout -b feature/my-feature
   ```
3. Commit and push your changes:
   ```bash
   git commit -m "feat: describe your change"
   git push origin feature/my-feature
   ```
4. Open a Pull Request against the `main` branch.

The team will review and provide feedback as soon as possible.

---

## 🐞 Reporting Issues

Use the [GitHub Issues](https://github.com/WeTechnoMind/Aivora/issues) page to report bugs.  
Include the following:
- A clear title and description.
- Steps to reproduce.
- Expected vs actual behavior.
- Environment (iOS version, Xcode, Swift version).

---

## 💡 Feature Requests

We welcome feature ideas!  
Before submitting, check if the feature already exists or is being discussed.

If not, open a new issue labeled `enhancement` and describe your idea clearly.

---

## 💬 Questions

If you have any questions, reach out via:
- GitHub Discussions
- Website: [https://www.wetechnomind.com](https://www.wetechnomind.com)

---

## ❤️ A Note from the Author

Crafted with passion by **WeTechnoMind**  
Made with ❤️ in Swift — lightweight, fast, and ready for modern apps.
