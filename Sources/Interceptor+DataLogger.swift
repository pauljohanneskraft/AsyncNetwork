//
//  Interceptor+Logger.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation
import os

public struct DataLoggerInterceptor: Interceptor {

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

extension Interceptor where Self == DataLoggerInterceptor {

    public static func dataLogger(
        request: @escaping (URLRequest) -> Void,
        response: @escaping (URLRequest, URLResponse, Data) -> Void
    ) -> Self {
        .init(logRequest: request, logResponse: response)
    }

    public static func dataResponseLogger(
        subsystem: String = Bundle.main.bundleIdentifier ?? String(),
        category: String = String(describing: DataLoggerInterceptor.self),
        level: OSLogType = .debug
    ) -> Self {
        return .dataLogger { _ in } response: { request, response, data in
            let httpResponse = response as? HTTPURLResponse
            if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
                let logger = Logger(subsystem: subsystem, category: category)
                logger.log(
                    level: level,
                    "Received \(httpResponse?.statusCode.description ?? "non-HTTP response") from \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "-") with \(data.count) bytes"
                )
            } else {
                os_log(
                    level,
                    log: OSLog(subsystem: subsystem, category: category),
                    "Received %@ from %@ %@ with %i bytes",
                    httpResponse?.statusCode.description ?? "non-HTTP response",
                    request.httpMethod ?? "GET",
                    request.url?.absoluteString ?? "-",
                    data.count
                )
            }


        }
    }

}
