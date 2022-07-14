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
    public func data(for request: URLRequest) async throws -> Data {
        try await _data(for: request, retryCount: maximumRetryCount)
    }

    @discardableResult
    public func data(from url: URL) async throws -> Data {
        try await data(for: .init(url: url))
    }

    // MARK: Helpers

    private func _data(for request: URLRequest, retryCount: Int) async throws -> Data {
        var actualRequest = request

        try Task.checkCancellation()

        for interceptor in interceptors {
            try await interceptor.prepare(&actualRequest)
        }

        try Task.checkCancellation()

        var (data, response) = try await session.receiveData(for: actualRequest)

        try Task.checkCancellation()

        for interceptor in interceptors.reversed() {
            if try await interceptor.shouldRetry(actualRequest, for: &response, data: &data) && retryCount > 0 {
                try Task.checkCancellation()
                return try await _data(for: request, retryCount: retryCount - 1)
            }
        }

        try Task.checkCancellation()

        return data
    }

}
