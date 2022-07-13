//
//  Interceptor+Logger.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation
import os

public struct LoggerInterceptor: Interceptor {

    // MARK: Stored Properties

    private let logRequest: (URLRequest) -> Void
    private let logResponse: (URLRequest, URLResponse, Data) -> Void

    // MARK: Initialization

    public init(
        logRequest: @escaping (URLRequest) -> Void,
        logResponse: @escaping (URLRequest, URLResponse, Data) -> Void
    ) {
        self.logRequest = logRequest
        self.logResponse = logResponse
    }

    // MARK: Methods

    public func prepare(_ request: inout URLRequest) async throws {
        logRequest(request)
    }

    public func shouldRetry(
        _ request: URLRequest,
        for response: inout URLResponse,
        data: inout Data
    ) async throws -> Bool {
        logResponse(request, response, data)
        return false
    }

}

extension Interceptor where Self == LoggerInterceptor {

    public static func logger(
        request: @escaping (URLRequest) -> Void,
        response: @escaping (URLRequest, URLResponse, Data) -> Void
    ) -> Self {
        LoggerInterceptor(logRequest: request, logResponse: response)
    }

    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
    public static func responseLogger(
        subsystem: String = Bundle.main.bundleIdentifier ?? String(),
        category: String = String(describing: LoggerInterceptor.self),
        level: OSLogType = .debug
    ) -> Self {
        let logger = Logger(subsystem: subsystem, category: category)
        return .logger { _ in } response: { request, response, data in
            let httpResponse = response as? HTTPURLResponse
            logger.log(
                level: level,
                "Received \(httpResponse?.statusCode.description ?? "non-HTTP response") from \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "-") with \(data.count) bytes"
            )
        }
    }

}
