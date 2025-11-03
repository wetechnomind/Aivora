//
//  AivoraAIInsights.swift
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

/// `AivoraAIInsights`
///
/// A lightweight AI-assisted performance analytics engine for **Aivora**.
/// Tracks request durations, detects performance trends,
/// and learns adaptive thresholds for intelligent recommendations.
///
/// Designed for **local AI inference** — no external ML/AI dependencies.
/// Perfect for observing client-side latency and generating contextual insights.
public final class AivoraAIInsights {
    
    // MARK: - Singleton
    
    /// Shared singleton instance to ensure centralized analytics access.
    public static let shared = AivoraAIInsights()
    
    // MARK: - Private Properties
    
    /// Dictionary to maintain endpoint-wise duration history.
    /// Key: Endpoint path (e.g., "/api/login")
    /// Value: Array of recorded request durations (in seconds)
    private var records: [String: [TimeInterval]] = [:]
    
    /// Lock used to ensure thread-safe access to `records` dictionary.
    private let lock = NSLock()
    
    /// Key used to store serialized insights data in `UserDefaults`.
    private let storageKey = "AivoraAIInsights_Records"
    
    // MARK: - Configurable Properties
    
    /// Defines how many duration samples to retain per endpoint.
    /// Helps maintain recent behavior without excessive memory use.
    public var recordWindow: Int = 50
    
    /// Default threshold (in seconds) to consider a request “slow”
    /// when insufficient historical data is available.
    public var defaultSlowThreshold: TimeInterval = 1.5
    
    // MARK: - Initialization
    
    /// Initializes the engine and loads any stored analytics data from previous app sessions.
    private init() {
        loadInsights()
    }
    
    // MARK: - Recording
    
    /// Records a request duration for a given endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: Unique identifier for the request (e.g., "/api/login").
    ///   - duration: Time taken to complete the request (in seconds).
    ///
    /// Stores durations in a sliding window fashion (limited by `recordWindow`)
    /// to ensure data remains recent and memory efficient.
    public func record(endpoint: String, duration: TimeInterval) {
        lock.lock(); defer { lock.unlock() } // Ensure thread-safe operation
        
        // Retrieve existing duration samples or create a new array
        var samples = records[endpoint] ?? []
        samples.append(duration)
        
        // Keep only the latest `recordWindow` samples
        if samples.count > recordWindow {
            samples.removeFirst(samples.count - recordWindow)
        }
        
        // Update dictionary and persist changes
        records[endpoint] = samples
        saveInsights()
    }
    
    // MARK: - AI-Assisted Analytics
    
    /// Calculates a dynamic threshold for "slow" response detection.
    ///
    /// Uses statistical analysis:
    /// - Mean (average)
    /// - Standard deviation
    ///
    /// The adaptive threshold = mean + 1.5 × standard deviation.
    /// This ensures that only *significant outliers* are flagged as slow.
    private func adaptiveThreshold(for endpoint: String) -> TimeInterval {
        guard let samples = records[endpoint], samples.count > 5 else {
            // Fallback to default threshold if insufficient samples
            return defaultSlowThreshold
        }
        
        // Compute mean and standard deviation
        let average = samples.reduce(0, +) / Double(samples.count)
        let variance = samples.map { pow($0 - average, 2) }.reduce(0, +) / Double(samples.count)
        let stdDev = sqrt(variance)
        
        // Dynamic threshold: captures changing system conditions
        return average + stdDev * 1.5
    }
    
    /// Detects the performance trend for a given endpoint.
    ///
    /// Compares the average durations of the first half vs. second half of data samples:
    /// - If performance worsened by >20%, it’s flagged as degrading.
    /// - If improved by >20%, it’s flagged as improving.
    /// - Otherwise, trend is stable.
    ///
    /// - Returns: A human-readable summary of performance direction.
    private func trend(for endpoint: String) -> String {
        guard let samples = records[endpoint], samples.count > 5 else {
            return "Not enough data."
        }
        
        let half = samples.count / 2
        let firstHalfAvg = samples.prefix(half).reduce(0, +) / Double(half)
        let secondHalfAvg = samples.suffix(half).reduce(0, +) / Double(half)
        
        // Analyze relative performance changes
        if secondHalfAvg > firstHalfAvg * 1.2 {
            // Slower over time
            let delta = Int(((secondHalfAvg / firstHalfAvg) - 1) * 100)
            return "Performance degrading by approximately \(delta)%."
        } else if secondHalfAvg < firstHalfAvg * 0.8 {
            // Faster over time
            let delta = Int(((firstHalfAvg / secondHalfAvg) - 1) * 100)
            return "Performance improving by approximately \(delta)%."
        } else {
            // Roughly stable
            return "Performance trend stable."
        }
    }
    
    // MARK: - Insight Generation
    
    /// Generates a full, human-readable report for an endpoint.
    ///
    /// Provides:
    /// - Sample count
    /// - Average response time
    /// - Learned adaptive threshold
    /// - Trend interpretation
    /// - AI suggestion if performance is poor
    ///
    /// - Parameter endpoint: Endpoint to analyze
    /// - Returns: Insight report text (for logs, debugging, or display)
    public func insightReport(for endpoint: String) -> String {
        lock.lock(); defer { lock.unlock() }
        
        guard let samples = records[endpoint], !samples.isEmpty else {
            return "No recorded data available for \(endpoint)."
        }
        
        // Compute key analytics
        let average = samples.reduce(0, +) / Double(samples.count)
        let threshold = adaptiveThreshold(for: endpoint)
        let trendMessage = trend(for: endpoint)
        
        // Build readable insight report
        var report = """
        Aivora AI Insight Report
        ───────────────────────────────
        Endpoint: \(endpoint)
        Samples: \(samples.count)
        Average Response: \(String(format: "%.2f", average))s
        Learned Threshold: \(String(format: "%.2f", threshold))s
        Trend: \(trendMessage)
        """
        
        // Add contextual recommendation
        if average > threshold {
            report += "\n💡 Suggestion: Response time exceeds adaptive threshold. Consider caching, pagination, or backend optimization."
        } else {
            report += "\nInsight: System performance is within optimal parameters."
        }
        
        return report
    }
    
    /// Provides a short, actionable suggestion string suitable for
    /// UI alerts or console logs.
    ///
    /// - Parameter endpoint: The endpoint being evaluated.
    /// - Returns: A short suggestion (if needed), or `nil` if performance is acceptable.
    public func suggestion(for endpoint: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        
        guard let samples = records[endpoint], !samples.isEmpty else { return nil }
        
        // Compare average to adaptive threshold
        let average = samples.reduce(0, +) / Double(samples.count)
        let threshold = adaptiveThreshold(for: endpoint)
        
        if average > threshold {
            return "\(endpoint) average response time: \(String(format: "%.2fs", average)). Consider optimization or caching."
        }
        return nil
    }
    
    // MARK: - Persistence
    
    /// Serializes analytics data into JSON and saves it to UserDefaults.
    /// Ensures that AI learning persists between app launches.
    private func saveInsights() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    /// Loads previously saved analytics data from UserDefaults.
    /// This allows adaptive thresholds to “learn” over time.
    private func loadInsights() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: [TimeInterval]].self, from: data) else {
            return
        }
        records = decoded
    }
}
