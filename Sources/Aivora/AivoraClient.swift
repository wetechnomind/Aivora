//
//  AivoraClient.swift
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

/// The `AivoraClient` class serves as the **core networking engine** for the Aivora framework.
///
/// It is designed to handle all aspects of network communication, including:
/// - Request execution and decoding
/// - Caching and retry logic
/// - Multipart uploads with progress tracking
/// - Integration with reachability, adapters, loggers, and offline queues
///
/// The client is lightweight, asynchronous (using Swift Concurrency),
/// and built to be easily extendable for custom behaviors.
public final class AivoraClient {

    // MARK: - Configuration Structure

    /// Configuration object defining base URL, default headers, and timeout settings.
    public struct Configuration {
        /// The base URL for all requests (optional).
        public var baseURL: URL?

        /// Default headers applied to every outgoing request.
        public var defaultHeaders: [String: String]

        /// Timeout interval for requests, in seconds.
        public var timeout: TimeInterval

        /// Creates a new configuration instance.
        ///
        /// - Parameters:
        ///   - baseURL: Optional base API URL.
        ///   - defaultHeaders: Common headers for all requests.
        ///   - timeout: Timeout duration for network calls (default = 60 seconds).
        public init(baseURL: URL? = nil,
                    defaultHeaders: [String: String] = [:],
                    timeout: TimeInterval = 60) {
            self.baseURL = baseURL
            self.defaultHeaders = defaultHeaders
            self.timeout = timeout
        }
    }

    // MARK: - Core Properties

    /// The underlying `URLSession` instance used for network operations.
    internal let session: URLSession

    /// Stores configuration details such as base URL and default headers.
    public var configuration: Configuration

    /// Centralized logging utility shared across Aivora.
    public let logger = AivoraLogger.shared

    /// Manages automatic retry behavior for failed network calls.
    public let retryPolicy = AivoraRetryPolicy()

    /// In-memory cache used to store decoded responses for performance.
    public let cache = AivoraCache.shared

    /// Optional adapter that can modify or enrich outgoing requests.
    public let adapter: AivoraRequestAdapter?

    // MARK: - Initialization

    /// Initializes an `AivoraClient` instance.
    ///
    /// - Parameters:
    ///   - configuration: The configuration object (base URL, headers, etc.).
    ///   - adapter: Optional request adapter for custom modification of requests.
    ///   - urlSession: Custom `URLSession` instance; defaults to system configuration.
    public init(configuration: Configuration = .init(),
                adapter: AivoraRequestAdapter? = nil,
                urlSession: URLSession? = nil) {
        self.configuration = configuration
        self.adapter = adapter

        // Create and configure the URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.timeout
        self.session = urlSession ?? URLSession(configuration: config)

        // Start reachability monitoring to track network availability
        AivoraReachability.shared.start()

        // Bind this client to the offline queue so queued requests can execute later
        AivoraOfflineQueue.shared.client = self
    }

    // MARK: - Generic Request Execution

    /// Executes a network request and decodes its response into a given `Decodable` type.
    ///
    /// This function performs:
    /// - Request adaptation (if an adapter is provided)
    /// - Cache lookup and validation
    /// - Actual network call execution
    /// - Response decoding and caching
    ///
    /// - Parameter endpoint: The request definition (`AivoraRequest`).
    /// - Returns: A decoded object of the specified type `T`.
    /// - Throws: `AivoraError` for network, decoding, or server issues.
    public func request<T: Decodable>(_ endpoint: AivoraRequest) async throws -> T {
        // Apply request adapter if available
        let adapted = try await adapter?.adapt(endpoint) ?? endpoint
        let cacheKey = adapted.cacheKey

        // ✅ Step 1: Attempt to retrieve a cached response before performing the network call
        if let cached = cache.value(forKey: cacheKey) as? T {
            logger.log(.info, "Cache hit: \(cacheKey)")
            return cached
        }

        // ✅ Step 2: Perform actual network call
        let (data, response) = try await perform(adapted)

        // Ensure a valid HTTP response
        guard let http = response as? HTTPURLResponse else {
            throw AivoraError.unknown
        }

        // ✅ Step 3: Decode and cache successful responses
        if (200..<300).contains(http.statusCode) {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            cache.set(value: decoded as AnyObject, forKey: cacheKey)
            return decoded
        } else {
            // ⚠️ Handle non-success HTTP responses
            throw AivoraError.server(statusCode: http.statusCode, data: data, response: http)
        }
    }

    // MARK: - Internal Request Performer

    /// Performs the actual URLSession request for the provided endpoint.
    ///
    /// This method:
    /// - Builds the final `URLRequest` using base URL and headers.
    /// - Merges default headers with request-specific headers.
    /// - Logs outgoing requests.
    /// - Executes the request through the retry policy for reliability.
    ///
    /// - Parameter endpoint: The configured `AivoraRequest`.
    /// - Returns: A tuple `(Data, URLResponse)` upon successful completion.
    private func perform(_ endpoint: AivoraRequest) async throws -> (Data, URLResponse) {
        // Build the final URLRequest (resolves relative paths using baseURL)
        var urlRequest = try endpoint.asURLRequest(baseURL: configuration.baseURL)

        // Merge default headers if not already set
        for (key, value) in configuration.defaultHeaders where urlRequest.value(forHTTPHeaderField: key) == nil {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Log the outgoing request for debugging and analytics
        logger.log(.debug, "→ \(urlRequest.httpMethod ?? "REQ") \(urlRequest.url?.absoluteString ?? "")")

        // Execute the request using the retry policy
        return try await retryPolicy.execute { [session] in
            try await session.data(for: urlRequest)
        }
    }

    // MARK: - Multipart Uploads

    /// Handles multipart uploads (e.g., file uploads) with progress tracking and decoding.
    ///
    /// This function:
    /// - Builds a multipart request
    /// - Tracks upload progress
    /// - Decodes the server’s response upon completion
    ///
    /// - Parameters:
    ///   - endpoint: Multipart request containing form data and files.
    ///   - progress: Closure called with upload progress (0.0–1.0).
    /// - Returns: A decoded object of type `T` if successful.
    /// - Throws: `AivoraError` on network or decoding failures.
    public func uploadMultipart<T: Decodable>(
        _ endpoint: AivoraMultipartRequest,
        progress: @escaping (Double) -> Void
    ) async throws -> T {

        // Prepare the multipart URLRequest (includes bodyData)
        let urlRequest = try endpoint.asURLRequest(baseURL: configuration.baseURL)

        // Use continuation to bridge async completion handler
        return try await withCheckedThrowingContinuation { continuation in
            // Create the upload task
            let task = session.uploadTask(with: urlRequest, from: endpoint.bodyData) { data, response, error in
                defer { progress(1.0) } // Ensure progress completes at the end

                // Handle client-side or network errors
                if let error = error {
                    continuation.resume(throwing: AivoraError.network(error))
                    return
                }

                // Ensure valid response and data
                guard let data = data, let http = response as? HTTPURLResponse else {
                    continuation.resume(throwing: AivoraError.unknown)
                    return
                }

                // ✅ Successful response — attempt to decode
                if (200..<300).contains(http.statusCode) {
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        continuation.resume(returning: decoded)
                    } catch {
                        continuation.resume(throwing: AivoraError.decoding(error))
                    }
                } else {
                    // ⚠️ Server returned an error response
                    continuation.resume(
                        throwing: AivoraError.server(statusCode: http.statusCode, data: data, response: http)
                    )
                }
            }

            // Observe upload progress and report it on the main thread
            let observation = task.progress.observe(\.fractionCompleted) { prog, _ in
                DispatchQueue.main.async {
                    progress(prog.fractionCompleted)
                }
            }

            // Start the upload
            task.resume()

            // Clean up progress observation after the task completes or is canceled
            Task.detached {
                await withTaskCancellationHandler {
                    observation.invalidate()
                } onCancel: {}
            }
        }
    }
}
