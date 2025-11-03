//
// AivoraTokenRefreshInterceptor.swift
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

/// An interceptor that handles automatic token injection and refresh logic
/// for authenticated network requests.
///
/// This class is designed to be used within `AivoraClient` to:
/// - Add a `Bearer` token to outgoing requests.
/// - Automatically refresh the token when receiving an HTTP 401 response.
/// - Provide thread-safe access and mutation of token values.
public final class AivoraTokenRefreshInterceptor: AivoraInterceptor {
    
    // MARK: - Private State
    
    /// Lock to synchronize token and refresh operations for thread safety.
    private let lock = NSLock()
    
    /// Indicates if a refresh operation is currently in progress.
    private var isRefreshing = false
    
    /// The currently active access token (if available).
    private var token: String?
    
    /// The endpoint URL used for refreshing tokens (optional).
    private var refreshURL: URL?

    // MARK: - Initialization
    
    /// Creates a new token interceptor.
    ///
    /// - Parameters:
    ///   - initialToken: The initial token to use for requests (optional).
    ///   - refreshURL: The endpoint used to refresh tokens (optional).
    public init(initialToken: String? = nil, refreshURL: URL? = nil) {
        self.token = initialToken
        self.refreshURL = refreshURL
    }

    // MARK: - Token Access
    
    /// Safely updates the stored access token.
    public func setToken(_ newToken: String?) {
        lock.lock()
        token = newToken
        lock.unlock()
    }

    /// Safely retrieves the current access token.
    public func getToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }

    // MARK: - Request Interception
    
    /// Intercepts an outgoing request and attaches the authorization header if a token exists.
    ///
    /// - Parameter request: The original `URLRequest` before modification.
    /// - Returns: A modified request containing the `Authorization` header.
    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        var req = request
        if let t = getToken() {
            req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    // MARK: - Response Handling
    
    /// Handles responses and triggers token refresh on `401 Unauthorized`.
    ///
    /// - Parameters:
    ///   - response: The received URL response.
    ///   - data: The raw data returned by the server (optional).
    public func didReceive(_ response: URLResponse?, data: Data?) async {
        guard let http = response as? HTTPURLResponse, http.statusCode == 401 else { return }
        await refreshTokenIfNeeded()
    }

    // MARK: - Public Manual Refresh
    
    /// Manually refreshes the token, typically called by `AivoraClient`
    /// or automatically upon detecting an expired session.
    ///
    /// This method is thread-safe and ensures that only one refresh
    /// occurs at a time, even if multiple requests fail concurrently.
    public func refreshToken() async {
        lock.lock()
        if isRefreshing {
            lock.unlock()
            return
        }
        isRefreshing = true
        lock.unlock()

        defer {
            lock.lock()
            isRefreshing = false
            lock.unlock()
        }

        do {
            if let refreshURL = refreshURL {
                var req = URLRequest(url: refreshURL)
                req.httpMethod = "POST"

                // Optional: attach old token or refresh credentials here
                let (data, response) = try await URLSession.shared.data(for: req)

                if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                    // Parse JSON to extract new token
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let newToken = json["token"] as? String {
                        setToken(newToken)
                        print("🔐 Token refreshed successfully (server)")
                    } else {
                        // Fallback if the response isn’t standard JSON
                        setToken(String(data: data, encoding: .utf8))
                        print("🔐 Token refreshed (raw string)")
                    }
                }
            } else {
                // Simulated refresh path — useful for offline or testing scenarios
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                setToken("simulated-token-\(UUID().uuidString)")
                print("🔐 Token refreshed (simulated)")
            }
        } catch {
            print("⚠️ Token refresh failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Internal Auto Refresh
    
    /// Invoked internally by `didReceive(_:,data:)` after detecting a 401 response.
    internal func refreshTokenIfNeeded() async {
        await refreshToken()
    }
}
