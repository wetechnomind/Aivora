//
//  AivoraClientTests.swift
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

/// Unit tests verifying the behavior of `AivoraClient`,
/// including request handling, response caching, and error propagation.
final class AivoraClientTests: XCTestCase {

    /// Helper method that constructs an isolated `AivoraClient`
    /// configured with a mock URL session for deterministic testing.
    private func makeClient() -> AivoraClient {
        // Configure a temporary URLSession using MockURLProtocol for network interception.
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        // Initialize client with mock base URL and session
        let client = AivoraClient(
            configuration: .init(baseURL: URL(string: "https://api.test")!),
            adapter: nil,
            urlSession: session
        )

        // Ensure both memory and disk caches are clean before test
        AivoraCache.shared.clear()
        AivoraDiskCache.shared.clear()

        return client
    }

    /// Ensures that successful responses are cached and reused for subsequent identical requests.
    func testRequestCachesResponse() async throws {
        // Given: a mock client and pre-defined response
        let client = makeClient()
        let sampleJSON = #"{"message":"ok"}"#.data(using: .utf8)!

        // Configure the mock protocol to return a 200 OK response with JSON payload
        MockURLProtocol.requestHandler = { request in
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, sampleJSON)
        }

        struct Resp: Decodable { let message: String }

        // When: performing the first request
        let endpoint = AivoraRequest(path: "/ping")
        let first: Resp = try await client.request(endpoint)

        // Then: verify that the decoded message is correct
        XCTAssertEqual(first.message, "ok", "First request should decode expected JSON payload.")

        // When: performing the same request again
        // The cache should respond; the network handler must not be called.
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Network should not be called — response must come from cache.")
            let resp = HTTPURLResponse(url: URL(string: "https://api.test/ping")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (resp, nil)
        }

        let second: Resp = try await client.request(endpoint)

        // Then: verify that cached data is returned correctly
        XCTAssertEqual(second.message, "ok", "Second request should return the same cached result.")
    }

    /// Validates that server errors are correctly caught and mapped to `AivoraError.server`.
    func testRequestHandlesServerError() async {
        // Given: a mock client and an endpoint that returns a 500 error
        let client = makeClient()

        MockURLProtocol.requestHandler = { request in
            let resp = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            let data = #"{"error":"server"}"#.data(using: .utf8)
            return (resp, data)
        }

        struct Dummy: Decodable { let a: Int }

        // When: performing a request expected to fail
        do {
            _ = try await client.request(AivoraRequest(path: "/err")) as Dummy
            XCTFail("Expected request to throw due to server error.")
        } catch let error as AivoraError {
            // Then: ensure correct error mapping
            switch error {
            case .server(let code, _):
                XCTAssertEqual(code, 500, "Expected 500 server error code.")
            default:
                XCTFail("Expected AivoraError.server, got \(error).")
            }
        } catch {
            XCTFail("Unexpected error type thrown: \(error).")
        }
    }
}
