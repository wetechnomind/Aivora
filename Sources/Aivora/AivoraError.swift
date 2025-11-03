//
//  AivoraError.swift
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

/// Represents all possible error cases in the Aivora networking and caching layers.
///
/// `AivoraError` provides descriptive, structured, and typed error cases
/// for clear debugging, analytics, and developer experience.
public enum AivoraError: Error, LocalizedError {
    
    // MARK: - Core Networking
    
    /// The URL provided to the request was invalid or malformed.
    case invalidURL
    
    /// A network-level error occurred (e.g., no internet, DNS issue).
    /// - Parameter error: The original underlying `Error` from `URLSession`.
    case network(Error)
    
    /// The response decoding failed (e.g., invalid JSON format or mismatched model).
    /// - Parameter error: The original decoding `Error`.
    case decoding(Error)
    
    /// The server returned a non-success HTTP status code (e.g., 404, 500).
    /// - Parameters:
    ///   - statusCode: The HTTP status code returned by the server.
    ///   - data: Optional raw data returned from the server for debugging.
    ///   - response: The associated `URLResponse` object for additional context.
    case server(statusCode: Int, data: Data?, response: URLResponse?)
    
    /// The request was cancelled by the client or system.
    case cancelled
    
    /// The request took too long and exceeded its timeout interval.
    case timeout
    
    /// Authentication failed (commonly due to 401 Unauthorized).
    case authenticationFailed
    
    /// An unknown or unspecified error occurred.
    case unknown

    // MARK: - Cache & Disk Layer
    
    /// No data found for a requested cache key.
    case cacheMiss(key: String)
    
    /// A disk I/O or file system related failure.
    case diskError(Error)
    
    // MARK: - Computed Properties
    
    /// A user-friendly description of the error, suitable for display or logging.
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided to Aivora."
            
        case .network(let e):
            return "Network error: \(e.localizedDescription)"
            
        case .decoding(let e):
            return "Decoding failed: \(e.localizedDescription)"
            
        case .server(let code, _, _):
            return "Server returned HTTP status \(code)."
            
        case .cancelled:
            return "Request was cancelled."
            
        case .timeout:
            return "Request timed out."
            
        case .authenticationFailed:
            return "Authentication failed (401)."
            
        case .cacheMiss(let key):
            return "Cache miss for key: \(key)"
            
        case .diskError(let e):
            return "Disk operation failed: \(e.localizedDescription)"
            
        case .unknown:
            return "Unknown error."
        }
    }
    
    /// Provides the original underlying system or decoding error, if any.
    public var underlyingError: Error? {
        switch self {
        case .network(let e), .decoding(let e), .diskError(let e):
            return e
        default:
            return nil
        }
    }
    
    /// Indicates if the error is likely related to networking or connectivity.
    public var isNetworkRelated: Bool {
        switch self {
        case .network, .timeout:
            return true
        default:
            return false
        }
    }
}

// MARK: - Equatable Support

extension AivoraError: Equatable {
    public static func == (lhs: AivoraError, rhs: AivoraError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.cancelled, .cancelled),
             (.timeout, .timeout),
             (.authenticationFailed, .authenticationFailed),
             (.unknown, .unknown):
            return true
        case (.server(let a, _, _), .server(let b, _, _)):
            return a == b
        case (.cacheMiss(let a), .cacheMiss(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Debug Logging

extension AivoraError: CustomDebugStringConvertible {
    public var debugDescription: String {
        var base = "[AivoraError] \(errorDescription ?? "No description")"
        if let underlying = underlyingError {
            base += " | Underlying: \(underlying)"
        }
        return base
    }
}
