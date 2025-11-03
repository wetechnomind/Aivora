//
//  AivoraReachabilityTests.swift
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

/// Unit tests for the `AivoraReachability` component.
///
/// These tests verify that the reachability system correctly:
/// - Starts and stops monitoring network changes.
/// - Triggers the `onStatusChange` callback when the status updates.
/// - Maintains a valid current network status.
final class AivoraReachabilityTests: XCTestCase {

    /// Tests that the `onStatusChange` handler is properly invoked
    /// when the network status changes.
    ///
    /// This test simulates a reachable network event and verifies
    /// that the callback is executed as expected.
    func testReachabilityStatusChangeHandler() async {
        // Obtain the shared reachability instance
        let reachability = AivoraReachability.shared

        // Begin monitoring network changes
        reachability.start()

        // Expectation to wait for the async callback
        let expectation = XCTestExpectation(description: "Reachability status changed")

        // Assign a closure to handle status changes
        reachability.onStatusChange = { status in
            // Verify that the received status is valid
            XCTAssertNotNil(status, "Status should not be nil")
            expectation.fulfill()
        }

        // Simulate a network status change (e.g., to 'reachable')
        await reachability.simulateStatusChange(.reachable)

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)

        // Stop monitoring to clean up the test
        reachability.stop()
    }

    /// Tests that the `currentStatus` property of `AivoraReachability`
    /// always returns a valid state when monitoring is active.
    func testReachabilityCurrentStatus() {
        // Obtain the shared reachability instance
        let reachability = AivoraReachability.shared

        // Start monitoring network status
        reachability.start()

        // Validate that a current status exists
        XCTAssertNotNil(reachability.currentStatus, "Current reachability status should not be nil")

        // Stop monitoring to release resources
        reachability.stop()
    }
}
