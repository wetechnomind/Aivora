//
//  MockInterceptor.swift
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
@testable import Aivora

/// A lightweight mock implementation of `AivoraInterceptor` used in tests.
///
/// `MockInterceptor` helps verify interceptor chain behavior by:
/// - Appending custom headers to outgoing requests.
/// - Observing whether response-handling methods are invoked.
///
/// This mock enables isolated testing of request modification and interceptor integration.
struct MockInterceptor: AivoraInterceptor {
    
    /// The name of the HTTP header to be added.
    let headerName: String
    
    /// The value of the HTTP header to be added.
    let headerValue: String
    
    /// Flag used in tests to confirm if response handling was triggered.
    var didReceiveCalled = false

    /// Intercepts the request and appends a custom header.
    ///
    /// - Parameter request: The original `URLRequest` before modification.
    /// - Returns: A modified request including the test header.
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var req = request
        req.setValue(headerValue, forHTTPHeaderField: headerName)
        return req
    }

    /// Called when a response is received. This is a no-op in the mock.
    ///
    /// - Parameters:
    ///   - response: The received response, if any.
    ///   - data: The response data, if available.
    func didReceive(_ response: URLResponse?, data: Data?) async {
        // No operation – used only for test conformance.
    }
}
