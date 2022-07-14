//
//  URLSession+Data.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

extension URLSession {

    public func receiveData(for request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return try await data(for: request)
        }
        var task: URLSessionDataTask?
        let onCancel = { task?.cancel() }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = self.dataTask(with: request) { data, response, error in
                    guard let data = data, let response = response, error == nil else {
                        precondition(error != nil, "There should either be data with a response or an error.")
                        continuation.resume(throwing: error ?? URLError(.badServerResponse))
                        return
                    }
                    continuation.resume(returning: (data, response))
                }
                task?.resume()
            }
        } onCancel: {
            onCancel()
        }
    }

    public func receiveData(from url: URL) async throws -> (Data, URLResponse) {
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return try await data(from: url)
        }
        return try await receiveData(for: .init(url: url))
    }

}
