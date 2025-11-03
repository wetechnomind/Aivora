//
//  AivoraProgress.swift
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

import Foundation

/// A lightweight progress-tracking utility for monitoring data upload or download.
///
/// `AivoraProgress` can represent generic task progress or
/// byte-based transfer progress. It provides fractional completion
/// and completion status checks.
///
/// Example:
/// ```swift
/// let progress = AivoraProgress(totalUnitCount: 100)
/// progress.completedUnitCount = 40
/// print(progress.fractionCompleted) // 0.4
/// ```
public final class AivoraProgress {

    // MARK: - Stored Properties

    /// The total expected unit count (e.g., total bytes to send or total work units).
    public var totalUnitCount: Int64

    /// The number of completed units (e.g., bytes sent or completed work units).
    public var completedUnitCount: Int64 {
        didSet {
            if completedUnitCount > totalUnitCount {
                completedUnitCount = totalUnitCount
            }
        }
    }

    // MARK: - Computed Properties

    /// Fractional progress between `0.0` and `1.0`.
    public var fractionCompleted: Double {
        guard totalUnitCount > 0 else { return 0.0 }
        return Double(completedUnitCount) / Double(totalUnitCount)
    }

    /// Indicates whether the progress is finished.
    public var isFinished: Bool {
        completedUnitCount >= totalUnitCount
    }

    // MARK: - Initializers

    /// Creates a new progress object with a total unit count.
    ///
    /// - Parameter totalUnitCount: The total units representing full completion.
    public init(totalUnitCount: Int64) {
        self.totalUnitCount = totalUnitCount
        self.completedUnitCount = 0
    }

    /// Creates a byte-based progress object for data transmission tasks.
    ///
    /// - Parameters:
    ///   - bytesSent: The most recent bytes sent in this operation.
    ///   - totalBytesSent: The total bytes sent so far.
    ///   - totalBytesExpectedToSend: The total expected bytes to send.
    public init(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.totalUnitCount = totalBytesExpectedToSend
        self.completedUnitCount = totalBytesSent
    }
}
