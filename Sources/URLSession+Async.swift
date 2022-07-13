//
//  URLSession+Async.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

@available(iOS 13, *)
extension URLSession {

    internal func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let result = try await _send(request)
        try Task.checkCancellation()
        return result
    }

    private func _send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return try await self.data(for: request)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task = self.dataTask(with: request) { data, response, error in
                    guard let data = data, let response = response, error == nil else {
                        precondition(error != nil, "There should either be data with a response or an error.")
                        continuation.resume(throwing: error ?? URLError(.badServerResponse))
                        return
                    }
                    continuation.resume(returning: (data, response))
                }
                task.resume()
            }
        }
    }

}
