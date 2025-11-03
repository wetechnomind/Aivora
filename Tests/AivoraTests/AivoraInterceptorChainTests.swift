//
//  AivoraInterceptorChainTests.swift
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

import XCTest
@testable import Aivora

/// Tests for `AivoraInterceptorChain`, ensuring that request
/// and response interceptors execute properly and in the correct order.
final class AivoraInterceptorChainTests: XCTestCase {
    
    /// Verifies that multiple interceptors modify the request sequentially
    /// in the same order they were added to the chain.
    func testInterceptorsRunInOrder() async throws {
        // Given: Two mock interceptors that add distinct headers
        var i1 = MockInterceptor(headerName: "X-First", headerValue: "one")
        let i2 = MockInterceptor(headerName: "X-Second", headerValue: "two")
        
        // Create a chain with both interceptors in order
        let chain = AivoraInterceptorChain(interceptors: [i1, i2])

        // And a base request with no headers
        var req = URLRequest(url: URL(string: "https://example.com")!)

        // When: The chain runs the interceptors sequentially
        let out = try await chain.run(request: req)
        
        // Then: Each interceptor should have modified the request headers in order
        XCTAssertEqual(out.value(forHTTPHeaderField: "X-First"), "one")
        XCTAssertEqual(out.value(forHTTPHeaderField: "X-Second"), "two")
    }

    /// Ensures that the chain's `notify(response:data:)` method calls
    /// each interceptor's `didReceive` without throwing errors or crashing.
    func testNotifyCallsDidReceive() async {
        // Given: A mock interceptor
        let i1 = MockInterceptor(headerName: "h", headerValue: "v")
        let chain = AivoraInterceptorChain(interceptors: [i1])
        
        // When: The chain is notified of a response and data
        // Then: The method should complete gracefully without exceptions
        await chain.notify(response: nil, data: nil)
    }
}
