//
//  AivoraRequest.swift
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
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//

import Foundation

// MARK: - HTTP Method Enumeration

/// Represents standard HTTP methods used in API communication.
///
/// Used to define the request type when building an `AivoraRequest`.
public enum AivoraHTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
}

// MARK: - Request Adapter Protocol

/// Defines a protocol for intercepting or modifying outgoing requests.
///
/// Conform to this protocol if you want to inject authentication tokens,
/// manipulate headers, or log requests before sending them.
public protocol AivoraRequestAdapter {
    /// Modifies or adapts a given request asynchronously.
    /// - Parameter request: The original `AivoraRequest` instance.
    /// - Returns: A modified `AivoraRequest` ready for transmission.
    func adapt(_ request: AivoraRequest) async throws -> AivoraRequest
}

// MARK: - JSON Encoder

/// Aivora’s built-in JSON encoder.
///
/// Provides a shared and consistently configured `JSONEncoder`
/// for encoding Swift models into JSON `Data`.
public struct AivoraJSONEncoder {
    
    /// A single shared instance of JSONEncoder configured with
    /// `snake_case` keys and pretty-printed output.
    private static let shared: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    
    /// Encodes an `Encodable` Swift model into JSON data.
    /// - Parameter value: The value to encode.
    /// - Throws: `AivoraError.encodingFailed` if encoding fails.
    /// - Returns: Encoded JSON `Data`.
    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try shared.encode(value)
        } catch {
            throw AivoraError.encodingFailed(error)
        }
    }
}

// MARK: - JSON Decoder

/// Aivora’s built-in JSON decoder.
///
/// Provides a consistent `JSONDecoder` configured to match
/// the encoder’s style, ensuring reliable round-tripping of data.
public struct AivoraJSONDecoder {
    
    /// Shared decoder configured for `snake_case` keys and ISO8601 date decoding.
    private static let shared: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    /// Decodes JSON data into a Swift model.
    /// - Parameters:
    ///   - type: The type of object to decode.
    ///   - data: The JSON data to decode from.
    /// - Throws: `AivoraError.decodingFailed` if decoding fails.
    /// - Returns: A decoded Swift object of type `T`.
    public static func decode<T: Decodable>(_ type: T.Type = T.self, from data: Data) throws -> T {
        do {
            return try shared.decode(type, from: data)
        } catch {
            throw AivoraError.decodingFailed(error)
        }
    }
}

// MARK: - URL Utilities

/// Resolves a relative or absolute path into a valid `URL`.
///
/// Used internally by Aivora to standardize URL resolution.
/// - Parameters:
///   - path: API endpoint or relative URL path.
///   - baseURL: Optional base URL for constructing absolute paths.
/// - Throws: `AivoraError.invalidURL` if the URL is invalid.
/// - Returns: A fully resolved `URL`.
private func resolveURL(path: String, baseURL: URL?) throws -> URL {
    guard let resolved = (baseURL != nil)
        ? URL(string: path, relativeTo: baseURL)?.absoluteURL
        : URL(string: path)
    else {
        throw AivoraError.invalidURL
    }
    return resolved
}

// MARK: - Standard Request

/// Represents a standard HTTP request structure used by Aivora.
///
/// Encapsulates path, method, headers, query parameters, and body data.
/// Also provides helper functions for converting to native `URLRequest`.
public struct AivoraRequest {
    /// The API endpoint or relative path.
    public let path: String
    
    /// The HTTP method used for the request.
    public let method: AivoraHTTPMethod
    
    /// Optional query parameters added to the request URL.
    public var queryItems: [URLQueryItem] = []
    
    /// HTTP headers associated with the request.
    public var headers: [String: String] = [:]
    
    /// The HTTP body payload, if any.
    public var body: Data? = nil
    
    /// A unique cache key generated from method, path, and query items.
    public var cacheKey: String {
        "\(method.rawValue):\(path)?\(queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&"))"
    }

    /// Initializes a new request with the specified parameters.
    /// - Parameters:
    ///   - path: API path or endpoint.
    ///   - method: HTTP method (default: `.GET`).
    ///   - headers: Optional HTTP headers.
    ///   - queryItems: Optional query parameters.
    ///   - body: Optional request body data.
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

    /// Converts an `AivoraRequest` into a native `URLRequest`.
    /// - Parameter baseURL: Optional base URL to prepend to the path.
    /// - Throws: `AivoraError.invalidURL` if URL formation fails.
    /// - Returns: A fully configured `URLRequest`.
    public func asURLRequest(baseURL: URL?) throws -> URLRequest {
        var components = URLComponents(url: try resolveURL(path: path, baseURL: baseURL), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let finalURL = components?.url else { throw AivoraError.invalidURL }
        
        var req = URLRequest(url: finalURL)
        req.httpMethod = method.rawValue
        req.httpBody = body
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        return req
    }
}

// MARK: - JSON Request Helper

public extension AivoraRequest {
    /// Creates a JSON-based HTTP request by automatically encoding
    /// an `Encodable` object into the request body.
    ///
    /// Example:
    /// ```swift
    /// let user = User(name: "Alice")
    /// let req = try AivoraRequest.json(path: "/users", bodyObject: user)
    /// ```
    /// - Parameters:
    ///   - path: API endpoint path.
    ///   - method: HTTP method (default: `.POST`).
    ///   - headers: Request headers (default includes `application/json`).
    ///   - bodyObject: Encodable object to encode as JSON.
    /// - Throws: `AivoraError.encodingFailed` if encoding fails.
    /// - Returns: Configured `AivoraRequest`.
    static func json<T: Encodable>(
        path: String,
        method: AivoraHTTPMethod = .POST,
        headers: [String: String] = ["Content-Type": "application/json"],
        bodyObject: T
    ) throws -> AivoraRequest {
        let bodyData = try AivoraJSONEncoder.encode(bodyObject)
        return AivoraRequest(path: path, method: method, headers: headers, body: bodyData)
    }
}

// MARK: - Multipart Request

/// Represents a multipart/form-data request for file uploads.
///
/// This type allows building multipart requests with both form fields
/// and files, automatically constructing proper MIME boundaries.
public struct AivoraMultipartRequest {
    /// The API endpoint or upload path.
    public let path: String
    
    /// HTTP headers for the request.
    public var headers: [String: String] = [:]
    
    /// Unique boundary string used to separate multipart sections.
    public var boundary: String = UUID().uuidString
    
    /// Internal storage for multipart body data.
    public var bodyData = Data()
    
    /// Initializes a new multipart request.
    /// - Parameter path: API path or endpoint.
    public init(path: String) {
        self.path = path
    }

    /// Adds a plain text form field to the multipart body.
    /// - Parameters:
    ///   - name: The form field name.
    ///   - value: The field’s text value.
    public mutating func addFormField(name: String, value: String) {
        var part = "--\(boundary)\r\n"
        part += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
        part += "\(value)\r\n"
        bodyData.append(Data(part.utf8))
    }

    /// Adds a file attachment to the multipart body.
    /// - Parameters:
    ///   - fieldName: The name of the file field.
    ///   - filename: The original filename.
    ///   - mimeType: MIME type (e.g. `"image/jpeg"`).
    ///   - data: The raw file data.
    public mutating func addFile(fieldName: String, filename: String, mimeType: String, data: Data) {
        var part = "--\(boundary)\r\n"
        part += "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n"
        part += "Content-Type: \(mimeType)\r\n\r\n"
        bodyData.append(Data(part.utf8))
        bodyData.append(data)
        bodyData.append(Data("\r\n".utf8))
    }

    /// Builds the final `URLRequest` for multipart upload.
    /// - Parameter baseURL: Optional base URL for the endpoint.
    /// - Throws: `AivoraError.invalidURL` if URL construction fails.
    /// - Returns: Fully prepared `URLRequest` with multipart body.
    public func asURLRequest(baseURL: URL?) throws -> URLRequest {
        var req = URLRequest(url: try resolveURL(path: path, baseURL: baseURL))
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        var final = bodyData
        final.append(Data("--\(boundary)--\r\n".utf8))
        req.httpBody = final
        return req
    }
}
