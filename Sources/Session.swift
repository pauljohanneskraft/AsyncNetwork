//
//  Session.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

public final class Session {

    // MARK: Stored Properties

    private let session: URLSession
    private let interceptors: [any Interceptor]
    private let maximumRetryCount: Int

    // MARK: Initialization

    public init(session: URLSession = .shared, interceptors: [any Interceptor] = [], maximumRetryCount: Int = 1) {
        self.session = session
        self.interceptors = interceptors
        self.maximumRetryCount = maximumRetryCount
    }

    // MARK: Methods

    @discardableResult
    func send(_ request: URLRequest) async throws -> Data {
        try await _send(request, retryCount: maximumRetryCount)
    }

    // MARK: Helpers

    private func _send(_ request: URLRequest, retryCount: Int) async throws -> Data {
        var actualRequest = request

        try Task.checkCancellation()

        for interceptor in interceptors {
            try await interceptor.prepare(&actualRequest)
        }

        try Task.checkCancellation()

        var (data, response) = try await session.send(actualRequest)

        try Task.checkCancellation()

        for interceptor in interceptors.reversed() {
            if try await interceptor.shouldRetry(actualRequest, for: &response, data: &data) && retryCount > 0 {
                try Task.checkCancellation()
                return try await _send(request, retryCount: retryCount - 1)
            }
        }

        try Task.checkCancellation()

        return data
    }

}
