# Aivora UIKit Example (Aivora v1.1.0)

This is a minimal UIKit example demonstrating core Aivora features:
- GET request (JSON decode)
- POST request
- Multipart upload with progress
- Resumable file download with progress
- Using an interceptor (token refresh)
- Offline queue sample (enqueue request)
- Cache read/write demonstration
- AI Insights sample (slow endpoint detection)

## How to use
1. Open Xcode and create a new iOS App (UIKit App) project (Single View App). 
2. Add the `Aivora` package as a local Swift Package Dependency: File → Add Packages → Add Local Package → point to your Aivora package root.
3. Copy the files in this folder into your project target (e.g., AppDelegate.swift, SceneDelegate.swift, ViewController.swift).
4. Ensure the project's deployment target is iOS 13.0+.
5. Run the app on a device or simulator.

Notes:
- Background downloads require App Delegate implementation for `handleEventsForBackgroundURLSession` and proper entitlements.
- Replace placeholder URLs (jsonplaceholder / example) with your API endpoints as needed.
