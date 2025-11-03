//
//  AivoraRetryPolicyTests.swift
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

/// Unit tests verifying the behavior of `AivoraRetryPolicy`.
///
/// These tests validate the retry logic to ensure:
/// - Tasks that initially fail are retried according to the configured policy.
/// - Retry limits are respected.
/// - Success and failure paths behave predictably.
final class AivoraRetryPolicyTests: XCTestCase {

    /// Tests that a task eventually succeeds after a few retry attempts.
    ///
    /// This verifies:
    /// - The retry policy retries failed attempts up to the allowed maximum.
    /// - Once the condition succeeds, retries stop and the result is returned.
    /// - The number of attempts matches the number of expected retries.
    func testRetrySucceedsAfterFailure() async throws {
        // Given
        let policy = AivoraRetryPolicy()
        policy.maxRetries = 3
        var attempts = 0

        // When
        let result = try await policy.execute {
            attempts += 1
            // Simulate transient failures for first two attempts.
            if attempts < 3 { throw URLError(.timedOut) }
            return "Success"
        }

        // Then
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attempts, 3)
    }

    /// Tests that the retry policy stops retrying after the maximum attempts are reached.
    ///
    /// This ensures:
    /// - The retry mechanism stops after exceeding `maxRetries`.
    /// - The total attempt count equals `maxRetries + 1` (initial + retries).
    /// - The final thrown error is correctly propagated.
    func testRetryFailsAfterMaxAttempts() async {
        // Given
        let policy = AivoraRetryPolicy()
        policy.maxRetries = 2
        var attempts = 0

        // When / Then
        do {
            _ = try await policy.execute {
                attempts += 1
                // Always fail to trigger full retry sequence.
                throw URLError(.cannotConnectToHost)
            }
            XCTFail("Expected to throw an error after maximum retries")
        } catch {
            // Should perform 1 initial + 2 retries = 3 attempts total.
            XCTAssertEqual(attempts, 3)
        }
    }
}
