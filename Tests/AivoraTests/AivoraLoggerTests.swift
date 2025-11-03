//
//  AivoraLoggerTests.swift
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

final class AivoraLoggerTests: XCTestCase {

    func testLoggerPrintsExpectedOutput() {
        let logger = AivoraLogger.shared
        let expectation = XCTestExpectation(description: "Logger prints output")

        // Capture print output temporarily
        let originalStdOut = dup(STDOUT_FILENO)
        let pipe = Pipe()
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        logger.log(.info, "Test message")
        pipe.fileHandleForWriting.closeFile()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        dup2(originalStdOut, STDOUT_FILENO)

        let output = String(data: outputData, encoding: .utf8) ?? ""
        XCTAssertTrue(output.contains("Test message"))
        XCTAssertTrue(output.contains("INFO"))
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testLoggerLevels() {
        let logger = AivoraLogger.shared
        logger.level = .debug
        XCTAssertEqual(logger.level, .debug)
    }
}

