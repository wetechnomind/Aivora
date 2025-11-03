//
//  AivoraCache.swift
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

/// `AivoraCache` provides a lightweight in-memory caching layer built on top of `NSCache`.
///
/// It is designed for temporary storage of objects such as API responses,
/// decoded models, or image data to enhance performance and reduce redundant network calls.
///
/// This class is implemented as a **singleton** for easy global access and
/// ensures thread-safety via `NSCache`.
public final class AivoraCache {

    /// Shared singleton instance for global cache access.
    public static let shared = AivoraCache()

    /// The internal cache storage using `NSCache`.
    private var memory: NSCache<NSString, AnyObject> = NSCache()

    /// Private initializer to prevent external instantiation.
    private init() {}

    // MARK: - Configuration

    /// The maximum number of objects the cache can hold.
    public var countLimit: Int {
        get { memory.countLimit }
        set { memory.countLimit = newValue }
    }

    /// The maximum total cost that the cache can hold.
    public var totalCostLimit: Int {
        get { memory.totalCostLimit }
        set { memory.totalCostLimit = newValue }
    }

    // MARK: - Cache Operations

    /// Stores an object in the cache for the given key.
    public func set(value: AnyObject, forKey key: String) {
        memory.setObject(value, forKey: NSString(string: key))
    }

    /// Stores an object in the cache with an associated cost.
    public func set(value: AnyObject, forKey key: String, cost: Int) {
        memory.setObject(value, forKey: NSString(string: key), cost: cost)
    }

    /// Retrieves a cached object for the specified key.
    public func value(forKey key: String) -> AnyObject? {
        return memory.object(forKey: NSString(string: key))
    }

    /// Retrieves a cached object and attempts to cast it to the specified type.
    public func value<T>(forKey key: String, as type: T.Type) -> T? {
        return memory.object(forKey: NSString(string: key)) as? T
    }

    /// Removes a specific cached object associated with the given key.
    public func remove(forKey key: String) {
        memory.removeObject(forKey: NSString(string: key))
    }

    /// Clears all cached objects from memory.
    public func clear() {
        memory.removeAllObjects()
    }
}
