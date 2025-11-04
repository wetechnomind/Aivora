//
//  ViewController.swift
//  Aivora Example
//
//  Created by Example on 2025-11-04.
//

import UIKit
import Aivora

/// Example view controller demonstrating how to use the Aivora networking framework.
final class ViewController: UIViewController {
    
    // MARK: - Client Configuration
    
    /// The main AivoraClient instance configured with a base URL and token interceptor chain.
    private let client: AivoraClient = {
        // Define the base configuration (API root URL)
        let config = AivoraClient.Configuration(
            baseURL: URL(string: "https://jsonplaceholder.typicode.com")
        )
        
        // Example interceptor simulating token refresh capability
        let tokenInterceptor = AivoraTokenRefreshInterceptor(
            initialToken: nil,
            refreshURL: URL(string: "https://example.com/refresh")
        )
        
        // Combine interceptors into a chain (can add more)
        let chain = AivoraInterceptorChain(interceptors: [tokenInterceptor])
        
        // Create the AivoraClient instance
        return AivoraClient(configuration: config, adapter: chain)
    }()
    
    // MARK: - UI Elements
    
    /// Stack view containing all demo buttons.
    private let stack = UIStackView()
    
    /// Label for displaying operation status or results.
    private let statusLabel = UILabel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    // MARK: - UI Setup
    
    /// Configures the layout and appearance of all UI components.
    private func setupUI() {
        // Stack configuration
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        // Center stack in the view
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])
        
        // Create buttons with titles and actions
        let buttons: [(String, Selector)] = [
            ("Fetch GET /posts/1", #selector(fetchTapped)),
            ("POST /posts", #selector(postTapped)),
            ("Multipart Upload", #selector(uploadTapped)),
            ("Download File", #selector(downloadTapped)),
            ("Enqueue Offline Request", #selector(offlineTapped)),
            ("Show Cache Keys", #selector(cacheTapped)),
            ("Show AI Insights", #selector(aiTapped))
        ]
        
        // Add all buttons to stack view
        for (title, action) in buttons {
            stack.addArrangedSubview(makeButton(title: title, action: action))
        }
        
        // Configure status label below stack
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])
    }
    
    /// Helper method to create a styled button for demo actions.
    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 320).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - Actions
    
    /// Example GET request fetching a post from JSONPlaceholder.
    @objc private func fetchTapped() {
        statusLabel.text = "Fetching..."
        Task {
            struct Post: Decodable { let id: Int; let title: String; let body: String }
            do {
                // Build GET request
                let request = AivoraRequest(path: "/posts/1", method: .GET)
                // Send and decode response
                let post: Post = try await client.request(request)
                statusLabel.text = "✅ \(post.title)"
            } catch {
                statusLabel.text = "❌ Fetch failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Example POST request sending JSON body.
    @objc private func postTapped() {
        statusLabel.text = "Posting..."
        Task {
            struct PostBody: Encodable { let title: String; let body: String; let userId: Int }
            struct PostResponse: Decodable { let id: Int; let title: String; let body: String }
            
            // Prepare request body
            let body = PostBody(title: "Hello", body: "From Aivora Example", userId: 1)
            let request = AivoraRequest(path: "/posts", method: .POST)
            
            do {
                // Send POST request and decode response
                let response: PostResponse = try await client.request(request, body: body)
                statusLabel.text = "✅ Posted: \(response.title)"
            } catch {
                statusLabel.text = "❌ Post failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Example multipart upload with progress callback.
    @objc private func uploadTapped() {
        statusLabel.text = "Uploading..."
        Task {
            do {
                // Build multipart request
                var multipart = AivoraMultipartRequest(path: "/upload")
                multipart.addFormField(name: "title", value: "Demo Upload")
                
                // Attach a text file as data
                let fileData = "Hello Aivora".data(using: .utf8)!
                multipart.addFile(
                    fieldName: "file",
                    filename: "demo.txt",
                    mimeType: "text/plain",
                    data: fileData
                )
                
                // Define expected response model
                struct UploadResponse: Decodable { let id: Int }
                
                // Perform upload with progress tracking
                let response: UploadResponse = try await client.upload(
                    multipart,
                    onProgress: { progress in
                        DispatchQueue.main.async {
                            self.statusLabel.text = String(format: "📤 Upload: %.0f%%", progress * 100)
                        }
                    }
                )
                statusLabel.text = "✅ Upload complete (id: \(response.id))"
            } catch {
                statusLabel.text = "❌ Upload failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Example file download using AivoraDownloadManager.
    @objc private func downloadTapped() {
        statusLabel.text = "Downloading..."
        guard let url = URL(string: "https://speed.hetzner.de/100MB.bin") else { return }
        
        // Define temporary destination file path
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent("100MB.bin")
        
        // Start download and track progress
        AivoraDownloadManager.shared.download(
            url: url,
            to: dest,
            progress: { progress in
                DispatchQueue.main.async {
                    self.statusLabel.text = String(format: "⬇️ Download: %.0f%%", progress * 100)
                }
            },
            completion: { file, error in
                DispatchQueue.main.async {
                    if let file = file {
                        self.statusLabel.text = "✅ Downloaded: \(file.lastPathComponent)"
                    } else {
                        self.statusLabel.text = "❌ Download failed: \(error?.localizedDescription ?? "Unknown error")"
                    }
                }
            }
        )
    }
    
    /// Example of enqueueing an offline task using AivoraOfflineQueue.
    @objc private func offlineTapped() {
        statusLabel.text = "⏳ Enqueuing offline request..."
        
        // Add background operation to offline queue
        AivoraOfflineQueue.shared.enqueue {
            Task {
                do {
                    struct OfflineBody: Encodable { let title: String; let body: String; let userId: Int }
                    let body = OfflineBody(title: "Offline", body: "Queued", userId: 1)
                    let req = AivoraRequest(path: "/posts", method: .POST)
                    
                    // Execute queued request
                    let _: [String: Any] = try await self.client.request(req, body: body)
                    print("✅ Offline request completed.")
                } catch {
                    print("❌ Offline request failed:", error)
                }
            }
        }
        statusLabel.text = "✅ Offline job enqueued."
    }
    
    /// Displays cache information.
    @objc private func cacheTapped() {
        statusLabel.text = "🗄️ Cache: \(AivoraCache.shared)"
    }
    
    /// Displays AI-based insights for a given endpoint.
    @objc private func aiTapped() {
        let endpoint = "https://jsonplaceholder.typicode.com/posts/1"
        if let suggestion = AivoraAIInsights.shared.suggestion(for: endpoint) {
            statusLabel.text = "🤖 \(suggestion)"
        } else {
            statusLabel.text = "No AI insights available."
        }
    }
}
