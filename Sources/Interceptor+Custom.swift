//
//  Interceptor+Custom.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 13.07.22.
//

import Foundation

public struct CustomInterceptor: Interceptor {

    // MARK: Stored Properties

    private let preparationHandler: (inout URLRequest) async throws -> Void
    private let responseHandler: (URLRequest, inout URLResponse, inout Data) async throws -> Bool

    // MARK: Initialization

    public init(
        prepare preparationHandler: @escaping (inout URLRequest) async throws -> Void,
        shouldRetry responseHandler: @escaping (URLRequest, inout URLResponse, inout Data) async throws -> Bool
    ) {
        self.preparationHandler = preparationHandler
        self.responseHandler = responseHandler
    }

    // MARK: Methods

    public func prepare(_ request: inout URLRequest) async throws {
        try await preparationHandler(&request)
    }

    public func shouldRetry(
        _ request: URLRequest,
        for response: inout URLResponse,
        data: inout Data
    ) async throws -> Bool {
        try await responseHandler(request, &response, &data)
    }

}

extension Interceptor where Self == CustomInterceptor {

    public static func custom(
        prepare: @escaping (inout URLRequest) async throws -> Void,
        shouldRetry: @escaping (URLRequest, inout URLResponse, inout Data) async throws -> Bool
    ) -> Self {
        .init(prepare: prepare, shouldRetry: shouldRetry)
    }

}
