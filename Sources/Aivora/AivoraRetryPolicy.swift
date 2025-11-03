//
// AivoraRetryPolicy.swift
// Aivora

// Copyright (c) 2025 Aivora Software Foundation (https://www.wetechnomind.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

/// A lightweight retry handler used for executing asynchronous operations
/// with exponential backoff when network or transient failures occur.
///
/// This is typically used internally by `AivoraClient` to retry failed requests.
public final class AivoraRetryPolicy {
    
    /// Maximum number of retry attempts before giving up.
    /// Default is `3`.
    public var maxRetries = 3
    
    /// The base delay (in seconds) between retries.
    /// The actual delay grows exponentially based on the attempt count.
    public var baseDelay: TimeInterval = 0.5

    /// Creates a new retry policy with default configuration.
    public init() {}

    /// Executes an asynchronous operation with retry logic.
    ///
    /// - Parameter operation: The asynchronous task to attempt.
    /// - Returns: The successful result of the operation.
    /// - Throws: The last error encountered if all retries fail.
    ///
    /// The delay between retries is computed as `2^attempt * baseDelay`
    /// to implement exponential backoff, which helps reduce server load
    /// under repeated failure conditions.
    public func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var attempt = 0
        var lastError: Error?
        
        // Retry loop — will execute until maxRetries is reached
        while attempt <= maxRetries {
            do {
                // Attempt to execute the provided async operation
                return try await operation()
            } catch {
                lastError = error
                attempt += 1
                
                // If we've exceeded the max retries, break the loop
                if attempt > maxRetries { break }
                
                // Calculate exponential delay before the next attempt
                let delay = pow(2.0, Double(attempt)) * baseDelay
                
                // Suspend the task for the computed duration
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // After exhausting all attempts, throw the last recorded error
        throw lastError ?? AivoraError.unknown
    }
}
