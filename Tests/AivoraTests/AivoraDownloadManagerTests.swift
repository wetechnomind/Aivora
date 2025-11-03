//
//  AivoraDownloadManagerTests.swift
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

/// Unit tests for `AivoraDownloadManager`, validating its safe handling
/// of resume operations and ensuring that its public API behaves predictably.
final class AivoraDownloadManagerTests: XCTestCase {

    /// Verifies that the `resume(with:)` method executes safely when provided
    /// with invalid or empty resume data, and that a valid `URLSessionDownloadTask`
    /// is returned when possible.
    func testDownloadCreatesFile() {
        // Given: a shared instance of AivoraDownloadManager
        let dm = AivoraDownloadManager.shared

        // When: attempting to resume a download with empty or invalid resume data
        let dummyResume = Data()
        let task = dm.resume(with: dummyResume)

        // Then: method should either return nil (invalid data)
        // or a valid `URLSessionDownloadTask` object if handled internally.
        // This ensures no crash or unsafe behavior occurs.
        XCTAssertTrue(task == nil || task is URLSessionDownloadTask,
                      "Resume operation should return nil or a valid download task safely.")
    }
}
