//
//  AivoraDownloadManager.swift
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

/// `AivoraDownloadManager` provides a robust and thread-safe file download manager
/// supporting background downloads, resume functionality, and progress tracking.
///
/// ### Features:
/// - ✅ Background downloads using `URLSessionConfiguration.background`
/// - 🔁 Resumable tasks via stored resume data
/// - 💾 Auto file relocation to `Documents/AivoraDownloads`
/// - 📊 Real-time progress updates through closures
/// - 🧩 Thread-safe access using a concurrent dispatch queue
public final class AivoraDownloadManager: NSObject, URLSessionDownloadDelegate {

    // MARK: - Singleton
    /// Shared global instance for managing all downloads.
    public static let shared = AivoraDownloadManager()

    // MARK: - Internal State
    private var backgroundSession: URLSession!
    
    /// Dictionary storing active download handlers, mapping each URL to its progress and completion closures.
    private var activeHandlers: [URL: (progress: ((Double) -> Void)?, completion: (URL?, Error?) -> Void)] = [:]
    
    /// Concurrent queue for thread-safe operations on `activeHandlers`.
    private let queue = DispatchQueue(label: "Aivora.download.manager", attributes: .concurrent)

    // MARK: - Initialization
    private override init() {
        super.init()

        // Create a unique identifier for the background session.
        let id = "com.Aivora.download.\(UUID().uuidString)"
        
        // Configure session for background downloads with proper timeout and network behavior.
        let config = URLSessionConfiguration.background(withIdentifier: id)
        config.httpMaximumConnectionsPerHost = 4
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 600
        config.allowsExpensiveNetworkAccess = true
        config.allowsCellularAccess = true

        // Initialize the background session with the current instance as the delegate.
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // MARK: - Public API

    /// Starts a new download task.
    ///
    /// - Parameters:
    ///   - url: The remote file URL to download.
    ///   - destination: Optional destination URL. Defaults to `Documents/AivoraDownloads`.
    ///   - progress: Closure for progress updates (0.0–1.0).
    ///   - completion: Closure called when the download completes or fails.
    /// - Returns: The created `URLSessionDownloadTask` instance.
    @discardableResult
    public func download(
        url: URL,
        to destination: URL? = nil,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping (URL?, Error?) -> Void
    ) -> URLSessionDownloadTask {

        let request = URLRequest(url: url)
        let task = backgroundSession.downloadTask(with: request)

        // Register handler closures in a thread-safe manner.
        queue.async(flags: .barrier) {
            self.activeHandlers[url] = (progress, completion)
        }

        task.resume()
        return task
    }

    /// Resumes a previously paused or failed download using stored resume data.
    ///
    /// - Parameter resumeData: The resume data from a cancelled task.
    /// - Returns: The resumed `URLSessionDownloadTask`, or `nil` if invalid.
    @discardableResult
    public func resume(with resumeData: Data) -> URLSessionDownloadTask? {
        let task = backgroundSession.downloadTask(withResumeData: resumeData)
        task.resume()
        return task
    }

    // MARK: - Resume Data Persistence

    /// Saves resume data for a given URL to disk for later use.
    public func saveResumeData(_ data: Data, for url: URL) {
        let key = url.absoluteString.data(using: .utf8)!.base64EncodedString()
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(key)
        try? data.write(to: path)
    }

    /// Loads resume data for a URL from disk if available.
    public func loadResumeData(for url: URL) -> Data? {
        let key = url.absoluteString.data(using: .utf8)!.base64EncodedString()
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(key)
        return try? Data(contentsOf: path)
    }

    /// Deletes stored resume data for a URL.
    public func removeResumeData(for url: URL) {
        let key = url.absoluteString.data(using: .utf8)!.base64EncodedString()
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(key)
        try? FileManager.default.removeItem(at: path)
    }

    // MARK: - URLSessionDownloadDelegate

    /// Called when a download finishes successfully and the file is temporarily stored.
    /// Moves the file to the permanent destination and triggers completion callback.
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let sourceURL = downloadTask.originalRequest?.url else { return }

        // Remove handler entry in a thread-safe manner.
        let handler = queue.sync(flags: .barrier) { activeHandlers.removeValue(forKey: sourceURL) }

        let fileManager = FileManager.default
        let destination: URL = {
            // Determine final destination directory (Documents/AivoraDownloads).
            let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dir = docs.appendingPathComponent("AivoraDownloads")
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent(sourceURL.lastPathComponent)
        }()

        do {
            // Remove any existing file at the same path and move the new one.
            try? fileManager.removeItem(at: destination)
            try fileManager.moveItem(at: location, to: destination)
            handler?.completion(destination, nil)
        } catch {
            handler?.completion(nil, error)
        }
    }

    /// Called periodically during download to report progress.
    /// Updates the registered progress closure for the current URL.
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let url = downloadTask.originalRequest?.url else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        // Trigger the progress closure safely from the concurrent queue.
        queue.sync {
            activeHandlers[url]?.progress?(progress)
        }
    }

    /// Called when a task completes (successfully or with an error).
    /// If failed, it saves resume data for later continuation.
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let url = task.originalRequest?.url else { return }

        // If download was interrupted, save the resume data for continuation.
        if let err = error as NSError?,
           let resumeData = err.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            saveResumeData(resumeData, for: url)
        }

        // Clean up the handler and invoke completion with the error.
        let handler = queue.sync(flags: .barrier) { activeHandlers.removeValue(forKey: url) }
        handler?.completion(nil, error)
    }
}
