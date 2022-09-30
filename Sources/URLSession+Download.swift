//
//  URLSession+Download.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 14.07.22.
//

import Combine
import Foundation

extension URLSession {

    // MARK: Methods

    public func startDownload(
        for request: URLRequest,
		to destinationURL: URL? = nil,
        progress: @escaping (Double) -> Void = { _ in },
        resumeData resumeDataHandler: ((Data?) -> Void)? = nil
    ) async throws -> (URL, URLResponse) {
		try await download(to: destinationURL) {
            $0.downloadTask(with: request, completionHandler: $1)
        } progress: {
            progress($0)
        } resumeData: {
            resumeDataHandler?($0)
        }
    }

    public func startDownload(
        from url: URL,
		to destinationURL: URL? = nil,
        progress: @escaping (Double) -> Void = { _ in },
        resumeData resumeDataHandler: ((Data?) -> Void)? = nil
    ) async throws -> (URL, URLResponse) {
		try await download(to: destinationURL) {
            $0.downloadTask(with: url, completionHandler: $1)
        } progress: {
            progress($0)
        } resumeData: {
            resumeDataHandler?($0)
        }
    }

    public func resumeDownload(
        from resumeData: Data,
		to destinationURL: URL? = nil,
        progress: @escaping (Double) -> Void = { _ in },
        resumeData resumeDataHandler: ((Data?) -> Void)? = nil
    ) async throws -> (URL, URLResponse) {
		try await download(to: destinationURL) {
            $0.downloadTask(withResumeData: resumeData, completionHandler: $1)
        } progress: {
            progress($0)
        } resumeData: {
            resumeDataHandler?($0)
        }
    }

    // MARK: Helpers

    private func download(
		to destinationURL: URL?,
        create: @escaping (URLSession, @Sendable @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask,
        progress: @escaping (Double) -> Void,
        resumeData resumeDataHandler: @escaping (Data?) -> Void
    ) async throws -> (URL, URLResponse) {
        var task: URLSessionDownloadTask?
        var progressCancellable: Cancellable?
        let onCancel = {
            task?.cancel { resumeDataHandler($0) }
            progressCancellable?.cancel()
        }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = create(self) { url, response, error in
                    guard let url = url, let response = response else {
						precondition(error != nil, "There should always be either both url and response or an error.")
                        continuation.resume(throwing: error ?? URLError(.badServerResponse))
                        return
                    }

					do {
						let fileManager = FileManager.default
						if let destination = destinationURL {
							try fileManager.moveItem(at: url, to: destination)
							continuation.resume(returning: (destination, response))
						} else {
							let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
							var destination = temporaryDirectory.appendingPathComponent("_AsyncNetwork_" + UUID().uuidString)
							while fileManager.fileExists(atPath: destination.path) {
								destination = temporaryDirectory.appendingPathComponent("_AsyncNetwork_" + UUID().uuidString)
							}
							try fileManager.moveItem(at: url, to: destination)
							continuation.resume(returning: (destination, response))
						}
					} catch {
						continuation.resume(throwing: error)
					}
                }
                progressCancellable = task?.progress
                    .publisher(for: \.fractionCompleted)
                    .sink(receiveValue: progress)
                task?.resume()
            }

        } onCancel: {
            onCancel()
        }
    }

}
