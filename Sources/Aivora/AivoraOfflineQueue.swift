//
// AivoraOfflineQueue.swift
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

/// A singleton queue manager that stores and executes network tasks when the device is offline.
///
/// `AivoraOfflineQueue` provides an offline-safe mechanism for temporarily queuing
/// async tasks (typically network calls) and executing them later once the app is online.
/// It’s primarily designed to support background recovery or deferred synchronization.
///
/// Example:
/// ```swift
/// AivoraOfflineQueue.shared.enqueue {
///     await client.sendDataToServer()
/// }
/// AivoraOfflineQueue.shared.flush()
/// ```
public final class AivoraOfflineQueue {
    
    /// Shared singleton instance for global access.
    public static let shared = AivoraOfflineQueue()
    
    /// Internal queue storing suspended async tasks to be executed later.
    internal var queue: [() async -> Void] = []
    
    /// Reference to the `AivoraClient` responsible for handling requests.
    public weak var client: AivoraClient?

    /// Private initializer to prevent external instantiation.
    private init() {}

    // MARK: - Queue Management
    
    /// Adds a new asynchronous job to the offline queue.
    ///
    /// Use this method to enqueue a task that should run later
    /// (for example, when network connectivity is restored).
    ///
    /// - Parameter job: The async closure to execute when flushing the queue.
    public func enqueue(_ job: @escaping () async -> Void) {
        queue.append(job)
    }

    /// Executes all queued jobs and clears the queue.
    ///
    /// Each queued job is executed asynchronously on a new task.
    /// If the queue is empty, this method exits silently.
    public func flush() {
        guard !queue.isEmpty else { return }
        let jobs = queue
        queue.removeAll()
        for job in jobs {
            Task { await job() }
        }
    }
}
