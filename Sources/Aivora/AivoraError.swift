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

/// A unified enumeration that represents all possible errors
/// encountered within the **Aivora networking and caching layers**.
///
/// This enum provides type-safe and descriptive error handling for
/// networking, caching, encoding/decoding, and server response errors.
/// It conforms to both `Error` and `LocalizedError` to provide meaningful
/// developer and user-facing messages.
public enum AivoraError: Error, LocalizedError {
    
    // MARK: - Core Networking Errors
    
    /// The URL provided to the request is invalid or improperly formatted.
    case invalidURL
    
    /// A network-level issue occurred (e.g., no internet, DNS lookup failed, etc.).
    /// - Parameter Error: The underlying system error from `URLSession`.
    case network(Error)
    
    /// The response data could not be decoded into the expected model type.
    /// Usually caused by mismatched model structures or malformed JSON.
    case decodingFailed(Error)
    
    /// The request body could not be encoded into JSON.
    /// Typically caused by encoding invalid data or unsupported types.
    case encodingFailed(Error)
    
    /// The server returned a response with a **non-successful HTTP status code**.
    /// - Parameters:
    ///   - statusCode: The HTTP status code (e.g., 400, 401, 500).
    ///   - data: Optional raw data returned by the server for further analysis.
    ///   - response: The original `URLResponse` from the request.
    case server(statusCode: Int, data: Data?, response: URLResponse?)
    
    /// The request was intentionally or automatically cancelled.
    case cancelled
    
    /// The request exceeded its timeout interval and failed.
    case timeout
    
    /// Authentication failed, typically due to a `401 Unauthorized` response.
    case authenticationFailed
    
    /// A catch-all case for unexpected or unclassified errors.
    case unknown

    // MARK: - Cache & Disk Layer Errors
    
    /// No cached data was found for a given cache key.
    /// - Parameter key: The cache key that caused the miss.
    case cacheMiss(key: String)
    
    /// A disk read/write or file system error occurred.
    /// - Parameter Error: The underlying file system error.
    case diskError(Error)
    
    // MARK: - Computed Properties
    
    /// A localized, human-readable description of the error.
    /// Suitable for displaying to users or logging.
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided to Aivora."
            
        case .network(let e):
            return "Network error: \(e.localizedDescription)"
            
        case .decodingFailed(let e):
            return "Decoding failed: \(e.localizedDescription)"
            
        case .encodingFailed(let e):
            return "Encoding failed: \(e.localizedDescription)"
            
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
    
    /// Returns the **underlying system or framework error**, if available.
    /// Helpful for debugging or deeper inspection of the root cause.
    public var underlyingError: Error? {
        switch self {
        case .network(let e),
             .decodingFailed(let e),
             .encodingFailed(let e),
             .diskError(let e):
            return e
        default:
            return nil
        }
    }
    
    /// A Boolean indicating whether the error is related to network connectivity.
    /// This can help in handling offline states or retry mechanisms.
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
    
    /// Provides equality comparison between two `AivoraError` values.
    /// Useful for testing and error-specific handling in switch statements.
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

// MARK: - Debug Logging Support

extension AivoraError: CustomDebugStringConvertible {
    
    /// A more verbose description of the error, including its type
    /// and any available underlying error. Ideal for debugging.
    public var debugDescription: String {
        var base = "[AivoraError] \(errorDescription ?? "No description")"
        if let underlying = underlyingError {
            base += " | Underlying: \(underlying)"
        }
        return base
    }
}
