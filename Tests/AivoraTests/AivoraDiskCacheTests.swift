//
//  AivoraDiskCacheTests.swift
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

/// Unit tests for validating the persistence, retrieval,
/// and expiration behavior of `AivoraDiskCache`.
final class AivoraDiskCacheTests: XCTestCase {

    /// Tests that data can be stored, retrieved, and removed
    /// from the disk cache successfully.
    func testSetAndGet() throws {
        // Given: a shared cache instance
        let cache = AivoraDiskCache.shared
        cache.clear() // Ensure a clean cache before testing

        let key = "test-key"
        let payload = "hello".data(using: .utf8)! // Sample payload data

        // When: data is set in the cache without a TTL
        cache.set(data: payload, forKey: key, ttl: nil)

        // Wait briefly to allow any asynchronous disk write operations to complete
        sleep(1)

        // Then: data should be retrievable and match the original value
        let retrieved = cache.get(forKey: key)
        XCTAssertNotNil(retrieved, "Cached data should not be nil after saving.")
        XCTAssertEqual(String(data: retrieved!, encoding: .utf8), "hello", "Retrieved data should match original payload.")

        // When: the key is removed from cache
        cache.remove(forKey: key)

        // Then: retrieval should return nil
        let removed = cache.get(forKey: key)
        XCTAssertNil(removed, "Removed cache item should not be retrievable.")
    }

    /// Tests that data stored with a time-to-live (TTL) expires
    /// and is no longer retrievable after the duration elapses.
    func testTTLExpires() throws {
        // Given: a fresh cache and test key with a short TTL
        let cache = AivoraDiskCache.shared
        cache.clear()

        let key = "ttl-key"
        let payload = "x".data(using: .utf8)!

        // When: data is stored with a TTL of 1 second
        cache.set(data: payload, forKey: key, ttl: 1)

        // Wait for TTL to expire
        sleep(2)

        // Then: cache should return nil for expired entry
        let got = cache.get(forKey: key)
        XCTAssertNil(got, "Data should expire and be removed after TTL has elapsed.")
    }
}
