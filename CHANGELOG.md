# 📝 CHANGELOG
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] – 2025-11-01
### 🚀 Initial Release – Aivora v1.0.0

**Aivora** is a pure Swift Concurrency–based networking engine — a modern replacement for Alamofire, built for async/await.

### ✨ Added
- Full HTTP method support: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- SmartRequest Engine – automatic configuration for requests
- Auto-Decoding – Codable + nested model decoding
- Smart Error System – descriptive, developer-friendly error handling
- Retry Logic – built-in automatic retry with exponential backoff
- Caching System – memory + disk caching with TTL support
- Advanced Logging – request/response summaries and timing
- Multipart Uploads – async uploads with progress tracking
- File Downloads – resumable and background download support
- Network Reachability – with automatic requeue when back online
- Offline Queue – offline-safe request queueing
- Adapters & Interceptors – including token refresh interceptor
- Progress Tracking – upload & download progress callbacks
- AI Insights (placeholder) – detects slow endpoints (coming in v1.1.0)
- Platform Support – iOS, macOS, watchOS, tvOS
- MIT License – fully open source

### 🧠 Internal Improvements
- Refactored with modular architecture for scalability
- Added DocC documentation support
- GitHub Actions CI integrated (swift build + swift test)
- Added example projects (UIKit + SwiftUI)
- Created unit test suite for core components

### 🔜 Planned for v1.1.0
- AI Insights engine (automatic endpoint analysis)
- Disk persistence improvements for cache
- Interceptor chain enhancement
- Background download queue

**Author:** WeTechnoMind
**Date:** November 1, 2025
**License:** MIT
