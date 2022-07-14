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
        progress: @escaping (Double) -> Void = { _ in },
        resumeData resumeDataHandler: ((Data?) -> Void)? = nil
    ) async throws -> (URL, URLResponse) {
        try await download {
            $0.downloadTask(with: request, completionHandler: $1)
        } progress: {
            progress($0)
        } resumeData: {
            resumeDataHandler?($0)
        }
    }

    public func startDownload(
        from url: URL,
        progress: @escaping (Double) -> Void = { _ in },
        resumeData resumeDataHandler: ((Data?) -> Void)? = nil
    ) async throws -> (URL, URLResponse) {
        try await download {
            $0.downloadTask(with: url, completionHandler: $1)
        } progress: {
            progress($0)
        } resumeData: {
            resumeDataHandler?($0)
        }
    }

    public func resumeDownload(
        from resumeData: Data,
        progress: @escaping (Double) -> Void = { _ in },
        resumeData resumeDataHandler: ((Data?) -> Void)? = nil
    ) async throws -> (URL, URLResponse) {
        try await download {
            $0.downloadTask(withResumeData: resumeData, completionHandler: $1)
        } progress: {
            progress($0)
        } resumeData: {
            resumeDataHandler?($0)
        }
    }

    // MARK: Helpers

    private func download(
        create: @escaping (URLSession, @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask,
        progress: @escaping (Double) -> Void,
        resumeData resumeDataHandler: @escaping (Data?) -> Void
    ) async throws -> (URL, URLResponse) {
        var task: URLSessionDownloadTask?
        var progressCancellable: Cancellable?
        let onCancel = {
            task?.cancel {
                resumeDataHandler($0)
                progressCancellable?.cancel()
            }
        }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = create(self) { url, response, error in
                    guard let url = url, let response = response else {
                        assertionFailure("There should always be either both url and response or an error.")
                        continuation.resume(throwing: error ?? URLError(.badServerResponse))
                        return
                    }
                    continuation.resume(returning: (url, response))
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
