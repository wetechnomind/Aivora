//
// AivoraRequest.swift
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
//

import Foundation

// MARK: - HTTP Method Enumeration

/// Represents standard HTTP methods supported by Aivora.
///
/// Used to define the type of network operation being performed.
public enum AivoraHTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
}

// MARK: - Request Adapter Protocol

/// Defines a protocol for modifying requests before execution.
///
/// Adapters can be used to automatically inject headers, tokens, or modify paths.
/// For example:
/// ```swift
/// struct AuthAdapter: AivoraRequestAdapter {
///     func adapt(_ request: AivoraRequest) async throws -> AivoraRequest {
///         var req = request
///         req.headers["Authorization"] = "Bearer <token>"
///         return req
///     }
/// }
/// ```
public protocol AivoraRequestAdapter {
    func adapt(_ request: AivoraRequest) async throws -> AivoraRequest
}

// MARK: - Standard Request

/// Represents a standard HTTP request used by the Aivora client.
///
/// Provides built-in query parameter support, header customization, and body attachment.
public struct AivoraRequest {
    /// Request endpoint path or full URL.
    public let path: String
    
    /// HTTP method to use for this request.
    public let method: AivoraHTTPMethod
    
    /// Query parameters appended to the URL.
    public var queryItems: [URLQueryItem] = []
    
    /// HTTP headers included in the request.
    public var headers: [String: String] = [:]
    
    /// Optional body data (e.g., JSON payload).
    public var body: Data? = nil
    
    /// Unique cache key used by caching systems like `AivoraDiskCache`.
    public var cacheKey: String {
        return "\(method.rawValue):\(path)?\(queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&"))"
    }

    /// Initializes a new `AivoraRequest`.
    ///
    /// - Parameters:
    ///   - path: The relative or absolute endpoint path.
    ///   - method: The HTTP method to use (default is `.GET`).
    public init(
        path: String,
        method: AivoraHTTPMethod = .GET,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }

    /// Converts the `AivoraRequest` into a `URLRequest` ready for use by `URLSession`.
    ///
    /// - Parameter baseURL: Optional base URL used to resolve relative paths.
    /// - Throws: `AivoraError.invalidURL` if the constructed URL is invalid.
    /// - Returns: A fully configured `URLRequest`.
    public func asURLRequest(baseURL: URL?) throws -> URLRequest {
        // Construct the final URL
        guard let url: URL = {
            if let base = baseURL { return URL(string: path, relativeTo: base)?.absoluteURL }
            return URL(string: path)
        }() else {
            throw AivoraError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let finalURL = components?.url else {
            throw AivoraError.invalidURL
        }
        
        // Configure the URLRequest
        var req = URLRequest(url: finalURL)
        req.httpMethod = method.rawValue
        req.httpBody = body
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        return req
    }
}

// MARK: - Multipart Request

/// Represents a multipart/form-data request for file uploads or form submissions.
///
/// Provides helper methods for adding text fields and file attachments.
public struct AivoraMultipartRequest {
    /// Endpoint path or full URL string.
    public let path: String
    
    /// Additional HTTP headers.
    public var headers: [String: String] = [:]
    
    /// Multipart boundary used to separate data parts.
    public var boundary: String = UUID().uuidString
    
    /// Raw multipart body data.
    public var bodyData: Data = Data()

    /// Initializes a new multipart request with a given path.
    ///
    /// - Parameter path: The relative or absolute endpoint path.
    public init(path: String) {
        self.path = path
    }

    /// Adds a text field to the multipart body.
    ///
    /// - Parameters:
    ///   - name: Field name.
    ///   - value: Field value.
    public mutating func addFormField(name: String, value: String) {
        var part = "--\(boundary)\r\n"
        part += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
        part += "\(value)\r\n"
        bodyData.append(part.data(using: .utf8)!)
    }

    /// Adds a binary file part to the multipart body.
    ///
    /// - Parameters:
    ///   - fieldName: The name of the form field.
    ///   - filename: The name of the file.
    ///   - mimeType: The MIME type (e.g., `image/jpeg`).
    ///   - data: Binary data for the file.
    public mutating func addFile(fieldName: String, filename: String, mimeType: String, data: Data) {
        var part = "--\(boundary)\r\n"
        part += "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n"
        part += "Content-Type: \(mimeType)\r\n\r\n"
        bodyData.append(part.data(using: .utf8)!)
        bodyData.append(data)
        bodyData.append("\r\n".data(using: .utf8)!)
    }

    /// Converts this multipart request into a `URLRequest`.
    ///
    /// - Parameter baseURL: Optional base URL for resolving relative paths.
    /// - Throws: `AivoraError.invalidURL` if the URL cannot be constructed.
    /// - Returns: A configured `URLRequest` for uploading.
    public func asURLRequest(baseURL: URL?) throws -> URLRequest {
        guard let url = (baseURL != nil)
                ? URL(string: path, relativeTo: baseURL)?.absoluteURL
                : URL(string: path)
        else { throw AivoraError.invalidURL }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Finalize multipart body with boundary terminator
        var final = bodyData
        final.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // NOTE: `final` is ready for upload tasks.
        // If you need direct body attachment, uncomment:
        // req.httpBody = final
        
        return req
    }
}
