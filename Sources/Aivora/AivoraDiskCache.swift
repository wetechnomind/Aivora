//
//  AivoraDiskCache.swift
//  Aivora
//
//  Copyright (c) 2025
//  Aivora Software Foundation (https://www.wetechnomind.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

// MARK: - Overview
/// `AivoraDiskCache` is a lightweight, thread-safe, disk-based caching system.
///
/// It provides persistent storage of arbitrary binary data (`Data`) using JSON-encoded payloads.
/// Cached objects are written to the system cache directory and can be automatically expired or size-limited.
///
/// ### Key Features
/// - ⚡ **Thread-safe concurrent reads / barrier-protected writes**
/// - ⏱️ **Optional TTL (time-to-live) expiration**
/// - 💾 **Automatic cache directory management**
/// - 🧹 **Background cleanup and disk size enforcement**
///
/// ### Example
/// ```swift
/// // Store data with 5-minute expiry
/// AivoraDiskCache.shared.set(data: jsonData, forKey: "user-profile", ttl: 300)
///
/// // Retrieve cached entry
/// if let cached = AivoraDiskCache.shared.get(forKey: "user-profile") {
///     print("Loaded from disk cache!")
/// }
/// ```
public final class AivoraDiskCache {

    // MARK: - Singleton Instance
    /// The shared global instance of the disk cache.
    public static let shared = AivoraDiskCache()

    // MARK: - Private Properties
    private let directory: URL
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "Aivora.diskcache.queue", attributes: .concurrent)

    // MARK: - Configuration
    /// Maximum allowed cache size in bytes.
    /// Defaults to **50 MB**. Exceeding this limit triggers automatic cleanup.
    public var maxCacheSize: Int = 50 * 1024 * 1024

    // MARK: - Initialization
    /// Creates a new disk cache instance and ensures the cache directory exists.
    /// Access the shared singleton via `AivoraDiskCache.shared`.
    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())

        directory = caches.appendingPathComponent("AivoraDiskCache")
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }

    // MARK: - Internal Helpers
    /// Generates a safe file URL for a given cache key by Base64-encoding it.
    private func fileURL(for key: String) -> URL {
        var safe = Data(key.utf8).base64EncodedString()
        safe = safe.replacingOccurrences(of: "/", with: "_")
        return directory.appendingPathComponent(safe)
    }

    // MARK: - Write Cache
    /// Stores data on disk for a given cache key.
    ///
    /// Thread-safe and performed asynchronously on a concurrent queue.
    ///
    /// - Parameters:
    ///   - data: The raw `Data` to store.
    ///   - key: A unique string key identifying the cached object.
    ///   - ttl: Optional time-to-live (in seconds). Expired entries are purged automatically.
    public func set(data: Data, forKey key: String, ttl: TimeInterval? = nil) {
        queue.async(flags: .barrier) {
            var payload: [String: Any] = ["data": data.base64EncodedString()]
            if let ttl = ttl {
                payload["expiry"] = Date().addingTimeInterval(ttl).timeIntervalSince1970
            }

            guard let json = try? JSONSerialization.data(withJSONObject: payload, options: []) else { return }
            try? json.write(to: self.fileURL(for: key), options: .atomic)
        }
    }

    // MARK: - Read Cache
    /// Retrieves cached data for the specified key, validating TTL if present.
    ///
    /// - Parameter key: The unique cache key.
    /// - Returns: The cached `Data` if valid and not expired, or `nil` otherwise.
    @discardableResult
    public func get(forKey key: String) -> Data? {
        let url = fileURL(for: key)

        guard let json = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            return nil
        }

        // Check expiry
        if let expiry = object["expiry"] as? TimeInterval,
           Date().timeIntervalSince1970 > expiry {
            try? fileManager.removeItem(at: url)
            return nil
        }

        // Decode Base64 payload
        if let b64 = object["data"] as? String,
           let data = Data(base64Encoded: b64) {
            return data
        }
        return nil
    }

    // MARK: - Existence Check
    /// Determines whether a cached object exists for the specified key.
    ///
    /// - Parameter key: The cache key to check.
    /// - Returns: `true` if the cache file exists; otherwise, `false`.
    public func exists(forKey key: String) -> Bool {
        fileManager.fileExists(atPath: fileURL(for: key).path)
    }

    // MARK: - Remove Cache
    /// Removes the cached entry for the specified key.
    ///
    /// - Parameter key: The key of the cache entry to remove.
    public func remove(forKey key: String) {
        queue.async(flags: .barrier) {
            try? self.fileManager.removeItem(at: self.fileURL(for: key))
        }
    }

    // MARK: - Clear All
    /// Clears the entire disk cache by deleting all stored files.
    ///
    /// A new cache directory is automatically recreated after clearing.
    public func clear() {
        queue.async(flags: .barrier) {
            try? self.fileManager.removeItem(at: self.directory)
            try? self.fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Expiry Cleanup
    /// Scans the cache directory asynchronously and removes all expired files.
    ///
    /// Expiry metadata is stored in each cached file’s JSON payload.
    public func cleanupExpired() {
        queue.async {
            guard let files = try? self.fileManager.contentsOfDirectory(at: self.directory, includingPropertiesForKeys: nil)
            else { return }

            for file in files {
                guard
                    let data = try? Data(contentsOf: file),
                    let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let expiry = obj["expiry"] as? TimeInterval
                else { continue }

                if Date().timeIntervalSince1970 > expiry {
                    try? self.fileManager.removeItem(at: file)
                }
            }
        }
    }

    // MARK: - Disk Size Enforcement
    /// Enforces the configured `maxCacheSize` limit.
    ///
    /// If the total size exceeds the threshold, the oldest cache files
    /// (based on modification date) are deleted until the limit is satisfied.
    public func enforceSizeLimit() {
        queue.async(flags: .barrier) {
            guard let files = try? self.fileManager.contentsOfDirectory(
                at: self.directory,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
            ) else { return }

            var fileData: [(URL, Date, Int)] = []
            var totalSize = 0

            // Collect file metadata
            for url in files {
                let attrs = try? self.fileManager.attributesOfItem(atPath: url.path)
                let date = attrs?[.modificationDate] as? Date ?? .distantPast
                let size = attrs?[.size] as? Int ?? 0
                fileData.append((url, date, size))
                totalSize += size
            }

            // Exit if below limit
            guard totalSize > self.maxCacheSize else { return }

            // Delete oldest files first
            for (url, _, size) in fileData.sorted(by: { $0.1 < $1.1 }) {
                try? self.fileManager.removeItem(at: url)
                totalSize -= size
                if totalSize <= self.maxCacheSize { break }
            }
        }
    }
}
