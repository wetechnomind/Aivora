//
//  AivoraAIInsightsTests.swift
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

import XCTest
@testable import Aivora

final class AivoraAIInsightsTests: XCTestCase {

    func testRecordAndSuggestion() {
        let insights = AivoraAIInsights.shared
        insights.defaultSlowThreshold = 1.5

        // Simulate multiple slow responses for an endpoint
        for _ in 0..<50 {
            insights.record(endpoint: "/slow", duration: 2.0)
        }

        // Ask AIInsights for a suggestion
        let suggestion = insights.suggestion(for: "/slow")

        // Assert we get a valid suggestion string mentioning key performance hints
        XCTAssertNotNil(suggestion, "Expected a suggestion for slow endpoint")
        if let suggestion = suggestion {
            XCTAssertTrue(
                suggestion.contains("/slow") || suggestion.lowercased().contains("response time"),
                "Suggestion text should reference the endpoint or its latency"
            )
        }
    }

    func testNoSuggestionForFastEndpoint() {
        let insights = AivoraAIInsights.shared
        insights.defaultSlowThreshold = 1.5

        for _ in 0..<20 {
            insights.record(endpoint: "/fast", duration: 0.5)
        }

        let suggestion = insights.suggestion(for: "/fast")
        XCTAssertNil(suggestion, "No suggestion should be generated for consistently fast endpoints")
    }
}
