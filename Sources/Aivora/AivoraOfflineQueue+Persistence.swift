//
// AivoraOfflineQueue+Persistence.swift
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

/// Extension to `AivoraOfflineQueue` adding basic persistence functionality.
///
/// This extension provides a simple simulation of offline queue persistence.
/// Since Swift closures cannot be directly serialized, the implementation
/// saves placeholder identifiers instead of actual queued jobs.
/// The persistence system is designed for extensibility — future versions
/// may store serializable metadata or request representations.
public extension AivoraOfflineQueue {
    
    /// The file URL where the offline queue data will be persisted.
    ///
    /// Stored under the app's cache directory as `Aivora_offline_queue.json`.
    private static var storageURL: URL {
        let fm = FileManager.default
        let dir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("Aivora_offline_queue.json")
    }

    // MARK: - Persistence
    
    /// Persists the current offline queue to disk.
    ///
    /// Since closures cannot be serialized in Swift, this function writes
    /// an array of randomly generated UUID strings as placeholders for each
    /// queued task. The actual jobs are **not restored**, only simulated.
    ///
    /// Example output file content:
    /// ```json
    /// ["8B6D3A8E-3C91-4207-95B9-B0BFE9E7341D", "C54B43C0-F951-4387-A2C2-505F6535B2F1"]
    /// ```
    public func persist() {
        // ⚙️ Placeholder: since closures can’t be serialized, we just simulate persistence.
        let arr: [String] = queue.map { _ in UUID().uuidString }

        do {
            let data = try JSONSerialization.data(withJSONObject: arr)
            try data.write(to: Self.storageURL)
        } catch {
            print("[Aivora][OfflineQueue] Persist error:", error)
        }
    }

    /// Restores the simulated offline queue data from disk.
    ///
    /// This method only loads placeholder identifiers to confirm that
    /// previously persisted jobs existed. It does **not** recreate closures,
    /// since closures cannot be deserialized. This provides a safe mock
    /// mechanism for debugging and offline testing.
    public func restore() {
        guard FileManager.default.fileExists(atPath: Self.storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: Self.storageURL)
            let arr = try JSONSerialization.jsonObject(with: data) as? [String]
            print("[Aivora][OfflineQueue] Restored placeholders:", arr ?? [])
        } catch {
            print("[Aivora][OfflineQueue] Restore error:", error)
        }
    }
}
