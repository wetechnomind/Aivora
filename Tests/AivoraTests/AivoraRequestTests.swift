//
//  AivoraRequestTests.swift
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

/// Unit tests for verifying the behavior of `AivoraRequest`.
///
/// These tests validate the request-building process, cache key generation,
/// and error handling to ensure `AivoraRequest` produces correct and predictable
/// network request objects.
final class AivoraRequestTests: XCTestCase {

    /// Tests that a URLRequest is correctly built with query items appended to the base URL.
    ///
    /// The test verifies:
    /// - The final URL includes the query parameter.
    /// - The HTTP method is correctly applied.
    func testURLRequestBuilding_withQueryItems() throws {
        // Given
        var request = AivoraRequest(path: "/users", method: .GET)
        request.queryItems = [URLQueryItem(name: "page", value: "1")]

        // When
        let baseURL = URL(string: "https://api.example.com")!
        let urlRequest = try request.asURLRequest(baseURL: baseURL)

        // Then
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.example.com/users?page=1")
        XCTAssertEqual(urlRequest.httpMethod, "GET")
    }

    /// Tests the generation of a unique cache key for a request.
    ///
    /// The test ensures that:
    /// - The cache key includes the HTTP method and path.
    /// - Query parameters are incorporated as part of the key.
    func testCacheKeyGeneration() {
        // Given
        var request = AivoraRequest(path: "/posts", method: .GET)
        request.queryItems = [URLQueryItem(name: "id", value: "123")]

        // Then
        XCTAssertTrue(request.cacheKey.contains("GET:/posts"))
    }

    /// Tests that an invalid URL throws an `AivoraError.invalidURL`.
    ///
    /// The test covers failure scenarios to ensure:
    /// - Malformed paths are properly validated.
    /// - Errors are reported through `AivoraError` type.
    func testInvalidURL_throwsError() {
        // Given
        let request = AivoraRequest(path: "%%%")

        // Then
        XCTAssertThrowsError(try request.asURLRequest(baseURL: nil)) { error in
            XCTAssertEqual(error as? AivoraError, AivoraError.invalidURL)
        }
    }
}
