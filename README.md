<img width="1792" height="576" alt="AivoraLOGOT" src="https://github.com/user-attachments/assets/df7caa54-0cce-4214-ae52-98ae8717650b" />

# Aivora – The Modern Swift Networking Engine

![Aivora](https://img.shields.io/badge/Aivora-Networking%20Engine-red)
[![Swift](https://img.shields.io/badge/Swift-5.7%2B-orange.svg)](https://swift.org)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-blue.svg)
![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Version](https://img.shields.io/badge/Version-1.1.0-blue.svg)

Aivora is a **pure Swift Concurrency–based** networking library designed as a modern replacement for Alamofire.  
Lightweight, fast, and beginner-friendly — it’s built to simplify async/await HTTP networking while offering advanced power features.

---

## Table of Contents
- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Advanced Examples](#-advanced-examples)
- [Testing & CI](#-testing--ci)
- [Contributing](#-contributing)
- [Author](#-author)
- [License](#-license)
  
---

## Features

| Category | Description |
|-----------|--------------|
| **Language Support** | Pure Swift Concurrency (async/await) |
| **Dependency Size** | Lightweight – only uses Foundation |
| **Performance** | Optimized for speed and low memory usage |
| **Request Handling** | SmartRequest engine with automatic configuration |
| **Response Decoding** | Auto-decodes any Codable model (nested objects supported) |
| **Error Handling** | Detailed smart error system with hints and suggestions |
| **Retry Logic** | Automatic retry with exponential backoff |
| **Caching** | Smart memory + disk caching with TTL |
| **Logging** | Advanced request/response summary & timing |
| **Multipart Uploads** | Simple uploadMultipart() with progress and async/await |
| **File Download** | Resumable + optional background mode |
| **Network Reachability** | Smart network listener with auto-retry when online |
| **Offline Support** | Offline queue (executes pending requests when reconnected) |
| **Interceptors** | Token auto-refresh and adapter chain support |
| **Progress Tracking** | Real-time upload/download progress |
| **AI Insights (unique)** | Detects slow endpoints & suggests optimizations |
| **Ease of Use** | Extremely beginner-friendly syntax |
| **Platform Support** | iOS, macOS, watchOS, tvOS |
| **License** | MIT |

---

## Installation

### Swift Package Manager
1. In Xcode, go to **File → Add Packages…**
2. Enter:
   ```swift
   https://github.com/WeTechnoMind/Aivora.git
   ```
3. Select **Version: 1.1.0** (exact tag).

Or manually add to `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/WeTechnoMind/Aivora.git", from: "1.1.0")
]
```

---

## Quick Start
```swift
import Foundation
import Aivora

@main
struct ExampleApp {
    static func main() async {
        // Step 1: Create the client configuration
        let config = AivoraClient.Configuration(
            baseURL: URL(string: "https://jsonplaceholder.typicode.com")
        )

        // Step 2: Initialize AivoraClient
        let client = AivoraClient(configuration: config)

        do {
            // Step 3: Define the request (relative path only)
            let request = AivoraRequest(
                path: "/posts/1",
                method: .GET
            )

            // Step 4: Execute and decode directly into a Swift model
            struct Post: Decodable {
                let id: Int
                let title: String
                let body: String
            }

            let post: Post = try await client.request(request)
            print("Post ID:", post.id)
            print("Title:", post.title)
            print("Body:", post.body)

        } catch {
            // Step 5: Handle errors gracefully
            print("Request failed:", error)
        }
    }
}

```

## Advanced Examples

### 1. AI Insights
```swift

AivoraAIInsights brings AI-assisted performance analytics directly into your app — no cloud or ML dependencies.
It continuously tracks request durations, learns adaptive thresholds, and detects trends such as performance degradation or improvement.

import Aivora
import Foundation

// Access the shared AI insights instance
let insights = AivoraAIInsights.shared

// Simulate recording request durations
insights.record(endpoint: "/api/login", duration: 1.2)
insights.record(endpoint: "/api/login", duration: 0.9)
insights.record(endpoint: "/api/login", duration: 1.4)
insights.record(endpoint: "/api/login", duration: 2.0)
insights.record(endpoint: "/api/login", duration: 1.8)
insights.record(endpoint: "/api/login", duration: 2.1)

// Generate a full AI insight report
let report = insights.insightReport(for: "/api/login")
print(report)

// Get a short actionable suggestion (for logs or UI)
if let suggestion = insights.suggestion(for: "/api/login") {
    print(suggestion)
}

Example Output

  Aivora AI Insight Report
───────────────────────────────
Endpoint: /api/login
Samples: 6
Average Response: 1.57s
Learned Threshold: 1.88s
Trend: Performance degrading by approximately 25%.
Insight: System performance is within optimal parameters.

/api/login average response time: 1.57s. Consider optimization or caching.

Features

- Learns adaptive thresholds using mean + standard deviation.

- Detects performance trends (improving, degrading, or stable).

- Stores insights persistently across sessions using UserDefaults.

- Provides human-readable reports and short suggestions for UI or logging.


```


### 2. POST Request with Body

```swift
import Foundation
import Aivora

@main
struct PostExample {
    static func main() async {
        // Step 1: Configure the client
        let config = AivoraClient.Configuration(
            baseURL: URL(string: "https://jsonplaceholder.typicode.com")
        )
        let client = AivoraClient(configuration: config)

        // Step 2: Define request & response models
        struct CreatePostRequest: Encodable {
            let title: String
            let body: String
            let userId: Int
        }

        struct CreatePostResponse: Decodable {
            let id: Int
            let title: String
            let body: String
            let userId: Int
        }

        // Step 3: Build the endpoint
        let endpoint = AivoraRequest(path: "/posts", method: .POST)

        // Step 4: Perform POST request with JSON body
        do {
            let requestBody = CreatePostRequest(title: "foo", body: "bar", userId: 1)
            let response: CreatePostResponse = try await client.request(endpoint, body: requestBody)

            // Step 5: Handle decoded response
            print("Created Post:")
            print("ID:", response.id)
            print("Title:", response.title)
            print("Body:", response.body)
            print("User ID:", response.userId)

        } catch {
            // Step 6: Handle any networking or decoding errors
            print("Request failed:", error)
        }
    }
}

```

### 3. GET Request with Body
```swift
import Foundation
import Aivora

@main
struct GetExample {
    static func main() async {
        // Step 1: Configure the Aivora client
        let config = AivoraClient.Configuration(
            baseURL: URL(string: "https://jsonplaceholder.typicode.com")
        )
        let client = AivoraClient(configuration: config)

        // Step 2: Define a Decodable model for the API response
        struct Comment: Decodable {
            let postId: Int
            let id: Int
            let name: String
            let email: String
            let body: String
        }

        // Step 3: Create a request endpoint with query parameters
        let request = AivoraRequest(
            path: "/comments",
            method: .GET,
            queryItems: [
                URLQueryItem(name: "postId", value: "1")
            ]
        )

        // Step 4: Perform the request
        do {
            let comments: [Comment] = try await client.request(request)
            print("Comments for postId=1:\n")
            for comment in comments {
                print("💬 \(comment.name) (\(comment.email)):\n\(comment.body)\n")
            }
        } catch {
            // Step 5: Handle network or decoding errors
            print("Error fetching comments:", error)
        }
    }
}

```

### 4. Multipart Upload with Progress
```swift
import Foundation
import Aivora
import UIKit // Needed only for UIImage to Data conversion

@main
struct MultipartUploadExample {
    static func main() async {
        // Step 1: Initialize client
        let config = AivoraClient.Configuration(
            baseURL: URL(string: "https://example.com")
        )
        let client = AivoraClient(configuration: config)

        // Step 2: Prepare multipart request
        var multipartRequest = AivoraMultipartRequest(path: "/upload")

        // Add text fields
        multipartRequest.addFormField(name: "username", value: "dhiren")

        // Add file data (optional)
        if let imageData = UIImage(named: "photo.jpg")?.jpegData(compressionQuality: 0.8) {
            multipartRequest.addFile(
                fieldName: "file",
                filename: "photo.jpg",
                mimeType: "image/jpeg",
                data: imageData
            )
        }

        // Step 3: Perform upload using AivoraClient
        do {
            let response: UploadResponse = try await client.upload(
                multipartRequest,
                onProgress: { progress in
                    print(String(format: "Upload progress: %.2f%%", progress * 100))
                }
            )

            // Step 4: Handle decoded response
            print("Upload complete:")
            print("File ID:", response.fileId)
            print("URL:", response.url)

        } catch {
            // Step 5: Centralized error handling
            print("Upload failed:", error)
        }
    }
}

// MARK: - Response Model
struct UploadResponse: Decodable {
    let fileId: String
    let url: String
}

```

### 5. Using a Request Adapter
```swift

You can automatically inject headers (like tokens) using adapters:

struct AuthAdapter: AivoraRequestAdapter {
    func adapt(_ request: AivoraRequest) async throws -> AivoraRequest {
        var modified = request
        modified.headers["Authorization"] = "Bearer myToken"
        return modified
    }
}
```

### 6. File Download (Resumable)
```swift
import Foundation
import Aivora

@main
struct DownloadExample {
    static func main() async {
        let url = URL(string: "https://speed.hetzner.de/100MB.bin")! // Example file

        print("Starting download...")

        // Start the download
        let task = AivoraDownloadManager.shared.download(
            url: url,
            progress: { progress in
                let percentage = Int(progress * 100)
                print("Download Progress: \(percentage)%")
            },
            completion: { localURL, error in
                if let error = error {
                    print("Download failed: \(error.localizedDescription)")
                } else if let localURL = localURL {
                    print("File downloaded successfully at:", localURL.path)
                }
            }
        )

        // For demo: cancel after 3 seconds to simulate a network interruption
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("Pausing download...")
            task.cancel { resumeData in
                if let data = resumeData {
                    // Save resume data to continue later
                    AivoraDownloadManager.shared.saveResumeData(data, for: url)
                    print("Resume data saved for later continuation.")
                }
            }
        }

        // For demo: resume after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            if let resumeData = AivoraDownloadManager.shared.loadResumeData(for: url) {
                print("Resuming download...")
                AivoraDownloadManager.shared.resume(with: resumeData)
            } else {
                print("No resume data found.")
            }
        }

        RunLoop.current.run() // Keep app running for demo
    }
}
```

### 7. Token Auto-Refresh Interceptor
```swift
import Foundation
import Aivora

@main
struct TokenInterceptorExample {
    static func main() async {
        // STEP 1: Initialize your interceptor with initial token and refresh endpoint
        let interceptor = AivoraTokenRefreshInterceptor(
            initialToken: "initial-demo-token",
            refreshURL: URL(string: "https://example.com/api/refresh-token")
        )
        
        // STEP 2: Create your request that needs authentication
        let request = AivoraRequest(
            path: "https://example.com/api/secure-endpoint",
            method: .GET
        )
        
        do {
            // STEP 3: Intercept the request (attaches Authorization header)
            var urlRequest = try request.asURLRequest(baseURL: nil)
            urlRequest = try await interceptor.intercept(urlRequest)
            
            // STEP 4: Perform the request
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // STEP 5: Handle response (interceptor auto-detects 401 and refreshes)
            await interceptor.didReceive(response, data: data)
            
            if let json = try? JSONSerialization.jsonObject(with: data) {
                print("Authenticated response:", json)
            }
            
        } catch {
            print("Request failed:", error)
        }
    }
}

```

### 8. Simulated Refresh Example (for Testing)
```swift

If you don’t specify a real refreshURL, the interceptor automatically simulates a token refresh after 1 second:

let interceptor = AivoraTokenRefreshInterceptor(initialToken: "expired-token")

await interceptor.refreshToken()
// Output: Token refreshed (simulated)

```

### 9. Offline Queue Example
```swift

AivoraOfflineQueue helps you safely queue network tasks when the device is offline and automatically re-run them later when connectivity is restored.

This is useful for background syncs, failed uploads, or caching API calls for retry.


import Aivora
import Foundation

// Setup your AivoraClient (assuming your API base URL)
let client = AivoraClient(baseURL: URL(string: "https://api.example.com")!)

// Assign the client to the offline queue for global access
AivoraOfflineQueue.shared.client = client

// Simulate an offline scenario
let isOffline = true

// Enqueue a network call while offline
if isOffline {
    AivoraOfflineQueue.shared.enqueue {
        do {
            // Example API request when back online
            let request = AivoraRequest(path: "/user/sync", method: .POST)
            let response = try await client.send(request)
            print("Synced after reconnect:", response)
        } catch {
            print("Sync failed:", error)
        }
    }

    // Optionally persist queued jobs to disk
    AivoraOfflineQueue.shared.persist()
    print("🕓 Task queued for later and persisted.")
}

// Simulate regaining network connectivity
let isNowOnline = true

if isNowOnline {
    // Restore any previous queue data (if app restarted)
    AivoraOfflineQueue.shared.restore()

    // Execute all pending jobs
    AivoraOfflineQueue.shared.flush()
    print("All offline tasks executed.")
}


Example Output

Task queued for later and persisted.
[Aivora][OfflineQueue] Restored placeholders: ["2F3B8D2E-7E8C-4E89-9C5F-2C1D5A9A41F7"]
All offline tasks executed.
Synced after reconnect: 200 OK


```

---

## Testing & CI

Run unit tests:
```bash
swift test
```

GitHub Actions CI (`.github/workflows/ci.yml`) automatically builds and tests on macOS.

---

##  Contributing

Contributions are welcome!  

Before contributing to Aivora, please read the instructions detailed in our [contribution guide](CONTRIBUTING.md).

---

## Author

**WeTechnoMind**  
Crafted with ❤️ in Swift — lightweight, fast, and ready for modern apps.

---

## License

Aivora is released under the MIT license. See [LICENSE](LICENSE) for details.




