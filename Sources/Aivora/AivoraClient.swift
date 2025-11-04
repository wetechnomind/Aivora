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
    /// Encapsulates all configurable properties for `AivoraClient`.
    /// Includes base URL, default headers, and request timeout.
    public struct Configuration {
        public var baseURL: URL?                  // Base API endpoint
        public var defaultHeaders: [String: String] // Default headers applied to all requests
        public var timeout: TimeInterval           // Request timeout duration

        /// Initializes a new configuration instance.
        public init(baseURL: URL? = nil,
                    defaultHeaders: [String: String] = [:],
                    timeout: TimeInterval = 60) {
            self.baseURL = baseURL
            self.defaultHeaders = defaultHeaders
            self.timeout = timeout
        }
    }

    // MARK: - Core Properties

    internal let session: URLSession              // URLSession used for network communication
    public var configuration: Configuration       // Holds client configuration
    public let logger = AivoraLogger.shared       // Shared logger for debugging and analytics
    public let retryPolicy = AivoraRetryPolicy()  // Retry mechanism for transient failures
    public let cache = AivoraCache.shared         // In-memory/disk response caching
    public let adapter: AivoraRequestAdapter?     // Optional request adapter for custom modification

    // MARK: - Initialization

    /// Initializes the `AivoraClient` with optional configuration, adapter, and custom URLSession.
    public init(configuration: Configuration = .init(),
                adapter: AivoraRequestAdapter? = nil,
                urlSession: URLSession? = nil) {
        self.configuration = configuration
        self.adapter = adapter

        // Configure URLSession with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.timeout
        self.session = urlSession ?? URLSession(configuration: config)

        // Start reachability monitoring and bind offline queue to this client
        AivoraReachability.shared.start()
        AivoraOfflineQueue.shared.client = self
    }

    // MARK: - Generic Request Execution (Decoded Models)

    /// Executes a network request and decodes its response into a given `Decodable` type.
    ///
    /// Automatically checks the cache before performing the request,
    /// logs activity, and handles server errors gracefully.
    public func request<T: Decodable>(_ endpoint: AivoraRequest) async throws -> T {
        // Apply any adapter transformation (e.g., adding auth headers)
        let adapted = try await adapter?.adapt(endpoint) ?? endpoint
        let cacheKey = adapted.cacheKey

        // Step 1: Check cache
        if let cached = cache.value(forKey: cacheKey) as? T {
            logger.log(.info, "Cache hit: \(cacheKey)")
            return cached
        }

        // Step 2: Perform request
        let (data, response) = try await perform(adapted)

        // Step 3: Validate HTTP response
        guard let http = response as? HTTPURLResponse else {
            throw AivoraError.unknown
        }

        // Step 4: Decode response if successful
        if (200..<300).contains(http.statusCode) {
            let decoded = try AivoraJSONDecoder.decode(T.self, from: data)
            cache.set(value: decoded as AnyObject, forKey: cacheKey)
            return decoded
        } else {
            //  Step 5: Throw server error for non-2xx status
            throw AivoraError.server(statusCode: http.statusCode, data: data, response: http)
        }
    }

    // MARK: - Raw Data Request Support

    /// Executes a network request and returns the raw `Data` response.
    ///
    /// Useful for endpoints that don’t return JSON (e.g., image downloads, binary files).
    public func requestData(_ endpoint: AivoraRequest) async throws -> Data {
        // Apply adapter modification if available
        let adapted = try await adapter?.adapt(endpoint) ?? endpoint
        let (data, response) = try await perform(adapted)

        // Validate HTTP response
        guard let http = response as? HTTPURLResponse else {
            throw AivoraError.unknown
        }

        // Return data for successful responses
        if (200..<300).contains(http.statusCode) {
            return data
        } else {
            // Throw server-side error with response details
            throw AivoraError.server(statusCode: http.statusCode, data: data, response: http)
        }
    }

    // MARK: - SON Body Encoding Support

    /// Executes a request with an `Encodable` JSON body and decodes a `Decodable` response.
    ///
    /// - Automatically encodes the body using `AivoraJSONEncoder`.
    /// - Adds `Content-Type: application/json` header if missing.
    public func request<Body: Encodable, Response: Decodable>(
        _ endpoint: AivoraRequest,
        body: Body
    ) async throws -> Response {
        var encodedEndpoint = endpoint
        // Encode request body as JSON
        encodedEndpoint.body = try AivoraJSONEncoder.encode(body)
        // Ensure correct content type header
        encodedEndpoint.headers["Content-Type"] = "application/json"
        // Delegate actual execution to the generic request method
        return try await request(encodedEndpoint)
    }

    // MARK: - Internal Request Performer

    /// Constructs and performs the actual network call.
    /// Handles header merging, retries, and logging.
    private func perform(_ endpoint: AivoraRequest) async throws -> (Data, URLResponse) {
        // Convert endpoint into a URLRequest (applies baseURL + parameters)
        var urlRequest = try endpoint.asURLRequest(baseURL: configuration.baseURL)

        // Merge default headers if not already present
        for (key, value) in configuration.defaultHeaders
        where urlRequest.value(forHTTPHeaderField: key) == nil {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Log outgoing request details
        logger.log(.debug, "→ \(urlRequest.httpMethod ?? "REQ") \(urlRequest.url?.absoluteString ?? "")")

        // Execute request with retry support
        return try await retryPolicy.execute { [session] in
            try await session.data(for: urlRequest)
        }
    }

    // MARK: - Multipart Uploads (with Progress Tracking)

    /// Performs a multipart/form-data upload with progress updates.
    ///
    /// Supports background upload progress tracking and JSON decoding on completion.
    public func uploadMultipart<T: Decodable>(
        _ endpoint: AivoraMultipartRequest,
        progress: @escaping (Double) -> Void
    ) async throws -> T {
        // Build multipart request
        let urlRequest = try endpoint.asURLRequest(baseURL: configuration.baseURL)

        return try await withCheckedThrowingContinuation { continuation in
            // Create upload task
            let task = session.uploadTask(with: urlRequest, from: endpoint.bodyData) { data, response, error in
                defer { progress(1.0) } // Ensure completion callback

                // Handle network-level errors
                if let error = error {
                    continuation.resume(throwing: AivoraError.network(error))
                    return
                }

                // Validate response and data
                guard let data = data, let http = response as? HTTPURLResponse else {
                    continuation.resume(throwing: AivoraError.unknown)
                    return
                }

                // Parse success responses
                if (200..<300).contains(http.statusCode) {
                    do {
                        let decoded = try AivoraJSONDecoder.decode(T.self, from: data)
                        continuation.resume(returning: decoded)
                    } catch {
                        // Handle JSON decoding error
                        continuation.resume(throwing: AivoraError.decodingFailed(error))
                    }
                } else {
                    // Handle server-side error
                    continuation.resume(
                        throwing: AivoraError.server(statusCode: http.statusCode, data: data, response: http)
                    )
                }
            }

            // Observe and report upload progress
            let observation = task.progress.observe(\.fractionCompleted) { prog, _ in
                DispatchQueue.main.async {
                    progress(prog.fractionCompleted)
                }
            }

            // Start upload task
            task.resume()

            // Clean up observation upon task cancellation
            Task.detached {
                await withTaskCancellationHandler {
                    observation.invalidate()
                } onCancel: {}
            }
        }
    }
}
