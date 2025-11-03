//
// AivoraInterceptorChain.swift
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

/// A sequential processor that executes a chain of `AivoraInterceptor` instances.
///
/// `AivoraInterceptorChain` manages the lifecycle of all registered interceptors.
/// Each interceptor can modify the outgoing request or respond to the received response.
///
/// The chain ensures that:
/// - Requests are processed in **FIFO** order (first added, first executed).
/// - Each interceptor has a chance to modify or reject a request before it is sent.
/// - All interceptors are notified when a response is received.
///
/// Example:
/// ```swift
/// let chain = AivoraInterceptorChain(interceptors: [AuthInterceptor(), LoggingInterceptor()])
/// let modifiedRequest = try await chain.run(request: originalRequest)
/// let (data, response) = try await URLSession.shared.data(for: modifiedRequest)
/// await chain.notify(response: response, data: data)
/// ```
public final class AivoraInterceptorChain {
    /// List of all interceptors in this chain.
    private var interceptors: [AivoraInterceptor] = []

    /// Initializes a new interceptor chain.
    ///
    /// - Parameter interceptors: The list of interceptors to register. Defaults to an empty array.
    public init(interceptors: [AivoraInterceptor] = []) {
        self.interceptors = interceptors
    }

    /// Adds a new interceptor to the chain.
    ///
    /// Interceptors are executed in the order they are added.
    ///
    /// - Parameter interceptor: The interceptor instance to add.
    public func add(_ interceptor: AivoraInterceptor) {
        interceptors.append(interceptor)
    }

    /// Runs all interceptors sequentially on the given request.
    ///
    /// Each interceptor can modify and return a new `URLRequest` instance.
    /// If any interceptor throws an error, execution stops and the error is propagated.
    ///
    /// - Parameter request: The original `URLRequest` before modification.
    /// - Returns: The final `URLRequest` after all interceptors have processed it.
    /// - Throws: An error thrown by any interceptor in the chain.
    public func run(request: URLRequest) async throws -> URLRequest {
        var current = request
        for interceptor in interceptors {
            current = try await interceptor.intercept(current)
        }
        return current
    }

    /// Notifies all interceptors after a response is received.
    ///
    /// Each interceptor’s `didReceive(_:data:)` method is invoked in sequence.
    /// This allows for logging, analytics, or other response-side operations.
    ///
    /// - Parameters:
    ///   - response: The response received from the network, if any.
    ///   - data: The response body data, if any.
    public func notify(response: URLResponse?, data: Data?) async {
        for interceptor in interceptors {
            await interceptor.didReceive(response, data: data)
        }
    }
}
