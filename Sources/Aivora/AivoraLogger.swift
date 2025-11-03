//
// AivoraLogger.swift
// Aivora

// Copyright (c) 2025 Aivora Software Foundation (https://www.wetechnomind.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

/// Represents the severity level of a log message.
///
/// Each level defines the importance and purpose of a log.
/// Used internally by `AivoraLogger` to categorize log outputs.
///
/// - debug: Low-level debugging information, typically for development.
/// - info: General information about normal app flow.
/// - warning: Indicates potential issues or unexpected states.
/// - error: Critical errors or failed operations.
public enum AivoraLogLevel: Int {
    case debug, info, warning, error
}

/// A lightweight and thread-safe logger used throughout the Aivora SDK.
///
/// `AivoraLogger` provides a unified way to output log messages with different
/// levels of severity. It can be toggled on or off globally via the `enabled` flag.
///
/// ### Features:
/// - ✅ Simple, lightweight, and dependency-free.
/// - 🧩 Supports multiple log levels (`debug`, `info`, `warning`, `error`).
/// - 🛑 Easily disabled for production builds.
/// - 📄 Prints formatted messages with `[Aivora]` prefixes.
///
/// ### Example:
/// ```swift
/// AivoraLogger.shared.log(.info, "Aivora initialized successfully.")
/// AivoraLogger.shared.log(.error, "Failed to parse response data.")
/// ```
public final class AivoraLogger {
    /// Shared singleton instance for global logging.
    public static let shared = AivoraLogger()

    /// Private initializer to prevent direct instantiation.
    private init() {}

    /// Enables or disables all logging globally.
    ///
    /// Set this to `false` to silence all Aivora log output.
    public var enabled: Bool = true
    
    /// The current minimum log level. Messages below this are ignored.
    public var level: AivoraLogLevel = .debug

    /// Logs a message at the specified log level.
    ///
    /// - Parameters:
    ///   - level: The `AivoraLogLevel` to categorize the message.
    ///   - message: The log message to display.
    ///
    /// Example:
    /// ```swift
    /// AivoraLogger.shared.log(.debug, "Cache miss for key: \(key)")
    /// ```
    public func log(_ level: AivoraLogLevel, _ message: String) {
        guard enabled else { return }
        guard level.rawValue >= self.level.rawValue else { return }

        let prefix: String
        switch level {
        case .debug: prefix = "[Aivora][DEBUG]"
        case .info: prefix = "[Aivora][INFO]"
        case .warning: prefix = "[Aivora][WARN]"
        case .error: prefix = "[Aivora][ERROR]"
        }

        print("\(prefix) \(message)")
    }
}
