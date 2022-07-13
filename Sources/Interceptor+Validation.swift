//
//  Interceptor+Validation.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

public struct ValidationError: Error {

    // MARK: Stored Properties

    public let response: URLResponse
    public let data: Data

    // MARK: Initialization

    public init(response: URLResponse, data: Data) {
        self.response = response
        self.data = data
    }

}

public struct ValidationInterceptor: Interceptor {

    // MARK: Stored Properties

    let validate: (URLRequest, URLResponse, Data) throws -> Void

    // MARK: Initialization

    public init(validate: @escaping (URLRequest, URLResponse, Data) throws -> Void) {
        self.validate = validate
    }

    // MARK: Methods

    public func shouldRetry(_ request: URLRequest, for response: inout URLResponse, data: inout Data) async throws -> Bool {
        try validate(request, response, data)
        return false
    }

}

extension Interceptor where Self == ValidationInterceptor {

    public static func validate(
        _ validate: @escaping (URLRequest, URLResponse, Data) throws -> Void = { _, _, _ in }
    ) -> Self {
        .init(validate: validate)
    }

    public static func validateStatus(
        validRange: Range<Int> = 200..<300,
        customError: @escaping (URLRequest, HTTPURLResponse, Data) -> Error? = {
            ValidationError(response: $1, data: $2)
        }
    ) -> Self {
        .init { request, response, data in
            if let httpResponse = response as? HTTPURLResponse,
               !validRange.contains(httpResponse.statusCode),
               let error = customError(request, httpResponse, data) {
                throw error
            }
        }
    }

}
