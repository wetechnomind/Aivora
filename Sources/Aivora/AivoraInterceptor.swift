//
//  AivoraInterceptor.swift
//  Aivora
//
//  Copyright (c) 2025
//  Aivora Software Foundation (https://www.wetechnomind.com/)
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

// MARK: - AivoraInterceptor Protocol
//
// This protocol defines the interception behavior for Aivora’s
// networking pipeline. Interceptors act as middleware components that
// can modify requests, log responses, or handle network errors before
// and after network calls.
//

public protocol AivoraInterceptor {
    
    // MARK: - Request Interception
    //
    // Called before a request is executed.
    // This is your opportunity to modify or inspect the outgoing URLRequest.
    // For example:
    // - Add authentication headers
    // - Modify query parameters
    // - Cancel the request by throwing an error
    //
    // Returning a modified or original URLRequest continues execution.
    //
    // Example:
    // ```swift
    // func intercept(_ request: URLRequest) async throws -> URLRequest {
    //     var req = request
    //     req.addValue("Bearer token", forHTTPHeaderField: "Authorization")
    //     return req
    // }
    // ```
    
    func intercept(_ request: URLRequest) async throws -> URLRequest
    
    // MARK: - Response Observation
    //
    // Called after a response is received.
    // Use this for:
    // - Logging and analytics
    // - Caching
    // - Response inspection or validation
    // - Retrying logic
    //
    // The method is asynchronous to support async post-processing.
    
    func didReceive(_ response: URLResponse?, data: Data?) async
    
    // MARK: - Error Handling
    //
    // Invoked when a network error occurs.
    // This method is optional; a default empty implementation is provided.
    // Common uses:
    // - Centralized error logging
    // - Retrying failed requests
    // - Analytics reporting
    //
    // Example:
    // ```swift
    // func didEncounter(_ error: Error) async {
    //     Logger.error("Network failed: \(error.localizedDescription)")
    // }
    // ```
    
    func didEncounter(_ error: Error) async
}

// MARK: - Default Implementation
//
// Provides a no-op implementation for `didEncounter(_:)`
// so conforming interceptors only need to implement the methods
// they actually use.
//
public extension AivoraInterceptor {
    func didEncounter(_ error: Error) async {}
}
