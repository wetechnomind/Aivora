//
//  MockURLProtocol.swift
//  Aivora
//
//  Copyright (c) 2025 Aivora Software Foundation
//  (https://www.wetechnomind.com/)
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

/// A mock implementation of `URLProtocol` used for intercepting and simulating
/// network requests during testing.
///
/// `MockURLProtocol` allows you to define a custom response handler that
/// returns a predefined `HTTPURLResponse` and optional `Data`.
/// This enables isolated, repeatable unit tests without making real network calls.
///
/// Usage Example:
/// ```swift
/// let config = URLSessionConfiguration.ephemeral
/// config.protocolClasses = [MockURLProtocol.self]
/// let session = URLSession(configuration: config)
///
/// MockURLProtocol.requestHandler = { request in
///     let response = HTTPURLResponse(url: request.url!,
///                                    statusCode: 200,
///                                    httpVersion: nil,
///                                    headerFields: nil)!
///     let data = "{\"result\": \"ok\"}".data(using: .utf8)
///     return (response, data)
/// }
/// ```
public final class MockURLProtocol: URLProtocol {

    /// A closure type that provides a custom response for an intercepted request.
    /// - Parameter request: The intercepted `URLRequest`.
    /// - Returns: A tuple containing an `HTTPURLResponse` and optional response `Data`.
    public typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data?)

    /// The global handler that test cases can assign to simulate network responses.
    public static var requestHandler: Handler?

    /// Determines whether this protocol can handle the given request.
    /// Always returns `true` since this mock intercepts all requests.
    public override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    /// Returns the canonical version of the request.
    /// Here it simply returns the original request unchanged.
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    /// Starts loading the request by invoking the `requestHandler`.
    ///
    /// If a handler is not set, it reports a failure back to the client.
    /// If the handler provides a response and data, those are delivered to the client.
    public override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            let error = NSError(
                domain: "MockURLProtocol",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No handler set"]
            )
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    /// Stops loading the request.
    /// This implementation does nothing since loading completes immediately.
    public override func stopLoading() {
        // No active tasks to cancel.
    }
}
