//
//  File.swift
//  
//
//  Created by Paul Kraft on 14.07.22.
//

import Combine
import Foundation

extension URLSession {

    // MARK: Methods

    public func startUpload(
        with request: URLRequest,
        from data: Data,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws -> (Data, URLResponse) {
        try await upload {
            $0.uploadTask(with: request, from: data, completionHandler: $1)
        } progress: {
            progress($0)
        }
    }

    public func startUpload(
        with request: URLRequest,
        fromFile file: URL,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws -> (Data, URLResponse) {
        try await upload {
            $0.uploadTask(with: request, fromFile: file, completionHandler: $1)
        } progress: {
            progress($0)
        }
    }

    // MARK: Helpers

    private func upload(
        create: @escaping (URLSession, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask,
        progress: @escaping (Double) -> Void
    ) async throws -> (Data, URLResponse) {
        var task: URLSessionUploadTask?
        var progressCancellable: Cancellable?
        let onCancel = {
            task?.cancel()
            progressCancellable?.cancel()
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
