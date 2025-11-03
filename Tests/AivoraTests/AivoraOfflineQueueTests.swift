//
//  AivoraOfflineQueueTests.swift
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

/// Unit tests for the `AivoraOfflineQueue` class, which manages
/// queued asynchronous jobs for offline or delayed execution.
final class AivoraOfflineQueueTests: XCTestCase {
    
    /// Verifies that a job can be successfully enqueued, executed,
    /// and that the queue is properly cleared after flushing.
    func testEnqueueAndFlush() async {
        // Given: A shared instance of the offline queue
        let queue = AivoraOfflineQueue.shared
        
        // Reset to a clean state to ensure test isolation
        queue.queue.removeAll()

        // Expectation to confirm that the enqueued job executes
        let expectation = XCTestExpectation(description: "Job executed")

        // When: A job is enqueued that fulfills the expectation
        queue.enqueue {
            expectation.fulfill()
        }

        // Then: The queue should contain exactly one job before flush
        XCTAssertEqual(queue.queue.count, 1, "Job should be added to the queue before flushing.")
        
        // When: The queue is flushed to execute all jobs
        queue.flush()

        // Wait for the enqueued job to finish asynchronously
        wait(for: [expectation], timeout: 2.0)
        
        // Then: After execution, the queue should be empty
        XCTAssertEqual(queue.queue.count, 0, "Queue should be empty after flushing executed jobs.")
    }
}
