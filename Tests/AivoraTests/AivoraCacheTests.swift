//
//  AivoraCacheTests.swift
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

/// Unit tests for validating the in-memory caching behavior
/// of `AivoraCache`.
final class AivoraCacheTests: XCTestCase {

    /// Tests that values can be stored, retrieved, and removed
    /// correctly from the shared memory cache.
    func testSetValueAndRetrieve() {
        // Given: a clean shared cache instance
        let cache = AivoraCache.shared
        cache.clear() // Ensure test isolation by clearing previous state

        let key = "mem-key"
        let obj = "value" as NSString // Store an NSString for type consistency

        // When: value is set in the cache
        cache.set(value: obj, forKey: key)

        // Then: the same value should be retrievable by key
        let retrieved = cache.value(forKey: key) as? NSString
        XCTAssertEqual(retrieved, obj, "Retrieved cache value should match stored object.")

        // When: the value is removed
        cache.remove(forKey: key)

        // Then: retrieving the key should return nil
        XCTAssertNil(cache.value(forKey: key), "Cache should return nil after key removal.")
    }
}
