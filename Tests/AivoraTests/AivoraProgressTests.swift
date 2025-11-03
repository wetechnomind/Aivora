//
//  AivoraProgressTests.swift
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

/// Unit tests for the `AivoraProgress` class.
///
/// This suite verifies that progress tracking logic works correctly across different scenarios:
/// - Proper initialization with total unit count.
/// - Accurate fractional completion during updates.
/// - Automatic capping when completed units exceed total units.
/// - Correct completion detection.
/// - Initialization support for byte-based progress.
final class AivoraProgressTests: XCTestCase {

    /// Tests that a newly created progress object initializes
    /// with correct default values and uncompleted state.
    func testInitialValues() {
        let progress = AivoraProgress(totalUnitCount: 100)

        // Verify initial values
        XCTAssertEqual(progress.totalUnitCount, 100, "Total units should match initializer value")
        XCTAssertEqual(progress.completedUnitCount, 0, "Initial completed units should be zero")
        XCTAssertFalse(progress.isFinished, "Progress should not be marked as finished initially")
    }

    /// Tests that updating the completed unit count correctly updates
    /// the fractional completion ratio.
    func testUpdateProgress() {
        let progress = AivoraProgress(totalUnitCount: 100)
        progress.completedUnitCount = 50

        // Verify fractional completion (should be 50%)
        XCTAssertEqual(progress.fractionCompleted, 0.5, accuracy: 0.0001, "Fraction completed should reflect progress")
    }

    /// Tests that the completed unit count never exceeds the total,
    /// ensuring logical consistency in progress tracking.
    func testCappingCompletedUnits() {
        let progress = AivoraProgress(totalUnitCount: 100)
        progress.completedUnitCount = 200

        // Ensure progress is capped at 100%
        XCTAssertEqual(progress.completedUnitCount, 100, "Completed units should not exceed total units")
    }

    /// Tests that progress correctly recognizes completion once
    /// all units are completed.
    func testProgressCompletionNotification() {
        let progress = AivoraProgress(totalUnitCount: 10)
        progress.completedUnitCount = 10

        // Verify that progress is now marked as finished
        XCTAssertTrue(progress.isFinished, "Progress should be marked as finished when fully completed")
    }

    /// Tests the convenience initializer designed for byte-based tracking,
    /// commonly used in upload or download progress monitoring.
    func testByteBasedInitializer() {
        let progress = AivoraProgress(
            bytesSent: 50,
            totalBytesSent: 50,
            totalBytesExpectedToSend: 100
        )

        // Verify byte-based initialization maps correctly to unit counts
        XCTAssertEqual(progress.totalUnitCount, 100, "Total unit count should reflect total bytes expected")
        XCTAssertEqual(progress.completedUnitCount, 50, "Completed unit count should reflect bytes sent")
        XCTAssertEqual(progress.fractionCompleted, 0.5, accuracy: 0.0001, "Fraction should represent sent/expected ratio")
    }
}
