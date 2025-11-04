//
//  AivoraClient+Extensions.swift
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

/// Extension to `AivoraClient` that adds enhanced request capabilities,
/// including progress tracking, disk caching, and intelligent token refresh.
public extension AivoraClient {

    /// Executes a network request with disk + memory cache support and progress tracking.
    public func requestWithProgress<T: Decodable>(
        _ endpoint: AivoraRequest,
        progress: @escaping (Double) -> Void
    ) async throws -> T {

        // Adapt the endpoint first (adapter may add auth headers, etc.)
        var adapted = try await adapter?.adapt(endpoint) ?? endpoint
        let cacheKey = adapted.cacheKey

        // MARK: - Memory Cache Check
        if let cached: T = (cache.value(forKey: cacheKey) as? T) {
            logger.log(.info, "Cache hit (memory): \(cacheKey)")
            DispatchQueue.main.async { progress(1.0) }
            return cached
        }

        // MARK: - Disk Cache Check
        if let diskData = AivoraDiskCache.shared.get(forKey: cacheKey) {
            let decoded = try JSONDecoder().decode(T.self, from: diskData)
            cache.set(value: decoded as AnyObject, forKey: cacheKey)
            logger.log(.info, "Cache hit (disk): \(cacheKey)")
            DispatchQueue.main.async { progress(1.0) }
            return decoded
        }

        // MARK: - Build URLRequest
        var urlRequest = try adapted.asURLRequest(baseURL: configuration.baseURL)

        // Merge default headers into request
        for (key, value) in configuration.defaultHeaders where urlRequest.value(forHTTPHeaderField: key) == nil {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // MARK: - Interceptor Chain (Optional)
        if let chain = adapter as? AivoraInterceptorChain {
            urlRequest = try await chain.run(request: urlRequest)
        }

        logger.log(.debug, "→ \(urlRequest.httpMethod ?? "REQ") \(urlRequest.url?.absoluteString ?? "")")

        // MARK: - Perform request using dataTask so we can observe progress
        let startTime = Date()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in

            // Create the task so we can observe its progress
            let task = session.dataTask(with: urlRequest) { dataOpt, responseOpt, errorOpt in
                // Ensure progress completes
                DispatchQueue.main.async { progress(1.0) }

                // Stop observing progress (observer invalidation handled below)
                // Handle callback
                if let error = errorOpt {
                    continuation.resume(throwing: AivoraError.network(error))
                    return
                }

                guard let data = dataOpt, let response = responseOpt as? HTTPURLResponse else {
                    continuation.resume(throwing: AivoraError.unknown)
                    return
                }

                // Notify interceptors of response (fire-and-forget)
                Task {
                    await (self.adapter as? AivoraInterceptorChain)?.notify(response: response, data: data)
                }

                // Record duration
                let duration = Date().timeIntervalSince(startTime)
                AivoraAIInsights.shared.record(endpoint: urlRequest.url?.absoluteString ?? adapted.cacheKey, duration: duration)

                switch response.statusCode {
                case 200..<300:
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        // Cache in-memory and on-disk
                        self.cache.set(value: decoded as AnyObject, forKey: cacheKey)
                        AivoraDiskCache.shared.set(data: data, forKey: cacheKey, ttl: 60 * 5)
                        continuation.resume(returning: decoded)
                    } catch {
                        continuation.resume(throwing: AivoraError.decodingFailed(error))
                    }

                case 401:
                    // Attempt token refresh if interceptor supports it, then retry once
                    Task {
                        if let tokenInterceptor = self.adapter as? AivoraTokenRefreshInterceptor {
                            // refresh token (async)
                            await tokenInterceptor.refreshToken()
                            do {
                                // Re-adapt the original endpoint to pick up refreshed tokens/headers
                                adapted = try await self.adapter?.adapt(endpoint) ?? endpoint
                                var retryRequest = try adapted.asURLRequest(baseURL: self.configuration.baseURL)
                                for (key, value) in self.configuration.defaultHeaders where retryRequest.value(forHTTPHeaderField: key) == nil {
                                    retryRequest.setValue(value, forHTTPHeaderField: key)
                                }
                                if let chain = self.adapter as? AivoraInterceptorChain {
                                    retryRequest = try await chain.run(request: retryRequest)
                                }

                                // Perform a single retry using session.dataTask -> but we need to perform async
                                let (retryData, retryResponse) = try await self.session.data(for: retryRequest)
                                guard let http2 = retryResponse as? HTTPURLResponse else {
                                    continuation.resume(throwing: AivoraError.unknown)
                                    return
                                }

                                // Record retry duration
                                let retryDuration = Date().timeIntervalSince(startTime)
                                AivoraAIInsights.shared.record(endpoint: retryRequest.url?.absoluteString ?? adapted.cacheKey, duration: retryDuration)

                                if (200..<300).contains(http2.statusCode) {
                                    let decoded = try JSONDecoder().decode(T.self, from: retryData)
                                    self.cache.set(value: decoded as AnyObject, forKey: cacheKey)
                                    AivoraDiskCache.shared.set(data: retryData, forKey: cacheKey, ttl: 60 * 5)
                                    continuation.resume(returning: decoded)
                                } else {
                                    //continuation.resume(throwing: AivoraError.server(statusCode: http2.statusCode, data: retryData, //response: <#URLResponse?#>))
                                    continuation.resume(
                                            throwing: AivoraError.server(
                                                statusCode: http2.statusCode,
                                                data: retryData,
                                                response: retryResponse
                                            )
                                        )
                                }
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        } else {
                            //continuation.resume(throwing: AivoraError.server(statusCode: response.statusCode, data: data))
                            continuation.resume(
                                throwing: AivoraError.server(
                                    statusCode: response.statusCode,
                                    data: data,
                                    response: response
                                )
                            )
                        }
                    }

                default:
                  //  continuation.resume(throwing: AivoraError.server(statusCode: response.statusCode, data: data))
                    continuation.resume(
                        throwing: AivoraError.server(
                            statusCode: response.statusCode,
                            data: data,
                            response: response
                        )
                    )
                }
            }

            // Observe task progress and forward to caller on main thread
            let observation = task.progress.observe(\.fractionCompleted) { prog, _ in
                DispatchQueue.main.async {
                    progress(prog.fractionCompleted)
                }
            }

            // Ensure observer invalidation when continuation finishes (success or failure).
            // There's no direct callback here, so use a detached Task to wait until continuation finishes.
            // We will invalidate when the task completes (in its completion handler above), so also handle cancellation.
            task.resume()

            // Also ensure observation invalidation after task completes or on cancellation.
            Task.detached {
                // Poll the task state and invalidate when finished or cancelled to avoid leaking observers.
                while task.state == .running {
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                    if Task.isCancelled { break }
                }
                observation.invalidate()
            }
        }
    }
}
